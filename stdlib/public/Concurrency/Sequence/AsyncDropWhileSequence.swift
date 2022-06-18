import Swift

@available(SwiftStdlib 5.1, *)
extension AsyncSequence {
    /// Omits elements from the base asynchronous sequence until a given closure
    /// returns false, after which it passes through all remaining elements.
    // 只要, predicate 返回了 false, 就放开权限了.
    // 后面的所有的 element, 就能够正常的涌入了.
    // Combine 里面, 延续了这一个理念, 只要放开一次, 就可以将所有的后续数据收纳了.
    /// Use `drop(while:)` to omit elements from an asynchronous sequence until
    /// the element received meets a condition you specify.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `drop(while:)` method causes the modified
    /// sequence to ignore received values until it encounters one that is
    /// divisible by `3`:
    ///
    ///     let stream = Counter(howHigh: 10)
    ///         .drop { $0 % 3 != 0 }
    ///     for await number in stream {
    ///         print("\(number) ", terminator: " ")
    ///     }
    ///     // prints "3 4 5 6 7 8 9 10"
    
    // 只要, Predicate false 了一次, 这个 Predicate 就失效了.
    /// After the predicate returns `false`, the sequence never executes it again,
    /// and from then on the sequence passes through elements from its underlying
    /// sequence as-is.
    ///
    /// - Parameter predicate: A closure that takes an element as a parameter and
    ///   returns a Boolean value indicating whether to drop the element from the
    ///   modified sequence.
    /// - Returns: An asynchronous sequence that skips over values from the
    ///   base sequence until the provided closure returns `false`.
    @preconcurrency
    @inlinable
    public __consuming func drop(
        // 传递过来的函数, 要是 @Sendable 修饰的, 这对于闭包的捕获值类型有着特殊的要求.
        // 这更多的是一个编译器的选项, 如果不符合的话, 直接就编译报错了.
        while predicate: @Sendable @escaping (Element) async -> Bool
    ) -> AsyncDropWhileSequence<Self> {
        AsyncDropWhileSequence(self, predicate: predicate)
    }
}

/// An asynchronous sequence which omits elements from the base sequence until a
/// given closure returns false, after which it passes through all remaining
/// elements.
// 一顿存储操作.
public struct AsyncDropWhileSequence<Base: AsyncSequence> {
    @usableFromInline
    let base: Base
    
    @usableFromInline
    let predicate: (Base.Element) async -> Bool
    
    @usableFromInline
    init(
        _ base: Base,
        predicate: @escaping (Base.Element) async -> Bool
    ) {
        self.base = base
        self.predicate = predicate
    }
}

// 最最和新的地方, 就是定义相对应的 Iterator 对象.
extension AsyncDropWhileSequence: AsyncSequence {
    /// The type of element produced by this asynchronous sequence.
    /// The drop-while sequence produces whatever type of element its base
    /// sequence produces.
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = Iterator
    
    /// The iterator that produces elements of the drop-while sequence.
    public struct Iterator: AsyncIteratorProtocol {
        @usableFromInline
        var baseIterator: Base.AsyncIterator
        
        @usableFromInline
        var predicate: ((Base.Element) async -> Bool)?
        
        @usableFromInline
        init(
            _ baseIterator: Base.AsyncIterator,
            predicate: @escaping (Base.Element) async -> Bool
        ) {
            self.baseIterator = baseIterator
            self.predicate = predicate
        }
        
        /// Produces the next element in the drop-while sequence.
        ///
        /// This iterator calls `next()` on its base iterator and evaluates the
        /// result with the `predicate` closure. As long as the predicate returns
        /// `true`, this method returns `nil`. After the predicate returns `false`,
        /// for a value received from the base iterator, this method returns that
        /// value. After that, the iterator returns values received from its
        /// base iterator as-is, and never executes the predicate closure again.
        public mutating func next() async rethrows -> Base.Element? {
            while let predicate = self.predicate {
                // 先是从源头取值.
                guard let element = try await baseIterator.next() else {
                    return nil
                }
                // 然后, 使用 predicate 进行判断.
                // 在判断完了之后, 立马对 predicate 进行了置空处理.
                // 之后所有的操作, 都是直接使用源头的数据了.
                if await predicate(element) == false {
                    self.predicate = nil
                    return element
                }
            }
            return try await baseIterator.next()
        }
    }
    
    /// Creates an instance of the drop-while sequence iterator.
    public __consuming func makeAsyncIterator() -> Iterator {
        return Iterator(base.makeAsyncIterator(), predicate: predicate)
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncDropWhileSequence: @unchecked Sendable 
where Base: Sendable,
        Base.Element: Sendable { }

@available(SwiftStdlib 5.1, *)
extension AsyncDropWhileSequence.Iterator: @unchecked Sendable 
where Base.AsyncIterator: Sendable,
        Base.Element: Sendable { }
