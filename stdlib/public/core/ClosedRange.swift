// ... ..< 操作符, 返回的真实的类型.
// 当, LowerBound, UpperBound 是 Strde 的时候, 并且 Int 作为单位的时候, Range 可以当做是 Collection 来使用,
public struct ClosedRange<Bound: Comparable> {
    public let lowerBound: Bound
    public let upperBound: Bound
    public init(uncheckedBounds bounds: (lower: Bound, upper: Bound)) {
        self.lowerBound = bounds.lower
        self.upperBound = bounds.upper
    }
}

extension ClosedRange {
    public var isEmpty: Bool {
        return false
    }
}

extension ClosedRange: RangeExpression {
    public func relative<C: Collection>(to collection: C) -> Range<Bound>
    where C.Index == Bound {
        return Range(
            uncheckedBounds: (
                lower: lowerBound, upper: collection.index(after: self.upperBound)))
    }
    public func contains(_ element: Bound) -> Bool {
        return element >= self.lowerBound && element <= self.upperBound
    }
}

extension ClosedRange: Sequence
where Bound: Strideable, Bound.Stride: SignedInteger {
    public typealias Element = Bound
    public typealias Iterator = IndexingIterator<ClosedRange<Bound>>
}

extension ClosedRange where Bound: Strideable, Bound.Stride: SignedInteger {
    // End 应该怎么表示, 其实就是状态值. Max 之后, index after, 都是一个值.
    // 而这种, 状态值 + 伴随值, 其实就是应该使用 Enum 来实现.
    public enum Index {
        case pastEnd
        case inRange(Bound)
    }
}

extension ClosedRange.Index: Comparable {
    @inlinable
    public static func == (
        lhs: ClosedRange<Bound>.Index,
        rhs: ClosedRange<Bound>.Index
    ) -> Bool {
        switch (lhs, rhs) {
        case (.inRange(let l), .inRange(let r)):
            return l == r
        case (.pastEnd, .pastEnd):
            return true
        default:
            return false
        }
    }
    
    public static func < (
        lhs: ClosedRange<Bound>.Index,
        rhs: ClosedRange<Bound>.Index
    ) -> Bool {
        switch (lhs, rhs) {
        case (.inRange(let l), .inRange(let r)):
            return l < r
        case (.inRange, .pastEnd):
            return true
        default:
            return false
        }
    }
}

extension ClosedRange.Index: Hashable
where Bound: Strideable, Bound.Stride: SignedInteger, Bound: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .inRange(let value):
            hasher.combine(0 as Int8)
            hasher.combine(value)
        case .pastEnd:
            hasher.combine(1 as Int8)
        }
    }
}

extension ClosedRange: Collection, BidirectionalCollection, RandomAccessCollection
where Bound: Strideable, Bound.Stride: SignedInteger
{
    public typealias SubSequence = Slice<ClosedRange<Bound>>
    
    public var startIndex: Index {
        return .inRange(lowerBound)
    }
    
    public var endIndex: Index {
        return .pastEnd
    }
    
    @inlinable
    public func index(after i: Index) -> Index {
        switch i {
        case .inRange(let x):
            // 如果, 到达了上边界, 就是返回 End. 也就是状态值发生了改变
            return x == upperBound
                ? .pastEnd
                : .inRange(x.advanced(by: 1))
        case .pastEnd:
        }
    }
    
    @inlinable
    public func index(before i: Index) -> Index {
        switch i {
        case .inRange(let x):
            _precondition(x > lowerBound, "Incrementing past start index")
            return .inRange(x.advanced(by: -1))
        case .pastEnd:
            _precondition(upperBound >= lowerBound, "Incrementing past start index")
            return .inRange(upperBound)
        }
    }
    
    @inlinable
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        switch i {
        case .inRange(let x):
            let d = x.distance(to: upperBound)
            if distance <= d {
                let newPosition = x.advanced(by: numericCast(distance))
                _precondition(newPosition >= lowerBound,
                              "Advancing past start index")
                return .inRange(newPosition)
            }
            if d - -1 == distance { return .pastEnd }
            _preconditionFailure("Advancing past end index")
        case .pastEnd:
            if distance == 0 {
                return i
            }
            if distance < 0 {
                return index(.inRange(upperBound), offsetBy: numericCast(distance + 1))
            }
            _preconditionFailure("Advancing past end index")
        }
    }
    
    @inlinable
    public func distance(from start: Index, to end: Index) -> Int {
        switch (start, end) {
        case let (.inRange(left), .inRange(right)):
            // in range <--> in range
            return numericCast(left.distance(to: right))
        case let (.inRange(left), .pastEnd):
            // in range --> end
            return numericCast(1 + left.distance(to: upperBound))
        case let (.pastEnd, .inRange(right)):
            // in range <-- end
            return numericCast(upperBound.distance(to: right) - 1)
        case (.pastEnd, .pastEnd):
            // end <--> end
            return 0
        }
    }
    
    /// Accesses the element at specified position.
    ///
    /// You can subscript a collection with any valid index other than the
    /// collection's end index. The end index refers to the position one past
    /// the last element of a collection, so it doesn't correspond with an
    /// element.
    ///
    /// - Parameter position: The position of the element to access. `position`
    ///   must be a valid index of the range, and must not equal the range's end
    ///   index.
    @inlinable
    public subscript(position: Index) -> Bound {
        // FIXME: swift-3-indexing-model: range checks and tests.
        switch position {
        case .inRange(let x): return x
        case .pastEnd: _preconditionFailure("Index out of range")
        }
    }
    
    @inlinable
    public subscript(bounds: Range<Index>)
    -> Slice<ClosedRange<Bound>> {
        return Slice(base: self, bounds: bounds)
    }
    
    // 更加高效的, 进行 contains 的判断.
    public func _customContainsEquatableElement(_ element: Bound) -> Bool? {
        return lowerBound <= element && element <= upperBound
    }
    
    @inlinable
    public func _customIndexOfEquatableElement(_ element: Bound) -> Index?? {
        return lowerBound <= element && element <= upperBound
            ? .inRange(element) : nil
    }
    
    @inlinable
    public func _customLastIndexOfEquatableElement(_ element: Bound) -> Index?? {
        // The first and last elements are the same because each element is unique.
        return _customIndexOfEquatableElement(element)
    }
}

