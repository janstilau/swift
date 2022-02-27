public protocol Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool
}

// 面向协议编程的实现. extension 中编写通用的逻辑, 这些通用逻辑, 会受到 primitive method 的影响.
extension Equatable {
    public static func != (lhs: Self, rhs: Self) -> Bool {
        return !(lhs == rhs)
    }
}

// 引用 === 操作符, 就是使用 ObjectIdentifier 包装一下, 然后进行判等.
// 而 ObjectIdentifier 的 == 实际上, 是指针Int值的判等.
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

public func !== (lhs: AnyObject?, rhs: AnyObject?) -> Bool {
    return !(lhs === rhs)
}


