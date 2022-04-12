/*
 Strideable 可以比较, 可以快速的算出来, 两个值之间的差距
 例如, String 是可以比较的, 但是并不能知道, 两个字符串中间, 有多少值
 */
public protocol Strideable: Comparable {
    associatedtype Stride: SignedNumeric, Comparable
    
    // 快速算出, 两个 Stride 之间的差距.
    func distance(to other: Self) -> Stride
    
    // 快速算出, 多少之后的 Stride 的值.
    func advanced(by n: Stride) -> Self
    
    /// Returns the next result of striding by a specified distance.
    ///
    /// This method is an implementation detail of `Strideable`; do not call it
    /// directly.
    ///
    /// While striding, `_step(after:from:by:)` is called at each step to
    /// determine the next result. At the first step, the value of `current` is
    /// `(index: 0, value: start)`. At each subsequent step, the value of
    /// `current` is the result returned by this method in the immediately
    /// preceding step.
    ///
    /// If the result of advancing by a given `distance` is not representable as a
    /// value of this type, then a runtime error may occur.
    ///
    /// Implementing `_step(after:from:by:)` to Customize Striding Behavior
    /// ===================================================================
    ///
    /// The default implementation of this method calls `advanced(by:)` to offset
    /// `current.value` by a specified `distance`. No attempt is made to count the
    /// number of prior steps, and the result's `index` is always `nil`.
    ///
    /// To avoid incurring runtime errors that arise from advancing past
    /// representable bounds, a conforming type can signal that the result of
    /// advancing by a given `distance` is not representable by using `Int.min` as
    /// a sentinel value for the result's `index`. In that case, the result's
    /// `value` must be either the minimum representable value of this type if
    /// `distance` is less than zero or the maximum representable value of this
    /// type otherwise. Fixed-width integer types make use of arithmetic
    /// operations reporting overflow to implement this customization.
    ///
    /// A conforming type may use any positive value for the result's `index` as
    /// an opaque state that is private to that type. For example, floating-point
    /// types increment `index` with each step so that the corresponding `value`
    /// can be computed by multiplying the number of steps by the specified
    /// `distance`. Serially calling `advanced(by:)` would accumulate
    /// floating-point rounding error at each step, which is avoided by this
    /// customization.
    ///
    /// - Parameters:
    ///   - current: The result returned by this method in the immediately
    ///     preceding step while striding, or `(index: 0, value: start)` if there
    ///     have been no preceding steps.
    ///   - start: The starting value used for the striding sequence.
    ///   - distance: The amount to step by with each iteration of the striding
    ///     sequence.
    /// - Returns: A tuple of `index` and `value`; `index` may be `nil`, any
    ///   positive value as an opaque state private to the conforming type, or
    ///   `Int.min` to signal that the notional result of advancing by `distance`
    ///   is unrepresentable, and `value` is the next result after `current.value`
    ///   while striding from `start` by `distance`.
    ///
    /// - Complexity: O(1)
    static func _step(
        after current: (index: Int?, value: Self),
        from start: Self, by distance: Self.Stride
    ) -> (index: Int?, value: Self)
}

extension Strideable {
    public static func < (x: Self, y: Self) -> Bool {
        return x.distance(to: y) > 0
    }
    
    public static func == (x: Self, y: Self) -> Bool {
        return x.distance(to: y) == 0
    }
}

extension Strideable {
    @inlinable // protocol-only
    public static func _step(
        after current: (index: Int?, value: Self),
        from start: Self, by distance: Self.Stride
    ) -> (index: Int?, value: Self) {
        return (nil, current.value.advanced(by: distance))
    }
}

extension Strideable where Self: FixedWidthInteger & SignedInteger {
    public static func _step(
        after current: (index: Int?, value: Self),
        from start: Self, by distance: Self.Stride
    ) -> (index: Int?, value: Self) {
        let value = current.value
        let (partialValue, overflow) =
        Self.bitWidth >= Self.Stride.bitWidth ||
        (value < (0 as Self)) == (distance < (0 as Self.Stride))
        ? value.addingReportingOverflow(Self(distance))
        : (Self(Self.Stride(value) + distance), false)
        return overflow
        ? (.min, distance < (0 as Self.Stride) ? .min : .max)
        : (nil, partialValue)
    }
}

