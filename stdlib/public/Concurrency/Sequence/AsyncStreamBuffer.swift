import Swift

#if ASYNC_STREAM_STANDALONE
@_exported import _Concurrency
import Darwin

func _lockWordCount() -> Int {
    let sz =
    MemoryLayout<os_unfair_lock>.size / MemoryLayout<UnsafeRawPointer>.size
    return max(sz, 1)
}

func _lockInit(_ ptr: UnsafeRawPointer) {
    UnsafeMutableRawPointer(mutating: ptr)
        .assumingMemoryBound(to: os_unfair_lock.self)
        .initialize(to: os_unfair_lock())
}

func _lock(_ ptr: UnsafeRawPointer) {
    os_unfair_lock_lock(UnsafeMutableRawPointer(mutating: ptr)
        .assumingMemoryBound(to: os_unfair_lock.self))
}

func _unlock(_ ptr: UnsafeRawPointer) {
    os_unfair_lock_unlock(UnsafeMutableRawPointer(mutating: ptr)
        .assumingMemoryBound(to: os_unfair_lock.self))
}
#else
@_silgen_name("_swift_async_stream_lock_size")
func _lockWordCount() -> Int

@_silgen_name("_swift_async_stream_lock_init")
func _lockInit(_ ptr: UnsafeRawPointer)

@_silgen_name("_swift_async_stream_lock_lock")
func _lock(_ ptr: UnsafeRawPointer)

@_silgen_name("_swift_async_stream_lock_unlock")
func _unlock(_ ptr: UnsafeRawPointer)
#endif

@available(SwiftStdlib 5.1, *)
extension AsyncStream {
    
    // 真正的存储, Async 实现的基础.
    internal final class _Storage: @unchecked Sendable {
        typealias TerminationHandler = @Sendable (Continuation.Termination) -> Void
        
        struct State {
            var continuations = [UnsafeContinuation<Element?, Never>]()
            // 真正的存储.
            var pending = _Deque<Element>()
            let limit: Continuation.BufferingPolicy
            var onTermination: TerminationHandler?
            var terminal: Bool = false
            init(limit: Continuation.BufferingPolicy) {
                self.limit = limit
            }
        }
        
        // Stored as a singular structured assignment for initialization
        // 所有的数据, 都存储在这一个地方了. 应该这样说, AsyncStreamBuffer 是一个接口对象, 它并不管底层存储.
        // 不太明白为什么这样的设计, State 会被其他的地方复用吗.
        var state: State
        
        // 可以学习这种写法, private 的同时, 进行 fatalError 的调用.
        private init(_doNotCallMe: ()) {
            fatalError("Storage must be initialized by create")
        }
        
        deinit {
            state.onTermination?(.cancelled)
        }
        
        // 该上锁的时候, 还是要进行上锁.
        // 协程, 其实是一个唤醒机制, 而这个机制的开始, 在这里是数据的改动.
        // 这个改动, 其实是在多线程的环境下的.
        // 这是一个, 将自身当做上锁标志的实现方案, 类似于 synchronize
        private func lock() {
            let ptr =
            UnsafeRawPointer(Builtin.projectTailElems(self, UnsafeRawPointer.self))
            _lock(ptr)
        }
        
        private func unlock() {
            let ptr =
            UnsafeRawPointer(Builtin.projectTailElems(self, UnsafeRawPointer.self))
            _unlock(ptr)
        }
        
        func getOnTermination() -> TerminationHandler? {
            lock()
            let handler = state.onTermination
            unlock()
            return handler
        }
        
        func setOnTermination(_ newValue: TerminationHandler?) {
            lock()
            withExtendedLifetime(state.onTermination) {
                state.onTermination = newValue
                unlock()
            }
        }
        
        @Sendable func cancel() {
            lock()
            // swap out the handler before we invoke it to prevent double cancel
            let handler = state.onTermination
            state.onTermination = nil
            unlock()
            
            // handler must be invoked before yielding nil for termination
            handler?(.cancelled)
            
            finish()
        }
        
