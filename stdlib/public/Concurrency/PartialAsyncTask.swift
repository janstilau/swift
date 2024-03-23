import Swift
@_implementationOnly import _SwiftConcurrencyShims

@available(SwiftStdlib 5.1, *)
@_silgen_name("swift_job_run")
@usableFromInline
internal func _swiftJobRun(_ job: UnownedJob,
                           _ executor: UnownedSerialExecutor) -> ()

/// A unit of scheduleable work.
///
/// Unless you're implementing a scheduler,
/// you don't generally interact with jobs directly.
@available(SwiftStdlib 5.1, *)
@frozen
public struct UnownedJob: Sendable {
    private var context: Builtin.Job
    
    @_alwaysEmitIntoClient
    @inlinable
    public func _runSynchronously(on executor: UnownedSerialExecutor) {
        _swiftJobRun(self, executor)
    }
}

/// A mechanism to interface
/// between synchronous and asynchronous code,
/// without correctness checking.

/// A *continuation* is an opaque representation of program state.
/// To create a continuation in asynchronous code,
/// call the `withUnsafeContinuation(_:)` or
/// `withUnsafeThrowingContinuation(_:)` function.
/// To resume the asynchronous task,
/// call the `resume(returning:)`,
/// `resume(throwing:)`,
/// `resume(with:)`,
/// or `resume()` method.
///
/// - Important: You must call a resume method exactly once
///   on every execution path throughout the program.
///   Resuming from a continuation more than once is undefined behavior.
///   Never resuming leaves the task in a suspended state indefinitely,
///   and leaks any associated resources.

/// `CheckedContinuation` performs runtime checks
/// for missing or multiple resume operations.
/// `UnsafeContinuation` avoids enforcing these invariants at runtime
/// because it aims to be a low-overhead mechanism
/// for interfacing Swift tasks with
/// event loops, delegate methods, callbacks,
/// and other non-`async` scheduling mechanisms.
/// However, during development, the ability to verify that the
/// invariants are being upheld in testing is important.
/// Because both types have the same interface,
/// you can replace one with the other in most circumstances,
/// without making other changes.
/*
 /// 这是一个在同步和异步代码之间进行接口交互的机制，但不进行正确性检查。

 /// *Continuation* 是程序状态的不透明表示。在异步代码中创建 continuation，调用 `withUnsafeContinuation(_:)` 或 `withUnsafeThrowingContinuation(_:)` 函数。要恢复异步任务，调用 `resume(returning:)`、`resume(throwing:)`、`resume(with:)` 或 `resume()` 方法。

 /// - 重要：在程序的每个执行路径上，您必须恰好调用一次 resume 方法。从 continuation 恢复超过一次是未定义行为。不恢复将使任务无限期处于挂起状态，并泄漏任何相关资源。

 /// `CheckedContinuation` 执行运行时检查，以确保未丢失或多次恢复操作。`UnsafeContinuation` 避免在运行时强制执行这些不变式，因为它旨在成为一种低开销的机制，用于将 Swift 任务与事件循环、委托方法、回调和其他非`async`调度机制进行接口交互。然而，在开发过程中，验证这些不变式在测试中被遵守的能力是很重要的。由于这两种类型具有相同的接口，因此在大多数情况下，您可以在不进行其他更改的情况下将一个替换为另一个。
 */
@available(SwiftStdlib 5.1, *)
// 实际上, 这就是一个包装类型.
// 真正的调用, 是使用了系统的底层函数.
public struct UnsafeContinuation<T, E: Error> {
    @usableFromInline internal var context: Builtin.RawUnsafeContinuation
    
    @_alwaysEmitIntoClient
    internal init(_ context: Builtin.RawUnsafeContinuation) {
        self.context = context
    }
    
    /// Resume the task that's awaiting the continuation
    /// by returning the given value.
    ///
    /// - Parameter value: The value to return from the continuation.
    ///
    /// A continuation must be resumed exactly once.
    /// If the continuation has already resumed,
    /// then calling this method results in undefined behavior.
    ///
    /// After calling this method,
    /// control immediately returns to the caller.
    /// The task continues executing
    /// when its executor schedules it.
    // resume 仅仅是提交一个任务.
    // 通知, 对应的协程, 可以开始动作了.
    public func resume(returning value: __owned T) where E == Never {
#if compiler(>=5.5) && $BuiltinContinuation
        Builtin.resumeNonThrowingContinuationReturning(context, value)
#else
        fatalError("Swift compiler is incompatible with this SDK version")
#endif
    }
    
    /// Resume the task that's awaiting the continuation
    /// by returning the given value.
    ///
    /// - Parameter value: The value to return from the continuation.
    ///
    /// A continuation must be resumed exactly once.
    /// If the continuation has already resumed,
    /// then calling this method results in undefined behavior.
    ///
    /// After calling this method,
    /// control immediately returns to the caller.
    /// The task continues executing
    /// when its executor schedules it.
    @_alwaysEmitIntoClient
    public func resume(returning value: __owned T) {
#if compiler(>=5.5) && $BuiltinContinuation
        Builtin.resumeThrowingContinuationReturning(context, value)
#else
        fatalError("Swift compiler is incompatible with this SDK version")
#endif
    }
    
