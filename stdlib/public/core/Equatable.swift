// 相等这件事, 在 Swift 里面, 专门用了一个协议来进行表示.

public protocol Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool
}

extension Equatable {
  public static func != (lhs: Self, rhs: Self) -> Bool {
    return !(lhs == rhs)
  }
}

//===----------------------------------------------------------------------===//
// Reference comparison
//===----------------------------------------------------------------------===//

/// Returns a Boolean value indicating whether two references point to the same
/// object instance.
///
/// This operator tests whether two instances have the same identity, not the
/// same value. For value equality, see the equal-to operator (`==`) and the
/// `Equatable` protocol.
///
/// The following example defines an `IntegerRef` type, an integer type with
/// reference semantics.
///
///     class IntegerRef: Equatable {
///         let value: Int
///         init(_ value: Int) {
///             self.value = value
///         }
///     }
///
///     func ==(lhs: IntegerRef, rhs: IntegerRef) -> Bool {
///         return lhs.value == rhs.value
///     }
///
/// Because `IntegerRef` is a class, its instances can be compared using the
/// identical-to operator (`===`). In addition, because `IntegerRef` conforms
/// to the `Equatable` protocol, instances can also be compared using the
/// equal-to operator (`==`).
///
///     let a = IntegerRef(10)
///     let b = a
///     print(a == b)
///     // Prints "true"
///     print(a === b)
///     // Prints "true"
///
/// The identical-to operator (`===`) returns `false` when comparing two
/// references to different object instances, even if the two instances have
/// the same value.
///
///     let c = IntegerRef(10)
///     print(a == c)
///     // Prints "true"
///     print(a === c)
///     // Prints "false"
///
/// - Parameters:
///   - lhs: A reference to compare.
///   - rhs: Another reference to compare.
@inlinable // trivial-implementation
public func === (lhs: AnyObject?, rhs: AnyObject?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return ObjectIdentifier(l) == ObjectIdentifier(r)
  case (nil, nil):
    return true
  default:
    return false
  }
}

@inlinable // trivial-implementation
public func !== (lhs: AnyObject?, rhs: AnyObject?) -> Bool {
  return !(lhs === rhs)
}


