public protocol _Pointer
: Hashable, Strideable, CustomDebugStringConvertible, CustomReflectable {
        
    // 指针之间的距离, 就是 Int 值.
    typealias Distance = Int
    associatedtype Pointee
    
    // 里面的值, 就是一个 void* 指针而已.
    var _rawValue: Builtin.RawPointer { get }
    init(_ _rawValue: Builtin.RawPointer)
}

// 各种其他类型的初始化方法, 其实就是找到 raw value, 然后调用 Builtin.RawPointer 为参数的初始化方法.
extension _Pointer {
    public init(_ from: OpaquePointer) {
        self.init(from._rawValue)
    }
    public init?(_ from: OpaquePointer?) {
        guard let unwrapped = from else { return nil }
        self.init(unwrapped)
    }
    public init?(bitPattern: Int) {
        if bitPattern == 0 { return nil }
        self.init(Builtin.inttoptr_Word(bitPattern._builtinWordValue))
    }
    public init?(bitPattern: UInt) {
        if bitPattern == 0 { return nil }
        self.init(Builtin.inttoptr_Word(bitPattern._builtinWordValue))
    }
    public init(_ other: Self) {
        self.init(other._rawValue)
    }
    public init?(_ other: Self?) {
        guard let unwrapped = other else { return nil }
        self.init(unwrapped._rawValue)
    }
}

// 相等性, 可比较性, 都是建立在 rawValue 的基础上
// 这些都建立在 _Pointer 的基础上, 任何实际类型, 都不要写重复的代码逻辑了
// rawValue 的逻辑, 就是 C 风格语言的指针逻辑. 所以, 语言其实逃脱不了最终计算机模型的.
extension _Pointer /*: Equatable */ {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
    }
}
extension _Pointer /*: Comparable */ {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return Bool(Builtin.cmp_ult_RawPointer(lhs._rawValue, rhs._rawValue))
    }
}

extension _Pointer /*: Strideable*/ {
    @_transparent
    public func successor() -> Self {
        return advanced(by: 1)
    }
    
    @_transparent
    public func predecessor() -> Self {
        return advanced(by: -1)
    }
    
    // 就是指针相减, 然后除以指针指向类型的宽度.
    // 这里是 Strideable 的实现, 所以也就绑定了 Int 就是 Strideable 的 Associate type : Stride
    @_transparent
    public func distance(to end: Self) -> Int {
        return
            Int(Builtin.sub_Word(Builtin.ptrtoint_Word(end._rawValue),
                                 Builtin.ptrtoint_Word(_rawValue)))
            / MemoryLayout<Pointee>.stride
    }
    
    // 可以看到 advanced 这个函数是考虑了类型的长度的
    // 几个参数是 起始点, 长度, 以及这个指针的类型信息, 而这个类型信息里面, 一定是有着类型的长度的.
    public func advanced(by n: Int) -> Self {
        return Self(Builtin.gep_Word(
                        self._rawValue, n._builtinWordValue, Pointee.self))
    }
}

// 哈希, 就是直接使用 rawPointer 的 Int 值.
// 这其实和 C 风格的概念是一样的.
extension _Pointer /*: Hashable */ {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(UInt(bitPattern: self))
    }
    
    @inlinable
    public func _rawHashValue(seed: Int) -> Int {
        return Hasher._hash(seed: seed, UInt(bitPattern: self))
    }
}

extension _Pointer /*: CustomDebugStringConvertible */ {
    public var debugDescription: String {
        return _rawPointerToString(_rawValue)
    }
}

extension _Pointer /*: CustomReflectable */ {
    public var customMirror: Mirror {
        let ptrValue = UInt64(
            bitPattern: Int64(Int(Builtin.ptrtoint_Word(_rawValue))))
        return Mirror(self, children: ["pointerValue": ptrValue])
    }
}

