
// 定义, 就是存储 base, 以及进行判断的闭包而已.
public struct LazyDropWhileSequence<Base: Sequence> {
    public typealias Element = Base.Element
    internal init(_base: Base, predicate: @escaping (Element) -> Bool) {
        self._base = _base
        self._predicate = predicate
    }
    
    internal var _base: Base
    internal let _predicate: (Element) -> Bool
}

extension LazyDropWhileSequence {
    public struct Iterator {
        public typealias Element = Base.Element
        internal init(_base: Base.Iterator, predicate: @escaping (Element) -> Bool) {
            self._base = _base
            self._predicate = predicate
        }
        
        // _predicateHasFailed 这个标志位, 代表着当前的 predicate 是否已经是失去效力了.
        // 也就是说, 可以真正的返回值了.
        internal var _predicateHasFailed = false
        internal var _base: Base.Iterator
        internal let _predicate: (Element) -> Bool
    }
}

extension LazyDropWhileSequence.Iterator: IteratorProtocol {
    public mutating func next() -> Element? {
        // 如果, predicate 失败过一次了, 就是可以正常的取 base 里面的值了.
        if _predicateHasFailed {
            return _base.next()
        }
        
        // 通过 base 取值的时候, 首先会有一次前面的数据的过滤操作.
        // 知道, predicate 认为, 达到了条件位置, 之前的数据都会舍弃.
        // 之后的获取ele, 从 base 拿回的数据, 就不在走过滤了.
        while let nextElement = _base.next() {
            if !_predicate(nextElement) {
                _predicateHasFailed = true
                return nextElement
            }
        }
        return nil
    }
}

extension LazyDropWhileSequence: Sequence {
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base: _base.makeIterator(), predicate: _predicate)
    }
}

extension LazyDropWhileSequence: LazySequenceProtocol {
    public typealias Elements = LazyDropWhileSequence
}

// 一个特殊的方法, 返回 LazyDropWhileSequence 来体现 dropWhile 这个业务.
extension LazySequenceProtocol {
    public __consuming func drop(
        while predicate: @escaping (Elements.Element) -> Bool
    ) -> LazyDropWhileSequence<Self.Elements> {
        return LazyDropWhileSequence(_base: self.elements, predicate: predicate)
    }
}

/// A lazy wrapper that includes the elements of an underlying
/// collection after any initial consecutive elements that satisfy a
/// predicate.
///
/// - Note: The performance of accessing `startIndex`, `first`, or any methods
///   that depend on `startIndex` depends on how many elements satisfy the
///   predicate at the start of the collection, and may not offer the usual
///   performance given by the `Collection` protocol. Be aware, therefore,
///   that general operations on lazy collections may not have the
///   documented complexity.
public typealias LazyDropWhileCollection<T: Collection> = LazyDropWhileSequence<T>

extension LazyDropWhileCollection: Collection {
    public typealias SubSequence = Slice<LazyDropWhileCollection<Base>>
    public typealias Index = Base.Index
    
    @inlinable // lazy-performance
    public var startIndex: Index {
        var index = _base.startIndex
        while index != _base.endIndex && _predicate(_base[index]) {
            _base.formIndex(after: &index)
        }
        return index
    }
    
    @inlinable // lazy-performance
    public var endIndex: Index {
        return _base.endIndex
    }
    
    @inlinable // lazy-performance
    public func index(after i: Index) -> Index {
        _precondition(i < _base.endIndex, "Can't advance past endIndex")
        return _base.index(after: i)
    }
    
    @inlinable // lazy-performance
    public subscript(position: Index) -> Element {
        return _base[position]
    }
}

extension LazyDropWhileCollection: BidirectionalCollection 
where Base: BidirectionalCollection {
    @inlinable // lazy-performance
    public func index(before i: Index) -> Index {
        _precondition(i > startIndex, "Can't move before startIndex")
        return _base.index(before: i)
    }
}

extension LazyDropWhileCollection: LazyCollectionProtocol { }
