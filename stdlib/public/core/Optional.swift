/// A type that represents either a wrapped value or `nil`, the absence of a
/// value.
///
/// You use the `Optional` type whenever you use optional values, even if you
/// never type the word `Optional`. Swift's type system usually shows the
/// wrapped type's name with a trailing question mark (`?`) instead of showing
/// the full type name. For example, if a variable has the type `Int?`, that's
/// just another way of writing `Optional<Int>`. The shortened form is
/// preferred for ease of reading and writing code.
///
/// The types of `shortForm` and `longForm` in the following code sample are
/// the same:
///
///     let shortForm: Int? = Int("42")
///     let longForm: Optional<Int> = Int("42")
///
/// The `Optional` type is an enumeration with two cases. `Optional.none` is
/// equivalent to the `nil` literal. `Optional.some(Wrapped)` stores a wrapped
/// value. For example:
///
///     let number: Int? = Optional.some(42)
///     let noNumber: Int? = Optional.none
///     print(noNumber == nil)
///     // Prints "true"
///
/// You must unwrap the value of an `Optional` instance before you can use it
/// in many contexts. Because Swift provides several ways to safely unwrap
/// optional values, you can choose the one that helps you write clear,
/// concise code.
///
/// The following examples use this dictionary of image names and file paths:
///
///     let imagePaths = ["star": "/glyphs/star.png",
///                       "portrait": "/images/content/portrait.jpg",
///                       "spacer": "/images/shared/spacer.gif"]
///
/// Getting a dictionary's value using a key returns an optional value, so
/// `imagePaths["star"]` has type `Optional<String>` or, written in the
/// preferred manner, `String?`.
///
/// Optional Binding
/// ----------------
///
/// To conditionally bind the wrapped value of an `Optional` instance to a new
/// variable, use one of the optional binding control structures, including
/// `if let`, `guard let`, and `switch`.
///
///     if let starPath = imagePaths["star"] {
///         print("The star image is at '\(starPath)'")
///     } else {
///         print("Couldn't find the star image")
///     }
///     // Prints "The star image is at '/glyphs/star.png'"
///
/// Optional Chaining
/// -----------------
///
/// To safely access the properties and methods of a wrapped instance, use the
/// postfix optional chaining operator (postfix `?`). The following example uses
/// optional chaining to access the `hasSuffix(_:)` method on a `String?`
/// instance.
///
///     if imagePaths["star"]?.hasSuffix(".png") == true {
///         print("The star image is in PNG format")
///     }
///     // Prints "The star image is in PNG format"
///
/// Using the Nil-Coalescing Operator
/// ---------------------------------
///
/// Use the nil-coalescing operator (`??`) to supply a default value in case
/// the `Optional` instance is `nil`. Here a default path is supplied for an
/// image that is missing from `imagePaths`.
///
///     let defaultImagePath = "/images/default.png"
///     let heartPath = imagePaths["heart"] ?? defaultImagePath
///     print(heartPath)
///     // Prints "/images/default.png"
///
/// The `??` operator also works with another `Optional` instance on the
/// right-hand side. As a result, you can chain multiple `??` operators
/// together.
///
///     let shapePath = imagePaths["cir"] ?? imagePaths["squ"] ?? defaultImagePath
///     print(shapePath)
///     // Prints "/images/default.png"
///
/// Unconditional Unwrapping
/// ------------------------
///
/// When you're certain that an instance of `Optional` contains a value, you
/// can unconditionally unwrap the value by using the forced
/// unwrap operator (postfix `!`). For example, the result of the failable `Int`
/// initializer is unconditionally unwrapped in the example below.
///
///     let number = Int("42")!
///     print(number)
///     // Prints "42"
///
/// You can also perform unconditional optional chaining by using the postfix
/// `!` operator.
///
///     let isPNG = imagePaths["star"]!.hasSuffix(".png")
///     print(isPNG)
///     // Prints "true"
///
/// Unconditionally unwrapping a `nil` instance with `!` triggers a runtime
/// error.

