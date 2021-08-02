//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
// C Primitive Types
//===----------------------------------------------------------------------===//

/// The C 'char' type.
///
/// This will be the same as either `CSignedChar` (in the common
/// case) or `CUnsignedChar`, depending on the platform.
public typealias CChar = Int8

/// The C 'unsigned char' type.
public typealias CUnsignedChar = UInt8

/// The C 'unsigned short' type.
public typealias CUnsignedShort = UInt16

/// The C 'unsigned int' type.
public typealias CUnsignedInt = UInt32

/// The C 'unsigned long' type.
#if os(Windows) && arch(x86_64)
public typealias CUnsignedLong = UInt32
#else
public typealias CUnsignedLong = UInt
#endif

/// The C 'unsigned long long' type.
public typealias CUnsignedLongLong = UInt64

/// The C 'signed char' type.
public typealias CSignedChar = Int8

/// The C 'short' type.
public typealias CShort = Int16

/// The C 'int' type.
public typealias CInt = Int32

/// The C 'long' type.
#if os(Windows) && arch(x86_64)
public typealias CLong = Int32
#else
public typealias CLong = Int
#endif

/// The C 'long long' type.
public typealias CLongLong = Int64

/// The C 'float' type.
public typealias CFloat = Float

/// The C 'double' type.
public typealias CDouble = Double

/// The C 'long double' type.
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// On Darwin, long double is Float80 on x86, and Double otherwise.
#if arch(x86_64) || arch(i386)
public typealias CLongDouble = Float80
#else
public typealias CLongDouble = Double
#endif
#elseif os(Windows)
// On Windows, long double is always Double.
public typealias CLongDouble = Double
#elseif os(Linux)
// On Linux/x86, long double is Float80.
// TODO: Fill in definitions for additional architectures as needed. IIRC
// armv7 should map to Double, but arm64 and ppc64le should map to Float128,
// which we don't yet have in Swift.
#if arch(x86_64) || arch(i386)
public typealias CLongDouble = Float80
#endif
// TODO: Fill in definitions for other OSes.
#if arch(s390x)
// On s390x '-mlong-double-64' option with size of 64-bits makes the
// Long Double type equivalent to Double type.
public typealias CLongDouble = Double
#endif
#elseif os(Android)
// On Android, long double is Float128 for AAPCS64, which we don't have yet in
// Swift (SR-9072); and Double for ARMv7.
#if arch(arm)
public typealias CLongDouble = Double
#endif
#endif

// FIXME: Is it actually UTF-32 on Darwin?
//
/// The C++ 'wchar_t' type.
public typealias CWideChar = Unicode.Scalar

// FIXME: Swift should probably have a UTF-16 type other than UInt16.
//
/// The C++11 'char16_t' type, which has UTF-16 encoding.
public typealias CChar16 = UInt16

/// The C++11 'char32_t' type, which has UTF-32 encoding.
public typealias CChar32 = Unicode.Scalar

/// The C '_Bool' and C++ 'bool' type.
public typealias CBool = Bool

/*
 C 指针的表现.
 就是 void *
 如果 Builtin.RawPointer 被暴露出来, 那么所有的就是直接操作 Builtin.RawPointer 了.
 但是这样, 操作就不在类型的限制之下了.
 各种概念, 都被特定的类型所束缚着. 相应的代价就是, 要提供大量的转化函数.
 */
@frozen
public struct OpaquePointer {
    // 内存部分, 就是一个 void * 指针.
    internal var _rawValue: Builtin.RawPointer
    
    internal init(_ v: Builtin.RawPointer) {
        self._rawValue = v
    }
    
    // 用 Int 值来表现这个指针, 因为 Int 是跟随操作系统的字长的, 所以, 一定可以表示.
    public init?(bitPattern: Int) {
        if bitPattern == 0 { return nil }
        self._rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
    }
    
    public init?(bitPattern: UInt) {
        if bitPattern == 0 { return nil }
        self._rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
    }

    // 用 Swfit 的指针类型初始化.
    public init<T>(_ from: UnsafePointer<T>) {
        self._rawValue = from._rawValue
    }
    
