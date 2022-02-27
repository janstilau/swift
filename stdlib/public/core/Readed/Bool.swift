/*
 Swift 里面, 打破了, 非 0 为 True 的这一个规则. 作为判断逻辑的地方, 必须是 Bool 值 .
 */

public struct Bool: Sendable {
    
    // 最终, 在内存上, 就占用一个 Bit 的空间.
    internal var _value: Builtin.Int1
    
    public init() {
        let zero: Int8 = 0
        self._value = Builtin.trunc_Int8_Int1(zero._value)
    }
    
    internal init(_ v: Builtin.Int1) { self._value = v }
    
    public init(_ value: Bool) {
        self = value
    }
    
    // 这种, 参数下一行展示, 是 Swfit 官方推荐的写法.
    public static func random<T: RandomNumberGenerator>(
        using generator: inout T
    ) -> Bool {
        return (generator.next() >> 17) & 1 == 0
    }
    
    // 直接使用 SystemRandomNumberGenerator 做协议实现对象.
    public static func random() -> Bool {
        var g = SystemRandomNumberGenerator()
        return Bool.random(using: &g)
    }
}

extension Bool: _ExpressibleByBuiltinBooleanLiteral, ExpressibleByBooleanLiteral {
    
    public init(_builtinBooleanLiteral value: Builtin.Int1) {
        self._value = value
    }
    
    public init(booleanLiteral value: Bool) {
        self = value
    }
}

// 在一个 Extension 里面, 进行一个 Protocol 的实现.
// 这样的组织代码的方式, 会更加的清晰.
extension Bool: CustomStringConvertible {
    
    public var description: String {
        return self ? "true" : "false"
    }
}

// 相等性判断, 就是内存值的判断.
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

//===----------------------------------------------------------------------===//
// Operators
//===----------------------------------------------------------------------===//

extension Bool {
    public static prefix func ! (a: Bool) -> Bool {
        return Bool(Builtin.xor_Int1(a._value, true._value))
    }
}

// Bool 的运算操作符, 在这, 变为了函数.
// 本质上, 其他语言的运算操作符, 就是函数.
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