/// `Optional` 是一个类型，表示一个包装的值或 `nil`，即无值。
///
/// 在使用可选值时，无论是否实际输入 `Optional` 这个关键字，你都会使用 `Optional` 类型。
/// Swift 的类型系统通常会显示被包装类型的名称后面跟着一个问号（`?`），而不是显示完整的类型名称。
/// 例如，如果一个变量的类型是 `Int?`，那只是另一种写法，实际上等同于 `Optional<Int>`。为了方便阅读和编写代码，通常采用简短形式。
///
/// 在下面的代码示例中，`shortForm` 和 `longForm` 的类型是相同的：
///
///     let shortForm: Int? = Int("42")
///     let longForm: Optional<Int> = Int("42")
///
/// `Optional` 类型是一个枚举类型，有两种情况。`Optional.none` 等价于 `nil` 字面量。`Optional.some(Wrapped)` 存储了一个包装的值。例如：
///
///     let number: Int? = Optional.some(42)
///     let noNumber: Int? = Optional.none
///     print(noNumber == nil)
///     // 输出 "true"
///
/// 在许多上下文中，你必须先解包 `Optional` 实例的值才能使用它。由于 Swift 提供了多种安全解包可选值的方式，你可以选择适合你编写清晰、简洁代码的方式。
///
/// 下面的示例使用以下图像名称和文件路径的字典：
///
///     let imagePaths = ["star": "/glyphs/star.png",
///                       "portrait": "/images/content/portrait.jpg",
///                       "spacer": "/images/shared/spacer.gif"]
///
/// 使用键获取字典的值会返回一个可选值，因此 `imagePaths["star"]` 的类型是 `Optional<String>`，或者以首选方式编写为 `String?`。
///
/// 可选绑定
/// -------
///
/// 要将 `Optional` 实例的包装值条件绑定到一个新变量中，请使用可选绑定控制结构之一，包括 `if let`、`guard let` 和 `switch`。
///
///     if let starPath = imagePaths["star"] {
///         print("星星图像位于 '\(starPath)'")
///     } else {
///         print("找不到星星图像")
///     }
///     // 输出 "星星图像位于 '/glyphs/star.png'"
///
/// 可选链
/// ------
///
/// 要安全地访问包装实例的属性和方法，请使用后缀可选链操作符（后缀 `?`）。以下示例使用可选链访问 `String?` 实例上的 `hasSuffix(_:)` 方法。
///
///     if imagePaths["star"]?.hasSuffix(".png") == true {
///         print("星星图像是 PNG 格式")
///     }
///     // 输出 "星星图像是 PNG 格式"
///
/// 使用空合并运算符
/// ----------------
///
/// 使用空合并运算符（`??`）在 `Optional` 实例为 `nil` 时提供默认值。例如，在 `imagePaths` 中找不到图像时，提供默认路径。
///
///     let defaultImagePath = "/images/default.png"
///     let heartPath = imagePaths["heart"] ?? defaultImagePath
///     print(heartPath)
///     // 输出 "/images/default.png"
///
/// `??` 运算符也适用于右侧的另一个 `Optional` 实例。因此，可以将多个 `??` 运算符链接在一起。
///
///     let shapePath = imagePaths["cir"] ?? imagePaths["squ"] ?? defaultImagePath
///     print(shapePath)
///     // 输出 "/images/default.png"
///
/// 无条件解包
/// ----------
///
/// 当你确信 `Optional` 实例包含一个值时，你可以使用强制解包运算符（后缀 `!`）来无条件解包该值。例如，在下面的示例中，可失败的 `Int` 初始化器的结果被无条件解包。
///
///     let number = Int("42")!
///     print(number)
///     // 输出 "42"
///
/// 你也可以通过使用后缀 `!` 运算符执行无条件可选链。
///
///     let isPNG = imagePaths["star"]!.hasSuffix(".png")
///     print(isPNG)
///     // 输出 "true"
///
/// 使用 `!` 运算符对 `nil` 实例进行无条件解包会触发运行时错误。
@frozen
public enum Optional<Wrapped>: ExpressibleByNilLiteral {
    /// The absence of a value.
    ///
    /// In code, the absence of a value is typically written using the `nil`
    /// literal rather than the explicit `.none` enumeration case.
    case none
    
    /// The presence of a value, stored as `Wrapped`.
    case some(Wrapped)
    
    /// Creates an instance that stores the given value.
    public init(_ some: Wrapped) { self = .some(some) }
    
