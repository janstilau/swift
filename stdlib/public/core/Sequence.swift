
// IteratorProtocol 是一个带有 associateType 的类型. 所以, 他不能单独当做类型来使用
// AnyIterator是一个泛型类型, 在使用的时候, 就固定了 Element 的类型.
public protocol IteratorProtocol {
    associatedtype Element
    mutating func next() -> Element?
}
/// A sequence should provide its iterator in O(1). The `Sequence` protocol
/// makes no other requirements about element access, so routines that
/// traverse a sequence should be considered O(*n*) unless documented
/// otherwise.
public protocol Sequence {
    associatedtype Element
    
    /// A type that provides the sequence's iteration interface and
    /// encapsulates its iteration state.
    // 这里说的很明白了, 迭代器, 应该保持自己的迭代的状态.
    associatedtype Iterator: IteratorProtocol where Iterator.Element == Element
    
    __consuming func makeIterator() -> Iterator
    
    // Extension 里面的是, 定制方法, 而 Protocol 里面的是, primitive 方法.
    // 没有提供实现的 protocol 里面的方法, 叫做限制.
    // 提供了默认实现的 protocol 里面的方法, 叫做定制点.
    // 定制点, 是为了 extension 里面的方法服务的. 单独一个定制点是没有作用的. 就如同 optinal delegate 一样, 没有实现, extension 里面有着默认的路线. 而实现了, 那么就可以改变已有的代码逻辑, 实现绑定.
    var underestimatedCount: Int { get }
    
    // 定制点. 提供高效的判断 contains 的操作. _表明, 这个定制点应该是私有的. 也就是, 应该是熟悉 sequence 实现者来定制这个方法.
    // 一般来说, 是这个类库的同一批维护者, 做这个事情.
    func _customContainsEquatableElement(
        _ element: Element
    ) -> Bool?
    
    // sequence 这个概念, 很像数组. 其实数组是更加具体的类型. 但是数组是最常用的, 和存储息息相关的数据结构, 所以提供了一个
    __consuming func _copyToContiguousArray() -> ContiguousArray<Element>
    
    // 将 sequence 里面的数据, 存储到 ptr 指定的空间. 这是一个有着 C 风格的扩展.
    __consuming func _copyContents(
        initializing ptr: UnsafeMutableBufferPointer<Element>
    ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index)
    
    // 在 Swfit 里面, with 开头的方法, 都是将自己的数据进行转化, 操作, 然后将操作完的数据, 传到闭包里面.
    // 一般方法的返回值, 是闭包的返回值确定的.
    func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<Element>) throws -> R
    ) rethrows -> R?
}

extension Sequence where Self: IteratorProtocol {
    // @_implements(Sequence, Iterator)
    public typealias _Default_Iterator = Self
}

extension Sequence where Self.Iterator == Self {
    /// Returns an iterator over the elements of this sequence.
    @inlinable
    public __consuming func makeIterator() -> Self {
        return self
    }
}

// 一个特殊的数据结构, 主要就是为了完成, drop 这个函数所提供的语义.
// 在 Swfit 里面, 大量使用了简单的存储, 这个存储, 是为了延后执行具体的操作, 也就是 lazy 的含义.
@frozen
public struct DropFirstSequence<Base: Sequence> {
    internal let _base: Base
    internal let _limit: Int
    public init(_ base: Base, dropping limit: Int) {
        _base = base
        _limit = limit
    }
}

// Drop 是如何实现对于 base sequence 的序列概念的保持的.
extension DropFirstSequence: Sequence {
    public typealias Element = Base.Element
    public typealias Iterator = Base.Iterator
    public typealias SubSequence = AnySequence<Element>
    
    // lazy 的实现. 就是在真正的进行遍历的时候, 才会消耗前面的几个数据.
    public __consuming func makeIterator() -> Iterator {
        var it = _base.makeIterator()
        var dropped = 0
        while dropped < _limit, it.next() != nil { dropped &+= 1 }
        return it
    }
    
    // 因为, drop 的设计意图一部分就是 lazy 计算, 所以, 在这个对象上, 继续 drop 是一件很高效的事情, 仅仅是存储值的变化.
    public __consuming func dropFirst(_ k: Int) -> DropFirstSequence<Base> {
        return DropFirstSequence(_base, dropping: _limit + k)
    }
}

// prefix, 里面记录的是 count, 而不是 Sequence 的位置.
// 记录 Count, 后面 drop, prefix 怎么操作, 都没有关系. count 是一个自己的属性, 和包装的 Seq 无关
public struct PrefixSequence<Base: Sequence> {
    internal var _base: Base
    internal let _maxLength: Int
    @inlinable
    public init(_ base: Base, maxLength: Int) {
        _base = base
        _maxLength = maxLength
    }
}

extension PrefixSequence {
    // 每一个特殊的 Sequence, 都有自己的 Iterator.
    public struct Iterator {
        internal var _base: Base.Iterator
        internal var _remaining: Int
        internal init(_ base: Base.Iterator, maxLength: Int) {
            _base = base
            _remaining = maxLength
        }
    }
}

