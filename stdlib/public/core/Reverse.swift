
// Reverse 更多的是一种概念上的封装. 是一组操作的集合.
// 这些操作有一个基本的前提, 就是 Base Collection, 一定是 BidirectionalCollection. 一定是可以从后向前进行遍历的.
// 只有这样, 才能进行 reverse. 如果, 每次都要遍历一次, 才能拿到后面的位置, 是无法完成翻转这个概念, 要求的各种操作的.

extension MutableCollection where Self: BidirectionalCollection {
    // 原地算法, 进行翻转.
    // 基本的算法, 其实就是数组的翻转.
    // 这里, 使用的是 Collection 的 Primitive case,
    // 可以直接通过 Index 进行 get, set,
    // 可以 FormIndex, after, before
    // 通过这三层抽象 case, 将 reverse 这个行为变得通用, 不在绑定到一个具体的类型上.
    
    public mutating func reverse() {
        if isEmpty { return }
        var f = startIndex
        var l = index(before: endIndex)
        while f < l {
            swapAt(f, l)
            formIndex(after: &f)
            formIndex(before: &l)
        }
    }
}

// 初始化工作, 专门写在一个 scope 里面.
@frozen
public struct ReversedCollection<Base: BidirectionalCollection> {
    public let _base: Base
    @inlinable
    internal init(_base: Base) {
        self._base = _base
    }
}

// Embed Itertor, 专门写在一个 Scope 里面.
extension ReversedCollection {
    @frozen
    public struct Iterator {
        @usableFromInline
        internal let _base: Base
        @usableFromInline
        internal var _position: Base.Index
        
        @inlinable
        @inline(__always)
        public /// @testable
        init(_base: Base) {
            self._base = _base
            self._position = _base.endIndex
        }
    }
}

// Emben Iterator 的实现, 专门写在一个 Scope 里面.
extension ReversedCollection.Iterator: IteratorProtocol, Sequence {
    public typealias Element = Base.Element
    
    @inlinable
    @inline(__always)
    public mutating func next() -> Element? {
        _base.formIndex(before: &_position)
        return _base[_position]
    }
}

// Iteraotr 的实现, 专门写在一个 Scope 里面.
extension ReversedCollection: Sequence {
    public typealias Element = Base.Element
    @inlinable
    @inline(__always)
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base: _base)
    }
}

// ReversedCollection 的 index 的实现, 可以发现和 ReversedCollection 一样, 一个 Box
extension ReversedCollection {
    @frozen
    public struct Index {
        public let base: Base.Index
        @inlinable
        public init(_ base: Base.Index) {
            self.base = base
        }
    }
}

extension ReversedCollection.Index: Comparable {
    @inlinable
    public static func == (
        lhs: ReversedCollection<Base>.Index,
        rhs: ReversedCollection<Base>.Index
    ) -> Bool {
        // Note ReversedIndex has inverted logic compared to base Base.Index
        return lhs.base == rhs.base
    }
    
    @inlinable
    public static func < (
        lhs: ReversedCollection<Base>.Index,
        rhs: ReversedCollection<Base>.Index
    ) -> Bool {
        // Note ReversedIndex has inverted logic compared to base Base.Index
        return lhs.base > rhs.base
    }
}

extension ReversedCollection.Index: Hashable where Base.Index: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

// 这里的实现, 和 ReverseIterator 的实现思路是一样的.
// 所有的操作, 都在抽象的基础上, 将相关的操作进行翻转. 
extension ReversedCollection: BidirectionalCollection {  
    @inlinable
    public var startIndex: Index {
        return Index(_base.endIndex)
    }
    
    @inlinable
    public var endIndex: Index {
        return Index(_base.startIndex)
    }
    
    @inlinable
    public func index(after i: Index) -> Index {
        return Index(_base.index(before: i.base))
    }
    
    @inlinable
    public func index(before i: Index) -> Index {
        return Index(_base.index(after: i.base))
    }
    
    @inlinable
    public func index(_ i: Index, offsetBy n: Int) -> Index {
        // FIXME: swift-3-indexing-model: `-n` can trap on Int.min.
        return Index(_base.index(i.base, offsetBy: -n))
    }
    
    @inlinable
    public func index(
        _ i: Index, offsetBy n: Int, limitedBy limit: Index
    ) -> Index? {
        // FIXME: swift-3-indexing-model: `-n` can trap on Int.min.
        return _base.index(i.base, offsetBy: -n, limitedBy: limit.base)
            .map(Index.init)
    }
    
    @inlinable
    public func distance(from start: Index, to end: Index) -> Int {
        return _base.distance(from: end.base, to: start.base)
    }
    
    @inlinable
    public subscript(position: Index) -> Element {
        return _base[_base.index(before: position.base)]
    }
}

/*
 the fundamental difference between random-access and bidirectional collections is that operations that depend on index movement or distance measurement offer significantly improved efficiency
 因为, random 需要实现的方法, 其实已经在 bidirection 里面声明了, 所以, 这个协议就像是 error 一样, 仅仅是一个类型的标识, 并不需要增加新的方法的要求.
 不过, 如果声明了一个类, 是 RandomAccessCollection, 那么类的设计者就需要实现高效率的 index 计算的操作. 这是类的设计者的责任.
 */
extension ReversedCollection: RandomAccessCollection where Base: RandomAccessCollection { }

extension ReversedCollection {
    @inlinable
    @available(swift, introduced: 4.2)
    public __consuming func reversed() -> Base {
        return _base
    }
}

// 这个方法, 不会遍历原始集合.
// 一个简单的方法, 返回一个特殊的数据类型, 来满足这个方法的效果.
extension BidirectionalCollection {
    @inlinable
    public __consuming func reversed() -> ReversedCollection<Self> {
        return ReversedCollection(_base: self)
    }
}
