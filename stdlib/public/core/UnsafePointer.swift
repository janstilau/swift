@frozen // unsafe-performance
public struct UnsafePointer<Pointee>: _Pointer {
    
    // 对于 _Pointer 的适配
    public typealias Distance = Int
    public let _rawValue: Builtin.RawPointer
    public init(_ _rawValue: Builtin.RawPointer) {
        self._rawValue = _rawValue
    }
    
    // 就是调用 Swift 版本的 delete 方法.
    @inlinable
    public func deallocate() {
        Builtin.deallocRaw(_rawValue, (-1)._builtinWordValue, (0)._builtinWordValue)
    }
    
    @inlinable // unsafe-performance
    public var pointee: Pointee {
        @_transparent unsafeAddress {
            return self
        }
    }
  
    // 临时的把 rawPointer 转化成为 T 类型, 结束之后再转化回去.
    public func withMemoryRebound<T, Result>(to type: T.Type,
                                             capacity count: Int,
                                             _ body: (UnsafePointer<T>) throws -> Result
    ) rethrows -> Result {
        Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
        defer {
            Builtin.bindMemory(_rawValue, count._builtinWordValue, Pointee.self)
        }
        return try body(UnsafePointer<T>(_rawValue))
    }
    
    // 这里是使用了 _Pointer 里面的 + 运算符, 里面会考虑到类型的长度.
    public subscript(i: Int) -> Pointee {
        @_transparent
        unsafeAddress {
            return self + i
        }
    }
    
    internal static var _max: UnsafePointer {
        return UnsafePointer(
            bitPattern: 0 as Int &- MemoryLayout<Pointee>.stride
        )._unsafelyUnwrappedUnchecked
    }
}


// 这个类型, 增加了赋值相关的运算.
public struct UnsafeMutablePointer<Pointee>: _Pointer {
    public typealias Distance = Int
    public let _rawValue: Builtin.RawPointer
    public init(_ _rawValue: Builtin.RawPointer) {
        self._rawValue = _rawValue
    }
    public init(mutating other: UnsafePointer<Pointee>) {
        self._rawValue = other._rawValue
    }
    public init?(mutating other: UnsafePointer<Pointee>?) {
        guard let unwrapped = other else { return nil }
        self.init(mutating: unwrapped)
    }
    public init(_ other: UnsafeMutablePointer<Pointee>) {
        self._rawValue = other._rawValue
    }
    public init?(_ other: UnsafeMutablePointer<Pointee>?) {
        guard let unwrapped = other else { return nil }
        self.init(unwrapped)
    }
    
    
    // Alloc 放到了 MutablePointer 类型里面.
    // 基本上和我们自己写 alloc 代码的逻辑相符, 只不过, 类型的长度计算, 包裹在了函数的内部.
    public static func allocate(capacity count: Int)
    -> UnsafeMutablePointer<Pointee> {
        let size = MemoryLayout<Pointee>.stride * count
        // For any alignment <= _minAllocationAlignment, force alignment = 0.
        // This forces the runtime's "aligned" allocation path so that
        // deallocation does not require the original alignment.
        //
        // The runtime guarantees:
        //
        // align == 0 || align > _minAllocationAlignment:
        //   Runtime uses "aligned allocation".
        //
        // 0 < align <= _minAllocationAlignment:
        //   Runtime may use either malloc or "aligned allocation".
        var align = Builtin.alignof(Pointee.self)
        if Int(align) <= _minAllocationAlignment() {
            align = (0)._builtinWordValue
        }
        let rawPtr = Builtin.allocRaw(size._builtinWordValue, align)
        Builtin.bindMemory(rawPtr, count._builtinWordValue, Pointee.self)
        return UnsafeMutablePointer(rawPtr)
    }
    
    public func deallocate() {
        // Passing zero alignment to the runtime forces "aligned
        // deallocation". Since allocation via `UnsafeMutable[Raw][Buffer]Pointer`
        // always uses the "aligned allocation" path, this ensures that the
        // runtime's allocation and deallocation paths are compatible.
        Builtin.deallocRaw(_rawValue, (-1)._builtinWordValue, (0)._builtinWordValue)
    }
    
    /// Accesses the instance referenced by this pointer.
    ///
    /// When reading from the `pointee` property, the instance referenced by this
    /// pointer must already be initialized. When `pointee` is used as the left
    /// side of an assignment, the instance must be initialized or this
    /// pointer's `Pointee` type must be a trivial type.
    ///
    /// Do not assign an instance of a nontrivial type through `pointee` to
    /// uninitialized memory. Instead, use an initializing method, such as
    /// `initialize(to:count:)`.
    @inlinable // unsafe-performance
    public var pointee: Pointee {
        @_transparent unsafeAddress {
            return UnsafePointer(self)
        }
        @_transparent nonmutating unsafeMutableAddress {
            return self
        }
    }
    
