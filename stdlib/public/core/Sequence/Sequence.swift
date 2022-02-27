


/// A type that supplies the values of a sequence one at a time.
// 按序的可以提供数据的一个类型. 叫做序列.

/// The `IteratorProtocol` protocol is tightly linked with the `Sequence`
/// protocol. Sequences provide access to their elements by creating an
/// iterator, which keeps track of its iteration process and returns one
/// element at a time as it advances through the sequence.
/*
 序列, 提供一个迭代器, 然后让迭代器来返回序列内的内容.
 这个迭代器, 是一个抽象的数据类型. 里面, 保存了序列的内部存储, 所以可以按照序列的数据结构, 找到下一个数据.
 迭代器的概念, 是各个编程语言, 统一遵从的设计理念.
 */

/*
 在编写 Sequence 各种函数式方法的时候, 会直接使用到 Iter 的对象.
 因为这些方法, 就是在编译的时候, 按照方法名称所表示的业务含义在加工数据, 需要更加精细化的控制.
 而这些牢记这些方法所代表的含义, 可以使得这些方法像积木一样, 搭建出复杂的逻辑来.
 这个搭建过程, 简单有效具有表意. 因为各个方法的设计里面, 是通用的, 在各个语言中都有实现.
 */

/// Using Multiple Iterators
/// ========================
///
/// Whenever you use multiple iterators (or `for`-`in` loops) over a single
/// sequence, be sure you know that the specific sequence supports repeated
/// iteration, either because you know its concrete type or because the
/// sequence is also constrained to the `Collection` protocol.
///
/// Obtain each separate iterator from separate calls to the sequence's
/// `makeIterator()` method rather than by copying. Copying an iterator is
/// safe, but advancing one copy of an iterator by calling its `next()` method
/// may invalidate other copies of that iterator. `for`-`in` loops are safe in
/// this regard.

/// For example, consider a custom `Countdown` sequence. You can initialize the
/// `Countdown` sequence with a starting integer and then iterate over the
/// count down to zero. The `Countdown` structure's definition is short: It
/// contains only the starting count and the `makeIterator()` method required
/// by the `Sequence` protocol.
///
///     struct Countdown: Sequence {
///         let start: Int
///
///         func makeIterator() -> CountdownIterator {
///             return CountdownIterator(self)
///         }
///     }
///
/// The `makeIterator()` method returns another custom type, an iterator named
/// `CountdownIterator`. The `CountdownIterator` type keeps track of both the
/// `Countdown` sequence that it's iterating and the number of times it has
/// returned a value.
///
///     struct CountdownIterator: IteratorProtocol {
///         let countdown: Countdown
///         var times = 0
///
///         init(_ countdown: Countdown) {
///             self.countdown = countdown
///         }
///
///         mutating func next() -> Int? {
///             let nextNumber = countdown.start - times
///             guard nextNumber > 0
///                 else { return nil }
///
///             times += 1
///             return nextNumber
///         }
///     }
/*
 以上的设计, 是标配.
 设计一个 Sequence, 在 Sequence 里面, 做数据的存储, 业务功能的实现.
 然后, 将遍历这件事, 以及遍历过程中的索引状态记录, 交给相对应 Iter 对象 .
 */
public protocol IteratorProtocol {
    // associatedtype 就是 Protocol 里面的泛型 .
    // 泛型, 就是一个半成品, 只有实际可以确定下来类型参数的时候, 才能确定实际的类型.
    associatedtype Element
    mutating func next() -> Element?
}

// 这里, 是面向协议编程的好处. 将, 各种函数的定义, 定义到了真正的协议中.
// 协议的扩展里面, 使用协议的基本方法, 定义复杂的方法, 使得协议的实现者, 自动获取了各种方便的和协议相关的方法.

