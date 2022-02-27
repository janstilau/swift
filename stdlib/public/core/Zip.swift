/// Creates a sequence of pairs built out of two underlying sequences.
///
/// In the `Zip2Sequence` instance returned by this function, the elements of
/// the *i*th pair are the *i*th elements of each underlying sequence. The
/// following example uses the `zip(_:_:)` function to iterate over an array
/// of strings and a countable range at the same time:
///
///     let words = ["one", "two", "three", "four"]
///     let numbers = 1...4
///
///     for (word, number) in zip(words, numbers) {
///         print("\(word): \(number)")
///     }
///     // Prints "one: 1"
///     // Prints "two: 2
///     // Prints "three: 3"
///     // Prints "four: 4"
///
/// If the two sequences passed to `zip(_:_:)` are different lengths, the
/// resulting sequence is the same length as the shorter sequence. In this
/// example, the resulting array is the same length as `words`:
///
///     let naturalNumbers = 1...Int.max
///     let zipped = Array(zip(words, naturalNumbers))
///     // zipped == [("one", 1), ("two", 2), ("three", 3), ("four", 4)]
///
/// - Parameters:
///   - sequence1: The first sequence or collection to zip.
///   - sequence2: The second sequence or collection to zip.
/// - Returns: A sequence of tuple pairs, where the elements of each pair are
///   corresponding elements of `sequence1` and `sequence2`.

/*
    Zip2Sequence 是一个特殊的数据类型.
    大部分的功能, 都是在 Sequence 协议里面添加的.
    Zip2Sequence 通过, 满足 Sequence 的各种限制, 自动有了大部分的功能.
 */
@inlinable // generic-performance
public func zip<Sequence1, Sequence2>(
    _ sequence1: Sequence1, _ sequence2: Sequence2
) -> Zip2Sequence<Sequence1, Sequence2> {
    return Zip2Sequence(sequence1, sequence2)
}

/// A sequence of pairs built out of two underlying sequences.
///
/// In a `Zip2Sequence` instance, the elements of the *i*th pair are the *i*th
/// elements of each underlying sequence. To create a `Zip2Sequence` instance,
/// use the `zip(_:_:)` function.
///
/// The following example uses the `zip(_:_:)` function to iterate over an
/// array of strings and a countable range at the same time:
///
///     let words = ["one", "two", "three", "four"]
///     let numbers = 1...4
///
///     for (word, number) in zip(words, numbers) {
///         print("\(word): \(number)")
///     }
///     // Prints "one: 1"
///     // Prints "two: 2
///     // Prints "three: 3"
///     // Prints "four: 4"
@frozen // generic-performance
public struct Zip2Sequence<Sequence1: Sequence, Sequence2: Sequence> {
    /*
        还是使用了 _ 表示私有的成员变量.
     */
    @usableFromInline // generic-performance
    internal let _sequence1: Sequence1
    @usableFromInline // generic-performance
    internal let _sequence2: Sequence2
    
    /// Creates an instance that makes pairs of elements from `sequence1` and
    /// `sequence2`.
    @inlinable // generic-performance
    internal init(_ sequence1: Sequence1, _ sequence2: Sequence2) {
        (_sequence1, _sequence2) = (sequence1, sequence2)
    }
}

/*
    在 C++ 里面, 有着通用的算法, 只不过, 没有统一协议接口来进行约束.
    真正的迭代的过程, 还是变为 Iterator 来实现.
    原始的迭代器, 是存储着具体的数据格式的细节.
    在这个复合的 Iterator 里面, 是存储了, 两个 Iterator, 根据这两个 Iterator 进行新的复合逻辑.
 */
extension Zip2Sequence {
    /// An iterator for `Zip2Sequence`.
    @frozen // generic-performance
    public struct Iterator {
        @usableFromInline // generic-performance
        internal var _baseStream1: Sequence1.Iterator
        
        @usableFromInline // generic-performance
        internal var _baseStream2: Sequence2.Iterator
        
        @usableFromInline // generic-performance
        internal var _reachedEnd: Bool = false
        
        /// Creates an instance around a pair of underlying iterators.
        @inlinable // generic-performance
        internal init(
            _ iterator1: Sequence1.Iterator,
            _ iterator2: Sequence2.Iterator
        ) {
            (_baseStream1, _baseStream2) = (iterator1, iterator2)
        }
    }
}

/*
    每一个类型, 对于协议的实现. 都写到一个单独的 Extension 里面.
 */
extension Zip2Sequence.Iterator: IteratorProtocol {
    /// The type of element returned by `next()`.
    public typealias Element = (Sequence1.Element, Sequence2.Element)
    
    /// Advances to the next element and returns it, or `nil` if no next element
    /// exists.
    ///
    /*
        在 Zip2 的序列里面, 编写 Next 的逻辑.
     */
    @inlinable // generic-performance
    public mutating func next() -> Element? {
        // The next() function needs to track if it has reached the end.  If we
        // didn't, and the first sequence is longer than the second, then when we
        // have already exhausted the second sequence, on every subsequent call to
        // next() we would consume and discard one additional element from the
        // first sequence, even though next() had already returned nil.
        
        // 所以, 其实不用全部使用 Guard 来做逻辑的判断, 该用 if 判断的, 就可以使用 if 来进行判断.
        if _reachedEnd {
            return nil
        }
        
        guard let element1 = _baseStream1.next(),
              let element2 = _baseStream2.next() else {
                  _reachedEnd = true
                  return nil
              }
        
        return (element1, element2)
    }
}

/*
    对于 Sequence 的实现, 也是单独一个 Extension 来实现的.
 */
extension Zip2Sequence: Sequence {
    public typealias Element = (Sequence1.Element, Sequence2.Element)
    
    /// Returns an iterator over the elements of this sequence.
    @inlinable // generic-performance
    public __consuming func makeIterator() -> Iterator {
        return Iterator(
            _sequence1.makeIterator(),
            _sequence2.makeIterator())
    }
    
    @inlinable // generic-performance
    public var underestimatedCount: Int {
        return Swift.min(
            _sequence1.underestimatedCount,
            _sequence2.underestimatedCount
        )
    }
}
