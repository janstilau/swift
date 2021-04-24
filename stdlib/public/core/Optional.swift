/*
 编译器做了优化, 可以让我们
 var age: Int? = 1
 这样书写, 而不是 Optinal<Int>(1)
 本质上, Optinal 就是一个特殊的枚举类型而已.
 不过, 因为这个概念是这门语言里面的核心概念, 所以, 编译器为了它能够顺利执行, 做了很多的特殊优化判断.
 */
// Wrapped 良好的命名, 按时这个类型的作用
@frozen
public enum Optional<Wrapped>: ExpressibleByNilLiteral {
    case none
    case some(Wrapped)
    
    @_transparent
    public init(_ some: Wrapped) { self = .some(some) }
    
    @inlinable
    public func map<U>(
        _ transform: (Wrapped) throws -> U
    ) rethrows -> U? {
        switch self {
        case .some(let y):
            return .some(try transform(y))
        case .none:
            return .none
        }
    }
    
    @inlinable
    public func flatMap<U>(
        _ transform: (Wrapped) throws -> U?
    ) rethrows -> U? {
        switch self {
        case .some(let y):
            return try transform(y)
        case .none:
            return .none
        }
    }
    
    @_transparent
    public init(nilLiteral: ()) {
        self = .none
    }
    
    @inlinable
    public var unsafelyUnwrapped: Wrapped {
        @inline(__always)
        get {
            if let x = self {
                return x
            }
            _debugPreconditionFailure("unsafelyUnwrapped of nil optional")
        }
    }
    
    @inlinable
    internal var _unsafelyUnwrappedUnchecked: Wrapped {
        @inline(__always)
        get {
            if let x = self {
                return x
            }
            _internalInvariantFailure("_unsafelyUnwrappedUnchecked of nil optional")
        }
    }
}

extension Optional: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .some(let value):
            var result = "Optional("
            debugPrint(value, terminator: "", to: &result)
            result += ")"
            return result
        case .none:
            return "nil"
        }
    }
}

extension Optional: CustomReflectable {
    public var customMirror: Mirror {
        switch self {
        case .some(let value):
            return Mirror(
                self,
                children: [ "some": value ],
                displayStyle: .optional)
        case .none:
            return Mirror(self, children: [:], displayStyle: .optional)
        }
    }
}

// 只有, Optinal 里面的 warpped 是可以比较相等的时候, Optinale 才可以比较相等
// 当一个 Optinal 和一个 Non Optinal 比较的时候, 这个 Non Optinal 会被包装成为一个 Optinal 类型的值.
extension Optional: Equatable where Wrapped: Equatable {
    public static func ==(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
        switch (lhs, rhs) {
        case let (l?, r?):
            return l == r
        case (nil, nil):
            return true
        default:
            return false
        }
    }
}

extension Optional: Hashable where Wrapped: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .none:
            hasher.combine(0 as UInt8)
        case .some(let wrapped):
            hasher.combine(1 as UInt8)
            hasher.combine(wrapped)
        }
    }
}

extension Optional {
    /// Returns a Boolean value indicating whether an argument matches `nil`.
    ///
    /// You can use the pattern-matching operator (`~=`) to test whether an
    /// optional instance is `nil` even when the wrapped value's type does not
    /// conform to the `Equatable` protocol. The pattern-matching operator is used
    /// internally in `case` statements for pattern matching.
    ///
    /// The following example declares the `stream` variable as an optional
    /// instance of a hypothetical `DataStream` type, and then uses a `switch`
    /// statement to determine whether the stream is `nil` or has a configured
    /// value. When evaluating the `nil` case of the `switch` statement, this
    /// operator is called behind the scenes.
    ///
    ///     var stream: DataStream? = nil
    ///     switch stream {
    ///     case nil:
    ///         print("No data stream is configured.")
    ///     case let x?:
    ///         print("The data stream has \(x.availableBytes) bytes available.")
    ///     }
    ///     // Prints "No data stream is configured."
    ///
    /// - Note: To test whether an instance is `nil` in an `if` statement, use the
    ///   equal-to operator (`==`) instead of the pattern-matching operator. The
    ///   pattern-matching operator is primarily intended to enable `case`
    ///   statement pattern matching.
    ///
    /// - Parameters:
    ///   - lhs: A `nil` literal.
    ///   - rhs: A value to match against `nil`.
    @_transparent
    public static func ~=(lhs: _OptionalNilComparisonType, rhs: Wrapped?) -> Bool {
        switch rhs {
        case .some:
            return false
        case .none:
            return true
        }
    }
    
    // Enable equality comparisons against the nil literal, even if the
    // element type isn't equatable
    
