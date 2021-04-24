
// 实际上, 这个类就是对于指针的操作.
// 出现这个类的原因, 就是将指针的操作封装, 主要是 compare, equeal, hash 的能力的封装.
// 真正的实现方式, 就是对于指针的操作.

public struct ObjectIdentifier {
  @usableFromInline // trivial-implementation
  internal let _value: Builtin.RawPointer

  public init(_ x: AnyObject) {
    self._value = Builtin.bridgeToRawPointer(x)
  }

  public init(_ x: Any.Type) {
    self._value = unsafeBitCast(x, to: Builtin.RawPointer.self)
  }
}

// 下面三个经常对于指针的操作, 都是建立在操作 _value, 这个存储的指针的基础上的.
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
