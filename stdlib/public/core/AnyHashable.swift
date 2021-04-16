// 如果, 一个类型, 有着自己的对于 anyHash 的实现, 就会用他自己的实现.
// 这个主要用在了 AnyHashable 的初始化里面了.
// Array, set, dict 都实现了这个协议. 这是一个内部协议. 标准库的使用者, 不应该使用.
// 不过这是一个思路, 算是标准库对于扩展点的一个使用.
// 在我们自己写库的时候可以借鉴. 一个私有协议, 可以带来性能的提升, 同时, 定义一个默认的实现.
// 这在 Collection 的 SubSequence 等里面, 也有使用.
public protocol _HasCustomAnyHashableRepresentation {
    __consuming func _toCustomAnyHashable() -> AnyHashable?
}

internal protocol _AnyHashableBox {
    var _canonicalBox: _AnyHashableBox { get }
    func _isEqual(to box: _AnyHashableBox) -> Bool?
    func _rawHashValue(_seed: Int) -> Int
    
    var _base: Any { get }
    func _unbox<T: Hashable>() -> T?
    func _downCastConditional<T>(into result: UnsafeMutablePointer<T>) -> Bool
    
    //
    var _hashValue: Int { get }
    func _hash(into hasher: inout Hasher)
}

extension _AnyHashableBox {
    var _canonicalBox: _AnyHashableBox {
        return self
    }
}

// 默认的对于 _AnyHashableBox 的实现.
internal struct _ConcreteHashableBox<Base: Hashable>: _AnyHashableBox {
    internal var _baseHashable: Base
    
    internal init(_ base: Base) {
        self._baseHashable = base
    }
    
    // 这里, 原来是转为协议, 然后转为下面的 _ConcreteHashableBox<T>
    // 用 as? _ConcreteHashableBox<T> 也没有问题.
    internal func _unbox<T: Hashable>() -> T? {
        //        return (self as _AnyHashableBox as? _ConcreteHashableBox<T>)?._baseHashable
        return (self as? _ConcreteHashableBox<T>)?._baseHashable
    }
    
    // _baseHashable 并没有限定, 必须是类, 所以使用的 ==
    internal func _isEqual(to rhs: _AnyHashableBox) -> Bool? {
        if let rhs: Base = rhs._unbox() {
            return _baseHashable == rhs
        }
        return nil
    }
    
    internal var _hashValue: Int {
        return _baseHashable.hashValue
    }
    
    func _hash(into hasher: inout Hasher) {
        _baseHashable.hash(into: &hasher)
    }
    
    func _rawHashValue(_seed: Int) -> Int {
        return _baseHashable._rawHashValue(seed: _seed)
    }
    
    internal var _base: Any {
        return _baseHashable
    }
    
    func _downCastConditional<T>(into result: UnsafeMutablePointer<T>) -> Bool {
        guard let value = _baseHashable as? T else { return false }
        result.initialize(to: value)
        return true
    }
}

/// A type-erased hashable value.
///
/// The AnyHashable type forwards equality comparisons and hashing operations to an underlying hashable value,
/// hiding the type of the wrapped value.
///
/// The `AnyHashable` type forwards equality comparisons and hashing operations
/// to an underlying hashable value, hiding its specific underlying type.
///
/// You can store mixed-type keys in dictionaries and other collections that
/// require `Hashable` conformance by wrapping mixed-type keys in
/// `AnyHashable` instances:
///
///     let descriptions: [AnyHashable: Any] = [
///         AnyHashable("😄"): "emoji",
///         AnyHashable(42): "an Int",
///         AnyHashable(Int8(43)): "an Int8",
///         AnyHashable(Set(["a", "b"])): "a set of strings"
///     ]
///     print(descriptions[AnyHashable(42)]!)      // prints "an Int"
///     print(descriptions[AnyHashable(43)])       // prints "nil"
///     print(descriptions[AnyHashable(Int8(43))]!) // prints "an Int8"
///     print(descriptions[AnyHashable(Set(["a", "b"]))]!) // prints "a set of strings"
//
public struct AnyHashable {
    internal var _box: _AnyHashableBox
    
    // 这个函数, 就是 _AnyHashableBox 这层抽象存在的意义所在了.
    // 实现了 _HasCustomAnyHashableRepresentation 的类, 需要返回一个 AnyHashable
    // 但是, 其实 AnyHashable 的实现是固定的, 是一个 struct, 能够自定义的, 只有是自定义 _AnyHashableBox, 然后传递给 AnyHashable 作为里面 _base 的初值.
    // 因为, 有了这层替换的要求, 才专门建立了一个抽象层在里面.
    // 在我们自己写 anyProtocol 的时候, 可以去掉这层抽象.
    internal init(_box box: _AnyHashableBox) {
        self._box = box
    }
    
