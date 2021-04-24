public struct Bool {
    internal var _value: Builtin.Int1 // 内部, 其实就一个 bit 来存储内存里面的值.
    // 因为 Swift 不会强转, 所以, 要写出各种 init 方法, 来处理类型之间的转化
    public init() {
        let zero: Int8 = 0
        self._value = Builtin.trunc_Int8_Int1(zero._value)
    }
    internal init(_ v: Builtin.Int1) { self._value = v }
    public init(_ value: Bool) {
        self = value
    }
    public static func random<T: RandomNumberGenerator>(
        using generator: inout T
    ) -> Bool {
        return (generator.next() >> 17) & 1 == 0
    }
    // 提供一个默认的实现, 这是好的 Api 设计的很重要的标准.
    public static func random() -> Bool {
        var g = SystemRandomNumberGenerator()
        return Bool.random(using: &g)
    }
}

extension Bool: _ExpressibleByBuiltinBooleanLiteral, ExpressibleByBooleanLiteral {
    @_transparent
    public init(_builtinBooleanLiteral value: Builtin.Int1) {
        self._value = value
    }
    public init(booleanLiteral value: Bool) {
        self = value
    }
}

extension Bool: CustomStringConvertible {
    public var description: String {
        return self ? "true" : "false"
    }
}

extension Bool: Equatable {
    public static func == (lhs: Bool, rhs: Bool) -> Bool {
        return Bool(Builtin.cmp_eq_Int1(lhs._value, rhs._value))
    }
}

extension Bool: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine((self ? 1 : 0) as UInt8)
    }
}

// Swift 里面, 操作符就是全局的, 因为操作符里面有类型的限制, 所以, 不会出现 ambiguous 的情况
extension Bool {
    public static prefix func ! (a: Bool) -> Bool {
        return Bool(Builtin.xor_Int1(a._value, true._value))
    }
}

extension Bool {
    public static func && (lhs: Bool, rhs: @autoclosure () throws -> Bool) rethrows
    -> Bool {
        return lhs ? try rhs() : false
    }
    public static func || (lhs: Bool, rhs: @autoclosure () throws -> Bool) rethrows
    -> Bool {
        return lhs ? true : try rhs()
    }
}

extension Bool {
    public mutating func toggle() {
        self = !self
    }
}
