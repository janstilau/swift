/*
    A unique identifier for a class instance or metatype.
    对于引用语义的对象来说, 这是一个包装体.
    之所以要这样一个包装, 是因为这个对象, Hashable, Equalable.
 */
    
public struct ObjectIdentifier: Sendable {
    // 实际上, 就是指针的比对.
    // 里面存储的是, 每一引用对象的指针值.
    internal let _value: Builtin.RawPointer
    
    public init(_ x: AnyObject) {
        // 直接存储的就是指针值.
        self._value = Builtin.bridgeToRawPointer(x)
    }
    
    public init(_ x: Any.Type) {
        self._value = unsafeBitCast(x, to: Builtin.RawPointer.self)
    }
}

extension ObjectIdentifier: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "ObjectIdentifier(\(_rawPointerToString(_value)))"
    }
}

// 相等性的判断, 是指针 Int 值的判断.
extension ObjectIdentifier: Equatable {
    public static func == (x: ObjectIdentifier, y: ObjectIdentifier) -> Bool {
        return Bool(Builtin.cmp_eq_RawPointer(x._value, y._value))
    }
}

// 比大小的逻辑, 是指针的 Int 值的比较大小.
extension ObjectIdentifier: Comparable {
    public static func < (lhs: ObjectIdentifier, rhs: ObjectIdentifier) -> Bool {
        return UInt(bitPattern: lhs) < UInt(bitPattern: rhs)
    }
}

extension ObjectIdentifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(Int(Builtin.ptrtoint_Word(_value)))
    }
}

// 提供了一个 Int 值到 ObjectIdentifier 的转换
extension UInt {
    public init(bitPattern objectID: ObjectIdentifier) {
        self.init(Builtin.ptrtoint_Word(objectID._value))
    }
}

extension Int {
    public init(bitPattern objectID: ObjectIdentifier) {
        self.init(bitPattern: UInt(bitPattern: objectID))
    }
}