    /// Creates a type-erased hashable value that wraps the given instance.
    ///
    /// - Parameter base: A hashable value to wrap.
    public init<H: Hashable>(_ base: H) {
        if let custom =
            (base as? _HasCustomAnyHashableRepresentation)?._toCustomAnyHashable() {
            self = custom
            return
        }
        
        // 默认, 就是使用 _ConcreteHashableBox
        self.init(_box: _ConcreteHashableBox(false)) // Dummy value
        _makeAnyHashableUpcastingToHashableBaseType(
            base,
            storingResultInto: &self)
    }
    
    internal init<H: Hashable>(_usingDefaultRepresentationOf base: H) {
        self._box = _ConcreteHashableBox(base)
    }
    
    public var base: Any {
        return _box._base
    }
    
    /// Perform a downcast directly on the internal boxed representation.
    ///
    /// This avoids the intermediate re-boxing we would get if we just did
    /// a downcast on `base`.
    internal
    func _downCastConditional<T>(into result: UnsafeMutablePointer<T>) -> Bool {
        // Attempt the downcast.
        if _box._downCastConditional(into: result) { return true }
        
        #if _runtime(_ObjC)
        // Bridge to Objective-C and then attempt the cast from there.
        // FIXME: This should also work without the Objective-C runtime.
        if let value = _bridgeAnythingToObjectiveC(_box._base) as? T {
            result.initialize(to: value)
            return true
        }
        #endif
        
        return false
    }
}

extension AnyHashable: Equatable {
    /// Returns a Boolean value indicating whether two type-erased hashable
    /// instances wrap the same type and value.
    ///
    /// Two instances of `AnyHashable` compare as equal if and only if the
    /// underlying types have the same conformance to the `Equatable` protocol
    /// and the underlying values compare as equal.
    ///
    /// - Parameters:
    ///   - lhs: A type-erased hashable value.
    ///   - rhs: Another type-erased hashable value.
    public static func == (lhs: AnyHashable, rhs: AnyHashable) -> Bool {
        return lhs._box._canonicalBox._isEqual(to: rhs._box._canonicalBox) ?? false
    }
}

extension AnyHashable: Hashable {
    /// The hash value.
    public var hashValue: Int {
        return _box._canonicalBox._hashValue
    }
    
    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
    public func hash(into hasher: inout Hasher) {
        _box._canonicalBox._hash(into: &hasher)
    }
    
    public func _rawHashValue(seed: Int) -> Int {
        return _box._canonicalBox._rawHashValue(_seed: seed)
    }
}

extension AnyHashable: CustomStringConvertible {
    public var description: String {
        return String(describing: base)
    }
}

extension AnyHashable: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "AnyHashable(" + String(reflecting: base) + ")"
    }
}

extension AnyHashable: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(
            self,
            children: ["value": base])
    }
}

/// Returns a default (non-custom) representation of `self`
/// as `AnyHashable`.
///
/// Completely ignores the `_HasCustomAnyHashableRepresentation`
/// conformance, if it exists.
/// Called by AnyHashableSupport.cpp.
@_silgen_name("_swift_makeAnyHashableUsingDefaultRepresentation")
internal func _makeAnyHashableUsingDefaultRepresentation<H: Hashable>(
    of value: H,
    storingResultInto result: UnsafeMutablePointer<AnyHashable>
) {
    result.pointee = AnyHashable(_usingDefaultRepresentationOf: value)
}

/// Provided by AnyHashable.cpp.
@_silgen_name("_swift_makeAnyHashableUpcastingToHashableBaseType")
internal func _makeAnyHashableUpcastingToHashableBaseType<H: Hashable>(
    _ value: H,
    storingResultInto result: UnsafeMutablePointer<AnyHashable>
)

@inlinable
public // COMPILER_INTRINSIC
func _convertToAnyHashable<H: Hashable>(_ value: H) -> AnyHashable {
    return AnyHashable(value)
}

/// Called by the casting machinery.
@_silgen_name("_swift_convertToAnyHashableIndirect")
internal func _convertToAnyHashableIndirect<H: Hashable>(
    _ value: H,
    _ target: UnsafeMutablePointer<AnyHashable>
) {
    target.initialize(to: AnyHashable(value))
}

/// Called by the casting machinery.
@_silgen_name("_swift_anyHashableDownCastConditionalIndirect")
internal func _anyHashableDownCastConditionalIndirect<T>(
    _ value: UnsafePointer<AnyHashable>,
    _ target: UnsafeMutablePointer<T>
) -> Bool {
    return value.pointee._downCastConditional(into: target)
}
