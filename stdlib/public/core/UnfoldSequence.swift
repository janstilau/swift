public func sequence<T>(first: T, next: @escaping (T) -> T?) -> UnfoldFirstSequence<T> {
    // state中, true 代表的是第一次访问.
    // 因为这个函数是 first, 所以, 第一次是一定会有值的.
    return sequence(state: (first, true), next: {
        (state: inout (T?, Bool)) -> T? in
        switch state {
        case (let value, true):
            state.1 = false
            return value
        case (let value?, _):
            let nextValue = next(value)
            state.0 = nextValue
            return nextValue
        case (nil, _):
            return nil
        }
    })
}

/// Returns a sequence formed from repeated lazy applications of `next` to a
/// mutable `state`.
///
/// The elements of the sequence are obtained by invoking `next` with a mutable
/// state. The same state is passed to all invocations of `next`, so subsequent
/// calls will see any mutations made by previous calls. The sequence ends when
/// `next` returns `nil`. If `next` never returns `nil`, the sequence is
/// infinite.
///
/// This function can be used to replace many instances of `AnyIterator` that
/// wrap a closure.
///
/// Example:
///
///     // Interleave two sequences that yield the same element type
///     sequence(state: (false, seq1.makeIterator(), seq2.makeIterator()), next: { iters in
///       iters.0 = !iters.0
///       return iters.0 ? iters.1.next() : iters.2.next()
///     })
///
/// - Parameter state: The initial state that will be passed to the closure.
/// - Parameter next: A closure that accepts an `inout` state and returns the
///   next element of the sequence.
/// - Returns: A sequence that yields each successive value from `next`.
@inlinable // generic-performance
public func sequence<T, State>(state: State,
                               next: @escaping (inout State) -> T?)
-> UnfoldSequence<T, State> {
    return UnfoldSequence(_state: state, _next: next)
}

/// The return type of `sequence(first:next:)`.
public typealias UnfoldFirstSequence<T> = UnfoldSequence<T, (T?, Bool)>

// 通过, 不断的调用闭包, 产生一个新的 sequence.
// 这个 sequence, 都可以看做是 lazy 的.
public struct UnfoldSequence<Element, State>: Sequence, IteratorProtocol {
    
    internal var _state: State
    internal let _next: (inout State) -> Element?
    internal var _done = false
    
    internal init(_state: State, _next: @escaping (inout State) -> Element?) {
        self._state = _state
        self._next = _next
    }
    
    public mutating func next() -> Element? {
        guard !_done else { return nil }
        if let elt = _next(&_state) {
            return elt
        } else {
            _done = true
            return nil
        }
    }
    
    
}