    /*
     如果是值语义的 Pointee, 就是简单的值的复制的事情,
     如果是引用语义的, 就是指针的复制.
     Swfit 里面, Copy 就是简单的值的复制.
     但是 VWT 里面, 会考虑到引用计数的修改.
     至于拷贝构造这种复杂的东西, 不需要.
     */
    public func initialize(repeating repeatedValue: Pointee, count: Int) {
        // FIXME: add tests (since the `count` has been added)
        _debugPrecondition(count >= 0,
                           "UnsafeMutablePointer.initialize(repeating:count:): negative count")
        // Must not use `initializeFrom` with a `Collection` as that will introduce
        // a cycle.
        for offset in 0..<count {
            Builtin.initialize(repeatedValue, (self + offset)._rawValue)
        }
    }
    
    /// Initializes this pointer's memory with a single instance of the given value.
    ///
    /// The destination memory must be uninitialized or the pointer's `Pointee`
    /// must be a trivial type. After a call to `initialize(to:)`, the
    /// memory referenced by this pointer is initialized. Calling this method is
    /// roughly equivalent to calling `initialize(repeating:count:)` with a
    /// `count` of 1.
    ///
    /// - Parameters:
    ///   - value: The instance to initialize this pointer's pointee to.
    @inlinable
    public func initialize(to value: Pointee) {
        Builtin.initialize(value, self._rawValue)
    }
    
    /// Retrieves and returns the referenced instance, returning the pointer's
    /// memory to an uninitialized state.
    ///
    /// Calling the `move()` method on a pointer `p` that references memory of
    /// type `T` is equivalent to the following code, aside from any cost and
    /// incidental side effects of copying and destroying the value:
    ///
    ///     let value: T = {
    ///         defer { p.deinitialize(count: 1) }
    ///         return p.pointee
    ///     }()
    ///
    /// The memory referenced by this pointer must be initialized. After calling
    /// `move()`, the memory is uninitialized.
    ///
    /// - Returns: The instance referenced by this pointer.
    @inlinable
    public func move() -> Pointee {
        return Builtin.take(_rawValue)
    }
    
    /// Replaces this pointer's memory with the specified number of
    /// consecutive copies of the given value.
    ///
    /// The region of memory starting at this pointer and covering `count`
    /// instances of the pointer's `Pointee` type must be initialized or
    /// `Pointee` must be a trivial type. After calling
    /// `assign(repeating:count:)`, the region is initialized.
    ///
    /// - Parameters:
    ///   - repeatedValue: The instance to assign this pointer's memory to.
    ///   - count: The number of consecutive copies of `newValue` to assign.
    ///     `count` must not be negative.
    @inlinable
    public func assign(repeating repeatedValue: Pointee, count: Int) {
        _debugPrecondition(count >= 0, "UnsafeMutablePointer.assign(repeating:count:) with negative count")
        for i in 0..<count {
            self[i] = repeatedValue
        }
    }
    
