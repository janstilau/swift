import SwiftShims

// 把权限控制语句单独成行也是没有问题的.
// 可以猜测, 里面的实现, assert_configuration 也就是去读取 Mach-0 中的配置相关信息.
public
func _isDebugAssertConfiguration() -> Bool {
    // The values for the assert_configuration call are:
    // 0: Debug
    // 1: Release
    // 2: Fast
    return Int32(Builtin.assert_configuration()) == 0
}

internal func _isReleaseAssertConfiguration() -> Bool {
    // The values for the assert_configuration call are:
    // 0: Debug
    // 1: Release
    // 2: Fast
    return Int32(Builtin.assert_configuration()) == 1
}

public
func _isFastAssertConfiguration() -> Bool {
    // The values for the assert_configuration call are:
    // 0: Debug
    // 1: Release
    // 2: Fast
    return Int32(Builtin.assert_configuration()) == 2
}

@_transparent
public // @testable
func _isStdlibInternalChecksEnabled() -> Bool {
#if INTERNAL_CHECKS_ENABLED
    return true
#else
    return false
#endif
}

@usableFromInline @_transparent
internal func _fatalErrorFlags() -> UInt32 {
    // The current flags are:
    // (1 << 0): Report backtrace on fatal error
#if os(iOS) || os(tvOS) || os(watchOS)
    return 0
#else
    return _isDebugAssertConfiguration() ? 1 : 0
#endif
}

/// This function should be used only in the implementation of user-level
/// assertions.
///
/// This function should not be inlined because it is cold and inlining just
/// bloats code.
@usableFromInline
@inline(never)
@_semantics("programtermination_point")
internal func _assertionFailure(
    _ prefix: StaticString, _ message: StaticString,
    file: StaticString, line: UInt,
    flags: UInt32
) -> Never {
    prefix.withUTF8Buffer {
        (prefix) -> Void in
        message.withUTF8Buffer {
            (message) -> Void in
            file.withUTF8Buffer {
                (file) -> Void in
                _swift_stdlib_reportFatalErrorInFile(
                    prefix.baseAddress!, CInt(prefix.count),
                    message.baseAddress!, CInt(message.count),
                    file.baseAddress!, CInt(file.count), UInt32(line),
                    flags)
                Builtin.int_trap()
            }
        }
    }
    Builtin.int_trap()
}

/// This function should be used only in the implementation of user-level
/// assertions.
///
/// This function should not be inlined because it is cold and inlining just
/// bloats code.
@usableFromInline
@inline(never)
@_semantics("programtermination_point")
internal func _assertionFailure(
    _ prefix: StaticString, _ message: String,
    file: StaticString, line: UInt,
    flags: UInt32
) -> Never {
    prefix.withUTF8Buffer {
        (prefix) -> Void in
        var message = message
        message.withUTF8 {
            (messageUTF8) -> Void in
            file.withUTF8Buffer {
                (file) -> Void in
                _swift_stdlib_reportFatalErrorInFile(
                    prefix.baseAddress!, CInt(prefix.count),
                    messageUTF8.baseAddress!, CInt(messageUTF8.count),
                    file.baseAddress!, CInt(file.count), UInt32(line),
                    flags)
            }
        }
    }
    
    Builtin.int_trap()
}

/// This function should be used only in the implementation of user-level
/// assertions.
///
/// This function should not be inlined because it is cold and inlining just
/// bloats code.
@usableFromInline
@inline(never)
@_semantics("programtermination_point")
internal func _assertionFailure(
    _ prefix: StaticString, _ message: String,
    flags: UInt32
) -> Never {
    prefix.withUTF8Buffer {
        (prefix) -> Void in
        var message = message
        message.withUTF8 {
            (messageUTF8) -> Void in
            _swift_stdlib_reportFatalError(
                prefix.baseAddress!, CInt(prefix.count),
                messageUTF8.baseAddress!, CInt(messageUTF8.count),
                flags)
        }
    }
    
    Builtin.int_trap()
}

/// This function should be used only in the implementation of stdlib
/// assertions.
///
/// This function should not be inlined because it is cold and it inlining just
/// bloats code.
@usableFromInline
@inline(never)
@_semantics("programtermination_point")
internal func _fatalErrorMessage(
    _ prefix: StaticString, _ message: StaticString,
    file: StaticString, line: UInt,
    flags: UInt32
) -> Never {
    _assertionFailure(prefix, message, file: file, line: line, flags: flags)
}

/// Prints a fatal error message when an unimplemented initializer gets
/// called by the Objective-C runtime.
@_transparent
public // COMPILER_INTRINSIC
func _unimplementedInitializer(className: StaticString,
                               initName: StaticString = #function,
                               file: StaticString = #file,
                               line: UInt = #line,
                               column: UInt = #column
) -> Never {
    // This function is marked @_transparent so that it is inlined into the caller
    // (the initializer stub), and, depending on the build configuration,
    // redundant parameter values (#file etc.) are eliminated, and don't leak
    // information about the user's source.
    
    if _isDebugAssertConfiguration() {
        className.withUTF8Buffer {
            (className) in
            initName.withUTF8Buffer {
                (initName) in
                file.withUTF8Buffer {
                    (file) in
                    _swift_stdlib_reportUnimplementedInitializerInFile(
                        className.baseAddress!, CInt(className.count),
                        initName.baseAddress!, CInt(initName.count),
                        file.baseAddress!, CInt(file.count),
                        UInt32(line), UInt32(column),
                        /*flags:*/ 0)
                }
            }
        }
    } else {
        className.withUTF8Buffer {
            (className) in
            initName.withUTF8Buffer {
                (initName) in
                _swift_stdlib_reportUnimplementedInitializer(
                    className.baseAddress!, CInt(className.count),
                    initName.baseAddress!, CInt(initName.count),
                    /*flags:*/ 0)
            }
        }
    }
    
    Builtin.int_trap()
}

public // COMPILER_INTRINSIC
func _undefined<T>(
    _ message: @autoclosure () -> String = String(),
    file: StaticString = #file, line: UInt = #line
) -> T {
    _assertionFailure("Fatal error", message(), file: file, line: line, flags: 0)
}

/// Called when falling off the end of a switch and the type can be represented
/// as a raw value.
///
/// This function should not be inlined because it is cold and inlining just
/// bloats code. It doesn't take a source location because it's most important
/// in release builds anyway (old apps that are run on new OSs).
@inline(never)
@usableFromInline // COMPILER_INTRINSIC
internal func _diagnoseUnexpectedEnumCaseValue<SwitchedValue, RawValue>(
    type: SwitchedValue.Type,
    rawValue: RawValue
) -> Never {
    _assertionFailure("Fatal error",
                      "unexpected enum case '\(type)(rawValue: \(rawValue))'",
                      flags: _fatalErrorFlags())
}

/// Called when falling off the end of a switch and the value is not safe to
/// print.
///
/// This function should not be inlined because it is cold and inlining just
/// bloats code. It doesn't take a source location because it's most important
/// in release builds anyway (old apps that are run on new OSs).
@inline(never)
@usableFromInline // COMPILER_INTRINSIC
internal func _diagnoseUnexpectedEnumCase<SwitchedValue>(
    type: SwitchedValue.Type
) -> Never {
    _assertionFailure(
        "Fatal error",
        "unexpected enum case while switching on value of type '\(type)'",
        flags: _fatalErrorFlags())
}
