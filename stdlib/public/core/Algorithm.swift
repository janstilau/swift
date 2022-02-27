/*
 和 C++ 不同, 这里, 必须是使用 Comparable 的协议, 才能使用 min 这方法.
 显示的进行协议的指定.
 隐式的进行协议的指定.
 */

public func min<T: Comparable>(_ x: T, _ y: T) -> T {
    return y < x ? y : x
}

public func min<T: Comparable>(_ x: T, _ y: T, _ z: T, _ rest: T...) -> T {
    var minValue = min(min(x, y), z)
    for value in rest where value < minValue {
        minValue = value
    }
    return minValue
}

/// Returns the greater of two comparable values.
///
/// - Parameters:
///   - x: A value to compare.
///   - y: Another value to compare.
/// - Returns: The greater of `x` and `y`. If `x` is equal to `y`, returns `y`.
@inlinable // protocol-only
public func max<T: Comparable>(_ x: T, _ y: T) -> T {
    // In case `x == y`, we pick `y`. See min(_:_:).
    return y >= x ? y : x
}

/// Returns the greatest argument passed.
///
/// - Parameters:
///   - x: A value to compare.
///   - y: Another value to compare.
///   - z: A third value to compare.
///   - rest: Zero or more additional values.
/// - Returns: The greatest of all the arguments. If there are multiple equal
///   greatest arguments, the result is the last one.
@inlinable // protocol-only
public func max<T: Comparable>(_ x: T, _ y: T, _ z: T, _ rest: T...) -> T {
    var maxValue = max(max(x, y), z)
    // In case `value == maxValue`, we pick `value`. See min(_:_:).
    for value in rest where value >= maxValue {
        maxValue = value
    }
    return maxValue
}

/*
 相比, Index 之前是需要人工进行控制, Enumerate 是将 Index 的加减内置到了算法里面.
 */
// 非常差的代码的安放位置, 为什么这个类的定义在这里.
public struct EnumeratedSequence<Base: Sequence> {
    internal var _base: Base
    internal init(_base: Base) {
        self._base = _base
    }
}

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

extension EnumeratedSequence.Iterator: IteratorProtocol, Sequence {
    // 在这里, 进行了 count 的修改
    public typealias Element = (offset: Int, element: Base.Element)
    public mutating func next() -> Element? {
        guard let b = _base.next() else { return nil }
        let result = (offset: _count, element: b)
        _count += 1
        return result
    }
}

extension EnumeratedSequence: Sequence {
    // 在这里面, 直接使用 Iterator, 这就是在类内进行 typedef 的好处.
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base: _base.makeIterator())
    }
}