/*
 原本的接口概念, 仅仅是操作蓝本.
 但是, swift 里面的接口, 更多的是操作蓝本和在操作蓝本基础上的扩展方法.
 所以, 可以当做抽象类来进行看待.
 扩展方法, 看做是模板方法, 里面的基础方法, 可以由各个类进行重写.
 各个类通过基础方法的重写, 完成自定义, 影响扩展方法的实现.
 扩展方法, 则提供了可以复用的基础, 让协议成为了更好地, 通用的代码逻辑的实现者.
 */
/// The `Sequence` protocol provides default implementations for many common
/// operations that depend on sequential access to a sequence's values. For
/// clearer, more concise code, the example above could use the array's
/// `contains(_:)` method, which every sequence inherits from `Sequence`,
/// instead of iterating manually:


public protocol Sequence {
    associatedtype Element
    associatedtype Iterator: IteratorProtocol where Iterator.Element == Element
    
    __consuming func makeIterator() -> Iterator
    
    
    // 这个有默认实现, 就是返回 0. 实现了这个方法, 能够让算法更加的高效.
    // 这也是协议的 PRIMITIVEMethod 的作用, 影响 extension 里面的实现.
    var underestimatedCount: Int { get }
    
    // 自定义的 ele 的相等判断. Primitive Method, 有默认实现.
    // 子类重写, 可以影响到 extension 里面的逻辑
    func _customContainsEquatableElement(
        _ element: Element
    ) -> Bool?
    
    /// Create a native array buffer containing the elements of `self`,
    /// in the same order.
    __consuming func _copyToContiguousArray() -> ContiguousArray<Element>
    
    /// Copy `self` into an unsafe buffer, initializing its memory.
    ///
    /// The default implementation simply iterates over the elements of the
    /// sequence, initializing the buffer one item at a time.
    ///
    /// For sequences whose elements are stored in contiguous chunks of memory,
    /// it may be more efficient to copy them in bulk, using the
    /// `UnsafeMutablePointer.initialize(from:count:)` method.
    ///
    /// - Parameter ptr: An unsafe buffer addressing uninitialized memory. The
    ///    buffer must be of sufficient size to accommodate
    ///    `source.underestimatedCount` elements. (Some implementations trap
    ///    if given a buffer that's smaller than this.)
    ///
    /// - Returns: `(it, c)`, where `c` is the number of elements copied into the
    ///    buffer, and `it` is a partially consumed iterator that can be used to
    ///    retrieve elements that did not fit into the buffer (if any). (This can
    ///    only happen if `underestimatedCount` turned out to be an actual
    ///    underestimate, and the buffer did not contain enough space to hold the
    ///    entire sequence.)
    ///
    ///    On return, the memory region in `buffer[0 ..< c]` is initialized to
    ///    the first `c` elements in the sequence.
    __consuming func _copyContents(
        initializing ptr: UnsafeMutableBufferPointer<Element>
    ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index)
    
    /// Call `body(p)`, where `p` is a pointer to the collection's
    /// contiguous storage.  If no such storage exists, it is
    /// first created.  If the collection does not support an internal
    /// representation in a form of contiguous storage, `body` is not
    /// called and `nil` is returned.
    ///
    /// A `Collection` that provides its own implementation of this method
    /// must also guarantee that an equivalent buffer of its `SubSequence`
    /// can be generated by advancing the pointer by the distance to the
    /// slice's `startIndex`.
    func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<Element>) throws -> R
    ) rethrows -> R?
}

// Provides a default associated type witness for Iterator when the
// Self type is both a Sequence and an Iterator.
extension Sequence where Self: IteratorProtocol {
    // @_implements(Sequence, Iterator)
    public typealias _Default_Iterator = Self
}

/// A default makeIterator() function for `IteratorProtocol` instances that
/// are declared to conform to `Sequence`
extension Sequence where Self.Iterator == Self {
    /// Returns an iterator over the elements of this sequence.
    @inlinable
    public __consuming func makeIterator() -> Self {
        return self
    }
}


