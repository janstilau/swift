/*
 这个类, 是专门用来进行手动管理 Swift 对象内存的.
 直接传入一个 Swift 对象, 然后可以调用 retained, release 这两个方法.
 SWIFT 对象的地址, 其实是没有办法直接变为 Pointer 的. 专门使用这个类, 提供了抽取这个地址的方案.
 */

@frozen
public struct Unmanaged<Instance: AnyObject> {
    
    // 这个类, 管理的数据, 就是一个 AnyObject 的指针. 并且使用 unowned(unsafe) 这种内存管理方案.
    // 但是, 这个类不对外暴露对象的接口, 而是统一使用类方法, 来获取对象, 然后进行调用.
    
    @usableFromInline
    internal unowned(unsafe) var _value: Instance
    
    // 构造方法, 仅仅是做值的记录.
    // 没有任何的内存管理语义代码的触发.
    @usableFromInline @_transparent
    internal init(_private: Instance) { _value = _private }
    
    /// Unsafely turns an opaque C pointer into an unmanaged class reference.
    ///
    /// This operation does not change reference counts.
    ///
    ///     let str: CFString = Unmanaged.fromOpaque(ptr).takeUnretainedValue()
    ///
    /// - Parameter value: An opaque C pointer.
    /// - Returns: An unmanaged class reference to `value`.
    @_transparent
    public static func fromOpaque(
    @_nonEphemeral _ value: UnsafeRawPointer
    ) -> Unmanaged {
        return Unmanaged(_private: unsafeBitCast(value, to: Instance.self))
    }
    
    /// Unsafely converts an unmanaged class reference to a pointer.
    ///
    /// This operation does not change reference counts.
    ///
    ///     let str0 = "boxcar" as CFString
    ///     let bits = Unmanaged.passUnretained(str0)
    ///     let ptr = bits.toOpaque()
    ///
    /// - Returns: An opaque pointer to the value of this unmanaged reference.
    @_transparent
    public func toOpaque() -> UnsafeMutableRawPointer {
        return unsafeBitCast(_value, to: UnsafeMutableRawPointer.self)
    }
    
    /// Creates an unmanaged reference with an unbalanced retain.
    ///
    /// The instance passed as `value` will leak if nothing eventually balances
    /// the retain.
    ///
    /// This is useful when passing an object to an API which Swift does not know
    /// the ownership rules for, but you know that the API expects you to pass
    /// the object at +1.
    ///
    /// - Parameter value: A class instance.
    /// - Returns: An unmanaged reference to the object passed as `value`.
    @_transparent
    public static func passRetained(_ value: Instance) -> Unmanaged {
        return Unmanaged(_private: value).retain()
    }
    
    /// Creates an unmanaged reference without performing an unbalanced
    /// retain.
    ///
    /// This is useful when passing a reference to an API which Swift
    /// does not know the ownership rules for, but you know that the
    /// API expects you to pass the object at +0.
    ///
    ///     CFArraySetValueAtIndex(.passUnretained(array), i,
    ///                            .passUnretained(object))
    ///
    /// - Parameter value: A class instance.
    /// - Returns: An unmanaged reference to the object passed as `value`.
    @_transparent
    public static func passUnretained(_ value: Instance) -> Unmanaged {
        return Unmanaged(_private: value)
    }
    
    /// Gets the value of this unmanaged reference as a managed
    /// reference without consuming an unbalanced retain of it.
    ///
    /// This is useful when a function returns an unmanaged reference
    /// and you know that you're not responsible for releasing the result.
    ///
    /// - Returns: The object referenced by this `Unmanaged` instance.
    @_transparent // unsafe-performance
    public func takeUnretainedValue() -> Instance {
        return _value
    }
    
    /// Gets the value of this unmanaged reference as a managed
    /// reference and consumes an unbalanced retain of it.
    ///
    /// This is useful when a function returns an unmanaged reference
    /// and you know that you're responsible for releasing the result.
    ///
    /// - Returns: The object referenced by this `Unmanaged` instance.
    @_transparent // unsafe-performance
    public func takeRetainedValue() -> Instance {
        let result = _value
        release()
        return result
    }
    