// 特殊的 Iterator 对于 protocol 的实现, 在自己的 scope 里面/
extension PrefixSequence.Iterator: IteratorProtocol {
    public typealias Element = Base.Element
    public mutating func next() -> Element? {
        if _remaining != 0 {
            _remaining &-= 1
            return _base.next()
        } else {
            return nil
        }
    }
}

// PrefixSequence 这个特殊的数据类型, 对于 sequence 的实现.
// 这些类型, 都是泛型的.
// 这些泛型类型里面, 几个成员变量, 用来存储业务值, pre, drop 的个数等等, 还要一个 protocol container, 用来存储这个协议对象.
// 能够当做具体类型使用的, 一定是泛型. 协议, 只能当做约束来使用.
// 所以, 不会出现这样的函数 foreach (base: Sequence, block: (T)->Void)
// 这里, Sequence 直接当做类型使用了
// 只会出现
// foreach<T:Sequence>(base: T, block:(T.Element)->Void)
/*
 
 可以编译, Sequence 用来修饰 Base, 后面闭包, 直接使用了 Base 的关联类型
 func foreach<Base: Sequence>(base: Base, block: (Base.Element)->Void) {
     for ele in base {
         block(ele)
     }
 }
 
 // 通不过编译, 因为实际上, 自己写的时候, 就觉得不对, block 到底怎么使用到 Sequence 的关联类型呢.
 // Sequence 这里不是一个具体的类型, 仅仅是一个修饰, 怎么让 Block 里面的 Element 和 base 的 Sequence 关系上呢
 //func foreach(base: Sequence, block: ()->Void) {
 //
 //}
 */

extension PrefixSequence: Sequence {
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base.makeIterator(), maxLength: _maxLength)
    }
    public __consuming func prefix(_ maxLength: Int) -> PrefixSequence<Base> {
        let length = Swift.min(maxLength, self._maxLength)
        return PrefixSequence(_base, maxLength: length)
    }
}


// 存储一个 Block, 直到整个 Block 的返回值为 false, 之前的元素都越过
public struct DropWhileSequence<Base: Sequence> {
    public typealias Element = Base.Element
    
    internal var _iterator: Base.Iterator
    internal var _nextElement: Element?
    
    // 这里, 为什么不在第一次,
    internal init(iterator: Base.Iterator, predicate: (Element) throws -> Bool) rethrows {
        _iterator = iterator
        _nextElement = _iterator.next()
        while let x = _nextElement, try predicate(x) {
            _nextElement = _iterator.next()
        }
    }
    
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

// 模板方法, 使用 primitive method 写出的通用算法.
extension Sequence {
    public func map<T>(
        _ transform: (Element) throws -> T
    ) rethrows -> [T] {
        // underestimatedCount 有默认实现, 就是返回 0.
        // 这是一个扩展点, 可以帮助 extension 的 template 方法提高性能.
        let initialCapacity = underestimatedCount
        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)
        
        var iterator = self.makeIterator()
        
        // 这里, 不经过 optinal 的判断, 能够快一点点
        // 这也提出了要求, 就是 underestimatedCount 的值, 一定不能超过 sequence 的长度.
        for _ in 0..<initialCapacity {
            result.append(try transform(iterator.next()!))
        }
        // Add remaining elements, if any.
        while let element = iterator.next() {
            result.append(try transform(element))
        }
        return Array(result)
    }
    
    public __consuming func filter(
        _ isIncluded: (Element) throws -> Bool
    ) rethrows -> [Element] {
        return try _filter(isIncluded)
    }
    
    // 实现很简单, 和自己写的代码, 没有太多的区别.
    public func _filter(
        _ isIncluded: (Element) throws -> Bool
    ) rethrows -> [Element] {
        var result = ContiguousArray<Element>()
        var iterator = self.makeIterator()
        while let element = iterator.next() {
            if try isIncluded(element) {
                result.append(element)
            }
        }
        return Array(result)
    }
    
    // 扩展点, 提供默认实现, 默认实现一定可以保证 template 里面, 不会出错.
    public var underestimatedCount: Int {
        return 0
    }
    
    // 扩展点, 提供默认实现, 默认实现一定可以保证 template 里面, 不会出错.
    public func _customContainsEquatableElement(
        _ element: Iterator.Element
    ) -> Bool? {
        return nil
    }
    
    // 这个方法, 其实用的不多. 因为它没有办法提前退出.
    // 所以, 用的时候, 带有强有力的暗示, 所有的 element 都有机会进行调用.
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
    /// Copies `self` into the supplied buffer.
    ///
    /// - Precondition: The memory in `self` is uninitialized. The buffer must
    ///   contain sufficient uninitialized memory to accommodate `source.underestimatedCount`.
    ///
    /// - Postcondition: The `Pointee`s at `buffer[startIndex..<returned index]` are
    ///   initialized.
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

/* FIXME: ideally for compatability we would declare
 extension Sequence {
 @available(swift, deprecated: 5, message: "")
 public typealias SubSequence = AnySequence<Element>
 }
 */