/*
 定义是定义, 对于 Protocol 的实现, 是在一个专门的 Extension 里面.
 这样代码的组织方式, 更加的合理.
 在这个 Extension 里面, 都是协议相关的实现. 人工 review 的时候, 也更加方便.
 */


@frozen
public struct DropFirstSequence<Base: Sequence> {
    internal let _base: Base
    internal let _limit: Int
    
    public init(_ base: Base, dropping limit: Int) {
        _base = base
        _limit = limit
    }
}

extension DropFirstSequence: Sequence {
    // 应该, 大量的使用 typealias
    public typealias Element = Base.Element
    public typealias Iterator = Base.Iterator
    public typealias SubSequence = AnySequence<Element>
    // 在, 迭代的一开始, 就进行了消耗.
    // 这里, 直接使用的是 Base 的 Iterator, 没有定义自己的.
    // 如果定义了自己的, 可以是, 自己的存储 base 的 It. 然后存储 count 的值, 在第一次 next 的时候, 不断调用 base 的 Iter 进行消耗.
    // 使用这种, 也不必专门写一个 dropFirst 了.
    public __consuming func makeIterator() -> Iterator {
        var it = _base.makeIterator()
        var dropped = 0
        while dropped < _limit, it.next() != nil { dropped &+= 1 }
        return it
    }
    
    //
    public __consuming func dropFirst(_ k: Int) -> DropFirstSequence<Base> {
        return DropFirstSequence(_base, dropping: _limit + k)
    }
}

public struct PrefixSequence<Base: Sequence> {
    internal var _base: Base
    internal let _maxLength: Int
    
    public init(_ base: Base, maxLength: Int) {
        _base = base
        _maxLength = maxLength
    }
}

// 专门, 写一个 Iter, 来实现特殊的 sequence 的逻辑, 是更好地设计思路.
extension PrefixSequence {
    public struct Iterator {
        internal var _base: Base.Iterator
        internal var _remaining: Int
        internal init(_ base: Base.Iterator, maxLength: Int) {
            _base = base
            _remaining = maxLength
        }
    }
}

extension PrefixSequence.Iterator: IteratorProtocol {
    // 如果, 还在自己的 remain 的范围内, 使用 base 获取值然后返回 .
    // 如果自己的 remain 没有了, 直接返回 nil
    // 这和 rxswift 的 sink 是同样的思路. 从原有序列获取数据, 自身加工, 然后交给后续节点.
    // Rxswift 的后续节点接受, 是在 on 方法的基础上. 而这里, 是 iter 保留 base iter 实现的.
    public mutating func next() -> Element? {
        if _remaining != 0 {
            _remaining &-= 1
            return _base.next()
        } else {
            return nil
        }
    }
}

// 专门在一个 Extension 里面, 实现协议.
extension PrefixSequence: Sequence {
    @inlinable
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base.makeIterator(), maxLength: _maxLength)
    }
    
    @inlinable
    public __consuming func prefix(_ maxLength: Int) -> PrefixSequence<Base> {
        let length = Swift.min(maxLength, self._maxLength)
        return PrefixSequence(_base, maxLength: length)
    }
}


// 各种, Lazy 的实现, 其实都是, 先存起来. 然后在必要的时候才进行调用.
// 而存储是需要内存的, 所以, 使用一个特定的数据类型存储.
public struct DropWhileSequence<Base: Sequence> {
    public typealias Element = Base.Element
    
    internal var _iterator: Base.Iterator
    internal var _nextElement: Element?
    
    @inlinable
    internal init(iterator: Base.Iterator, predicate: (Element) throws -> Bool) rethrows {
        _iterator = iterator
        _nextElement = _iterator.next()
        // 在生成的时候, 就进行了过滤相关的操作.
        // 其实更好地做法, 应该是定义特定的 iter. 在 iter 中进行串联.
        while let x = _nextElement, try predicate(x) {
            _nextElement = _iterator.next()
        }
    }
    