extension Strideable where Self: FixedWidthInteger & UnsignedInteger {
    @_alwaysEmitIntoClient
    public static func _step(
        after current: (index: Int?, value: Self),
        from start: Self, by distance: Self.Stride
    ) -> (index: Int?, value: Self) {
        let (partialValue, overflow) = distance < (0 as Self.Stride)
        ? current.value.subtractingReportingOverflow(Self(-distance))
        : current.value.addingReportingOverflow(Self(distance))
        return overflow
        ? (.min, distance < (0 as Self.Stride) ? .min : .max)
        : (nil, partialValue)
    }
}

extension Strideable where Stride: FloatingPoint {
    @inlinable // protocol-only
    public static func _step(
        after current: (index: Int?, value: Self),
        from start: Self, by distance: Self.Stride
    ) -> (index: Int?, value: Self) {
        if let i = current.index {
            // When Stride is a floating-point type, we should avoid accumulating
            // rounding error from repeated addition.
            return (i + 1, start.advanced(by: Stride(i + 1) * distance))
        }
        return (nil, current.value.advanced(by: distance))
    }
}

extension Strideable where Self: FloatingPoint, Self == Stride {
    @inlinable // protocol-only
    public static func _step(
        after current: (index: Int?, value: Self),
        from start: Self, by distance: Self.Stride
    ) -> (index: Int?, value: Self) {
        if let i = current.index {
            // When both Self and Stride are the same floating-point type, we should
            // take advantage of fused multiply-add (where supported) to eliminate
            // intermediate rounding error.
            return (i + 1, start.addingProduct(Stride(i + 1), distance))
        }
        return (nil, current.value.advanced(by: distance))
    }
}

/// An iterator for a `StrideTo` instance.
@frozen
public struct StrideToIterator<Element: Strideable> {
    internal let _start: Element
    internal let _end: Element
    internal let _stride: Element.Stride
    // 第几个, 值是什么
    internal var _current: (index: Int?, value: Element)
    
    @inlinable
    internal init(_start: Element, end: Element, stride: Element.Stride) {
        self._start = _start
        _end = end
        _stride = stride
        _current = (0, _start)
    }
}

extension StrideToIterator: IteratorProtocol {
    public mutating func next() -> Element? {
        let result = _current.value
        if _stride > 0 ? result >= _end : result <= _end {
            return nil
        }
        _current = Element._step(after: _current, from: _start, by: _stride)
        return result
    }
}


// Stride 函数, 返回的是这个特殊的数据类型.
// 这个特殊的数据类型, 是一个 Sequence.
public struct StrideTo<Element: Strideable> {
    internal let _start: Element
    internal let _end: Element
    internal let _stride: Element.Stride
    
    @inlinable
    internal init(_start: Element, end: Element, stride: Element.Stride) {
        self._start = _start
        self._end = end
        self._stride = stride
    }
}

extension StrideTo: Sequence {
    public __consuming func makeIterator() -> StrideToIterator<Element> {
        return StrideToIterator(_start: _start, end: _end, stride: _stride)
    }
    // 算出来的, 这里, 时间复杂度不再是 O1 了
    public var underestimatedCount: Int {
        var it = self.makeIterator()
        var count = 0
        while it.next() != nil {
            count += 1
        }
        return count
    }
    
    @inlinable
    public func _customContainsEquatableElement(
        _ element: Element
    ) -> Bool? {
        if element < _start || _end <= element {
            return false
        }
        return nil
    }
}

extension StrideTo: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, children: ["from": _start, "to": _end, "by": _stride])
    }
}

