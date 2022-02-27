import SwiftShims

/*
 @available(iOS 11.0, *)
 从这里, 可以猜想, 系统编译到底在做什么事情.
 
 @available(iOS 11.0, *) 标识的代码, 不是说不编译了. 因为从程序运行的原理来说, 是没有办法根据运行环境, 打出不同的二进制包的.
 所以, 最终其实还是只有一份二进制包, 可能会根据 CPU 架构不同, 但是绝对不会因为所运行系统的版本不同.
 
 @available(iOS 11.0, *) 标识的意思, 其实就是下面代码所描述的. 显示进行当前的 OS 版本号, 然后进行动态的 check. 如果 check 成功, 就执行对应的代码.
 在运行的二进制包里面, 就包含着 if {} else {} 的逻辑判断了.
 因为, 是动态库链接, 所以是可以包含当前版本动态库没有的信号引用的, 动态库的符号链接方式是晚绑定, 如果 check 的时候没有通过, 也就不会触发没有的信号绑定的流程, 也就不会崩溃了. 
 */
public func _stdlib_isOSVersionAtLeast(
    _ major: Builtin.Word,
    _ minor: Builtin.Word,
    _ patch: Builtin.Word
) -> Builtin.Int1 {
    
#if (os(macOS) || os(iOS) || os(tvOS) || os(watchOS)) && SWIFT_RUNTIME_OS_VERSIONING
    if Int(major) == 9999 {
        return true._value
    }
    let runningVersion = _swift_stdlib_operatingSystemVersion()
    
    let result =
    (runningVersion.majorVersion,runningVersion.minorVersion,runningVersion.patchVersion)
    >= (Int(major),Int(minor),Int(patch))
    
    //
    return result._value
#else
    // FIXME: As yet, there is no obvious versioning standard for platforms other
    // than Darwin-based OSes, so we just assume false for now.
    // rdar://problem/18881232
    return false._value
#endif
}
