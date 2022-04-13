// 这个类型, 最大的作用, 还是作为一个 Collection 来进行使用.
/*
 面向抽象编程, 使用抽象接口, 可以写出稳定的算法来. 这种实现, 更加具有扩展性.
 但是为了满足各种抽象, 其实是需要大量的类型, 去满足抽象出的接口的.
 这个类型的出现, 其实主要是为了适配 Collection. 
*/

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

// 一个快捷的, 进行 Repeated 生成的类方法.
public func repeatElement<T>(_ element: T, count n: Int) -> Repeated<T> {
    return Repeated(_repeating: element, count: n)
}

extension Repeated: Sendable where Element: Sendable { }