extension StrideTo: RandomAccessCollection
where Element.Stride: BinaryInteger {
    
    public typealias Index = Int
    public typealias SubSequence = Slice<StrideTo<Element>>
    public typealias Indices = Range<Int>
    
    public var startIndex: Index { return 0 }
    public var endIndex: Index { return count }
    
    // 如果, 是 Int, 那么可以直接算出 count 来.
    public var count: Int {
        let distance = _start.distance(to: _end)
        guard distance != 0 && (distance < 0) == (_stride < 0) else { return 0 }
        return Int((distance - 1) / _stride) + 1
    }
    
    public subscript(position: Index) -> Element {
        return _start.advanced(by: Element.Stride(position) * _stride)
    }
    
    public subscript(bounds: Range<Index>) -> Slice<StrideTo<Element>> {
        return Slice(base: self, bounds: bounds)
    }
    
    @inlinable
    public func index(before i: Index) -> Index {
        _failEarlyRangeCheck(i, bounds: startIndex + 1...endIndex)
        return i - 1
    }
    
    @inlinable
    public func index(after i: Index) -> Index {
        _failEarlyRangeCheck(i, bounds: startIndex - 1..<endIndex)
        return i + 1
    }
}
#endif

/// Returns a sequence from a starting value to, but not including, an end
/// value, stepping by the specified amount.
///
/// You can use this function to stride over values of any type that conforms
/// to the `Strideable` protocol, such as integers or floating-point types.
/// Starting with `start`, each successive value of the sequence adds `stride`
/// until the next value would be equal to or beyond `end`.
///
///     for radians in stride(from: 0.0, to: .pi * 2, by: .pi / 2) {
///         let degrees = Int(radians * 180 / .pi)
///         print("Degrees: \(degrees), radians: \(radians)")
///     }
///     // Degrees: 0, radians: 0.0
///     // Degrees: 90, radians: 1.5707963267949
///     // Degrees: 180, radians: 3.14159265358979
///     // Degrees: 270, radians: 4.71238898038469
///
/// You can use `stride(from:to:by:)` to create a sequence that strides upward
/// or downward. Pass a negative value as `stride` to create a sequence from a
/// higher start to a lower end:
///
///     for countdown in stride(from: 3, to: 0, by: -1) {
///         print("\(countdown)...")
///     }
///     // 3...
///     // 2...
///     // 1...
///
/// If you pass a value as `stride` that moves away from `end`, the sequence
/// contains no values.
///
///     for x in stride(from: 0, to: 10, by: -1) {
///         print(x)
///     }
///     // Nothing is printed.
///
/// - Parameters:
///   - start: The starting value to use for the sequence. If the sequence
///     contains any values, the first one is `start`.
///   - end: An end value to limit the sequence. `end` is never an element of
///     the resulting sequence.
///   - stride: The amount to step by with each iteration. A positive `stride`
///     iterates upward; a negative `stride` iterates downward.
/// - Returns: A sequence from `start` toward, but not including, `end`. Each
///   value in the sequence steps by `stride`.
@inlinable
public func stride<T>(
    from start: T, to end: T, by stride: T.Stride
) -> StrideTo<T> {
    return StrideTo(_start: start, end: end, stride: stride)
}

/// An iterator for a `StrideThrough` instance.
@frozen
public struct StrideThroughIterator<Element: Strideable> {
    @usableFromInline
    internal let _start: Element
    
    @usableFromInline
    internal let _end: Element
    
    @usableFromInline
    internal let _stride: Element.Stride
    
    @usableFromInline
    internal var _current: (index: Int?, value: Element)
    
    @usableFromInline
    internal var _didReturnEnd: Bool = false
    
    @inlinable
    internal init(_start: Element, end: Element, stride: Element.Stride) {
        self._start = _start
        _end = end
        _stride = stride
        _current = (0, _start)
    }
}