    /// Returns a Boolean value indicating whether the left-hand-side argument is
    /// `nil`.
    ///
    /// You can use this equal-to operator (`==`) to test whether an optional
    /// instance is `nil` even when the wrapped value's type does not conform to
    /// the `Equatable` protocol.
    ///
    /// The following example declares the `stream` variable as an optional
    /// instance of a hypothetical `DataStream` type. Although `DataStream` is not
    /// an `Equatable` type, this operator allows checking whether `stream` is
    /// `nil`.
    ///
    ///     var stream: DataStream? = nil
    ///     if stream == nil {
    ///         print("No data stream is configured.")
    ///     }
    ///     // Prints "No data stream is configured."
    ///
    /// - Parameters:
    ///   - lhs: A value to compare to `nil`.
    ///   - rhs: A `nil` literal.
    @_transparent
    public static func ==(lhs: Wrapped?, rhs: _OptionalNilComparisonType) -> Bool {
        switch lhs {
        case .some:
            return false
        case .none:
            return true
        }
    }
    
    /// Returns a Boolean value indicating whether the left-hand-side argument is
    /// not `nil`.
    ///
    /// You can use this not-equal-to operator (`!=`) to test whether an optional
    /// instance is not `nil` even when the wrapped value's type does not conform
    /// to the `Equatable` protocol.
    ///
    /// The following example declares the `stream` variable as an optional
    /// instance of a hypothetical `DataStream` type. Although `DataStream` is not
    /// an `Equatable` type, this operator allows checking whether `stream` wraps
    /// a value and is therefore not `nil`.
    ///
    ///     var stream: DataStream? = fetchDataStream()
    ///     if stream != nil {
    ///         print("The data stream has been configured.")
    ///     }
    ///     // Prints "The data stream has been configured."
    ///
    /// - Parameters:
    ///   - lhs: A value to compare to `nil`.
    ///   - rhs: A `nil` literal.
    @_transparent
    public static func !=(lhs: Wrapped?, rhs: _OptionalNilComparisonType) -> Bool {
        switch lhs {
        case .some:
            return true
        case .none:
            return false
        }
    }
    
    /// Returns a Boolean value indicating whether the right-hand-side argument is
    /// `nil`.
    ///
    /// You can use this equal-to operator (`==`) to test whether an optional
    /// instance is `nil` even when the wrapped value's type does not conform to
    /// the `Equatable` protocol.
    ///
    /// The following example declares the `stream` variable as an optional
    /// instance of a hypothetical `DataStream` type. Although `DataStream` is not
    /// an `Equatable` type, this operator allows checking whether `stream` is
    /// `nil`.
    ///
    ///     var stream: DataStream? = nil
    ///     if nil == stream {
    ///         print("No data stream is configured.")
    ///     }
    ///     // Prints "No data stream is configured."
    ///
    /// - Parameters:
    ///   - lhs: A `nil` literal.
    ///   - rhs: A value to compare to `nil`.
    @_transparent
    public static func ==(lhs: _OptionalNilComparisonType, rhs: Wrapped?) -> Bool {
        switch rhs {
        case .some:
            return false
        case .none:
            return true
        }
    }
    
    /// Returns a Boolean value indicating whether the right-hand-side argument is
    /// not `nil`.
    ///
    /// You can use this not-equal-to operator (`!=`) to test whether an optional
    /// instance is not `nil` even when the wrapped value's type does not conform
    /// to the `Equatable` protocol.
    ///
    /// The following example declares the `stream` variable as an optional
    /// instance of a hypothetical `DataStream` type. Although `DataStream` is not
    /// an `Equatable` type, this operator allows checking whether `stream` wraps
    /// a value and is therefore not `nil`.
    ///
    ///     var stream: DataStream? = fetchDataStream()
    ///     if nil != stream {
    ///         print("The data stream has been configured.")
    ///     }
    ///     // Prints "The data stream has been configured."
    ///
    /// - Parameters:
    ///   - lhs: A `nil` literal.
    ///   - rhs: A value to compare to `nil`.
    @_transparent
    public static func !=(lhs: _OptionalNilComparisonType, rhs: Wrapped?) -> Bool {
        switch rhs {
        case .some:
            return true
        case .none:
            return false
        }
    }
}

/// Performs a nil-coalescing operation, returning the wrapped value of an
/// `Optional` instance or a default value.
///
/// A nil-coalescing operation unwraps the left-hand side if it has a value, or
/// it returns the right-hand side as a default. The result of this operation
/// will have the non-optional type of the left-hand side's `Wrapped` type.
///
/// This operator uses short-circuit evaluation: `optional` is checked first,
/// and `defaultValue` is evaluated only if `optional` is `nil`. For example:
///
///     func getDefault() -> Int {
///         print("Calculating default...")
///         return 42
///     }
///
///     let goodNumber = Int("100") ?? getDefault()
///     // goodNumber == 100
///
///     let notSoGoodNumber = Int("invalid-input") ?? getDefault()
///     // Prints "Calculating default..."
///     // notSoGoodNumber == 42
///
/// In this example, `goodNumber` is assigned a value of `100` because
/// `Int("100")` succeeded in returning a non-`nil` result. When
/// `notSoGoodNumber` is initialized, `Int("invalid-input")` fails and returns
/// `nil`, and so the `getDefault()` method is called to supply a default
/// value.
///
/// - Parameters:
///   - optional: An optional value.
///   - defaultValue: A value to use as a default. `defaultValue` is the same
///     type as the `Wrapped` type of `optional`.
@_transparent
public func ?? <T>(optional: T?, defaultValue: @autoclosure () throws -> T)
rethrows -> T {
    switch optional {
    case .some(let value):
        return value
    case .none:
        return try defaultValue()
    }
}

