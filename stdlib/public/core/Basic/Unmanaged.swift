/*
 这个类, 是专门用来进行手动管理 Swift 对象内存的.
 直接传入一个 Swift 对象, 然后可以调用 retained, release 这两个方法.
 */
/*
 一个 Swift 对象, 是无法直接变为指针的, let p = Person()
 &p 转化得到的, 指针变量的地址值.
 
 要想得到 Swift 对象堆空间的内存地址, 必须使用 Unmanaged 进行转化.
 */

public struct Unmanaged<Instance: AnyObject> {
    
    // 存一下指针的值, 不进行内存管理
    internal unowned(unsafe) var _value: Instance
    
    // Unmanaged 的构造方法, 不会被使用, 使用 static 的静态方法, 来进行生成, 然后调用.
    // 这个初始化方法, 是 Internal 的, 在外界是无法使用的. 通过这种方式, 使得 Unmanaged 对象的生成, 只能是通过
    internal init(_private: Instance) { _value = _private }
    
    public static func fromOpaque( _ value: UnsafeRawPointer ) -> Unmanaged {
        // 强暴的进行类型转化后, 进行初始化
        return Unmanaged(_private: unsafeBitCast(value, to: Instance.self))
    }
    
    // 强暴的, 将自己管理的指针, 进行类型转化.
    public func toOpaque() -> UnsafeMutableRawPointer {
        return unsafeBitCast(_value, to: UnsafeMutableRawPointer.self)
    }
    
    // +1 了, 一定要记得 -1
    public static func passRetained(_ value: Instance) -> Unmanaged {
        return Unmanaged(_private: value).retain()
    }
    
    public static func passUnretained(_ value: Instance) -> Unmanaged {
        return Unmanaged(_private: value)
    }
    
    public func takeUnretainedValue() -> Instance {
        return _value
    }
    
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
    // 在 Swift 里面, 只能通过 Unmanaged 来进行内存引用计数的变化.
    public func retain() -> Unmanaged {
        Builtin.retain(_value)
        return self
    }
    
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