extension StrideThroughIterator: IteratorProtocol {
    /// Advances to the next element and returns it, or `nil` if no next element
    /// exists.
    ///
    /// Once `nil` has been returned, all subsequent calls return `nil`.
    // 这里的实现, 就很简单了.
    @inlinable
    public mutating func next() -> Element? {
        let result = _current.value
        if _stride > 0 ? result >= _end : result <= _end {
            // Note the `>=` and `<=` operators above. When `result == _end`, the
            // following check is needed to prevent advancing `_current` past the
            // representable bounds of the `Strideable` type unnecessarily.
            //
            // If the `Strideable` type is a fixed-width integer, overflowed results
            // are represented using a sentinel value for `_current.index`, `Int.min`.
            if result == _end && !_didReturnEnd && _current.index != .min {
                _didReturnEnd = true
                return result
            }
            return nil
        }
        _current = Element._step(after: _current, from: _start, by: _stride)
        return result
    }
}

// FIXME: should really be a Collection, as it is multipass
/// A sequence of values formed by striding over a closed interval.
///
/// Use the `stride(from:through:by:)` function to create `StrideThrough` 
/// instances.
@frozen
public struct StrideThrough<Element: Strideable> {
    // 专门, 把 @ 这种, 新起一行进行编写, 看来是一个很官方的写法.
    // 而 Publich 这种访问权限控制, 则是需要和属性的命名, 在同样的行里面.
    // 但是, 属性的命名, 究竟是否需要用 _ 开头, 一直是没有很好的规范在这里.
    @usableFromInline
    internal let _start: Element
    @usableFromInline
    internal let _end: Element
    @usableFromInline
    internal let _stride: Element.Stride
    
    @inlinable
    internal init(_start: Element, end: Element, stride: Element.Stride) {
        _precondition(stride != 0, "Stride size must not be zero")
        self._start = _start
        self._end = end
        self._stride = stride
    }
}

extension StrideThrough: Sequence {
    /// Returns an iterator over the elements of this sequence.
    ///
    /// - Complexity: O(1).
    @inlinable
    public __consuming func makeIterator() -> StrideThroughIterator<Element> {
        return StrideThroughIterator(_start: _start, end: _end, stride: _stride)
    }
    
    // FIXME(conditional-conformances): this is O(N) instead of O(1), leaving it
    // here until a proper Collection conformance is possible
    // 这里其实不符合 underestimatedCount 的要求, 这也说明了, 在 Swift 里面, 编译器其实是不能完全掌握住所有的事情的.
    @inlinable
    public var underestimatedCount: Int {
        var it = self.makeIterator()
        var count = 0
        while it.next() != nil {
            count += 1
        }
        return count
    }
    
    // func contains(_ element: Element) -> Bool
    // 在 Contains 的判断里面, 使用了这种, 更加精细化的判断方法.
    // 其实, 个人写的代码, 是可以使用这个方法的. 就算头文件没有暴露出来, 只要实现了该方法, 那么就会到 pwt 里面, 那么, 编译出来的代码, 一定就会使用这里.
    @inlinable
    public func _customContainsEquatableElement(
        _ element: Element
    ) -> Bool? {
        if element < _start || _end < element {
            return false
        }
        return nil
    }
}

extension StrideThrough: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self,
                      children: ["from": _start, "through": _end, "by": _stride])
    }
}

