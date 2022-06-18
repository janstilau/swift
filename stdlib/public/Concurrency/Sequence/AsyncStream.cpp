#include "swift/Runtime/Mutex.h"

namespace swift {
// return the size in words for the given mutex primitive
extern "C"
size_t _swift_async_stream_lock_size() {
    size_t words = sizeof(MutexHandle) / sizeof(void *);
    if (words < 1) { return 1; }
    return words;
}

extern "C"
void _swift_async_stream_lock_init(MutexHandle &lock) {
    MutexPlatformHelper::init(lock);
}

extern "C"
void _swift_async_stream_lock_lock(MutexHandle &lock) {
    MutexPlatformHelper::lock(lock);
}

extern "C"
void _swift_async_stream_lock_unlock(MutexHandle &lock) {
    MutexPlatformHelper::unlock(lock);
}

}