    /// Gets the value of the unmanaged referenced as a managed reference without
    /// consuming an unbalanced retain of it and passes it to the closure. Asserts
    /// that there is some other reference ('the owning reference') to the
    /// instance referenced by the unmanaged reference that guarantees the
    /// lifetime of the instance for the duration of the
    /// '_withUnsafeGuaranteedRef' call.
    ///
    /// NOTE: You are responsible for ensuring this by making the owning
    /// reference's lifetime fixed for the duration of the
    /// '_withUnsafeGuaranteedRef' call.
    ///
    /// Violation of this will incur undefined behavior.
    ///
    /// A lifetime of a reference 'the instance' is fixed over a point in the
    /// program if:
    ///
    /// * There exists a global variable that references 'the instance'.
    ///
    ///   import Foundation
    ///   var globalReference = Instance()
    ///   func aFunction() {
    ///      point()
    ///   }
    ///
    /// Or if:
    ///
    /// * There is another managed reference to 'the instance' whose life time is
    ///   fixed over the point in the program by means of 'withExtendedLifetime'
    ///   dynamically closing over this point.
    ///
    ///   var owningReference = Instance()
    ///   ...
    ///   withExtendedLifetime(owningReference) {
    ///       point($0)
    ///   }
    ///
    /// Or if:
    ///
    /// * There is a class, or struct instance ('owner') whose lifetime is fixed
    ///   at the point and which has a stored property that references
    ///   'the instance' for the duration of the fixed lifetime of the 'owner'.
    ///
    ///  class Owned {
    ///  }
    ///
    ///  class Owner {
    ///    final var owned: Owned
    ///
    ///    func foo() {
    ///        withExtendedLifetime(self) {
    ///            doSomething(...)
    ///        } // Assuming: No stores to owned occur for the dynamic lifetime of
    ///          //           the withExtendedLifetime invocation.
    ///    }
    ///
    ///    func doSomething() {
    ///       // both 'self' and 'owned''s lifetime is fixed over this point.
    ///       point(self, owned)
    ///    }
    ///  }
    ///
    /// The last rule applies transitively through a chain of stored references
    /// and nested structs.
    ///
    /// Examples:
    ///
    ///   var owningReference = Instance()
    ///   ...
    ///   withExtendedLifetime(owningReference) {
    ///     let u = Unmanaged.passUnretained(owningReference)
    ///     for i in 0 ..< 100 {
    ///       u._withUnsafeGuaranteedRef {
    ///         $0.doSomething()
    ///       }
    ///     }
    ///   }
    ///
    ///  class Owner {
    ///    final var owned: Owned
    ///
    ///    func foo() {
    ///        withExtendedLifetime(self) {
    ///            doSomething(Unmanaged.passUnretained(owned))
    ///        }
    ///    }
    ///
    ///    func doSomething(_ u: Unmanaged<Owned>) {
    ///      u._withUnsafeGuaranteedRef {
    ///        $0.doSomething()
    ///      }
    ///    }
    ///  }
    @inlinable // unsafe-performance
    @_transparent
    public func _withUnsafeGuaranteedRef<Result>(
        _ body: (Instance) throws -> Result
    ) rethrows -> Result {
        var tmp = self
        // Builtin.convertUnownedUnsafeToGuaranteed expects to have a base value
        // that the +0 value depends on. In this case, we are assuming that is done
        // for us opaquely already. So, the builtin will emit a mark_dependence on a
        // trivial object. The optimizer knows to eliminate that so we do not have
        // any overhead from this.
        let fakeBase: Int? = nil
        return try body(Builtin.convertUnownedUnsafeToGuaranteed(fakeBase,
                                                                 &tmp._value))
    }
    
    
    // 在这几个方法里面, 调用了系统的方法, 来实现真正的内存管理的操作 .
    /// Performs an unbalanced retain of the object.
    @_transparent
    public func retain() -> Unmanaged {
        Builtin.retain(_value)
        return self
    }
    
    /// Performs an unbalanced release of the object.
    @_transparent
    public func release() {
        Builtin.release(_value)
    }
    
#if _runtime(_ObjC)
    /// Performs an unbalanced autorelease of the object.
    @_transparent
    public func autorelease() -> Unmanaged {
        Builtin.autorelease(_value)
        return self
    }
#endif
}

extension Unmanaged: Sendable where Instance: Sendable { }