    /// Evaluates the given closure when this `Optional` instance is not `nil`,
    /// passing the unwrapped value as a parameter.
    ///
    /// Use the `map` method with a closure that returns a non-optional value.
    /// This example performs an arithmetic operation on an
    /// optional integer.
    ///
    ///     let possibleNumber: Int? = Int("42")
    ///     let possibleSquare = possibleNumber.map { $0 * $0 }
    ///     print(possibleSquare)
    ///     // Prints "Optional(1764)"
    ///
    ///     let noNumber: Int? = nil
    ///     let noSquare = noNumber.map { $0 * $0 }
    ///     print(noSquare)
    ///     // Prints "nil"
    ///
    /// - Parameter transform: A closure that takes the unwrapped value
    ///   of the instance.
    /// - Returns: The result of the given closure. If this instance is `nil`,
    ///   returns `nil`.
    /// 当此 `Optional` 实例不为 `nil` 时，评估给定的闭包，并将解包后的值作为参数传递。
    ///
    /// 使用带有返回非可选值的闭包的 `map` 方法。以下示例对可选整数执行算术运算。
    ///
    ///     let possibleNumber: Int? = Int("42")
    ///     let possibleSquare = possibleNumber.map { $0 * $0 }
    ///     print(possibleSquare)
    ///     // 输出 "Optional(1764)"
    ///
    ///     let noNumber: Int? = nil
    ///     let noSquare = noNumber.map { $0 * $0 }
    ///     print(noSquare)
    ///     // 输出 "nil"
    ///
    /// - Parameter transform: 一个闭包，接受实例的解包值。
    /// - Returns: 给定闭包的结果。如果此实例为 `nil`，则返回 `nil`。
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
    
    /// Evaluates the given closure when this `Optional` instance is not `nil`,
    /// passing the unwrapped value as a parameter.
    ///
    /// Use the `flatMap` method with a closure that returns an optional value.
    /// This example performs an arithmetic operation with an optional result on
    /// an optional integer.
    ///
    ///     let possibleNumber: Int? = Int("42")
    ///     let nonOverflowingSquare = possibleNumber.flatMap { x -> Int? in
    ///         let (result, overflowed) = x.multipliedReportingOverflow(by: x)
    ///         return overflowed ? nil : result
    ///     }
    ///     print(nonOverflowingSquare)
    ///     // Prints "Optional(1764)"
    ///
    /// - Parameter transform: A closure that takes the unwrapped value
    ///   of the instance.  
    /// - Returns: The result of the given closure. If this instance is `nil`,
    ///   returns `nil`.
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
    
    /// Creates an instance initialized with `nil`.
    ///
    /// Do not call this initializer directly. It is used by the compiler when you
    /// initialize an `Optional` instance with a `nil` literal. For example:
    ///
    ///     var i: Index? = nil
    ///
    /// In this example, the assignment to the `i` variable calls this
    /// initializer behind the scenes.
    @_transparent
    public init(nilLiteral: ()) {
        self = .none
    }
    
    /// The wrapped value of this instance, unwrapped without checking whether
    /// the instance is `nil`.
    ///
    /// The `unsafelyUnwrapped` property provides the same value as the forced
    /// unwrap operator (postfix `!`). However, in optimized builds (`-O`), no
    /// check is performed to ensure that the current instance actually has a
    /// value. Accessing this property in the case of a `nil` value is a serious
    /// programming error and could lead to undefined behavior or a runtime
    /// error.
    ///
    /// In debug builds (`-Onone`), the `unsafelyUnwrapped` property has the same
    /// behavior as using the postfix `!` operator and triggers a runtime error
    /// if the instance is `nil`.
    ///
    /// The `unsafelyUnwrapped` property is recommended over calling the
    /// `unsafeBitCast(_:)` function because the property is more restrictive
    /// and because accessing the property still performs checking in debug
    /// builds.
    ///
    /// - Warning: This property trades safety for performance.  Use
    ///   `unsafelyUnwrapped` only when you are confident that this instance
    ///   will never be equal to `nil` and only after you've tried using the
    ///   postfix `!` operator.
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
    
    /// - Returns: `unsafelyUnwrapped`.
    ///
    /// This version is for internal stdlib use; it avoids any checking
    /// overhead for users, even in Debug builds.
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
    
