// Comparable 里面, 使用了 Self, 所以不能当做单独的类型, 只能用作约束.
public func min<T: Comparable>(_ x: T, _ y: T) -> T {
    // 实现很简单, 使用了 < 操作符, 这是一个显示的协议, 被 Comparable 显示的声明.
    return y < x ? y : x
}

public func min<T: Comparable>(_ x: T, _ y: T, _ z: T, _ rest: T...) -> T {
    // 标准库提供这种运算, 能大大减少业务代码.
    // 虽然简单, 但是是好用的工具
    var minValue = min(min(x, y), z)
    for value in rest where value < minValue {
        minValue = value
    }
    return minValue
}

public func max<T: Comparable>(_ x: T, _ y: T) -> T {
    return y >= x ? y : x
}

public func max<T: Comparable>(_ x: T, _ y: T, _ z: T, _ rest: T...) -> T {
    var maxValue = max(max(x, y), z)
    for value in rest where value >= maxValue {
        maxValue = value
    }
    return maxValue
}

// 原始的定义, 就是存一下 base 的值
public struct EnumeratedSequence<Base: Sequence> {
    internal var _base: Base
    internal init(_base: Base) {
        self._base = _base
    }
}

// 特殊的 Iter, 就是存一下 base 的 iter, 这个用来取原始的 base 里面的值.
// 新建一个 count, 这个用来记录下 next 调用的次数
extension EnumeratedSequence {
    public struct Iterator {
        internal var _base: Base.Iterator
        internal var _count: Int
        internal init(_base: Base.Iterator) {
            self._base = _base
            self._count = 0
        }
    }
}

// 对于 next 的实现.
extension EnumeratedSequence.Iterator: IteratorProtocol, Sequence {
    public typealias Element = (offset: Int, element: Base.Element)
    public mutating func next() -> Element? {
        guard let b = _base.next() else { return nil }
        let result = (offset: _count, element: b)
        _count += 1
        return result
    }
}

// 对于 Sequence 的实现/
extension EnumeratedSequence: Sequence {
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base: _base.makeIterator())
    }
}
