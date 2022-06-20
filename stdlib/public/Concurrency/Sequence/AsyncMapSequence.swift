import Swift

// Contains, First 这些都是返回一个单一的值.
// 而 Map 这些, 是返回一个新的 AsyncSequence, 它需要能够继续桥接的.
// 对于这些, 则是使用了一个新的类型进行了包装.
extension AsyncSequence {
    /// Creates an asynchronous sequence that maps the given closure over the
    /// asynchronous sequence’s elements.
    
    
    /// Use the `map(_:)` method to transform every element received from a base
    /// asynchronous sequence. Typically, you use this to transform from one type
    /// of element to another.
    
    
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `5`. The closure provided to the `map(_:)` method
    /// takes each `Int` and looks up a corresponding `String` from a
    /// `romanNumeralDict` dictionary. This means the outer `for await in` loop
    /// iterates over `String` instances instead of the underlying `Int` values
    /// that `Counter` produces:
    ///
    ///     let romanNumeralDict: [Int: String] =
    ///         [1: "I", 2: "II", 3: "III", 5: "V"]
    ///
    ///     let stream = Counter(howHigh: 5)
    ///     // 官方代码里面, 大量的使用了 ?? 这种符号.
    ///         .map { romanNumeralDict[$0] ?? "(unknown)" }
    ///     for await numeral in stream {
    ///         print("\(numeral) ", terminator: " ")
    ///     }
    ///     // Prints: I  II  III  (unknown)  V
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an element
    ///   of this sequence as its parameter and returns a transformed value of the
    ///   same or of a different type.
    /// - Returns: An asynchronous sequence that contains, in order, the elements
    ///   produced by the `transform` closure.
    @preconcurrency
    @inlinable
    public __consuming func map<Transformed>(
        _ transform: @Sendable @escaping (Element) async -> Transformed
    ) -> AsyncMapSequence<Self, Transformed> {
        return AsyncMapSequence(self, transform: transform)
    }
}

/// An asynchronous sequence that maps the given closure over the asynchronous
/// sequence’s elements.
@available(SwiftStdlib 5.1, *)
public struct AsyncMapSequence<Base: AsyncSequence, Transformed> {
    let base: Base
    
    let transform: (Base.Element) async -> Transformed
    
    // 这种写法, 会使得 Init 方法的第一行非常的古怪.
    // 也会让 ) { 这一行, 非常的古怪.
    init(
        _ base: Base,
        transform: @escaping (Base.Element) async -> Transformed
    ) {
        self.base = base
        self.transform = transform
    }
}

// 使用一个 Extension 来完成一个协议, 这是一个非常非常通用的做法.
extension AsyncMapSequence: AsyncSequence {
    /// The type of element produced by this asynchronous sequence.
    /// The map sequence produces whatever type of element its transforming
    /// closure produces.
    public typealias Element = Transformed
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = Iterator
    
    /// The iterator that produces elements of the map sequence.
    public struct Iterator: AsyncIteratorProtocol {
        @usableFromInline
        var baseIterator: Base.AsyncIterator
        
        @usableFromInline
        let transform: (Base.Element) async -> Transformed
        
        @usableFromInline
        init(
            _ baseIterator: Base.AsyncIterator,
            transform: @escaping (Base.Element) async -> Transformed
        ) {
            self.baseIterator = baseIterator
            self.transform = transform
        }
        
        /// Produces the next element in the map sequence.
        ///
        /// This iterator calls `next()` on its base iterator; if this call returns
        /// `nil`, `next()` returns `nil`. Otherwise, `next()` returns the result of
        /// calling the transforming closure on the received element.
        // 和之前 Map 的没有任何的区别, 仅仅是增加了 await 的调用而已.
        public mutating func next() async rethrows -> Transformed? {
            guard let element = try await baseIterator.next() else {
                return nil
            }
            return await transform(element)
        }
    }
    
    @inlinable
    public __consuming func makeAsyncIterator() -> Iterator {
        return Iterator(base.makeAsyncIterator(), transform: transform)
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncMapSequence: @unchecked Sendable 
where Base: Sendable,
      Base.Element: Sendable,
      Transformed: Sendable { }

@available(SwiftStdlib 5.1, *)
extension AsyncMapSequence.Iterator: @unchecked Sendable 
where Base.AsyncIterator: Sendable,
      Base.Element: Sendable,
      Transformed: Sendable { }
