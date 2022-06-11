
public protocol Comparable: Equatable {
    static func < (lhs: Self, rhs: Self) -> Bool
    static func <= (lhs: Self, rhs: Self) -> Bool
    static func > (lhs: Self, rhs: Self) -> Bool
    static func >= (lhs: Self, rhs: Self) -> Bool
}


extension Comparable {
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return rhs < lhs
    }
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        return !(rhs < lhs)
    }
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        return !(lhs < rhs)
    }
}
