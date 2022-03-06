
// 这个类的出现, 是想要使用通用的接口.
// 比如, removeAll 的实现, 就可以使用 replaceRange 的功能.
// 使用一个 EmptyCollection 来做后面的参数.

public struct EmptyCollection<Element> {
    public init() {}
}

extension EmptyCollection {
    // 特殊的类型, 返回特殊的 Iterator.
    public struct Iterator {
        public init() {}
    }
}

extension EmptyCollection.Iterator: IteratorProtocol, Sequence {
    public mutating func next() -> Element? {
        return nil
    }
}

// 对于 Collection 的实现. 
extension EmptyCollection: Sequence {
    public func makeIterator() -> Iterator {
        return Iterator()
    }
}

extension EmptyCollection: RandomAccessCollection, MutableCollection {
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias SubSequence = EmptyCollection<Element>
    
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return 0
    }
    
    public func index(after i: Index) -> Index {
        _preconditionFailure("EmptyCollection can't advance indices")
    }
    
    public func index(before i: Index) -> Index {
        _preconditionFailure("EmptyCollection can't advance indices")
    }
    
    public subscript(position: Index) -> Element {
        get {
            _preconditionFailure("Index out of range")
        }
        set {
            _preconditionFailure("Index out of range")
        }
    }
    
    public subscript(bounds: Range<Index>) -> SubSequence {
        get {
            _debugPrecondition(bounds.lowerBound == 0 && bounds.upperBound == 0,
                               "Index out of range")
            return self
        }
        set {
            _debugPrecondition(bounds.lowerBound == 0 && bounds.upperBound == 0,
                               "Index out of range")
        }
    }
    
    public var count: Int {
        return 0
    }
    
    public func index(_ i: Index, offsetBy n: Int) -> Index {
        _debugPrecondition(i == startIndex && n == 0, "Index out of range")
        return i
    }
    
    public func index(
        _ i: Index, offsetBy n: Int, limitedBy limit: Index
    ) -> Index? {
        _debugPrecondition(i == startIndex && limit == startIndex,
                           "Index out of range")
        return n == 0 ? i : nil
    }
    
    public func distance(from start: Index, to end: Index) -> Int {
        _debugPrecondition(start == 0, "From must be startIndex (or endIndex)")
        _debugPrecondition(end == 0, "To must be endIndex (or startIndex)")
        return 0
    }
    
    public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
        _debugPrecondition(index == 0, "out of bounds")
        _debugPrecondition(bounds == indices, "invalid bounds for an empty collection")
    }
    
    public func _failEarlyRangeCheck(
        _ range: Range<Index>, bounds: Range<Index>
    ) {
        _debugPrecondition(range == indices, "invalid range for an empty collection")
        _debugPrecondition(bounds == indices, "invalid bounds for an empty collection")
    }
}

extension EmptyCollection: Equatable {
    public static func == (
        lhs: EmptyCollection<Element>, rhs: EmptyCollection<Element>
    ) -> Bool {
        return true
    }
}

extension EmptyCollection: Sendable { }
extension EmptyCollection.Iterator: Sendable { }
