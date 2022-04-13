/*
 其实, 就是存储一个 bit 的值.
 
 Bool 类型的专门创建, 使得编译器可以使用类型系统, 来包装代码的含义.
 在需要判断的语法里面, 不能再是 非 0 为 True. 可以大大的减少 Bug. 必须显示的进行 Bool 值的构建, 这是 Clean Code 的表示. 
 */
public struct Bool: Sendable {
    
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
    // 增加了操作符的适配, 返回一个新值, 不改变原有值.
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
