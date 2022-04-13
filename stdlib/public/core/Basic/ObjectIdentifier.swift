/*
    A unique identifier for a class instance or metatype.
    对于引用语义的对象来说, 这是一个包装体.
    之所以要这样一个包装, 是因为这个对象, Hashable, Equalable.
 
    Swift 是没有指针这个概念的, 所以, 一个引用对象, 其实是没有办法直接当做 Key 来使用的.
    但是, 其实它就是一个指针. 所以, 专门有一个类型来做这个事情. 当我们想要使用引用对象的指针的概念的时候, 显示地使用 ObjectIdentifier, 来达到
    Equatable
    Comparable
    Hashable
    的效果
 */
    
public struct ObjectIdentifier: Sendable {
    // 实际上, 就是指针的比对.
    // 里面存储的是, 每一引用对象的指针值.
    internal let _value: Builtin.RawPointer
    
    public init(_ x: AnyObject) {
        // 直接存储的就是指针值.
        // 根据 Module 的限制. Builtin 值能在源码中使用.
        self._value = Builtin.bridgeToRawPointer(x)
    }
    
    public init(_ x: Any.Type) {
        // Any.Type, 一定是一个引用值.
        // 每一个对象, 都有一个 meta 对象存在, 这种对象, 内存里面只存在一份就可以了.
        // struct, enum 的对象, 单独占用空间, 但是他们的类型信息是共享的. 所以, 这里是直接进行指针的转换.
        self._value = unsafeBitCast(x, to: Builtin.RawPointer.self)
    }
}

extension ObjectIdentifier: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "ObjectIdentifier(\(_rawPointerToString(_value)))"
    }
}

// 各种 Protocol 的实现, 其实就是 Int 的操作了. 
extension ObjectIdentifier: Equatable {
    public static func == (x: ObjectIdentifier, y: ObjectIdentifier) -> Bool {
        return Bool(Builtin.cmp_eq_RawPointer(x._value, y._value))
    }
}

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