    @inlinable
    internal init(_ base: Base, predicate: (Element) throws -> Bool) rethrows {
        self = try DropWhileSequence(iterator: base.makeIterator(), predicate: predicate)
    }
}

extension DropWhileSequence {
    public struct Iterator {
        internal var _iterator: Base.Iterator
        internal var _nextElement: Element?
        internal init(_ iterator: Base.Iterator, nextElement: Element?) {
            _iterator = iterator
            _nextElement = nextElement
        }
    }
}

extension DropWhileSequence.Iterator: IteratorProtocol {
    public typealias Element = Base.Element
    // 直接, 就是使用的 Base 的 iter.
    public mutating func next() -> Element? {
        guard let next = _nextElement else { return nil }
        _nextElement = _iterator.next()
        return next
    }
}

extension DropWhileSequence: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(_iterator, nextElement: _nextElement)
    }
    
    @inlinable
    public __consuming func drop(
        while predicate: (Element) throws -> Bool
    ) rethrows -> DropWhileSequence<Base> {
        guard let x = _nextElement, try predicate(x) else { return self }
        return try DropWhileSequence(iterator: _iterator, predicate: predicate)
    }
}



// 这个 Extension, 是 Sequence 里面的核心.
// Sequence 之所以这么方便, 就是因为, 有这些预先设计好的方法.
extension Sequence {
    // 这种, ( 后直接回车换行的写法, 是 Swift 的标配.
    public func map<T>(
        _ transform: (Element) throws -> T
    ) rethrows -> [T] {
        // underestimatedCount 在这里, 起了作用. 可以帮助内存的快速扩张.
        let initialCapacity = underestimatedCount
        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)
        
        var iterator = self.makeIterator()
        
        // Add elements up to the initial capacity without checking for regrowth.
        // 从这里的实现, 可以看出, underestimatedCount 是不能瞎写的.
        // 必须是, 不能超过 sequence 的总个数.
        for _ in 0..<initialCapacity {
            result.append(try transform(iterator.next()!))
        }
        // 没有看出, 上面的 for _ in 0..<initialCapacity 作用, 调用 next 的性能是一样的. 判等影响性能???
        while let element = iterator.next() {
            result.append(try transform(element))
        }
        return Array(result)
    }
    
    @inlinable
    public __consuming func filter(
        _ isIncluded: (Element) throws -> Bool
    ) rethrows -> [Element] {
        return try _filter(isIncluded)
    }
    
    public func _filter(
        _ isIncluded: (Element) throws -> Bool
    ) rethrows -> [Element] {
        
        var result = ContiguousArray<Element>()
        var iterator = self.makeIterator()
        
        // 还是遍历, 然后在途中, 进行 filter 的判断.
        // 系统的方法, 大量的使用了 throws
        while let element = iterator.next() {
            if try isIncluded(element) {
                result.append(element)
            }
        }
        
        return Array(result)
    }
    
    // Extension 中, 可以对于 Protcol 提供默认实现. 这样可以减少实现者的负担 .
    public var underestimatedCount: Int {
        return 0
    }
    public func _customContainsEquatableElement(
        _ element: Iterator.Element
    ) -> Bool? {
        return nil
    }
    
    // 这个方法, 没有 break 的机制.
    // 但是它语义更明确, 都是全部都要进行 body 的调用.
    public func forEach(
        _ body: (Element) throws -> Void
    ) rethrows {
        for element in self {
            try body(element)
        }
    }
}

extension Sequence {
    
    public func first(
        where predicate: (Element) throws -> Bool
    ) rethrows -> Element? {
        for element in self {
            if try predicate(element) {
                return element
            }
        }
        return nil
    }
}