    /// Takes the wrapped value being stored in this instance and returns it while
    /// also setting the instance to `nil`. If there is no value being stored in
    /// this instance, this returns `nil` instead.
    ///
    ///     var numberOfShoes: Int? = 34
    ///
    ///     if let numberOfShoes = numberOfShoes.take() {
    ///       print(numberOfShoes)
    ///       // Prints "34"
    ///     }
    ///
    ///     print(numberOfShoes)
    ///     // Prints "nil"
    ///
    /// - Returns: The wrapped value being stored in this instance. If this
    ///   instance is `nil`, returns `nil`.
    internal mutating func _take() -> Wrapped? {
        switch self {
        case .some(let wrapped):
            self = nil
            return wrapped
        case .none:
            return nil
        }
    }
}

extension Optional: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case .some(let value):
#if !SWIFT_STDLIB_STATIC_PRINT
            var result = "Optional("
            debugPrint(value, terminator: "", to: &result)
            result += ")"
            return result
#else
            return "(optional printing not available)"
#endif
        case .none:
            return "nil"
        }
    }
}

#if SWIFT_ENABLE_REFLECTION
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
#endif

@_transparent
public // COMPILER_INTRINSIC
func _diagnoseUnexpectedNilOptional(_filenameStart: Builtin.RawPointer,
                                    _filenameLength: Builtin.Word,
                                    _filenameIsASCII: Builtin.Int1,
                                    _line: Builtin.Word,
                                    _isImplicitUnwrap: Builtin.Int1) {
    // Cannot use _preconditionFailure as the file and line info would not be
    // printed.
    if Bool(_isImplicitUnwrap) {
        _preconditionFailure(
            "Unexpectedly found nil while implicitly unwrapping an Optional value",
            file: StaticString(_start: _filenameStart,
                               utf8CodeUnitCount: _filenameLength,
                               isASCII: _filenameIsASCII),
            line: UInt(_line))
    } else {
        _preconditionFailure(
            "Unexpectedly found nil while unwrapping an Optional value",
            file: StaticString(_start: _filenameStart,
                               utf8CodeUnitCount: _filenameLength,
                               isASCII: _filenameIsASCII),
            line: UInt(_line))
    }
}

extension Optional: Equatable where Wrapped: Equatable {
    /// Returns a Boolean value indicating whether two optional instances are
    /// equal.
    ///
    /// Use this equal-to operator (`==`) to compare any two optional instances of
    /// a type that conforms to the `Equatable` protocol. The comparison returns
    /// `true` if both arguments are `nil` or if the two arguments wrap values
    /// that are equal. Conversely, the comparison returns `false` if only one of
    /// the arguments is `nil` or if the two arguments wrap values that are not
    /// equal.
    ///
    ///     let group1 = [1, 2, 3, 4, 5]
    ///     let group2 = [1, 3, 5, 7, 9]
    ///     if group1.first == group2.first {
    ///         print("The two groups start the same.")
    ///     }
    ///     // Prints "The two groups start the same."
    ///
    /// You can also use this operator to compare a non-optional value to an
    /// optional that wraps the same type. The non-optional value is wrapped as an
    /// optional before the comparison is made. In the following example, the
    /// `numberToMatch` constant is wrapped as an optional before comparing to the
    /// optional `numberFromString`:
    ///
    ///     let numberToFind: Int = 23
    ///     let numberFromString: Int? = Int("23")      // Optional(23)
    ///     if numberToFind == numberFromString {
    ///         print("It's a match!")
    ///     }
    ///     // Prints "It's a match!"
    ///
    /// An instance that is expressed as a literal can also be used with this
    /// operator. In the next example, an integer literal is compared with the
    /// optional integer `numberFromString`. The literal `23` is inferred as an
    /// `Int` instance and then wrapped as an optional before the comparison is
    /// performed.
    ///
    ///     if 23 == numberFromString {
    ///         print("It's a match!")
    ///     }
    ///     // Prints "It's a match!"
    ///
    /// - Parameters:
    ///   - lhs: An optional value to compare.
    ///   - rhs: Another optional value to compare.
    @inlinable
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
    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
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

// Enable pattern matching against the nil literal, even if the element type
// isn't equatable.
@frozen
public struct _OptionalNilComparisonType: ExpressibleByNilLiteral {
    /// Create an instance initialized with `nil`.
    @_transparent
    public init(nilLiteral: ()) {
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

extension Optional: Sendable where Wrapped: Sendable { }
