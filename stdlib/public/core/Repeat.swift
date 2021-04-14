// 里面, 所有的都是 let. 这个类, 是为了完成某种抽象的任务, 而不是存值, 之后修改的.
public struct Repeated<Element> {
    /// The number of elements in this collection.
    public let count: Int
    
    /// The value of every element in this collection.
    public let repeatedValue: Element
}


// Repeated 对于 Collection 协议的适配.
// start, end, [get], indices, indexAfter.
extension Repeated: RandomAccessCollection {
    public typealias Indices = Range<Int>
    
    // Collection, 应该直接从 Index 取值. 而对于, Repeated 来说, 他没有复杂的结果, 无论什么 Index, 都返回同样的 element.
    public typealias Index = Int
    
    internal init(_repeating repeatedValue: Element, count: Int) {
        self.count = count
        self.repeatedValue = repeatedValue
    }
    
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return count
    }
    
    public subscript(position: Int) -> Element {
        return repeatedValue
    }
}

public func repeatElement<T>(_ element: T, count n: Int) -> Repeated<T> {
    return Repeated(_repeating: element, count: n)
}