        func yield(_ value: __owned Element) -> Continuation.YieldResult {
            // result 表示的是插入的结果, 而不是 value 值.
            // 这个结果, 是给 yield 的调用者使用的.
            var result: Continuation.YieldResult
            
            lock()
            let limit = state.limit
            let count = state.pending.count
            
            // 如果, 已经有存储的 continuation 了, 那么其实是每次产生数据, 都有一个环境操作在里面.
            if !state.continuations.isEmpty {
                /*
                 可能会在不同的线程里面, 调用 it.next, 所以, 可能会有不同的协程, 进行等待.
                 所以在产生数据之后, 也仅仅是找到第一个被停止的协程, 然后进行唤醒操作.
                 */
                let continuation = state.continuations.removeFirst()
                if count > 0 {
                    if !state.terminal {
                        switch limit {
                        case .unbounded:
                            state.pending.append(value)
                            result = .enqueued(remaining: .max)
                        case .bufferingOldest(let limit):
                            if count < limit {
                                state.pending.append(value)
                                result = .enqueued(remaining: limit - (count + 1))
                            } else {
                                result = .dropped(value)
                            }
                        case .bufferingNewest(let limit):
                            if count < limit {
                                state.pending.append(value)
                                result = .enqueued(remaining: limit - (count + 1))
                            } else if count > 0 {
                                result = .dropped(state.pending.removeFirst())
                                state.pending.append(value)
                            } else {
                                result = .dropped(value)
                            }
                        }
                    } else {
                        result = .terminated
                    }
                    let toSend = state.pending.removeFirst()
                    unlock()
                    continuation.resume(returning: toSend)
                } else if state.terminal {
                    // 如果, 当前状态已经完结, 其实什么都不做的
                    result = .terminated
                    unlock()
                    continuation.resume(returning: nil)
                } else {
                    switch limit {
                    case .unbounded:
                        result = .enqueued(remaining: .max)
                    case .bufferingNewest(let limit):
                        result = .enqueued(remaining: limit)
                    case .bufferingOldest(let limit):
                        result = .enqueued(remaining: limit)
                    }
                    
                    unlock()
                    continuation.resume(returning: value)
                }
            } else {
                // 如果, 当前没有等待唤醒的协程, 其实是简单的值的存储.
                if !state.terminal {
                    switch limit {
                    case .unbounded:
                        result = .enqueued(remaining: .max)
                        state.pending.append(value)
                    case .bufferingOldest(let limit):
                        if count < limit {
                            result = .enqueued(remaining: limit - (count + 1))
                            state.pending.append(value)
                        } else {
                            result = .dropped(value)
                        }
                    case .bufferingNewest(let limit):
                        if count < limit {
                            state.pending.append(value)
                            result = .enqueued(remaining: limit - (count + 1))
                        } else if count > 0 {
                            result = .dropped(state.pending.removeFirst())
                            state.pending.append(value)
                        } else {
                            result = .dropped(value)
                        }
                    }
                } else {
                    result = .terminated
                }
                unlock()
            }
            return result
        }
        
        func finish() {
            lock()
            let handler = state.onTermination
            state.onTermination = nil
            state.terminal = true
            
            if let continuation = state.continuations.first {
                if state.pending.count > 0 {
                    state.continuations.removeFirst()
                    let toSend = state.pending.removeFirst()
                    unlock()
                    handler?(.finished)
                    continuation.resume(returning: toSend)
                } else if state.terminal {
                    state.continuations.removeFirst()
                    unlock()
                    handler?(.finished)
                    continuation.resume(returning: nil)
                } else {
                    unlock()
                    handler?(.finished)
                }
            } else {
                unlock()
                handler?(.finished)
            }
        }
        
        func next(_ continuation: UnsafeContinuation<Element?, Never>) {
            lock()
            state.continuations.append(continuation)
            if state.pending.count > 0 {
                let cont = state.continuations.removeFirst()
                let toSend = state.pending.removeFirst()
                unlock()
                cont.resume(returning: toSend)
            } else if state.terminal {
                let cont = state.continuations.removeFirst()
                unlock()
                cont.resume(returning: nil)
            } else {
                unlock()
            }
            
        }
        
        func next() async -> Element? {
            await withTaskCancellationHandler { [cancel] in
                cancel()
            } operation: {
                await withUnsafeContinuation {
                    next($0)
                }
            }
        }
        