// 提供了 Int 值和 Pointer 协议之间的转化
extension Int {
    public init<P: _Pointer>(bitPattern pointer: P?) {
        if let pointer = pointer {
            self = Int(Builtin.ptrtoint_Word(pointer._rawValue))
        } else {
            self = 0
        }
    }
}

// 提供了 Int 值和 Pointer 协议之间的转化
extension UInt {
    public init<P: _Pointer>(bitPattern pointer: P?) {
        if let pointer = pointer {
            self = UInt(Builtin.ptrtoint_Word(pointer._rawValue))
        } else {
            self = 0
        }
    }
}

extension Strideable where Self: _Pointer {
    @_transparent
    public static func + (lhs: Self, rhs: Self.Stride) -> Self {
        return lhs.advanced(by: rhs)
    }
    
    @_transparent
    public static func + (lhs: Self.Stride, rhs: Self) -> Self {
        return rhs.advanced(by: lhs)
    }
    
    @_transparent
    public static func - (lhs: Self, rhs: Self.Stride) -> Self {
        return lhs.advanced(by: -rhs)
    }
    
    @_transparent
    public static func - (lhs: Self, rhs: Self) -> Self.Stride {
        return rhs.distance(to: lhs)
    }
    
    @_transparent
    public static func += (lhs: inout Self, rhs: Self.Stride) {
        lhs = lhs.advanced(by: rhs)
    }
    
    @_transparent
    public static func -= (lhs: inout Self, rhs: Self.Stride) {
        lhs = lhs.advanced(by: -rhs)
    }
}

/// Derive a pointer argument from a convertible pointer type.
@_transparent
public // COMPILER_INTRINSIC
func _convertPointerToPointerArgument<
    FromPointer: _Pointer,
    ToPointer: _Pointer
>(_ from: FromPointer) -> ToPointer {
    return ToPointer(from._rawValue)
}

/// Derive a pointer argument from the address of an inout parameter.
@_transparent
public // COMPILER_INTRINSIC
func _convertInOutToPointerArgument<
    ToPointer: _Pointer
>(_ from: Builtin.RawPointer) -> ToPointer {
    return ToPointer(from)
}

/// Derive a pointer argument from a value array parameter.
///
/// This always produces a non-null pointer, even if the array doesn't have any
/// storage.
@_transparent
public // COMPILER_INTRINSIC
func _convertConstArrayToPointerArgument<
    FromElement,
    ToPointer: _Pointer
>(_ arr: [FromElement]) -> (AnyObject?, ToPointer) {
    let (owner, opaquePointer) = arr._cPointerArgs()
    
    let validPointer: ToPointer
    if let addr = opaquePointer {
        validPointer = ToPointer(addr._rawValue)
    } else {
        let lastAlignedValue = ~(MemoryLayout<FromElement>.alignment - 1)
        let lastAlignedPointer = UnsafeRawPointer(bitPattern: lastAlignedValue)!
        validPointer = ToPointer(lastAlignedPointer._rawValue)
    }
    return (owner, validPointer)
}

/// Derive a pointer argument from an inout array parameter.
///
/// This always produces a non-null pointer, even if the array's length is 0.
@_transparent
public // COMPILER_INTRINSIC
func _convertMutableArrayToPointerArgument<
    FromElement,
    ToPointer: _Pointer
>(_ a: inout [FromElement]) -> (AnyObject?, ToPointer) {
    // TODO: Putting a canary at the end of the array in checked builds might
    // be a good idea
    
    // Call reserve to force contiguous storage.
    a.reserveCapacity(0)
    _debugPrecondition(a._baseAddressIfContiguous != nil || a.isEmpty)
    
    return _convertConstArrayToPointerArgument(a)
}

/// Derive a UTF-8 pointer argument from a value string parameter.
public // COMPILER_INTRINSIC
func _convertConstStringToUTF8PointerArgument<
    ToPointer: _Pointer
>(_ str: String) -> (AnyObject?, ToPointer) {
    let utf8 = Array(str.utf8CString)
    return _convertConstArrayToPointerArgument(utf8)
}
