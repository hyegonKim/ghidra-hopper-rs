// Concurrent native validation: returned old values must form unique tickets.
#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdlib.h>
typedef uint32_t (*increment_fn)(uint32_t, volatile uint32_t *);
struct work { increment_fn fn; volatile uint32_t *value; uint32_t *tickets; uint32_t iterations; };
static void *worker(void *p) {
    struct work *w = p;
    for (uint32_t i = 0; i < w->iterations; ++i)
        w->tickets[i] = w->fn(1, w->value);
    return NULL;
}
int run_stress(uintptr_t address, uint32_t workers, uint32_t iterations, uint32_t *final, uint32_t *tickets) {
    if (!workers || workers > 8 || !iterations) return -1;
    _Atomic uint32_t value = 0;
    pthread_t threads[8];
    struct work work[8];
    uint32_t started = 0;
    for (; started < workers; ++started) {
        work[started] = (struct work){(increment_fn)address, (volatile uint32_t *)&value, tickets + started * iterations, iterations};
        if (pthread_create(&threads[started], NULL, worker, &work[started])) break;
    }
    int error = started != workers;
    for (uint32_t i = 0; i < started; ++i) if (pthread_join(threads[i], NULL)) error = 1;
    *final = atomic_load_explicit(&value, memory_order_acquire);
    return error;
}
// These two entry points follow the two-argument stress ABI; flags are untouched.
__asm__(".text\n.globl _stress_lse, _stress_exclusive\n"
"_stress_lse:\n ldaddal w0, w0, [x1]\n ret\n"
"_stress_exclusive:\n mov w16, w0\n1:\n ldaxr w0, [x1]\n add w17, w0, w16\n stlxr w15, w17, [x1]\n cbnz w15, 1b\n ret\n");