extension Sequence where Element: Equatable {
    /// Returns the longest possible subsequences of the sequence, in order,
    /// around elements equal to the given element.
    ///
    /// The resulting array consists of at most `maxSplits + 1` subsequences.
    /// Elements that are used to split the sequence are not returned as part of
    /// any subsequence.
    ///
    /// The following examples show the effects of the `maxSplits` and
    /// `omittingEmptySubsequences` parameters when splitting a string at each
    /// space character (" "). The first use of `split` returns each word that
    /// was originally separated by one or more spaces.
    ///
    ///     let line = "BLANCHE:   I don't want realism. I want magic!"
    ///     print(line.split(separator: " ")
    ///               .map(String.init))
    ///     // Prints "["BLANCHE:", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// The second example passes `1` for the `maxSplits` parameter, so the
    /// original string is split just once, into two new strings.
    ///
    ///     print(line.split(separator: " ", maxSplits: 1)
    ///               .map(String.init))
    ///     // Prints "["BLANCHE:", "  I don\'t want realism. I want magic!"]"
    ///
    /// The final example passes `false` for the `omittingEmptySubsequences`
    /// parameter, so the returned array contains empty strings where spaces
    /// were repeated.
    ///
    ///     print(line.split(separator: " ", omittingEmptySubsequences: false)
    ///               .map(String.init))
    ///     // Prints "["BLANCHE:", "", "", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// - Parameters:
    ///   - separator: The element that should be split upon.
    ///   - maxSplits: The maximum number of times to split the sequence, or one
    ///     less than the number of subsequences to return. If `maxSplits + 1`
    ///     subsequences are returned, the last one is a suffix of the original
    ///     sequence containing the remaining elements. `maxSplits` must be
    ///     greater than or equal to zero. The default value is `Int.max`.
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each consecutive pair of `separator`
    ///     elements in the sequence and for each instance of `separator` at the
    ///     start or end of the sequence. If `true`, only nonempty subsequences
    ///     are returned. The default value is `true`.
    /// - Returns: An array of subsequences, split from this sequence's elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public __consuming func split(
        separator: Element,
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true
    ) -> [ArraySlice<Element>] {
        return split(
            maxSplits: maxSplits,
            omittingEmptySubsequences: omittingEmptySubsequences,
            whereSeparator: { $0 == separator })
    }
}

extension Sequence {
    
