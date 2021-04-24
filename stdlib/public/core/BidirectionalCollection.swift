/// To add `BidirectionalProtocol` conformance to your custom types, implement
/// the `index(before:)` method in addition to the requirements of the
/// `Collection` protocol.
///
// 双向集合, 就是提供了向前遍历的能力.
public protocol BidirectionalCollection: Collection
where SubSequence: BidirectionalCollection, Indices: BidirectionalCollection {
    override associatedtype Element
    override associatedtype Index
    override associatedtype SubSequence
    override associatedtype Indices
    
    // 核心方法, 就是提供 Index 向前寻找的能力
    func index(before i: Index) -> Index
    func formIndex(before i: inout Index)
    override func index(after i: Index) -> Index
    override func formIndex(after i: inout Index)
    // 在 Bidirection 里面, offset 可以是负数了
    @_nonoverride func index(_ i: Index, offsetBy distance: Int) -> Index
    @_nonoverride func index(
        _ i: Index, offsetBy distance: Int, limitedBy limit: Index
    ) -> Index?
    
    // 在 Bidirection 里面, start, end 的前后关系可以改变了
    @_nonoverride func distance(from start: Index, to end: Index) -> Int
    override var indices: Indices { get }
    override subscript(bounds: Range<Index>) -> SubSequence { get }
    override subscript(position: Index) -> Element { get }
    override var startIndex: Index { get }
    override var endIndex: Index { get }
}

extension BidirectionalCollection {
    
    // 扩展点默认实现.
    public func formIndex(before i: inout Index) {
        i = index(before: i)
    }
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        return _index(i, offsetBy: distance)
    }
    // 根据 distance 的正负, 可以调用不同的实现了
    internal func _index(_ i: Index, offsetBy distance: Int) -> Index {
        if distance >= 0 {
            return _advanceForward(i, by: distance)
        }
        // 不断地调用 formIndex, 因为不是 random
        var i = i
        for _ in stride(from: 0, to: distance, by: -1) {
            formIndex(before: &i)
        }
        return i
    }
    
    @inlinable // protocol-only
    public func index(
        _ i: Index, offsetBy distance: Int, limitedBy limit: Index
    ) -> Index? {
        return _index(i, offsetBy: distance, limitedBy: limit)
    }
    
    @inlinable // protocol-only
    internal func _index(
        _ i: Index, offsetBy distance: Int, limitedBy limit: Index
    ) -> Index? {
        if distance >= 0 {
            return _advanceForward(i, by: distance, limitedBy: limit)
        }
        var i = i
        for _ in stride(from: 0, to: distance, by: -1) {
            if i == limit {
                return nil
            }
            formIndex(before: &i)
        }
        return i
    }
    
    @inlinable // protocol-only
    public func distance(from start: Index, to end: Index) -> Int {
        return _distance(from: start, to: end)
    }
    
    // 遍历得到 distance, 不是 random
    internal func _distance(from start: Index, to end: Index) -> Int {
        var start = start
        var count = 0
        
        if start < end {
            while start != end {
                count += 1
                formIndex(after: &start)
            }
        }
        else if start > end {
            while start != end {
                count -= 1
                formIndex(before: &start)
            }
        }
        
        return count
    }
}

// 当, SubSequence 和自身的类型一样的时候, 可以进行原地需改, 而不是返回一个新的值.
extension BidirectionalCollection where SubSequence == Self {
    public mutating func popLast() -> Element? {
        guard !isEmpty else { return nil }
        let element = last!
        self = self[startIndex..<index(before: endIndex)]
        return element
    }
    
    public mutating func removeLast() -> Element {
        let element = last!
        self = self[startIndex..<index(before: endIndex)]
        return element
    }
    
    public mutating func removeLast(_ k: Int) {
        if k == 0 { return }
        self = self[startIndex..<index(endIndex, offsetBy: -k)]
    }
}

// 返回一个新的值, 这是时候, 就不要求 subSequence 和 self 是一个类型了
extension BidirectionalCollection {
    // 集合只是返回 SubSequence, 可能里面会有 Index 的计算, 但是没有复制的操作的.
    public __consuming func dropLast(_ k: Int) -> SubSequence {
        let end = index(
            endIndex,
            offsetBy: -k,
            limitedBy: startIndex) ?? startIndex
        // 还是利用集合的 subscript 操作.
        return self[startIndex..<end]
    }
    
    public __consuming func suffix(_ maxLength: Int) -> SubSequence {
        let start = index(
            endIndex,
            offsetBy: -maxLength,
            limitedBy: startIndex) ?? startIndex
        return self[start..<endIndex]
    }
}

