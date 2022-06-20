import Swift

@available(SwiftStdlib 5.1, *)
extension AsyncSequence {
    /// Omits a specified number of elements from the base asynchronous sequence,
    /// then passes through all remaining elements.
    
    /// Use `dropFirst(_:)` when you want to drop the first *n* elements from the
    /// base sequence and pass through the remaining elements.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `dropFirst(_:)` method causes the modified
    /// sequence to ignore the values `0` through `4`, and instead emit `5` through `10`:
    ///
    ///     for await number in Counter(howHigh: 10).dropFirst(3) {
    ///         print("\(number) ", terminator: " ")
    ///     }
    ///     // prints "4 5 6 7 8 9 10"
    
    
    /// If the number of elements to drop exceeds the number of elements in the
    /// sequence, the result is an empty sequence.
    ///
    /// - Parameter count: The number of elements to drop from the beginning of
    ///   the sequence. `count` must be greater than or equal to zero.
    /// - Returns: An asynchronous sequence that drops the first `count`
    ///   elements from the base sequence.
    @inlinable
    public __consuming func dropFirst(
        _ count: Int = 1
    ) -> AsyncDropFirstSequence<Self> {
        // 在设计一个 API 的时候, 要进行防卫式的判断.
        // 当传入的值, 明显不符合自己的声明的时候, 要么进行修正, 要么直接进行报错.
        // 在自己的代码里面, 错误处理其实没有做的太好.
        precondition(count >= 0,
                     "Can't drop a negative number of elements from an async sequence")
        return AsyncDropFirstSequence(self, dropping: count)
    }
}

/// An asynchronous sequence which omits a specified number of elements from the
/// base asynchronous sequence, then passes through all remaining elements.
// 基础定义, 就是存值.
public struct AsyncDropFirstSequence<Base: AsyncSequence> {
    let base: Base
    
    let count: Int
    
    init(_ base: Base, dropping count: Int) {
        self.base = base
        self.count = count
    }
}

extension AsyncDropFirstSequence: AsyncSequence {
    /// The type of element produced by this asynchronous sequence.
    /// The drop-first sequence produces whatever type of element its base
    /// iterator produces.
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = Iterator
    
    /// The iterator that produces elements of the drop-first sequence.
    public struct Iterator: AsyncIteratorProtocol {
        var baseIterator: Base.AsyncIterator
        
        var count: Int
        
        init(_ baseIterator: Base.AsyncIterator, count: Int) {
            self.baseIterator = baseIterator
            self.count = count
        }
        
        /// Produces the next element in the drop-first sequence.
        ///
        /// Until reaching the number of elements to drop, this iterator calls
        /// `next()` on its base iterator and discards the result. If the base
        /// iterator returns `nil`, indicating the end of the sequence, this
        /// iterator returns `nil`. After reaching the number of elements to
        /// drop, this iterator passes along the result of calling `next()` on
        /// the base iterator.
        // 和 Sequence 没有太大的区别, 就是消耗上游的序列.
        public mutating func next() async rethrows -> Base.Element? {
            var remainingToDrop = count
            // 如果, 上游消耗的数量, 还没有到达配置的数量, 那么就不给下游发送数据.
            while remainingToDrop > 0 {
                guard try await baseIterator.next() != nil else {
                    count = 0
                    return nil
                }
                remainingToDrop -= 1
            }
            count = 0
            return try await baseIterator.next()
        }
    }
    
    @inlinable
    public __consuming func makeAsyncIterator() -> Iterator {
        return Iterator(base.makeAsyncIterator(), count: count)
    }
}

// 之所以, 要专门的定义这几个方法, 有一个词语叫做融合.
// 没有必要在进行新的节点的创建了, 直接返回一个节点, 这个节点对接最原始的节点就可以了.
// 在这个节点里面, 将消耗的总数量进行合并.

// 之所以有这样的设计, 更多的应该是为了性能.
extension AsyncDropFirstSequence {
    /// Omits a specified number of elements from the base asynchronous sequence,
    /// then passes through all remaining elements.
    ///
    /// When you call `dropFirst(_:)` on an asynchronous sequence that is already
    /// an `AsyncDropFirstSequence`, the returned sequence simply adds the new
    /// drop count to the current drop count.
    public __consuming func dropFirst(
        _ count: Int = 1
    ) -> AsyncDropFirstSequence<Base> {
        // If this is already a AsyncDropFirstSequence, we can just sum the current
        // drop count and additional drop count.
        precondition(count >= 0,
                     "Can't drop a negative number of elements from an async sequence")
        return AsyncDropFirstSequence(base, dropping: self.count + count)
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncDropFirstSequence: Sendable 
where Base: Sendable,
        Base.Element: Sendable { }

@available(SwiftStdlib 5.1, *)
extension AsyncDropFirstSequence.Iterator: Sendable 
where Base.AsyncIterator: Sendable,
        Base.Element: Sendable { }