        // 还可以这样, 在 Init 方法里面, 爆出 FatalError.
        // 必须使用工厂方法, 来创建对象.
        static func create(limit: Continuation.BufferingPolicy) -> _Storage {
            let minimumCapacity = _lockWordCount()
            let storage = Builtin.allocWithTailElems_1(
                _Storage.self,
                minimumCapacity._builtinWordValue,
                UnsafeRawPointer.self
            )
            
            let state =
            UnsafeMutablePointer<State>(Builtin.addressof(&storage.state))
            state.initialize(to: State(limit: limit))
            let ptr = UnsafeRawPointer(
                Builtin.projectTailElems(storage, UnsafeRawPointer.self))
            _lockInit(ptr)
            return storage
        }
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncThrowingStream {
    internal final class _Storage: @unchecked Sendable {
        typealias TerminationHandler = @Sendable (Continuation.Termination) -> Void
        enum Terminal {
            case finished
            case failed(Failure)
        }
        
        struct State {
            var continuation: UnsafeContinuation<Element?, Error>?
            var pending = _Deque<Element>()
            let limit: Continuation.BufferingPolicy
            var onTermination: TerminationHandler?
            var terminal: Terminal?
            
            init(limit: Continuation.BufferingPolicy) {
                self.limit = limit
            }
        }
        // Stored as a singular structured assignment for initialization
        var state: State
        
        private init(_doNotCallMe: ()) {
            fatalError("Storage must be initialized by create")
        }
        
        deinit {
            state.onTermination?(.cancelled)
        }
        
        private func lock() {
            let ptr =
            UnsafeRawPointer(Builtin.projectTailElems(self, UnsafeRawPointer.self))
            _lock(ptr)
        }
        
        private func unlock() {
            let ptr =
            UnsafeRawPointer(Builtin.projectTailElems(self, UnsafeRawPointer.self))
            _unlock(ptr)
        }
        
        func getOnTermination() -> TerminationHandler? {
            lock()
            let handler = state.onTermination
            unlock()
            return handler
        }
        
        func setOnTermination(_ newValue: TerminationHandler?) {
            lock()
            withExtendedLifetime(state.onTermination) {
                state.onTermination = newValue
                unlock()
            }
        }
        
        @Sendable func cancel() {
            lock()
            // swap out the handler before we invoke it to prevent double cancel
            let handler = state.onTermination
            state.onTermination = nil
            unlock()
            
            // handler must be invoked before yielding nil for termination
            handler?(.cancelled)
            
            finish()
        }
        
        func yield(_ value: __owned Element) -> Continuation.YieldResult {
            var result: Continuation.YieldResult
            lock()
            let limit = state.limit
            let count = state.pending.count
            if let continuation = state.continuation {
                if count > 0 {
                    if state.terminal == nil {
                        switch limit {
                        case .unbounded:
                            result = .enqueued(remaining: .max)
                            state.pending.append(value)
                        case .bufferingOldest(let limit):
                            if count < limit {
                                result = .enqueued(remaining: limit - (count + 1))
                                state.pending.append(value)
                            } else {
                                result = .dropped(value)
                            }
                        case .bufferingNewest(let limit):
                            if count < limit {
                                state.pending.append(value)
                                result = .enqueued(remaining: limit - (count + 1))
                            } else if count > 0 {
                                result = .dropped(state.pending.removeFirst())
                                state.pending.append(value)
                            } else {
                                result = .dropped(value)
                            }
                        }
                    } else {
                        result = .terminated
                    }
                    state.continuation = nil
                    let toSend = state.pending.removeFirst()
                    unlock()
                    continuation.resume(returning: toSend)
                } else if let terminal = state.terminal {
                    result = .terminated
                    state.continuation = nil
                    state.terminal = .finished
                    unlock()
                    switch terminal {
                    case .finished:
                        continuation.resume(returning: nil)
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    }
                } else {
                    switch limit {
                    case .unbounded:
                        result = .enqueued(remaining: .max)
                    case .bufferingOldest(let limit):
                        result = .enqueued(remaining: limit)
                    case .bufferingNewest(let limit):
                        result = .enqueued(remaining: limit)
                    }
                    
                    state.continuation = nil
                    unlock()
                    continuation.resume(returning: value)
                }
            } else {
                if state.terminal == nil {
                    switch limit {
                    case .unbounded:
                        result = .enqueued(remaining: .max)
                        state.pending.append(value)
                    case .bufferingOldest(let limit):
                        if count < limit {
                            result = .enqueued(remaining: limit - (count + 1))
                            state.pending.append(value)
                        } else {
                            result = .dropped(value)
                        }
                    case .bufferingNewest(let limit):
                        if count < limit {
                            state.pending.append(value)
                            result = .enqueued(remaining: limit - (count + 1))
                        } else if count > 0 {
                            result = .dropped(state.pending.removeFirst())
                            state.pending.append(value)
                        } else {
                            result = .dropped(value)
                        }
                    }
                } else {
                    result = .terminated
                }
                unlock()
            }
            return result
        }
        
        func finish(throwing error: __owned Failure? = nil) {
            lock()
            let handler = state.onTermination
            state.onTermination = nil
            if state.terminal == nil {
                if let failure = error {
                    state.terminal = .failed(failure)
                } else {
                    state.terminal = .finished
                }
            }
            
            if let continuation = state.continuation {
                if state.pending.count > 0 {
                    state.continuation = nil
                    let toSend = state.pending.removeFirst()
                    unlock()
                    handler?(.finished(error))
                    continuation.resume(returning: toSend)
                } else if let terminal = state.terminal {
                    state.continuation = nil
                    unlock()
                    handler?(.finished(error))
                    switch terminal {
                    case .finished:
                        continuation.resume(returning: nil)
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    }
                } else {
                    unlock()
                    handler?(.finished(error))
                }
            } else {
                unlock()
                handler?(.finished(error))
            }
        }
        
        func next(_ continuation: UnsafeContinuation<Element?, Error>) {
            lock()
            if state.continuation == nil {
                if state.pending.count > 0 {
                    let toSend = state.pending.removeFirst()
                    unlock()
                    continuation.resume(returning: toSend)
                } else if let terminal = state.terminal {
                    state.terminal = .finished
                    unlock()
                    switch terminal {
                    case .finished:
                        continuation.resume(returning: nil)
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    }
                } else {
                    state.continuation = continuation
                    unlock()
                }
            } else {
                unlock()
                fatalError("attempt to await next() on more than one task")
            }
        }
        
        func next() async throws -> Element? {
            try await withTaskCancellationHandler { [cancel] in
                cancel()
            } operation: {
                try await withUnsafeThrowingContinuation {
                    next($0)
                }
            }
        }
        
        static func create(limit: Continuation.BufferingPolicy) -> _Storage {
            let minimumCapacity = _lockWordCount()
            let storage = Builtin.allocWithTailElems_1(
                _Storage.self,
                minimumCapacity._builtinWordValue,
                UnsafeRawPointer.self
            )
            
            let state =
            UnsafeMutablePointer<State>(Builtin.addressof(&storage.state))
            state.initialize(to: State(limit: limit))
            let ptr = UnsafeRawPointer(
                Builtin.projectTailElems(storage, UnsafeRawPointer.self))
            _lockInit(ptr)
            return storage
        }
    }
}

// this is used to store closures; which are two words
final class _AsyncStreamCriticalStorage<Contents>: @unchecked Sendable {
    var _value: Contents
    private init(_doNotCallMe: ()) {
        fatalError("_AsyncStreamCriticalStorage must be initialized by create")
    }
    
    private func lock() {
        let ptr =
        UnsafeRawPointer(Builtin.projectTailElems(self, UnsafeRawPointer.self))
        _lock(ptr)
    }
    
    private func unlock() {
        let ptr =
        UnsafeRawPointer(Builtin.projectTailElems(self, UnsafeRawPointer.self))
        _unlock(ptr)
    }
    
    var value: Contents {
        get {
            lock()
            let contents = _value
            unlock()
            return contents
        }
        
        set {
            lock()
            withExtendedLifetime(_value) {
                _value = newValue
                unlock()
            }
        }
    }
    
    static func create(_ initial: Contents) -> _AsyncStreamCriticalStorage {
        let minimumCapacity = _lockWordCount()
        let storage = Builtin.allocWithTailElems_1(
            _AsyncStreamCriticalStorage.self,
            minimumCapacity._builtinWordValue,
            UnsafeRawPointer.self
        )
        
        let state =
        UnsafeMutablePointer<Contents>(Builtin.addressof(&storage._value))
        state.initialize(to: initial)
        let ptr = UnsafeRawPointer(
            Builtin.projectTailElems(storage, UnsafeRawPointer.self))
        _lockInit(ptr)
        return storage
    }
}