    /// Returns the longest possible subsequences of the sequence, in order, that
    /// don't contain elements satisfying the given predicate. Elements that are
    /// used to split the sequence are not returned as part of any subsequence.
    ///
    /// The following examples show the effects of the `maxSplits` and
    /// `omittingEmptySubsequences` parameters when splitting a string using a
    /// closure that matches spaces. The first use of `split` returns each word
    /// that was originally separated by one or more spaces.
    ///
    ///     let line = "BLANCHE:   I don't want realism. I want magic!"
    ///     print(line.split(whereSeparator: { $0 == " " })
    ///               .map(String.init))
    ///     // Prints "["BLANCHE:", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// The second example passes `1` for the `maxSplits` parameter, so the
    /// original string is split just once, into two new strings.
    ///
    ///     print(
    ///        line.split(maxSplits: 1, whereSeparator: { $0 == " " })
    ///                       .map(String.init))
    ///     // Prints "["BLANCHE:", "  I don\'t want realism. I want magic!"]"
    ///
    /// The final example passes `true` for the `allowEmptySlices` parameter, so
    /// the returned array contains empty strings where spaces were repeated.
    ///
    ///     print(
    ///         line.split(
    ///             omittingEmptySubsequences: false,
    ///             whereSeparator: { $0 == " " }
    ///         ).map(String.init))
    ///     // Prints "["BLANCHE:", "", "", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// - Parameters:
    ///   - maxSplits: The maximum number of times to split the sequence, or one
    ///     less than the number of subsequences to return. If `maxSplits + 1`
    ///     subsequences are returned, the last one is a suffix of the original
    ///     sequence containing the remaining elements. `maxSplits` must be
    ///     greater than or equal to zero. The default value is `Int.max`.
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each pair of consecutive elements
    ///     satisfying the `isSeparator` predicate and for each element at the
    ///     start or end of the sequence satisfying the `isSeparator` predicate.
    ///     If `true`, only nonempty subsequences are returned. The default
    ///     value is `true`.
    ///   - isSeparator: A closure that returns `true` if its argument should be
    ///     used to split the sequence; otherwise, `false`.
    /// - Returns: An array of subsequences, split from this sequence's elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public __consuming func split(
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true,
        whereSeparator isSeparator: (Element) throws -> Bool
    ) rethrows -> [ArraySlice<Element>] {
        _precondition(maxSplits >= 0, "Must take zero or more splits")
        let whole = Array(self)
        return try whole.split(
            maxSplits: maxSplits,
            omittingEmptySubsequences: omittingEmptySubsequences,
            whereSeparator: isSeparator)
    }
    
    /// Returns a subsequence, up to the given maximum length, containing the
    /// final elements of the sequence.
    ///
    /// The sequence must be finite. If the maximum length exceeds the number of
    /// elements in the sequence, the result contains all the elements in the
    /// sequence.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.suffix(2))
    ///     // Prints "[4, 5]"
    ///     print(numbers.suffix(10))
    ///     // Prints "[1, 2, 3, 4, 5]"
    ///
    /// - Parameter maxLength: The maximum number of elements to return. The
    ///   value of `maxLength` must be greater than or equal to zero.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public __consuming func suffix(_ maxLength: Int) -> [Element] {
        _precondition(maxLength >= 0, "Can't take a suffix of negative length from a sequence")
        guard maxLength != 0 else { return [] }
        
        // FIXME: <rdar://problem/21885650> Create reusable RingBuffer<T>
        // Put incoming elements into a ring buffer to save space. Once all
        // elements are consumed, reorder the ring buffer into a copy and return it.
        // This saves memory for sequences particularly longer than `maxLength`.
        var ringBuffer = ContiguousArray<Element>()
        ringBuffer.reserveCapacity(Swift.min(maxLength, underestimatedCount))
        
        var i = 0
        
        for element in self {
            if ringBuffer.count < maxLength {
                ringBuffer.append(element)
            } else {
                ringBuffer[i] = element
                i = (i + 1) % maxLength
            }
        }
        
        if i != ringBuffer.startIndex {
            var rotated = ContiguousArray<Element>()
            rotated.reserveCapacity(ringBuffer.count)
            rotated += ringBuffer[i..<ringBuffer.endIndex]
            rotated += ringBuffer[0..<i]
            return Array(rotated)
        } else {
            return Array(ringBuffer)
        }
    }
    
    /// Returns a sequence containing all but the given number of initial
    /// elements.
    ///
    /// If the number of elements to drop exceeds the number of elements in
    /// the sequence, the result is an empty sequence.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.dropFirst(2))
    ///     // Prints "[3, 4, 5]"
    ///     print(numbers.dropFirst(10))
    ///     // Prints "[]"
    ///
    /// - Parameter k: The number of elements to drop from the beginning of
    ///   the sequence. `k` must be greater than or equal to zero.
    /// - Returns: A sequence starting after the specified number of
    ///   elements.
    ///
    /// - Complexity: O(1), with O(*k*) deferred to each iteration of the result,
    ///   where *k* is the number of elements to drop from the beginning of
    ///   the sequence.
    @inlinable
    public __consuming func dropFirst(_ k: Int = 1) -> DropFirstSequence<Self> {
        return DropFirstSequence(self, dropping: k)
    }
    
    /// Returns a sequence containing all but the given number of final
    /// elements.
    ///
    /// The sequence must be finite. If the number of elements to drop exceeds
    /// the number of elements in the sequence, the result is an empty
    /// sequence.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.dropLast(2))
    ///     // Prints "[1, 2, 3]"
    ///     print(numbers.dropLast(10))
    ///     // Prints "[]"
    ///
    /// - Parameter n: The number of elements to drop off the end of the
    ///   sequence. `n` must be greater than or equal to zero.
    /// - Returns: A sequence leaving off the specified number of elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public __consuming func dropLast(_ k: Int = 1) -> [Element] {
        _precondition(k >= 0, "Can't drop a negative number of elements from a sequence")
        guard k != 0 else { return Array(self) }
        
        // FIXME: <rdar://problem/21885650> Create reusable RingBuffer<T>
        // Put incoming elements from this sequence in a holding tank, a ring buffer
        // of size <= k. If more elements keep coming in, pull them out of the
        // holding tank into the result, an `Array`. This saves
        // `k` * sizeof(Element) of memory, because slices keep the entire
        // memory of an `Array` alive.
        var result = ContiguousArray<Element>()
        var ringBuffer = ContiguousArray<Element>()
        var i = ringBuffer.startIndex
        
        for element in self {
            if ringBuffer.count < k {
                ringBuffer.append(element)
            } else {
                result.append(ringBuffer[i])
                ringBuffer[i] = element
                i = (i + 1) % k
            }
        }
        return Array(result)
    }
    
    /// Returns a sequence by skipping the initial, consecutive elements that
    /// satisfy the given predicate.
    ///
    /// The following example uses the `drop(while:)` method to skip over the
    /// positive numbers at the beginning of the `numbers` array. The result
    /// begins with the first element of `numbers` that does not satisfy
    /// `predicate`.
    ///
    ///     let numbers = [3, 7, 4, -2, 9, -6, 10, 1]
    ///     let startingWithNegative = numbers.drop(while: { $0 > 0 })
    ///     // startingWithNegative == [-2, 9, -6, 10, 1]
    ///
    /// If `predicate` matches every element in the sequence, the result is an
    /// empty sequence.
    ///
    /// - Parameter predicate: A closure that takes an element of the sequence as
    ///   its argument and returns a Boolean value indicating whether the
    ///   element should be included in the result.
    /// - Returns: A sequence starting after the initial, consecutive elements
    ///   that satisfy `predicate`.
    ///
    /// - Complexity: O(*k*), where *k* is the number of elements to drop from
    ///   the beginning of the sequence.
    @inlinable
    public __consuming func drop(
        while predicate: (Element) throws -> Bool
    ) rethrows -> DropWhileSequence<Self> {
        return try DropWhileSequence(self, predicate: predicate)
    }
    
    /// Returns a sequence, up to the specified maximum length, containing the
    /// initial elements of the sequence.
    ///
    /// If the maximum length exceeds the number of elements in the sequence,
    /// the result contains all the elements in the sequence.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.prefix(2))
    ///     // Prints "[1, 2]"
    ///     print(numbers.prefix(10))
    ///     // Prints "[1, 2, 3, 4, 5]"
    ///
    /// - Parameter maxLength: The maximum number of elements to return. The
    ///   value of `maxLength` must be greater than or equal to zero.
    /// - Returns: A sequence starting at the beginning of this sequence
    ///   with at most `maxLength` elements.
    ///
    /// - Complexity: O(1)
    @inlinable
    public __consuming func prefix(_ maxLength: Int) -> PrefixSequence<Self> {
        return PrefixSequence(self, maxLength: maxLength)
    }
    
    /// Returns a sequence containing the initial, consecutive elements that
    /// satisfy the given predicate.
    ///
    /// The following example uses the `prefix(while:)` method to find the
    /// positive numbers at the beginning of the `numbers` array. Every element
    /// of `numbers` up to, but not including, the first negative value is
    /// included in the result.
    ///
    ///     let numbers = [3, 7, 4, -2, 9, -6, 10, 1]
    ///     let positivePrefix = numbers.prefix(while: { $0 > 0 })
    ///     // positivePrefix == [3, 7, 4]
    ///
    /// If `predicate` matches every element in the sequence, the resulting
    /// sequence contains every element of the sequence.
    ///
    /// - Parameter predicate: A closure that takes an element of the sequence as
    ///   its argument and returns a Boolean value indicating whether the
    ///   element should be included in the result.
    /// - Returns: A sequence of the initial, consecutive elements that
    ///   satisfy `predicate`.
    ///
    /// - Complexity: O(*k*), where *k* is the length of the result.
    @inlinable
    public __consuming func prefix(
        while predicate: (Element) throws -> Bool
    ) rethrows -> [Element] {
        var result = ContiguousArray<Element>()
        
        for element in self {
            guard try predicate(element) else {
                break
            }
            result.append(element)
        }
        return Array(result)
    }
}

