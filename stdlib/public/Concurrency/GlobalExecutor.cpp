/// Routines related to the global concurrent execution service.
///
/// The execution side of Swift's concurrency model centers around
/// scheduling work onto various execution services ("executors").
/// Executors vary in several different dimensions:
///
/// First, executors may be exclusive or concurrent.  An exclusive
/// executor can only execute one job at once; a concurrent executor
/// can execute many.  Exclusive executors are usually used to achieve
/// some higher-level requirement, like exclusive access to some
/// resource or memory.  Concurrent executors are usually used to
/// manage a pool of threads and prevent the number of allocated
/// threads from growing without limit.
/// 
/// Second, executors may own dedicated threads, or they may schedule
/// work onto some some underlying executor.  Dedicated threads can
/// improve the responsiveness of a subsystem *locally*, but they impose
/// substantial costs which can drive down performance *globally*
/// if not used carefully.  When an executor relies on running work
/// on its own dedicated threads, jobs that need to run briefly on
/// that executor may need to suspend and restart.  Dedicating threads
/// to an executor is a decision that should be made carefully
/// and holistically.
///
/// If most executors should not have dedicated threads, they must
/// be backed by some underlying executor, typically a concurrent
/// executor.  The purpose of most concurrent executors is to
/// manage threads and prevent excessive growth in the number
/// of threads.  Having multiple independent concurrent executors
/// with their own dedicated threads would undermine that.
/// Therefore, it is sensible to have a single, global executor
/// that will ultimately schedule most of the work in the system.  
/// With that as a baseline, special needs can be recognized and
/// carved out from the global executor with its cooperation.
///
/// This file defines Swift's interface to that global executor.
///
/// The default implementation is backed by libdispatch, but there
/// may be good reasons to provide alternatives (e.g. when building
/// a single-threaded runtime).
///
///===----------------------------------------------------------------------===///
/*
 /// 与全局并发执行服务相关的例程。

 // 其实还是提交任务, 只不过, 在提交完任务之后, 可以通过环境进行恢复.
 /// Swift 的并发模型的执行端围绕将工作调度到各种执行服务（“执行器”）上展开。 执行器在几个不同的维度上有所不同：

 /// 首先，执行器可以是独占的或并发的。 独占的执行器一次只能执行一个作业；并发执行器可以执行多个。 独占执行器通常用于实现一些更高级的要求，比如对某些资源或内存的独占访问。 并发执行器通常用于管理线程池，并防止分配的线程数量无限增长。

 /// 其次，执行器可以拥有专用线程，也可以将工作调度到某些底层执行器上。 专用线程可以提高子系统的*局部*响应性，但如果不小心使用，它们会带来相当大的成本，从而降低*全局*性能。 当一个执行器依赖于在其自己的专用线程上运行工作时，需要在该执行器上短暂运行的作业可能需要暂停和重新启动。 将线程分配给执行器是一个需要慎重考虑和全面考虑的决定。

 /// 如果大多数执行器不应该有专用线程，它们必须由某些底层执行器支持，通常是一个并发执行器。 大多数并发执行器的目的是管理线程并防止线程数量过度增长。 有多个独立的并发执行器，拥有自己的专用线程，会破坏这一点。 因此，有一个单一的全局执行器，最终将调度系统中的大部分工作，这是明智的。 有了这个作为基准，可以识别特殊需求，并从全局执行器中划分出来，并与其进行合作。

 /// 该文件定义了 Swift 对该全局执行器的接口。

 /// 默认实现由 libdispatch 支持，但可能有充分的理由提供替代方案（例如，在构建单线程运行时时）。

 ///===----------------------------------------------------------------------===///
 */

#include "../CompatibilityOverride/CompatibilityOverride.h"
#include "swift/Runtime/Concurrency.h"
#include "swift/Runtime/EnvironmentVariables.h"
#include "TaskPrivate.h"
#include "Error.h"

using namespace swift;