extension Comparable {  
    // 操作符, 返回特殊的数据结构.
    public static func ... (minimum: Self, maximum: Self) -> ClosedRange<Self> {
        return ClosedRange(uncheckedBounds: (lower: minimum, upper: maximum))
    }
}

extension ClosedRange: Equatable {
    public static func == (
        lhs: ClosedRange<Bound>, rhs: ClosedRange<Bound>
    ) -> Bool {
        return lhs.lowerBound == rhs.lowerBound && lhs.upperBound == rhs.upperBound
    }
}

extension ClosedRange: Hashable where Bound: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(lowerBound)
        hasher.combine(upperBound)
    }
}

extension ClosedRange: CustomStringConvertible {
    public var description: String {
        return "\(lowerBound)...\(upperBound)"
    }
}

extension ClosedRange: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "ClosedRange(\(String(reflecting: lowerBound))"
            + "...\(String(reflecting: upperBound)))"
    }
}

extension ClosedRange: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(
            self, children: ["lowerBound": lowerBound, "upperBound": upperBound])
    }
}

extension ClosedRange {
    /// Returns a copy of this range clamped to the given limiting range.
    ///
    /// The bounds of the result are always limited to the bounds of `limits`.
    /// For example:
    ///
    ///     let x: ClosedRange = 0...20
    ///     print(x.clamped(to: 10...1000))
    ///     // Prints "10...20"
    ///
    /// If the two ranges do not overlap, the result is a single-element range at
    /// the upper or lower bound of `limits`.
    ///
    ///     let y: ClosedRange = 0...5
    ///     print(y.clamped(to: 10...1000))
    ///     // Prints "10...10"
    ///
    /// - Parameter limits: The range to clamp the bounds of this range.
    /// - Returns: A new range clamped to the bounds of `limits`.
    @inlinable // trivial-implementation
    @inline(__always)
    public func clamped(to limits: ClosedRange) -> ClosedRange {
        let lower =
            limits.lowerBound > self.lowerBound ? limits.lowerBound
            : limits.upperBound < self.lowerBound ? limits.upperBound
            : self.lowerBound
        let upper =
            limits.upperBound < self.upperBound ? limits.upperBound
            : limits.lowerBound > self.upperBound ? limits.lowerBound
            : self.upperBound
        return ClosedRange(uncheckedBounds: (lower: lower, upper: upper))
    }
}

extension ClosedRange where Bound: Strideable, Bound.Stride: SignedInteger {
    public init(_ other: Range<Bound>) {
        let upperBound = other.upperBound.advanced(by: -1)
        self.init(uncheckedBounds: (lower: other.lowerBound, upper: upperBound))
    }
}

extension ClosedRange {
    @inlinable
    public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
        // Disjoint iff the other range is completely before or after our range.
        // Unlike a `Range`, a `ClosedRange` can *not* be empty, so no check for
        // that case is needed here.
        let isDisjoint = other.upperBound < self.lowerBound
            || self.upperBound < other.lowerBound
        return !isDisjoint
    }
    
    @inlinable
    public func overlaps(_ other: Range<Bound>) -> Bool {
        return other.overlaps(self)
    }
}

// Note: this is not for compatibility only, it is considered a useful
// shorthand. TODO: Add documentation
public typealias CountableClosedRange<Bound: Strideable> = ClosedRange<Bound>
where Bound.Stride: SignedInteger

extension ClosedRange: Decodable where Bound: Decodable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let lowerBound = try container.decode(Bound.self)
        let upperBound = try container.decode(Bound.self)
        guard lowerBound <= upperBound else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot initialize \(ClosedRange.self) with a lowerBound (\(lowerBound)) greater than upperBound (\(upperBound))"))
        }
        self.init(uncheckedBounds: (lower: lowerBound, upper: upperBound))
    }
}

extension ClosedRange: Encodable where Bound: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.lowerBound)
        try container.encode(self.upperBound)
    }
}