extension Sequence {
    /// Copy `self` into an unsafe buffer, initializing its memory.
    ///
    /// The default implementation simply iterates over the elements of the
    /// sequence, initializing the buffer one item at a time.
    ///
    /// For sequences whose elements are stored in contiguous chunks of memory,
    /// it may be more efficient to copy them in bulk, using the
    /// `UnsafeMutablePointer.initialize(from:count:)` method.
    ///
    /// - Parameter ptr: An unsafe buffer addressing uninitialized memory. The
    ///    buffer must be of sufficient size to accommodate
    ///    `source.underestimatedCount` elements. (Some implementations trap
    ///    if given a buffer that's smaller than this.)
    ///
    /// - Returns: `(it, c)`, where `c` is the number of elements copied into the
    ///    buffer, and `it` is a partially consumed iterator that can be used to
    ///    retrieve elements that did not fit into the buffer (if any). (This can
    ///    only happen if `underestimatedCount` turned out to be an actual
    ///    underestimate, and the buffer did not contain enough space to hold the
    ///    entire sequence.)
    ///
    ///    On return, the memory region in `buffer[0 ..< c]` is initialized to
    ///    the first `c` elements in the sequence.
    @inlinable
    public __consuming func _copyContents(
        initializing buffer: UnsafeMutableBufferPointer<Element>
    ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index) {
        var it = self.makeIterator()
        guard var ptr = buffer.baseAddress else { return (it,buffer.startIndex) }
        for idx in buffer.startIndex..<buffer.count {
            guard let x = it.next() else {
                return (it, idx)
            }
            ptr.initialize(to: x)
            ptr += 1
        }
        return (it,buffer.endIndex)
    }
    