SWIFT_CC(swift)
void (*swift::swift_task_enqueueGlobal_hook)(
                                             Job *job, swift_task_enqueueGlobal_original original) = nullptr;

SWIFT_CC(swift)
void (*swift::swift_task_enqueueGlobalWithDelay_hook)(
                                                      JobDelay delay, Job *job,
                                                      swift_task_enqueueGlobalWithDelay_original original) = nullptr;

SWIFT_CC(swift)
void (*swift::swift_task_enqueueGlobalWithDeadline_hook)(
                                                         long long sec,
                                                         long long nsec,
                                                         long long tsec,
                                                         long long tnsec,
                                                         int clock, Job *job,
                                                         swift_task_enqueueGlobalWithDeadline_original original) = nullptr;

SWIFT_CC(swift)
void (*swift::swift_task_enqueueMainExecutor_hook)(
                                                   Job *job, swift_task_enqueueMainExecutor_original original) = nullptr;

#if SWIFT_CONCURRENCY_COOPERATIVE_GLOBAL_EXECUTOR
#include "CooperativeGlobalExecutor.inc"
#elif SWIFT_CONCURRENCY_ENABLE_DISPATCH
#include "DispatchGlobalExecutor.inc"
#else
#include "NonDispatchGlobalExecutor.inc"
#endif

void swift::swift_task_enqueueGlobal(Job *job) {
    _swift_tsan_release(job);
    
    concurrency::trace::job_enqueue_global(job);
    
    if (swift_task_enqueueGlobal_hook)
        swift_task_enqueueGlobal_hook(job, swift_task_enqueueGlobalImpl);
    else
        swift_task_enqueueGlobalImpl(job);
}

void swift::swift_task_enqueueGlobalWithDelay(JobDelay delay, Job *job) {
    concurrency::trace::job_enqueue_global_with_delay(delay, job);
    
    if (swift_task_enqueueGlobalWithDelay_hook)
        swift_task_enqueueGlobalWithDelay_hook(
                                               delay, job, swift_task_enqueueGlobalWithDelayImpl);
    else
        swift_task_enqueueGlobalWithDelayImpl(delay, job);
}

void swift::swift_task_enqueueGlobalWithDeadline(
                                                 long long sec,
                                                 long long nsec,
                                                 long long tsec,
                                                 long long tnsec,
                                                 int clock, Job *job) {
    if (swift_task_enqueueGlobalWithDeadline_hook)
        swift_task_enqueueGlobalWithDeadline_hook(
                                                  sec, nsec, tsec, tnsec, clock, job, swift_task_enqueueGlobalWithDeadlineImpl);
    else
        swift_task_enqueueGlobalWithDeadlineImpl(sec, nsec, tsec, tnsec, clock, job);
}

void swift::swift_task_enqueueMainExecutor(Job *job) {
    concurrency::trace::job_enqueue_main_executor(job);
    if (swift_task_enqueueMainExecutor_hook)
        swift_task_enqueueMainExecutor_hook(job,
                                            swift_task_enqueueMainExecutorImpl);
    else
        swift_task_enqueueMainExecutorImpl(job);
}

ExecutorRef swift::swift_task_getMainExecutor() {
#if !SWIFT_CONCURRENCY_ENABLE_DISPATCH
    // FIXME: this isn't right for the non-cooperative environment
    return ExecutorRef::generic();
#else
    return ExecutorRef::forOrdinary(
                                    reinterpret_cast<HeapObject*>(&_dispatch_main_q),
                                    _swift_task_getDispatchQueueSerialExecutorWitnessTable());
#endif
}

bool ExecutorRef::isMainExecutor() const {
#if !SWIFT_CONCURRENCY_ENABLE_DISPATCH
    // FIXME: this isn't right for the non-cooperative environment
    return isGeneric();
#else
    return Identity == reinterpret_cast<HeapObject*>(&_dispatch_main_q);
#endif
}

#define OVERRIDE_GLOBAL_EXECUTOR COMPATIBILITY_OVERRIDE
#include COMPATIBILITY_OVERRIDE_INCLUDE_PATH
