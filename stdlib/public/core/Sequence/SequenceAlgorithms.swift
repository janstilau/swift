
extension Sequence {
    public func enumerated() -> EnumeratedSequence<Self> {
        return EnumeratedSequence(_base: self)
    }
}

extension Sequence {
    
    /*
     areInIncreasingOrder 应该, 用函数的命名规则来命名参数变量名.
     Block 的参数, 如果传入的闭包, 是可以 throws 的, 那么外部函数就要进行 trycatch.
     否则, 就是不带 throws 版本的函数.
     */
    public func min(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> Element? {
        var it = makeIterator()
        guard var result = it.next() else { return nil }
        while let e = it.next() {
            if try areInIncreasingOrder(e, result) { result = e }
        }
        return result
    }
    
    public func max(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> Element? {
        var it = makeIterator()
        guard var result = it.next() else { return nil }
        while let e = it.next() {
            if try areInIncreasingOrder(result, e) { result = e }
        }
        return result
    }
}

// 对于, 实现了 Comparable, 有着更好地实现. 偏特化.
// 也即是, 编译器保证了, Comparable 的 element 可以有 min 的实现.
extension Sequence where Element: Comparable {
    public func min() -> Element? {
        return self.min(by: <)
    }
    public func max() -> Element? {
        return self.max(by: <)
    }
}

extension Sequence  {
    // 使用系统库的代码的好处就是, 简洁.
    // 其实, 这些逻辑, 自己写一遍也无妨. 但熟悉系统库, 可以写出清晰并且安全的代码.
    public func starts<PossiblePrefix: Sequence>(
        with possiblePrefix: PossiblePrefix,
        by areEquivalent: (Element, PossiblePrefix.Element) throws -> Bool
    ) rethrows -> Bool {
        var possiblePrefixIterator = possiblePrefix.makeIterator()
        for e0 in self {
            if let e1 = possiblePrefixIterator.next() {
                if try !areEquivalent(e0, e1) {
                    return false
                }
            } else {
                return true
            }
        }
        return possiblePrefixIterator.next() == nil
    }
}

extension Sequence where Element: Equatable {
    public func starts<PossiblePrefix: Sequence>(
        with possiblePrefix: PossiblePrefix
    ) -> Bool where PossiblePrefix.Element == Element {
        return self.starts(with: possiblePrefix, by: ==)
    }
}

extension Sequence {
    public func elementsEqual<OtherSequence: Sequence>(
        _ other: OtherSequence,
        by areEquivalent: (Element, OtherSequence.Element) throws -> Bool
    ) rethrows -> Bool {
        var iter1 = self.makeIterator()
        var iter2 = other.makeIterator()
        while true {
            // 注意, 这里 switch 的用法.
            switch (iter1.next(), iter2.next()) {
            case let (e1?, e2?):
                if try !areEquivalent(e1, e2) {
                    return false
                }
            case (_?, nil), (nil, _?): return false
            case (nil, nil):           return true
            }
        }
    }
}

extension Sequence where Element: Equatable {
    public func elementsEqual<OtherSequence: Sequence>(
        _ other: OtherSequence
    ) -> Bool where OtherSequence.Element == Element {
        return self.elementsEqual(other, by: ==)
    }
}

extension Sequence {
    /// Returns a Boolean value indicating whether the sequence precedes another
    /// sequence in a lexicographical (dictionary) ordering, using the given
    /// predicate to compare elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// - Parameters:
    ///   - other: A sequence to compare to this sequence.
    ///   - areInIncreasingOrder:  A predicate that returns `true` if its first
    ///     argument should be ordered before its second argument; otherwise,
    ///     `false`.
    /// - Returns: `true` if this sequence precedes `other` in a dictionary
    ///   ordering as ordered by `areInIncreasingOrder`; otherwise, `false`.
    ///
    /// - Note: This method implements the mathematical notion of lexicographical
    ///   ordering, which has no connection to Unicode.  If you are sorting
    ///   strings to present to the end user, use `String` APIs that perform
    ///   localized comparison instead.
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the length of the
    ///   sequence and the length of `other`.
    @inlinable
    public func lexicographicallyPrecedes<OtherSequence: Sequence>(
        _ other: OtherSequence,
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> Bool
    where OtherSequence.Element == Element {
        var iter1 = self.makeIterator()
        var iter2 = other.makeIterator()
        while true {
            if let e1 = iter1.next() {
                if let e2 = iter2.next() {
                    if try areInIncreasingOrder(e1, e2) {
                        return true
                    }
                    if try areInIncreasingOrder(e2, e1) {
                        return false
                    }
                    continue // Equivalent
                }
                return false
            }
            
            return iter2.next() != nil
        }
    }
}

extension Sequence where Element: Comparable {
    /// Returns a Boolean value indicating whether the sequence precedes another
    /// sequence in a lexicographical (dictionary) ordering, using the
    /// less-than operator (`<`) to compare elements.
    ///
    /// This example uses the `lexicographicallyPrecedes` method to test which
    /// array of integers comes first in a lexicographical ordering.
    ///
    ///     let a = [1, 2, 2, 2]
    ///     let b = [1, 2, 3, 4]
    ///
    ///     print(a.lexicographicallyPrecedes(b))
    ///     // Prints "true"
    ///     print(b.lexicographicallyPrecedes(b))
    ///     // Prints "false"
    ///
    /// - Parameter other: A sequence to compare to this sequence.
    /// - Returns: `true` if this sequence precedes `other` in a dictionary
    ///   ordering; otherwise, `false`.
    ///
    /// - Note: This method implements the mathematical notion of lexicographical
    ///   ordering, which has no connection to Unicode.  If you are sorting
    ///   strings to present to the end user, use `String` APIs that
    ///   perform localized comparison.
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the length of the
    ///   sequence and the length of `other`.
    @inlinable
    public func lexicographicallyPrecedes<OtherSequence: Sequence>(
        _ other: OtherSequence
    ) -> Bool where OtherSequence.Element == Element {
        return self.lexicographicallyPrecedes(other, by: <)
    }
}

extension Sequence {
    public func contains(
        where predicate: (Element) throws -> Bool
    ) rethrows -> Bool {
        for e in self {
            if try predicate(e) {
                return true
            }
        }
        return false
    }
    
    public func allSatisfy(
        _ predicate: (Element) throws -> Bool
    ) rethrows -> Bool {
        return try !contains { try !predicate($0) }
    }
}

extension Sequence where Element: Equatable {
    public func contains(_ element: Element) -> Bool {
        // 子类自定义 _customContainsEquatableElement, 可以有更好地实现
        if let result = _customContainsEquatableElement(element) {
            return result
        } else {
            return self.contains { $0 == element }
        }
    }
}

extension Sequence {
    public func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult:
        (_ partialResult: Result, Element) throws -> Result
    ) rethrows -> Result {
        var accumulator = initialResult
        for element in self {
            accumulator = try nextPartialResult(accumulator, element)
        }
        return accumulator
    }
    
    public func reduce<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult:
        (_ partialResult: inout Result, Element) throws -> ()
    ) rethrows -> Result {
        var accumulator = initialResult
        for element in self {
            try updateAccumulatingResult(&accumulator, element)
        }
        return accumulator
    }
}

extension Sequence {
    /// Returns an array containing the elements of this sequence in reverse
    /// order.
    ///
    /// The sequence must be finite.
    ///
    /// - Returns: An array containing the elements of this sequence in
    ///   reverse order.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public __consuming func reversed() -> [Element] {
        // FIXME(performance): optimize to 1 pass?  But Array(self) can be
        // optimized to a memcpy() sometimes.  Those cases are usually collections,
        // though.
        var result = Array(self)
        let count = result.count
        for i in 0..<count/2 {
            result.swapAt(i, count - ((i + 1) as Int))
        }
        return result
    }
}