// FIXME(conditional-conformances): This does not yet compile (SR-6474).
#if false
extension StrideThrough: RandomAccessCollection
where Element.Stride: BinaryInteger {
    public typealias Index = ClosedRangeIndex<Int>
    public typealias SubSequence = Slice<StrideThrough<Element>>
    
    @inlinable
    public var startIndex: Index {
        let distance = _start.distance(to: _end)
        return distance == 0 || (distance < 0) == (_stride < 0)
        ? ClosedRangeIndex(0)
        : ClosedRangeIndex()
    }
    
    @inlinable
    public var endIndex: Index { return ClosedRangeIndex() }
    
    @inlinable
    public var count: Int {
        let distance = _start.distance(to: _end)
        guard distance != 0 else { return 1 }
        guard (distance < 0) == (_stride < 0) else { return 0 }
        return Int(distance / _stride) + 1
    }
    
    public subscript(position: Index) -> Element {
        let offset = Element.Stride(position._dereferenced) * _stride
        return _start.advanced(by: offset)
    }
    
    public subscript(bounds: Range<Index>) -> Slice<StrideThrough<Element>> {
        return Slice(base: self, bounds: bounds)
    }
    
    @inlinable
    public func index(before i: Index) -> Index {
        switch i._value {
        case .inRange(let n):
            _precondition(n > 0, "Incrementing past start index")
            return ClosedRangeIndex(n - 1)
        case .pastEnd:
            _precondition(_end >= _start, "Incrementing past start index")
            return ClosedRangeIndex(count - 1)
        }
    }
    
    @inlinable
    public func index(after i: Index) -> Index {
        switch i._value {
        case .inRange(let n):
            return n == (count - 1)
            ? ClosedRangeIndex()
            : ClosedRangeIndex(n + 1)
        case .pastEnd:
            _preconditionFailure("Incrementing past end index")
        }
    }
}
#endif

/// Returns a sequence from a starting value toward, and possibly including, an end
/// value, stepping by the specified amount.
///
/// You can use this function to stride over values of any type that conforms
/// to the `Strideable` protocol, such as integers or floating-point types.
/// Starting with `start`, each successive value of the sequence adds `stride`
/// until the next value would be beyond `end`.
///
///     for radians in stride(from: 0.0, through: .pi * 2, by: .pi / 2) {
///         let degrees = Int(radians * 180 / .pi)
///         print("Degrees: \(degrees), radians: \(radians)")
///     }
///     // Degrees: 0, radians: 0.0
///     // Degrees: 90, radians: 1.5707963267949
///     // Degrees: 180, radians: 3.14159265358979
///     // Degrees: 270, radians: 4.71238898038469
///     // Degrees: 360, radians: 6.28318530717959
///
/// You can use `stride(from:through:by:)` to create a sequence that strides 
/// upward or downward. Pass a negative value as `stride` to create a sequence 
/// from a higher start to a lower end:
///
///     for countdown in stride(from: 3, through: 1, by: -1) {
///         print("\(countdown)...")
///     }
///     // 3...
///     // 2...
///     // 1...
///
/// The value you pass as `end` is not guaranteed to be included in the 
/// sequence. If stepping from `start` by `stride` does not produce `end`, 
/// the last value in the sequence will be one step before going beyond `end`.
///
///     for multipleOfThree in stride(from: 3, through: 10, by: 3) {
///         print(multipleOfThree)
///     }
///     // 3
///     // 6
///     // 9
///
/// If you pass a value as `stride` that moves away from `end`, the sequence 
/// contains no values.
///
///     for x in stride(from: 0, through: 10, by: -1) {
///         print(x)
///     }
///     // Nothing is printed.
///
/// - Parameters:
///   - start: The starting value to use for the sequence. If the sequence
///     contains any values, the first one is `start`.
///   - end: An end value to limit the sequence. `end` is an element of
///     the resulting sequence if and only if it can be produced from `start` 
///     using steps of `stride`.
///   - stride: The amount to step by with each iteration. A positive `stride`
///     iterates upward; a negative `stride` iterates downward.
/// - Returns: A sequence from `start` toward, and possibly including, `end`. 
///   Each value in the sequence is separated by `stride`.
@inlinable
public func stride<T>(
    from start: T, through end: T, by stride: T.Stride
) -> StrideThrough<T> {
    return StrideThrough(_start: start, end: end, stride: stride)
}

extension StrideToIterator: Sendable
where Element: Sendable, Element.Stride: Sendable { }
extension StrideTo: Sendable
where Element: Sendable, Element.Stride: Sendable { }
extension StrideThroughIterator: Sendable
where Element: Sendable, Element.Stride: Sendable { }
extension StrideThrough: Sendable
where Element: Sendable, Element.Stride: Sendable { }