    /// Resume the task that's awaiting the continuation
    /// by throwing the given error.
    ///
    /// - Parameter error: The error to throw from the continuation.
    ///
    /// A continuation must be resumed exactly once.
    /// If the continuation has already resumed,
    /// then calling this method results in undefined behavior.
    ///
    /// After calling this method,
    /// control immediately returns to the caller.
    /// The task continues executing
    /// when its executor schedules it.
    @_alwaysEmitIntoClient
    public func resume(throwing error: __owned E) {
#if compiler(>=5.5) && $BuiltinContinuation
        Builtin.resumeThrowingContinuationThrowing(context, error)
#else
        fatalError("Swift compiler is incompatible with this SDK version")
#endif
    }
}

@available(SwiftStdlib 5.1, *)
extension UnsafeContinuation: Sendable where T: Sendable { }

@available(SwiftStdlib 5.1, *)
extension UnsafeContinuation {
    /// Resume the task that's awaiting the continuation
    /// by returning or throwing the given result value.
    ///
    /// - Parameter result: The result.
    ///   If it contains a `.success` value,
    ///   the continuation returns that value;
    ///   otherwise, it throws the `.error` value.
    ///
    /// A continuation must be resumed exactly once.
    /// If the continuation has already resumed,
    /// then calling this method results in undefined behavior.
    ///
    /// After calling this method,
    /// control immediately returns to the caller.
    /// The task continues executing
    /// when its executor schedules it.
    @_alwaysEmitIntoClient
    public func resume<Er: Error>(with result: Result<T, Er>) where E == Error {
        switch result {
        case .success(let val):
            self.resume(returning: val)
        case .failure(let err):
            self.resume(throwing: err)
        }
    }
    
    /// Resume the task that's awaiting the continuation
    /// by returning or throwing the given result value.
    ///
    /// - Parameter result: The result.
    ///   If it contains a `.success` value,
    ///   the continuation returns that value;
    ///   otherwise, it throws the `.error` value.
    ///
    /// A continuation must be resumed exactly once.
    /// If the continuation has already resumed,
    /// then calling this method results in undefined behavior.
    ///
    /// After calling this method,
    /// control immediately returns to the caller.
    /// The task continues executing
    /// when its executor schedules it.
    @_alwaysEmitIntoClient
    public func resume(with result: Result<T, E>) {
        switch result {
        case .success(let val):
            self.resume(returning: val)
        case .failure(let err):
            self.resume(throwing: err)
        }
    }
    
    /// Resume the task that's awaiting the continuation by returning.
    ///
    /// A continuation must be resumed exactly once.
    /// If the continuation has already resumed,
    /// then calling this method results in undefined behavior.
    ///
    /// After calling this method,
    /// control immediately returns to the caller.
    /// The task continues executing
    /// when its executor schedules it.
    @_alwaysEmitIntoClient
    public func resume() where T == Void {
        self.resume(returning: ())
    }
}

#if _runtime(_ObjC)

// Intrinsics used by SILGen to resume or fail continuations.
@available(SwiftStdlib 5.1, *)
@_alwaysEmitIntoClient
internal func _resumeUnsafeContinuation<T>(
    _ continuation: UnsafeContinuation<T, Never>,
    _ value: __owned T
) {
    continuation.resume(returning: value)
}

@available(SwiftStdlib 5.1, *)
@_alwaysEmitIntoClient
internal func _resumeUnsafeThrowingContinuation<T>(
    _ continuation: UnsafeContinuation<T, Error>,
    _ value: __owned T
) {
    continuation.resume(returning: value)
}

@available(SwiftStdlib 5.1, *)
@_alwaysEmitIntoClient
internal func _resumeUnsafeThrowingContinuationWithError<T>(
    _ continuation: UnsafeContinuation<T, Error>,
    _ error: __owned Error
) {
    continuation.resume(throwing: error)
}

#endif

/// Suspends the current task,
/// then calls the given closure with an unsafe continuation for the current task.
///
/// - Parameter fn: A closure that takes an `UnsafeContinuation` parameter.
/// You must resume the continuation exactly once.
///
/// - Returns: The value passed to the continuation by the closure.
@available(SwiftStdlib 5.1, *)
@_unsafeInheritExecutor
@_alwaysEmitIntoClient
public func withUnsafeContinuation<T>(
    _ fn: (UnsafeContinuation<T, Never>) -> Void
) async -> T {
    return await Builtin.withUnsafeContinuation {
        fn(UnsafeContinuation<T, Never>($0))
    }
}

/// Suspends the current task,
/// then calls the given closure with an unsafe throwing continuation for the current task.
///
/// - Parameter fn: A closure that takes an `UnsafeContinuation` parameter.
/// You must resume the continuation exactly once.
///
/// - Returns: The value passed to the continuation by the closure.
///
/// If `resume(throwing:)` is called on the continuation,
/// this function throws that error.
@available(SwiftStdlib 5.1, *)
@_unsafeInheritExecutor
@_alwaysEmitIntoClient
public func withUnsafeThrowingContinuation<T>(
    _ fn: (UnsafeContinuation<T, Error>) -> Void
) async throws -> T {
    return try await Builtin.withUnsafeThrowingContinuation {
        fn(UnsafeContinuation<T, Error>($0))
    }
}

/// A hack to mark an SDK that supports swift_continuation_await.
@available(SwiftStdlib 5.1, *)
@_alwaysEmitIntoClient
public func _abiEnableAwaitContinuation() {
    fatalError("never use this function")
}