    public init?<T>(_ from: UnsafePointer<T>?) {
        guard let unwrapped = from else { return nil }
        self.init(unwrapped)
    }
    
    // 用 Swift 可变指针类型初始化.
    public init<T>(_ from: UnsafeMutablePointer<T>) {
        self._rawValue = from._rawValue
    }
    
    public init?<T>(_ from: UnsafeMutablePointer<T>?) {
        guard let unwrapped = from else { return nil }
        self.init(unwrapped)
    }
}

// 相等性比较, 就是原始指针的比较.
extension OpaquePointer: Equatable {
    @inlinable // unsafe-performance
    public static func == (lhs: OpaquePointer, rhs: OpaquePointer) -> Bool {
        return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
    }
}

// Hash 就是拿到原始指针进行 Hash
extension OpaquePointer: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(Int(Builtin.ptrtoint_Word(_rawValue)))
    }
}

extension OpaquePointer: CustomDebugStringConvertible {
    public var debugDescription: String {
        return _rawPointerToString(_rawValue)
    }
}

// 提供指针到 Int 值的转变.
extension Int {
    public init(bitPattern pointer: OpaquePointer?) {
        self.init(bitPattern: UnsafeRawPointer(pointer))
    }
}

// 提供指针到 Int 值的转变.
extension UInt {
    public init(bitPattern pointer: OpaquePointer?) {
        self.init(bitPattern: UnsafeRawPointer(pointer))
    }
}

/// A wrapper around a C `va_list` pointer.
#if arch(arm64) && !(os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(Windows))
@frozen
public struct CVaListPointer {
    @usableFromInline // unsafe-performance
    internal var _value: (__stack: UnsafeMutablePointer<Int>?,
                          __gr_top: UnsafeMutablePointer<Int>?,
                          __vr_top: UnsafeMutablePointer<Int>?,
                          __gr_off: Int32,
                          __vr_off: Int32)
    
    @inlinable // unsafe-performance
    public // @testable
    init(__stack: UnsafeMutablePointer<Int>?,
         __gr_top: UnsafeMutablePointer<Int>?,
         __vr_top: UnsafeMutablePointer<Int>?,
         __gr_off: Int32,
         __vr_off: Int32) {
        _value = (__stack, __gr_top, __vr_top, __gr_off, __vr_off)
    }
}

extension CVaListPointer: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "(\(_value.__stack.debugDescription), " +
            "\(_value.__gr_top.debugDescription), " +
            "\(_value.__vr_top.debugDescription), " +
            "\(_value.__gr_off), " +
            "\(_value.__vr_off))"
    }
}

#else

@frozen
public struct CVaListPointer {
    @usableFromInline // unsafe-performance
    internal var _value: UnsafeMutableRawPointer
    
    @inlinable // unsafe-performance
    public // @testable
    init(_fromUnsafeMutablePointer from: UnsafeMutableRawPointer) {
        _value = from
    }
}

extension CVaListPointer: CustomDebugStringConvertible {
    /// A textual representation of the pointer, suitable for debugging.
    public var debugDescription: String {
        return _value.debugDescription
    }
}

#endif

@inlinable
internal func _memcpy(
    dest destination: UnsafeMutableRawPointer,
    src: UnsafeRawPointer,
    size: UInt
) {
    let dest = destination._rawValue
    let src = src._rawValue
    let size = UInt64(size)._value
    Builtin.int_memcpy_RawPointer_RawPointer_Int64(
        dest, src, size,
        /*volatile:*/ false._value)
}

/// Copy `count` bytes of memory from `src` into `dest`.
///
/// The memory regions `source..<source + count` and
/// `dest..<dest + count` may overlap.
@inlinable
internal func _memmove(
    dest destination: UnsafeMutableRawPointer,
    src: UnsafeRawPointer,
    size: UInt
) {
    let dest = destination._rawValue
    let src = src._rawValue
    let size = UInt64(size)._value
    Builtin.int_memmove_RawPointer_RawPointer_Int64(
        dest, src, size,
        /*volatile:*/ false._value)
}