    @inlinable
    public func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<Element>) throws -> R
    ) rethrows -> R? {
        return nil
    }
}

// FIXME(ABI)#182
// Pending <rdar://problem/14011860> and <rdar://problem/14396120>,
// pass an IteratorProtocol through IteratorSequence to give it "Sequence-ness"
/// A sequence built around an iterator of type `Base`.
///
/// Useful mostly to recover the ability to use `for`...`in`,
/// given just an iterator `i`:
///
///     for x in IteratorSequence(i) { ... }
@frozen
public struct IteratorSequence<Base: IteratorProtocol> {
    @usableFromInline
    internal var _base: Base
    
    /// Creates an instance whose iterator is a copy of `base`.
    @inlinable
    public init(_ base: Base) {
        _base = base
    }
}

extension IteratorSequence: IteratorProtocol, Sequence {
    /// Advances to the next element and returns it, or `nil` if no next element
    /// exists.
    ///
    /// Once `nil` has been returned, all subsequent calls return `nil`.
    ///
    /// - Precondition: `next()` has not been applied to a copy of `self`
    ///   since the copy was made.
    @inlinable
    public mutating func next() -> Base.Element? {
        return _base.next()
    }
}

extension IteratorSequence: Sendable where Base: Sendable { }

/* FIXME: ideally for compatibility we would declare
 extension Sequence {
 @available(swift, deprecated: 5, message: "")
 public typealias SubSequence = AnySequence<Element>
 }
 */