/// Performs a nil-coalescing operation, returning the wrapped value of an
/// `Optional` instance or a default `Optional` value.
///
/// A nil-coalescing operation unwraps the left-hand side if it has a value, or
/// returns the right-hand side as a default. The result of this operation
/// will be the same type as its arguments.
///
/// This operator uses short-circuit evaluation: `optional` is checked first,
/// and `defaultValue` is evaluated only if `optional` is `nil`. For example:
///
///     let goodNumber = Int("100") ?? Int("42")
///     print(goodNumber)
///     // Prints "Optional(100)"
///
///     let notSoGoodNumber = Int("invalid-input") ?? Int("42")
///     print(notSoGoodNumber)
///     // Prints "Optional(42)"
///
/// In this example, `goodNumber` is assigned a value of `100` because
/// `Int("100")` succeeds in returning a non-`nil` result. When
/// `notSoGoodNumber` is initialized, `Int("invalid-input")` fails and returns
/// `nil`, and so `Int("42")` is called to supply a default value.
///
/// Because the result of this nil-coalescing operation is itself an optional
/// value, you can chain default values by using `??` multiple times. The
/// first optional value that isn't `nil` stops the chain and becomes the
/// result of the whole expression. The next example tries to find the correct
/// text for a greeting in two separate dictionaries before falling back to a
/// static default.
///
///     let greeting = userPrefs[greetingKey] ??
///         defaults[greetingKey] ?? "Greetings!"
///
/// If `userPrefs[greetingKey]` has a value, that value is assigned to
/// `greeting`. If not, any value in `defaults[greetingKey]` will succeed, and
/// if not that, `greeting` will be set to the non-optional default value,
/// `"Greetings!"`.
///
/// - Parameters:
///   - optional: An optional value.
///   - defaultValue: A value to use as a default. `defaultValue` and
///     `optional` have the same type.
@_transparent
public func ?? <T>(optional: T?, defaultValue: @autoclosure () throws -> T?)
rethrows -> T? {
    switch optional {
    case .some(let value):
        return value
    case .none:
        return try defaultValue()
    }
}

//===----------------------------------------------------------------------===//
// Bridging
//===----------------------------------------------------------------------===//

#if _runtime(_ObjC)
extension Optional: _ObjectiveCBridgeable {
    // The object that represents `none` for an Optional of this type.
    internal static var _nilSentinel: AnyObject {
        @_silgen_name("_swift_Foundation_getOptionalNilSentinelObject")
        get
    }
    
    public func _bridgeToObjectiveC() -> AnyObject {
        // Bridge a wrapped value by unwrapping.
        if let value = self {
            return _bridgeAnythingToObjectiveC(value)
        }
        // Bridge nil using a sentinel.
        return type(of: self)._nilSentinel
    }
    
    public static func _forceBridgeFromObjectiveC(
        _ source: AnyObject,
        result: inout Optional<Wrapped>?
    ) {
        // Map the nil sentinel back to .none.
        // NB that the signature of _forceBridgeFromObjectiveC adds another level
        // of optionality, so we need to wrap the immediate result of the conversion
        // in `.some`.
        if source === _nilSentinel {
            result = .some(.none)
            return
        }
        // Otherwise, force-bridge the underlying value.
        let unwrappedResult = source as! Wrapped
        result = .some(.some(unwrappedResult))
    }
    
    public static func _conditionallyBridgeFromObjectiveC(
        _ source: AnyObject,
        result: inout Optional<Wrapped>?
    ) -> Bool {
        // Map the nil sentinel back to .none.
        // NB that the signature of _forceBridgeFromObjectiveC adds another level
        // of optionality, so we need to wrap the immediate result of the conversion
        // in `.some` to indicate success of the bridging operation, with a nil
        // result.
        if source === _nilSentinel {
            result = .some(.none)
            return true
        }
        // Otherwise, try to bridge the underlying value.
        if let unwrappedResult = source as? Wrapped {
            result = .some(.some(unwrappedResult))
            return true
        } else {
            result = .none
            return false
        }
    }
    
    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: AnyObject?)
    -> Optional<Wrapped> {
        if let nonnullSource = source {
            // Map the nil sentinel back to none.
            if nonnullSource === _nilSentinel {
                return .none
            } else {
                return .some(nonnullSource as! Wrapped)
            }
        } else {
            // If we unexpectedly got nil, just map it to `none` too.
            return .none
        }
    }
}
#endif
