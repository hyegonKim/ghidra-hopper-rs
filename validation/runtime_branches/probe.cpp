// Original ELF images stay unchanged on disk. BRK is process-private and restored.
// Reuse the existing ThrowNew probe, including its independent plain call.
#include "../jni_runtime/probe.cpp"
#include <setjmp.h>
static_assert(offsetof(JNINativeInterface, NewDirectByteBuffer) == 229 * 8, "JNI slot 229");
static_assert(offsetof(JNINativeInterface, GetDirectBufferAddress) == 230 * 8, "JNI slot 230");
extern "C" JNIEXPORT void JNICALL Java_RuntimeBranchesProbe_throwCapture(JNIEnv* e, jclass c, jstring l, jstring o) {
    hits=0; Java_JniRuntimeProbe_capture(e,c,l,o);
}
static void maps_for(FILE* f, const uintptr_t* relevant, size_t count) {
    FILE* maps=fopen("/proc/self/maps","r"); require(maps,"maps");
    char line[1024]; bool comma=false;
    fprintf(f,",\"maps\":[");
    while(fgets(line,sizeof(line),maps)) {
        unsigned long start,end; if(sscanf(line,"%lx-%lx",&start,&end)!=2)continue;
        bool keep=false;
        for(size_t n=0;n<count;++n) { uintptr_t p=relevant[n]&0x00ffffffffffffffUL; if(p>=start&&p<end)keep=true; }
        if(!keep)continue;
        line[strcspn(line,"\n")]=0; if(comma)fputc(',',f); quoted(f,line); comma=true;
    }
    fclose(maps); fprintf(f,"]}\n"); require(fclose(f)==0,"close output");
}
static FILE* output_file(JNIEnv* env, jstring output) {
    const char* out=env->GetStringUTFChars(output,nullptr); FILE* f=fopen(out,"w"); env->ReleaseStringUTFChars(output,out);
    require(f,"output"); return f;
}
static void identity(FILE* f, int schema, const char* source) {
    char fingerprint[PROP_VALUE_MAX]={}; __system_property_get("ro.build.fingerprint",fingerprint);
    fprintf(f,"{\"schema\":%d,\"source\":",schema); quoted(f,source);
    fprintf(f,",\"abi\":\"arm64-v8a\",\"pid\":%d,\"fingerprint\":",getpid()); quoted(f,fingerprint);
}
static void code16(FILE* f, uintptr_t target) {
    fprintf(f,",\"code16\":\"");
    for(int b=0;b<16;++b)fprintf(f,"%02x",reinterpret_cast<const unsigned char*>(target)[b]);
    fputc('"',f);
}
extern "C" JNIEXPORT void JNICALL Java_RuntimeBranchesProbe_bufferCapture(JNIEnv* env,jclass,jstring library,jstring output) {
    const char* path=env->GetStringUTFChars(library,nullptr); void* handle=dlopen(path,RTLD_NOW|RTLD_LOCAL);
    if(!handle){fprintf(stderr,"dlopen: %s\n",dlerror());_exit(93);} env->ReleaseStringUTFChars(library,path);
    auto fn=reinterpret_cast<jobject(*)(JNIEnv*,jclass,jobject,jint,jint)>(dlsym(handle,"Java_androidx_camera_core_ImageProcessingUtil_nativeNewDirectByteBuffer"));
    require(fn,"buffer symbol"); uintptr_t entry=reinterpret_cast<uintptr_t>(fn); site=entry+0x40;
    require(*reinterpret_cast<uint32_t*>(site)==0xd61f0060,"buffer BR x3");
    uint8_t storage[128]; for(int n=0;n<128;++n)storage[n]=static_cast<uint8_t>(n*7+3);
    jobject input=env->NewDirectByteBuffer(storage,128); jclass cls=env->FindClass("java/lang/Object");
    require(input&&cls&&!env->ExceptionCheck(),"buffer input");
    const auto* table=env->functions; uintptr_t targets[]={reinterpret_cast<uintptr_t>(table->NewDirectByteBuffer),reinterpret_cast<uintptr_t>(table->GetDirectBufferAddress)};
    auto verify=[&](jobject b){require(b&&!env->ExceptionCheck(),"buffer result"); require(env->GetDirectBufferAddress(b)==storage+7&&env->GetDirectBufferCapacity(b)==31,"buffer address/capacity"); require(memcmp(env->GetDirectBufferAddress(b),storage+7,31)==0,"buffer contents"); env->DeleteLocalRef(b);};
    verify(fn(env,cls,input,7,31));
    struct sigaction action{},previous{}; action.sa_sigaction=trap; action.sa_flags=SA_SIGINFO; sigemptyset(&action.sa_mask);
    require(sigaction(SIGTRAP,&action,&previous)==0,"buffer sigaction"); hits=0;
    patch(0xd4207d00); jobject traced=fn(env,cls,input,7,31); patch(0xd61f0060);
    require(sigaction(SIGTRAP,&previous,nullptr)==0,"restore trap"); verify(traced);
    require(hits==1&&observed_x[0]==reinterpret_cast<uintptr_t>(env)&&observed_x[1]==reinterpret_cast<uintptr_t>(storage+7)&&observed_x[2]==31&&observed_x[3]==targets[0],"buffer BR arguments");
    require(env->functions==table&&reinterpret_cast<uintptr_t>(table->NewDirectByteBuffer)==targets[0]&&reinterpret_cast<uintptr_t>(table->GetDirectBufferAddress)==targets[1],"buffer table stable");
    FILE* f=output_file(env,output); identity(f,2,"android-art-process-private-brk");
    fprintf(f,",\"terminal_jni_slot\":229,\"env\":"); pointer(f,reinterpret_cast<uintptr_t>(env)); fprintf(f,",\"table\":");pointer(f,reinterpret_cast<uintptr_t>(table));
    fprintf(f,",\"entry\":");pointer(f,entry); fprintf(f,",\"branch_pc\":");pointer(f,observed_pc);
    for(int n=0;n<4;++n){fprintf(f,",\"x%d\":",n);pointer(f,observed_x[n]);}
    fprintf(f,",\"original_word\":\"0xd61f0060\",\"restored_word\":\"0x%x\",\"table_stable\":true,\"target_module\":",*reinterpret_cast<uint32_t*>(site));module(f,entry);
    fprintf(f,",\"slots\":[");
    for(int n=0;n<2;++n){fprintf(f,"%s{\"index\":%d,\"name\":\"%s\",\"value\":",n?",":"",229+n,n?"GetDirectBufferAddress":"NewDirectByteBuffer");pointer(f,targets[n]);fprintf(f,",\"module\":");module(f,targets[n]);code16(f,targets[n]);fprintf(f,"}");}
    fprintf(f,"],\"calls\":{\"uninstrumented\":0,\"instrumented\":0,\"trap_hits\":1,\"buffer_verified\":true,\"source_address\":");pointer(f,reinterpret_cast<uintptr_t>(storage));fprintf(f,",\"source_capacity\":128,\"offset\":7,\"length\":31}");
    uintptr_t relevant[]={reinterpret_cast<uintptr_t>(env),reinterpret_cast<uintptr_t>(table),entry,targets[0],targets[1],reinterpret_cast<uintptr_t>(storage)};
    maps_for(f,relevant,6); env->DeleteLocalRef(input);env->DeleteLocalRef(cls);dlclose(handle);
}
static volatile uintptr_t branch_pc, branch_regs[31], fault_pc, fault_address;
static volatile sig_atomic_t branch_hits, fault_hits, target_register, callback_hits;
static sigjmp_buf recovery;
static void branch_trap(int signal,siginfo_t* info,void* context) {
    auto* u=static_cast<ucontext_t*>(context);
    if(signal==SIGTRAP){
        if(u->uc_mcontext.pc!=site||branch_hits)_exit(94);
        branch_pc=u->uc_mcontext.pc; for(int n=0;n<31;++n)branch_regs[n]=u->uc_mcontext.regs[n];
        ++branch_hits; u->uc_mcontext.pc=u->uc_mcontext.regs[target_register];
    } else {
        fault_pc=u->uc_mcontext.pc;fault_address=reinterpret_cast<uintptr_t>(info->si_addr);++fault_hits;siglongjmp(recovery,1);
    }
}
extern "C" __attribute__((noinline,visibility("default"))) void REARuntimeCallback() { ++callback_hits; }
extern "C" JNIEXPORT void JNICALL Java_RuntimeBranchesProbe_branchCapture(JNIEnv* env,jclass,jstring library,jstring output,jboolean resolver) {
    const char* path=env->GetStringUTFChars(library,nullptr);void* handle=dlopen(path,RTLD_NOW|RTLD_LOCAL);
    if(!handle){fprintf(stderr,"dlopen: %s\n",dlerror());_exit(93);}env->ReleaseStringUTFChars(library,path);
    void* symbol=dlsym(handle,"_Z16ThrowIoExceptionP7_JNIEnvPKc");require(symbol,"counter symbol");Dl_info d{};require(dladdr(symbol,&d),"counter module");uintptr_t base=reinterpret_cast<uintptr_t>(d.dli_fbase);
    uintptr_t entry=base+(resolver?0x10c0:0xd50);site=base+(resolver?0x10d0:0xd5c);uint32_t original=resolver?0xd61f0220:0xd61f0200;
    require(*reinterpret_cast<uint32_t*>(site)==original,"branch original word");target_register=resolver?17:16;branch_hits=fault_hits=callback_hits=0;
    uintptr_t target=reinterpret_cast<uintptr_t>(&REARuntimeCallback);uintptr_t got=base+0x53b0;uintptr_t got_before=*reinterpret_cast<uintptr_t*>(got);
    auto wrapper=reinterpret_cast<void(*)(void(*)())>(entry);
    auto registration=reinterpret_cast<int(*)(void(*)())>(base+0xd64);
    auto finalize=reinterpret_cast<void(*)(void*)>(dlsym(RTLD_DEFAULT,"__cxa_finalize"));require(finalize,"cxa_finalize");
    struct sigaction action{},oldtrap{},oldsegv{};action.sa_sigaction=branch_trap;action.sa_flags=SA_SIGINFO;sigemptyset(&action.sa_mask);
    require(sigaction(SIGTRAP,&action,&oldtrap)==0&&sigaction(SIGSEGV,&action,&oldsegv)==0,"branch signals");
    if(resolver){require(got_before==0,"expected Android unused resolver slot"); if(sigsetjmp(recovery,1)==0)reinterpret_cast<void(*)()>(entry)(); require(fault_hits==1&&fault_pc==0&&fault_address==0,"plain resolver null fault");}
    else {wrapper(nullptr);require(callback_hits==0,"callback null guard");require(registration(&REARuntimeCallback)==0,"plain register");finalize(reinterpret_cast<void*>(base+0x51c0));require(callback_hits==1,"plain registered callback");}
    patch(0xd4207d00);
    if(resolver){if(sigsetjmp(recovery,1)==0)reinterpret_cast<void(*)()>(entry)(); require(fault_hits==2&&fault_pc==0&&fault_address==0,"instrumented resolver null fault");}
    else {require(registration(&REARuntimeCallback)==0,"traced register");finalize(reinterpret_cast<void*>(base+0x51c0));require(callback_hits==2,"traced callback");}
    patch(original);require(sigaction(SIGTRAP,&oldtrap,nullptr)==0&&sigaction(SIGSEGV,&oldsegv,nullptr)==0,"restore branch signals");
    require(branch_hits==1&&branch_pc==site&&branch_regs[target_register]==(resolver?0:target),"branch target observed");
    require(*reinterpret_cast<uintptr_t*>(got)==got_before,"GOT stable");
    FILE* f=output_file(env,output);identity(f,1,"android-process-private-branch");fprintf(f,",\"kind\":\"%s\",\"entry\":",resolver?"null-plt-resolver":"registered-callback");pointer(f,entry);
    fprintf(f,",\"branch_pc\":");pointer(f,branch_pc);fprintf(f,",\"original_word\":\"0x%x\",\"restored_word\":\"0x%x\",\"target_module\":",original,*reinterpret_cast<uint32_t*>(site));module(f,entry);
    fprintf(f,",\"entry_x0\":");pointer(f,resolver?0:target);fprintf(f,",\"target_register\":%d,\"observed_target\":",target_register);pointer(f,branch_regs[target_register]);
    fprintf(f,",\"registers\":[");for(int n=0;n<31;++n){if(n)fputc(',',f);pointer(f,branch_regs[n]);}fprintf(f,"]");
    if(resolver){fprintf(f,",\"memory\":{\"offset\":\"0x53b0\",\"address\":");pointer(f,got);fprintf(f,",\"before\":");pointer(f,got_before);fprintf(f,",\"after\":");pointer(f,*reinterpret_cast<uintptr_t*>(got));fprintf(f,"},\"calls\":{\"plain_faults\":1,\"traced_faults\":1,\"signal\":11,\"fault_pc\":\"0x0\",\"fault_address\":\"0x0\",\"trap_hits\":1}");}
    else {fprintf(f,",\"target\":{\"module\":");module(f,target);code16(f,target);fprintf(f,"},\"calls\":{\"uninstrumented\":1,\"instrumented\":1,\"null_guard\":true,\"registered\":true,\"finalized\":true,\"trap_hits\":1}");}
    uintptr_t relevant[]={entry,got,target};maps_for(f,relevant,3);dlclose(handle);
}
