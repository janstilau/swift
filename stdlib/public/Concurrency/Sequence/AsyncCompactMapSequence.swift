import Swift

extension AsyncSequence {
    /// Creates an asynchronous sequence that maps the given closure over the
    /// asynchronous sequence’s elements, omitting results that don't return a
    /// value.
    
    /// Use the `compactMap(_:)` method to transform every element received from
    /// a base asynchronous sequence, while also discarding any `nil` results
    /// from the closure. Typically, you use this to transform from one type of
    /// element to another.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `5`. The closure provided to the `compactMap(_:)`
    /// method takes each `Int` and looks up a corresponding `String` from a
    /// `romanNumeralDict` dictionary. Because there is no key for `4`, the closure
    /// returns `nil` in this case, which `compactMap(_:)` omits from the
    /// transformed asynchronous sequence.
    ///
    ///     let romanNumeralDict: [Int : String] =
    ///         [1: "I", 2: "II", 3: "III", 5: "V"]
    ///
    /// 在这里, 也是经常写换行. 的这种语法.
    ///     let stream = Counter(howHigh: 5)
    ///         .compactMap { romanNumeralDict[$0] }
    ///     for await numeral in stream {
    ///         print("\(numeral) ", terminator: " ")
    ///     }
    ///     // Prints: I  II  III  V
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an element
    ///   of this sequence as its parameter and returns a transformed value of the
    ///   same or of a different type.
    /// - Returns: An asynchronous sequence that contains, in order, the
    ///   non-`nil` elements produced by the `transform` closure.
    
    // 类型参数的声明, 直接写到函数的申明中.
    // 由 Transform 的返回值, 来确定 ElementOfResult 的类型. 而在各个内部类型中, 是直接使用了 ElementOfResult 的类型信息.
    public __consuming func compactMap<ElementOfResult>(
        _ transform: @Sendable @escaping (Element) async -> ElementOfResult?
    ) -> AsyncCompactMapSequence<Self, ElementOfResult> {
        return AsyncCompactMapSequence(self, transform: transform)
    }
}

/// An asynchronous sequence that maps a given closure over the asynchronous
/// sequence’s elements, omitting results that don't return a value.
// 基本的数据结构定义, 仅仅是为了进行值的存储.
public struct AsyncCompactMapSequence<Base: AsyncSequence, ElementOfResult> {
    @usableFromInline
    let base: Base
    
    @usableFromInline
    let transform: (Base.Element) async -> ElementOfResult?
    
    @usableFromInline
    init(
        _ base: Base,
        transform: @escaping (Base.Element) async -> ElementOfResult?
    ) {
        self.base = base
        self.transform = transform
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncCompactMapSequence: AsyncSequence {
    /// The type of element produced by this asynchronous sequence.
    /// The compact map sequence produces whatever type of element its
    /// transforming closure produces.
    
    public typealias Element = ElementOfResult
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = Iterator
    
    /// The iterator that produces elements of the compact map sequence.
    public struct Iterator: AsyncIteratorProtocol {
        public typealias Element = ElementOfResult
        
        var baseIterator: Base.AsyncIterator
        
        let transform: (Base.Element) async -> ElementOfResult?
        
        @usableFromInline
        init(
            _ baseIterator: Base.AsyncIterator,
            transform: @escaping (Base.Element) async -> ElementOfResult?
        ) {
            self.baseIterator = baseIterator
            self.transform = transform
        }
        
        /// Produces the next element in the compact map sequence.
        ///
        /// This iterator calls `next()` on its base iterator; if this call returns
        /// `nil`, `next()` returns `nil`. Otherwise, `next()` calls the
        /// transforming closure on the received element, returning it if the
        /// transform returns a non-`nil` value. If the transform returns `nil`,
        /// this method continues to wait for further elements until it gets one
        /// that transforms to a non-`nil` value.
        // 和 Map 相比, 就是增加了一个 nil 判断而已.
        public mutating func next() async rethrows -> ElementOfResult? {
            while true {
                guard let element = try await baseIterator.next() else {
                    return nil
                }
                // 只有, 明确的取到了 非 nil 的情况下, 才给后方的节点. 
                if let transformed = await transform(element) {
                    return transformed
                }
            }
        }
    }
    
    public __consuming func makeAsyncIterator() -> Iterator {
        return Iterator(base.makeAsyncIterator(), transform: transform)
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncCompactMapSequence: @unchecked Sendable 
where Base: Sendable,
        Base.Element: Sendable,
        ElementOfResult: Sendable { }

@available(SwiftStdlib 5.1, *)
extension AsyncCompactMapSequence.Iterator: @unchecked Sendable 
where Base.AsyncIterator: Sendable,
        Base.Element: Sendable,
        ElementOfResult: Sendable { }
