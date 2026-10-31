// Runs only in a disposable app_process on an ARM64 Android emulator.
// The ELF on disk is unchanged. A process-private BRK observes the original BR
// registers, and the signal context performs that BR to the real ART target.
#include <jni.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <sys/system_properties.h>
#include <unistd.h>
#include <signal.h>
#include <ucontext.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
static_assert(sizeof(void*) == 8, "ARM64 JNI layout required");
static_assert(offsetof(JNINativeInterface, FindClass) == 0x30, "FindClass slot");
static_assert(offsetof(JNINativeInterface, ThrowNew) == 0x70, "ThrowNew slot");
static volatile uintptr_t site, observed_pc, observed_x[4];
static volatile sig_atomic_t hits;
static void trap(int, siginfo_t*, void* context) {
    auto* u = static_cast<ucontext_t*>(context);
    if (u->uc_mcontext.pc != site || hits) _exit(91);
    observed_pc = u->uc_mcontext.pc;
    for (int n=0;n<4;++n) observed_x[n] = u->uc_mcontext.regs[n];
    ++hits;
    u->uc_mcontext.pc = u->uc_mcontext.regs[3]; // the replaced BR x3
}
static void require(bool ok, const char* message) {
    if (!ok) { fprintf(stderr, "probe: %s\n", message); _exit(92); }
}
static void patch(uint32_t value) {
    uintptr_t page = site & ~(static_cast<uintptr_t>(getpagesize()) - 1);
    require(mprotect(reinterpret_cast<void*>(page), getpagesize(), PROT_READ|PROT_WRITE|PROT_EXEC) == 0, "mprotect RWX");
    *reinterpret_cast<volatile uint32_t*>(site) = value;
    __builtin___clear_cache(reinterpret_cast<char*>(site), reinterpret_cast<char*>(site+4));
    require(mprotect(reinterpret_cast<void*>(page), getpagesize(), PROT_READ|PROT_EXEC) == 0, "mprotect RX");
}
static void quoted(FILE* f, const char* s) {
    fputc('"',f);
    for (const unsigned char* p=reinterpret_cast<const unsigned char*>(s); *p; ++p) {
        if (*p=='"' || *p=='\\') fputc('\\',f);
        if (*p<32) fprintf(f,"\\u%04x",*p); else fputc(*p,f);
    }
    fputc('"',f);
}
static void pointer(FILE* f, uintptr_t p) { fprintf(f,"\"0x%lx\"",static_cast<unsigned long>(p)); }
static void module(FILE* f, uintptr_t address) {
    Dl_info d{};
    require(dladdr(reinterpret_cast<void*>(address), &d) != 0 && d.dli_fbase, "dladdr target");
    fprintf(f,"{\"path\":"); quoted(f,d.dli_fname);
    fprintf(f,",\"base\":"); pointer(f,reinterpret_cast<uintptr_t>(d.dli_fbase));
    fprintf(f,",\"offset\":"); pointer(f,address-reinterpret_cast<uintptr_t>(d.dli_fbase));
    fprintf(f,",\"symbol\":"); quoted(f,d.dli_sname ? d.dli_sname : "");
    fprintf(f,"}");
}
static void exception_result(JNIEnv* env, const char* message) {
    jthrowable e = env->ExceptionOccurred();
    require(e != nullptr, "target failed to throw");
    env->ExceptionClear();
    jclass cls = env->FindClass("java/io/IOException");
    require(cls && env->IsInstanceOf(e,cls), "wrong exception class");
    jclass throwable = env->FindClass("java/lang/Throwable");
    jmethodID get = env->GetMethodID(throwable,"getMessage","()Ljava/lang/String;");
    auto text = static_cast<jstring>(env->CallObjectMethod(e,get));
    require(!env->ExceptionCheck() && text, "exception message");
    const char* actual = env->GetStringUTFChars(text,nullptr);
    require(actual && strcmp(actual,message)==0, "wrong exception message");
    env->ReleaseStringUTFChars(text,actual);
    env->DeleteLocalRef(text); env->DeleteLocalRef(throwable);
    env->DeleteLocalRef(cls); env->DeleteLocalRef(e);
}
extern "C" JNIEXPORT void JNICALL Java_JniRuntimeProbe_capture(JNIEnv* env, jclass, jstring library, jstring output) {
    const char* path = env->GetStringUTFChars(library,nullptr);
    void* handle = dlopen(path,RTLD_NOW|RTLD_LOCAL);
    if (!handle) { fprintf(stderr,"dlopen: %s\n",dlerror()); _exit(93); }
    env->ReleaseStringUTFChars(library,path);
    auto fn = reinterpret_cast<jint(*)(JNIEnv*,const char*)>(dlsym(handle,"_Z16ThrowIoExceptionP7_JNIEnvPKc"));
    require(fn != nullptr, "ThrowIoException symbol");
    uintptr_t entry = reinterpret_cast<uintptr_t>(fn);
    site = entry + 0x48;
    require(*reinterpret_cast<uint32_t*>(site)==0xd61f0060, "expected BR x3");
    const auto* table = env->functions;
    uintptr_t find = reinterpret_cast<uintptr_t>(table->FindClass);
    uintptr_t thrownew = reinterpret_cast<uintptr_t>(table->ThrowNew);
    require(find && thrownew && !env->ExceptionCheck(), "entry state");
    const char* message = "REA real Android JNI BR x3";
    jint direct = fn(env,message);
    require(direct == 0, "uninstrumented return");
    exception_result(env,message);
    struct sigaction action{}, previous{};
    action.sa_sigaction = trap;
    action.sa_flags = SA_SIGINFO;
    sigemptyset(&action.sa_mask);
    require(sigaction(SIGTRAP,&action,&previous)==0,"sigaction");
    patch(0xd4207d00); // BRK; observation is scoped to this one call.
    jint traced = fn(env,message);
    patch(0xd61f0060);
    require(sigaction(SIGTRAP,&previous,nullptr)==0,"restore signal handler");
    require(traced == 0 && hits == 1 && observed_pc == site, "observed BR");
    require(observed_x[0] == reinterpret_cast<uintptr_t>(env) && observed_x[3] == thrownew, "BR registers / table mismatch");
    require(observed_x[1] && observed_x[2] == reinterpret_cast<uintptr_t>(message), "ThrowNew arguments");
    exception_result(env,message);
    require(env->functions == table && reinterpret_cast<uintptr_t>(table->ThrowNew) == thrownew
        && reinterpret_cast<uintptr_t>(table->FindClass) == find, "table changed");
    const char* out = env->GetStringUTFChars(output,nullptr);
    FILE* f = fopen(out,"w");
    env->ReleaseStringUTFChars(output,out);
    require(f != nullptr,"output");
    char fingerprint[PROP_VALUE_MAX] = {}, sdk[PROP_VALUE_MAX] = {};
    __system_property_get("ro.build.fingerprint",fingerprint);
    __system_property_get("ro.build.version.sdk",sdk);
    fprintf(f,"{\"schema\":1,\"source\":\"android-art-process-private-brk\",\"abi\":\"arm64-v8a\",\"pid\":%d,\"sdk\":",getpid()); quoted(f,sdk);
    fprintf(f,",\"fingerprint\":"); quoted(f,fingerprint);
    fprintf(f,",\"env\":"); pointer(f,reinterpret_cast<uintptr_t>(env));
    fprintf(f,",\"table\":"); pointer(f,reinterpret_cast<uintptr_t>(table));
    fprintf(f,",\"entry\":"); pointer(f,entry);
    fprintf(f,",\"branch_pc\":"); pointer(f,observed_pc);
    fprintf(f,",\"x0\":"); pointer(f,observed_x[0]);
    fprintf(f,",\"x1\":"); pointer(f,observed_x[1]);
    fprintf(f,",\"x2\":"); pointer(f,observed_x[2]);
    fprintf(f,",\"x3\":"); pointer(f,observed_x[3]);
    fprintf(f,",\"original_word\":\"0xd61f0060\",\"restored_word\":\"0x%x\",\"table_stable\":true",*reinterpret_cast<uint32_t*>(site));
    fprintf(f,",\"target_module\":"); module(f,entry);
    fprintf(f,",\"slots\":[");
    for (int n=0;n<2;++n) {
        uintptr_t value = n ? thrownew : find;
        fprintf(f,"%s{\"index\":%d,\"name\":\"%s\",\"value\":",n?",":"",n?14:6,n?"ThrowNew":"FindClass"); pointer(f,value);
        fprintf(f,",\"module\":"); module(f,value);
        fprintf(f,",\"code16\":\"");
        for (int b=0;b<16;++b) fprintf(f,"%02x",reinterpret_cast<const unsigned char*>(value)[b]);
        fprintf(f,"\"}");
    }
    fprintf(f,"],\"calls\":{\"uninstrumented\":%d,\"instrumented\":%d,\"trap_hits\":%d,\"exception_class\":\"java/io/IOException\",\"message\":",direct,traced,hits); quoted(f,message);
    fprintf(f,",\"message_verified\":true},\"maps\":[");
    FILE* maps = fopen("/proc/self/maps","r");
    require(maps != nullptr,"maps");
    char line[1024]; bool comma=false;
    uintptr_t relevant[] = {reinterpret_cast<uintptr_t>(env),reinterpret_cast<uintptr_t>(table),entry,find,thrownew};
    while (fgets(line,sizeof(line),maps)) {
        unsigned long start,end;
        if (sscanf(line,"%lx-%lx",&start,&end)!=2) continue;
        bool keep=false;
        for (uintptr_t p: relevant) {
            p &= 0x00ffffffffffffffUL; // Android heap pointers may carry a TBI tag.
            if (p>=start && p<end) keep=true;
        }
        if (!keep) continue;
        line[strcspn(line,"\n")]=0;
        if (comma) fputc(',',f);
        quoted(f,line); comma=true;
    }
    fclose(maps); fprintf(f,"]}\n"); require(fclose(f)==0,"close output");
    dlclose(handle);
}