//===----------------------------------------------------------------------===//
// flatMap()
//===----------------------------------------------------------------------===//

extension Sequence {
    /// Returns an array containing the concatenated results of calling the
    /// given transformation with each element of this sequence.
    ///
    /// Use this method to receive a single-level collection when your
    /// transformation produces a sequence or collection for each element.
    ///
    /// In this example, note the difference in the result of using `map` and
    /// `flatMap` with a transformation that returns an array.
    ///
    ///     let numbers = [1, 2, 3, 4]
    ///
    ///     let mapped = numbers.map { Array(repeating: $0, count: $0) }
    ///     // [[1], [2, 2], [3, 3, 3], [4, 4, 4, 4]]
    ///
    ///     let flatMapped = numbers.flatMap { Array(repeating: $0, count: $0) }
    ///     // [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]
    ///
    /// In fact, `s.flatMap(transform)`  is equivalent to
    /// `Array(s.map(transform).joined())`.
    ///
    /// - Parameter transform: A closure that accepts an element of this
    ///   sequence as its argument and returns a sequence or collection.
    /// - Returns: The resulting flattened array.
    ///
    /// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
    ///   and *m* is the length of the result.
    @inlinable
    public func flatMap<SegmentOfResult: Sequence>(
        _ transform: (Element) throws -> SegmentOfResult
    ) rethrows -> [SegmentOfResult.Element] {
        var result: [SegmentOfResult.Element] = []
        for element in self {
            result.append(contentsOf: try transform(element))
        }
        return result
    }
}

extension Sequence {
    /// Returns an array containing the non-`nil` results of calling the given
    /// transformation with each element of this sequence.
    ///
    /// Use this method to receive an array of non-optional values when your
    /// transformation produces an optional value.
    ///
    /// In this example, note the difference in the result of using `map` and
    /// `compactMap` with a transformation that returns an optional `Int` value.
    ///
    ///     let possibleNumbers = ["1", "2", "three", "///4///", "5"]
    ///
    ///     let mapped: [Int?] = possibleNumbers.map { str in Int(str) }
    ///     // [1, 2, nil, nil, 5]
    ///
    ///     let compactMapped: [Int] = possibleNumbers.compactMap { str in Int(str) }
    ///     // [1, 2, 5]
    ///
    /// - Parameter transform: A closure that accepts an element of this
    ///   sequence as its argument and returns an optional value.
    /// - Returns: An array of the non-`nil` results of calling `transform`
    ///   with each element of the sequence.
    ///
    /// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
    ///   and *m* is the length of the result.
    @inlinable // protocol-only
    public func compactMap<ElementOfResult>(
        _ transform: (Element) throws -> ElementOfResult?
    ) rethrows -> [ElementOfResult] {
        return try _compactMap(transform)
    }
    
    // The implementation of compactMap accepting a closure with an optional result.
    // Factored out into a separate function in order to be used in multiple
    // overloads.
    @inlinable // protocol-only
    @inline(__always)
    public func _compactMap<ElementOfResult>(
        _ transform: (Element) throws -> ElementOfResult?
    ) rethrows -> [ElementOfResult] {
        var result: [ElementOfResult] = []
        for element in self {
            if let newElement = try transform(element) {
                result.append(newElement)
            }
        }
        return result
    }
}