    /// Replaces this pointer's initialized memory with the specified number of
    /// instances from the given pointer's memory.
    ///
    /// The region of memory starting at this pointer and covering `count`
    /// instances of the pointer's `Pointee` type must be initialized or
    /// `Pointee` must be a trivial type. After calling
    /// `assign(from:count:)`, the region is initialized.
    ///
    /// - Note: Returns without performing work if `self` and `source` are equal.
    ///
    /// - Parameters:
    ///   - source: A pointer to at least `count` initialized instances of type
    ///     `Pointee`. The memory regions referenced by `source` and this
    ///     pointer may overlap.
    ///   - count: The number of instances to copy from the memory referenced by
    ///     `source` to this pointer's memory. `count` must not be negative.
    @inlinable
    public func assign(from source: UnsafePointer<Pointee>, count: Int) {
        _debugPrecondition(
            count >= 0, "UnsafeMutablePointer.assign with negative count")
        if UnsafePointer(self) < source || UnsafePointer(self) >= source + count {
            // assign forward from a disjoint or following overlapping range.
            Builtin.assignCopyArrayFrontToBack(
                Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
            // This builtin is equivalent to:
            // for i in 0..<count {
            //   self[i] = source[i]
            // }
        }
        else if UnsafePointer(self) != source {
            // assign backward from a non-following overlapping range.
            Builtin.assignCopyArrayBackToFront(
                Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
            // This builtin is equivalent to:
            // var i = count-1
            // while i >= 0 {
            //   self[i] = source[i]
            //   i -= 1
            // }
        }
    }
    
    /// Moves instances from initialized source memory into the uninitialized
    /// memory referenced by this pointer, leaving the source memory
    /// uninitialized and the memory referenced by this pointer initialized.
    ///
    /// The region of memory starting at this pointer and covering `count`
    /// instances of the pointer's `Pointee` type must be uninitialized or
    /// `Pointee` must be a trivial type. After calling
    /// `moveInitialize(from:count:)`, the region is initialized and the memory
    /// region `source..<(source + count)` is uninitialized.
    ///
    /// - Parameters:
    ///   - source: A pointer to the values to copy. The memory region
    ///     `source..<(source + count)` must be initialized. The memory regions
    ///     referenced by `source` and this pointer may overlap.
    ///   - count: The number of instances to move from `source` to this
    ///     pointer's memory. `count` must not be negative.
    @inlinable
    public func moveInitialize(from source: UnsafeMutablePointer, count: Int) {
        _debugPrecondition(
            count >= 0, "UnsafeMutablePointer.moveInitialize with negative count")
        if self < source || self >= source + count {
            // initialize forward from a disjoint or following overlapping range.
            Builtin.takeArrayFrontToBack(
                Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
            // This builtin is equivalent to:
            // for i in 0..<count {
            //   (self + i).initialize(to: (source + i).move())
            // }
        }
        else {
            // initialize backward from a non-following overlapping range.
            Builtin.takeArrayBackToFront(
                Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
            // This builtin is equivalent to:
            // var src = source + count
            // var dst = self + count
            // while dst != self {
            //   (--dst).initialize(to: (--src).move())
            // }
        }
    }
    
    /// Initializes the memory referenced by this pointer with the values
    /// starting at the given pointer.
    ///
    /// The region of memory starting at this pointer and covering `count`
    /// instances of the pointer's `Pointee` type must be uninitialized or
    /// `Pointee` must be a trivial type. After calling
    /// `initialize(from:count:)`, the region is initialized.
    ///
    /// - Parameters:
    ///   - source: A pointer to the values to copy. The memory region
    ///     `source..<(source + count)` must be initialized. The memory regions
    ///     referenced by `source` and this pointer must not overlap.
    ///   - count: The number of instances to move from `source` to this
    ///     pointer's memory. `count` must not be negative.
    @inlinable
    public func initialize(from source: UnsafePointer<Pointee>, count: Int) {
        _debugPrecondition(
            count >= 0, "UnsafeMutablePointer.initialize with negative count")
        _debugPrecondition(
            UnsafePointer(self) + count <= source ||
                source + count <= UnsafePointer(self),
            "UnsafeMutablePointer.initialize overlapping range")
        Builtin.copyArray(
            Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
        // This builtin is equivalent to:
        // for i in 0..<count {
        //   (self + i).initialize(to: source[i])
        // }
    }
    
    /// Replaces the memory referenced by this pointer with the values
    /// starting at the given pointer, leaving the source memory uninitialized.
    ///
    /// The region of memory starting at this pointer and covering `count`
    /// instances of the pointer's `Pointee` type must be initialized or
    /// `Pointee` must be a trivial type. After calling
    /// `moveAssign(from:count:)`, the region is initialized and the memory
    /// region `source..<(source + count)` is uninitialized.
    ///
    /// - Parameters:
    ///   - source: A pointer to the values to copy. The memory region
    ///     `source..<(source + count)` must be initialized. The memory regions
    ///     referenced by `source` and this pointer must not overlap.
    ///   - count: The number of instances to move from `source` to this
    ///     pointer's memory. `count` must not be negative.
    @inlinable
    public func moveAssign(from source: UnsafeMutablePointer, count: Int) {
        _debugPrecondition(
            count >= 0, "UnsafeMutablePointer.moveAssign(from:) with negative count")
        _debugPrecondition(
            self + count <= source || source + count <= self,
            "moveAssign overlapping range")
        Builtin.assignTakeArray(
            Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
        // These builtins are equivalent to:
        // for i in 0..<count {
        //   self[i] = (source + i).move()
        // }
    }
    
    /// Deinitializes the specified number of values starting at this pointer.
    ///
    /// The region of memory starting at this pointer and covering `count`
    /// instances of the pointer's `Pointee` type must be initialized. After
    /// calling `deinitialize(count:)`, the memory is uninitialized, but still
    /// bound to the `Pointee` type.
    ///
    /// - Parameter count: The number of instances to deinitialize. `count` must
    ///   not be negative.
    /// - Returns: A raw pointer to the same address as this pointer. The memory
    ///   referenced by the returned raw pointer is still bound to `Pointee`.
    @inlinable
    @discardableResult
    public func deinitialize(count: Int) -> UnsafeMutableRawPointer {
        _debugPrecondition(count >= 0, "UnsafeMutablePointer.deinitialize with negative count")
        // FIXME: optimization should be implemented, where if the `count` value
        // is 1, the `Builtin.destroy(Pointee.self, _rawValue)` gets called.
        Builtin.destroyArray(Pointee.self, _rawValue, count._builtinWordValue)
        return UnsafeMutableRawPointer(self)
    }
    
    /// Executes the given closure while temporarily binding the specified number
    /// of instances to the given type.
    ///
    /// Use this method when you have a pointer to memory bound to one type and
    /// you need to access that memory as instances of another type. Accessing
    /// memory as a type `T` requires that the memory be bound to that type. A
    /// memory location may only be bound to one type at a time, so accessing
    /// the same memory as an unrelated type without first rebinding the memory
    /// is undefined.
    ///
    /// The region of memory starting at this pointer and covering `count`
    /// instances of the pointer's `Pointee` type must be initialized.
    ///
    /// The following example temporarily rebinds the memory of a `UInt64`
    /// pointer to `Int64`, then accesses a property on the signed integer.
    ///
    ///     let uint64Pointer: UnsafeMutablePointer<UInt64> = fetchValue()
    ///     let isNegative = uint64Pointer.withMemoryRebound(to: Int64.self) { ptr in
    ///         return ptr.pointee < 0
    ///     }
    ///
    /// Because this pointer's memory is no longer bound to its `Pointee` type
    /// while the `body` closure executes, do not access memory using the
    /// original pointer from within `body`. Instead, use the `body` closure's
    /// pointer argument to access the values in memory as instances of type
    /// `T`.
    ///
    /// After executing `body`, this method rebinds memory back to the original
    /// `Pointee` type.
    ///
    /// - Note: Only use this method to rebind the pointer's memory to a type
    ///   with the same size and stride as the currently bound `Pointee` type.
    ///   To bind a region of memory to a type that is a different size, convert
    ///   the pointer to a raw pointer and use the `bindMemory(to:capacity:)`
    ///   method.
    ///
    /// - Parameters:
    ///   - type: The type to temporarily bind the memory referenced by this
    ///     pointer. The type `T` must be the same size and be layout compatible
    ///     with the pointer's `Pointee` type.
    ///   - count: The number of instances of `Pointee` to bind to `type`.
    ///   - body: A closure that takes a mutable typed pointer to the
    ///     same memory as this pointer, only bound to type `T`. The closure's
    ///     pointer argument is valid only for the duration of the closure's
    ///     execution. If `body` has a return value, that value is also used as
    ///     the return value for the `withMemoryRebound(to:capacity:_:)` method.
    /// - Returns: The return value, if any, of the `body` closure parameter.
    @inlinable
    public func withMemoryRebound<T, Result>(to type: T.Type, capacity count: Int,
                                             _ body: (UnsafeMutablePointer<T>) throws -> Result
    ) rethrows -> Result {
        Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
        defer {
            Builtin.bindMemory(_rawValue, count._builtinWordValue, Pointee.self)
        }
        return try body(UnsafeMutablePointer<T>(_rawValue))
    }
    
    /// Accesses the pointee at the specified offset from this pointer.
    ///
    /// For a pointer `p`, the memory at `p + i` must be initialized when reading
    /// the value by using the subscript. When the subscript is used as the left
    /// side of an assignment, the memory at `p + i` must be initialized or
    /// the pointer's `Pointee` type must be a trivial type.
    ///
    /// Do not assign an instance of a nontrivial type through the subscript to
    /// uninitialized memory. Instead, use an initializing method, such as
    /// `initialize(to:count:)`.
    ///
    /// - Parameter i: The offset from this pointer at which to access an
    ///   instance, measured in strides of the pointer's `Pointee` type.
    @inlinable
    public subscript(i: Int) -> Pointee {
        @_transparent
        unsafeAddress {
            return UnsafePointer(self + i)
        }
        @_transparent
        nonmutating unsafeMutableAddress {
            return self + i
        }
    }
    
    @inlinable // unsafe-performance
    internal static var _max: UnsafeMutablePointer {
        return UnsafeMutablePointer(
            bitPattern: 0 as Int &- MemoryLayout<Pointee>.stride
        )._unsafelyUnwrappedUnchecked
    }
}
