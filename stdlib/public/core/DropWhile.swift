// A sequence whose elements consist of the elements that follow the initial
// consecutive elements of some base sequence that satisfy a given predicate.
/*
 A sequence whose elements consist of the elements that follow the initial consecutive elements of some base sequence that satisfy a given predicate.
 */
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
    /// An iterator over the elements traversed by a base iterator that follow the
    /// initial consecutive elements that satisfy a given predicate.
    ///
    /// This is the associated iterator for the `LazyDropWhileSequence`,
    /// `LazyDropWhileCollection`, and `LazyDropWhileBidirectionalCollection`
    /// types.
    public struct Iterator {
        public typealias Element = Base.Element
        
        internal init(_base: Base.Iterator, predicate: @escaping (Element) -> Bool) {
            self._base = _base
            self._predicate = predicate
        }
        
        internal var _predicateHasFailed = false
        internal var _base: Base.Iterator
        internal let _predicate: (Element) -> Bool
    }
}

extension LazyDropWhileSequence.Iterator: IteratorProtocol {
    
    public mutating func next() -> Element? {
        // 只要 predicate 失败过一次, 之后就一直使用原来的 sequence 的 next 值.
        if _predicateHasFailed {
            return _base.next()
        }
        
        // 过滤, 原来的 sequence 的元素, 只要符合过滤的条件, 就一直过滤, 直到原来的 sequence 失效
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
    /// Returns an iterator over the elements of this sequence.
    ///
    /// - Complexity: O(1).
    @inlinable // lazy-performance
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base: _base.makeIterator(), predicate: _predicate)
    }
}

extension LazyDropWhileSequence: LazySequenceProtocol {
    public typealias Elements = LazyDropWhileSequence
}

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
