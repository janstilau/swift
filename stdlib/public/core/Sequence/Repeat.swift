// 这个类型, 最大的作用, 还是作为一个 Collection 来进行使用.
// 也就是, 充当一个抽象数据类型.

public struct Repeated<Element> {
    public let count: Int
    public let repeatedValue: Element
}

extension Repeated: RandomAccessCollection {
    public typealias Indices = Range<Int>
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
        
    // 该做的范围 Check 还是应该做, 这个方法, 返回固定的 repeatedValue 的值.
    public subscript(position: Int) -> Element {
        _precondition(position >= 0 && position < count, "Index out of range")
        return repeatedValue
    }
}


public func repeatElement<T>(_ element: T, count n: Int) -> Repeated<T> {
    return Repeated(_repeating: element, count: n)
}

extension Repeated: Sendable where Element: Sendable { }
