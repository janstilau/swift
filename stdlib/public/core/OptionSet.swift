
/*
 这是一个协议, 一个抽象的类型.
 一般来说, 是把这个协议当做 Int Enum 的代替品.
 其实, Int enum 并没有体现 Enum 的性质, 并没有确定的一群值, 来列举所有的合法值.
 所以, 其实在从 C 时代, enum 和 或 的写法, 就是在表现, 这是一个集合.
 里面的值, 其实是一些特殊值, 是特定的集合.
 所以, 这个类型的值, 其实是无限的.
 
 Swift 把这两个概念做了区分.
 rawValue 表示数据部分.
 Set 表示集合的概念.
 当然, 我们用起来, 一般是使用Int. 也就是原始的 C 风格.
 标准库对 Int 完成了各种集合操作的适配.
 
 这是一个抽象类型, 每次使用, 都要创建一个实际的类型出来.
 这个类型, 通常每个 Bit 都有自己的 static 值, 特殊的集合 set 也定义 static 值.
 然后判断, 就是 contains 判断了.
 */
 
public protocol OptionSet: SetAlgebra, RawRepresentable {
    associatedtype Element = Self
    
    // FIXME: This initializer should just be the failable init from
    // RawRepresentable. Unfortunately, current language limitations
    // that prevent non-failable initializers from forwarding to
    // failable ones would prevent us from generating the non-failing
    // default (zero-argument) initializer.  Since OptionSet's main
    // purpose is to create convenient conformances to SetAlgebra,
    // we opt for a non-failable initializer.
    
    /// Creates a new option set from the given raw value.
    ///
    /// This initializer always succeeds, even if the value passed as `rawValue`
    /// exceeds the static properties declared as part of the option set. This
    /// example creates an instance of `ShippingOptions` with a raw value beyond
    /// the highest element, with a bit mask that effectively contains all the
    /// declared static members.
    ///
    ///     let extraOptions = ShippingOptions(rawValue: 255)
    ///     print(extraOptions.isStrictSuperset(of: .all))
    ///     // Prints "true"
    ///
    /// - Parameter rawValue: The raw value of the option set to create. Each bit
    ///   of `rawValue` potentially represents an element of the option set,
    ///   though raw values may include bits that are not defined as distinct
    ///   values of the `OptionSet` type.
    init(rawValue: RawValue)
}

/// `OptionSet` requirements for which default implementations
/// are supplied.
///
/// - Note: A type conforming to `OptionSet` can implement any of
///  these initializers or methods, and those implementations will be
///  used in lieu of these defaults.
extension OptionSet {
    /// Returns a new option set of the elements contained in this set, in the
    /// given set, or in both.
    ///
    /// This example uses the `union(_:)` method to add two more shipping options
    /// to the default set.
    ///
    ///     let defaultShipping = ShippingOptions.standard
    ///     let memberShipping = defaultShipping.union([.secondDay, .priority])
    ///     print(memberShipping.contains(.priority))
    ///     // Prints "true"
    ///
    /// - Parameter other: An option set.
    /// - Returns: A new option set made up of the elements contained in this
    ///   set, in `other`, or in both.
    @inlinable // generic-performance
    public func union(_ other: Self) -> Self {
        var r: Self = Self(rawValue: self.rawValue)
        r.formUnion(other)
        return r
    }
    
    /// Returns a new option set with only the elements contained in both this
    /// set and the given set.
    ///
    /// This example uses the `intersection(_:)` method to limit the available
    /// shipping options to what can be used with a PO Box destination.
    ///
    ///     // Can only ship standard or priority to PO Boxes
    ///     let poboxShipping: ShippingOptions = [.standard, .priority]
    ///     let memberShipping: ShippingOptions =
    ///             [.standard, .priority, .secondDay]
    ///
    ///     let availableOptions = memberShipping.intersection(poboxShipping)
    ///     print(availableOptions.contains(.priority))
    ///     // Prints "true"
    ///     print(availableOptions.contains(.secondDay))
    ///     // Prints "false"
    ///
    /// - Parameter other: An option set.
    /// - Returns: A new option set with only the elements contained in both this
    ///   set and `other`.
    @inlinable // generic-performance
    public func intersection(_ other: Self) -> Self {
        var r = Self(rawValue: self.rawValue)
        r.formIntersection(other)
        return r
    }
    
    /// Returns a new option set with the elements contained in this set or in
    /// the given set, but not in both.
    ///
    /// - Parameter other: An option set.
    /// - Returns: A new option set with only the elements contained in either
    ///   this set or `other`, but not in both.
    @inlinable // generic-performance
    public func symmetricDifference(_ other: Self) -> Self {
        var r = Self(rawValue: self.rawValue)
        r.formSymmetricDifference(other)
        return r
    }
}

/// `OptionSet` requirements for which default implementations are
/// supplied when `Element == Self`, which is the default.
///
/// - Note: A type conforming to `OptionSet` can implement any of
///   these initializers or methods, and those implementations will be
///   used in lieu of these defaults.
extension OptionSet where Element == Self {
    /// Returns a Boolean value that indicates whether a given element is a
    /// member of the option set.
    ///
    /// This example uses the `contains(_:)` method to check whether next-day
    /// shipping is in the `availableOptions` instance.
    ///
    ///     let availableOptions = ShippingOptions.express
    ///     if availableOptions.contains(.nextDay) {
    ///         print("Next day shipping available")
    ///     }
    ///     // Prints "Next day shipping available"
    ///
    /// - Parameter member: The element to look for in the option set.
    /// - Returns: `true` if the option set contains `member`; otherwise,
    ///   `false`.
    @inlinable // generic-performance
    public func contains(_ member: Self) -> Bool {
        return self.isSuperset(of: member)
    }
    
    /// Adds the given element to the option set if it is not already a member.
    ///
    /// In the following example, the `.secondDay` shipping option is added to
    /// the `freeOptions` option set if `purchasePrice` is greater than 50.0. For
    /// the `ShippingOptions` declaration, see the `OptionSet` protocol
    /// discussion.
    ///
    ///     let purchasePrice = 87.55
    ///
    ///     var freeOptions: ShippingOptions = [.standard, .priority]
    ///     if purchasePrice > 50 {
    ///         freeOptions.insert(.secondDay)
    ///     }
    ///     print(freeOptions.contains(.secondDay))
    ///     // Prints "true"
    ///
    /// - Parameter newMember: The element to insert.
    /// - Returns: `(true, newMember)` if `newMember` was not contained in
    ///   `self`. Otherwise, returns `(false, oldMember)`, where `oldMember` is
    ///   the member of the set equal to `newMember`.
    @inlinable // generic-performance
    @discardableResult
    public mutating func insert(
        _ newMember: Element
    ) -> (inserted: Bool, memberAfterInsert: Element) {
        let oldMember = self.intersection(newMember)
        let shouldInsert = oldMember != newMember
        let result = (
            inserted: shouldInsert,
            memberAfterInsert: shouldInsert ? newMember : oldMember)
        if shouldInsert {
            self.formUnion(newMember)
        }
        return result
    }
    
    /// Removes the given element and all elements subsumed by it.
    ///
    /// In the following example, the `.priority` shipping option is removed from
    /// the `options` option set. Attempting to remove the same shipping option
    /// a second time results in `nil`, because `options` no longer contains
    /// `.priority` as a member.
    ///
    ///     var options: ShippingOptions = [.secondDay, .priority]
    ///     let priorityOption = options.remove(.priority)
    ///     print(priorityOption == .priority)
    ///     // Prints "true"
    ///
    ///     print(options.remove(.priority))
    ///     // Prints "nil"
    ///
    /// In the next example, the `.express` element is passed to `remove(_:)`.
    /// Although `.express` is not a member of `options`, `.express` subsumes
    /// the remaining `.secondDay` element of the option set. Therefore,
    /// `options` is emptied and the intersection between `.express` and
    /// `options` is returned.
    ///
    ///     let expressOption = options.remove(.express)
    ///     print(expressOption == .express)
    ///     // Prints "false"
    ///     print(expressOption == .secondDay)
    ///     // Prints "true"
    ///
    /// - Parameter member: The element of the set to remove.
    /// - Returns: The intersection of `[member]` and the set, if the
    ///   intersection was nonempty; otherwise, `nil`.
    @inlinable // generic-performance
    @discardableResult
    public mutating func remove(_ member: Element) -> Element? {
        let r = isSuperset(of: member) ? Optional(member) : nil
        self.subtract(member)
        return r
    }
    
    /// Inserts the given element into the set.
    ///
    /// If `newMember` is not contained in the set but subsumes current members
    /// of the set, the subsumed members are returned.
    ///
    ///     var options: ShippingOptions = [.secondDay, .priority]
    ///     let replaced = options.update(with: .express)
    ///     print(replaced == .secondDay)
    ///     // Prints "true"
    ///
    /// - Returns: The intersection of `[newMember]` and the set if the
    ///   intersection was nonempty; otherwise, `nil`.
    @inlinable // generic-performance
    @discardableResult
    public mutating func update(with newMember: Element) -> Element? {
        let r = self.intersection(newMember)
        self.formUnion(newMember)
        return r.isEmpty ? nil : r
    }
}

// 各种集合的方法, 最最核心的, 也就是下面的 formUnion, formIntersection, formSymmetricDifference 方法. 
extension OptionSet where RawValue: FixedWidthInteger {
    /// Creates an empty option set.
    ///
    /// This initializer creates an option set with a raw value of zero.
    @inlinable // generic-performance
    public init() {
        self.init(rawValue: 0)
    }
    
    /// Inserts the elements of another set into this option set.
    ///
    /// This method is implemented as a `|` (bitwise OR) operation on the
    /// two sets' raw values.
    ///
    /// - Parameter other: An option set.
    @inlinable // generic-performance
    public mutating func formUnion(_ other: Self) {
        self = Self(rawValue: self.rawValue | other.rawValue)
    }
    
    /// Removes all elements of this option set that are not
    /// also present in the given set.
    ///
    /// This method is implemented as a `&` (bitwise AND) operation on the
    /// two sets' raw values.
    ///
    /// - Parameter other: An option set.
    @inlinable // generic-performance
    public mutating func formIntersection(_ other: Self) {
        self = Self(rawValue: self.rawValue & other.rawValue)
    }
    
    /// Replaces this set with a new set containing all elements
    /// contained in either this set or the given set, but not in both.
    ///
    /// This method is implemented as a `^` (bitwise XOR) operation on the two
    /// sets' raw values.
    ///
    /// - Parameter other: An option set.
    @inlinable // generic-performance
    public mutating func formSymmetricDifference(_ other: Self) {
        self = Self(rawValue: self.rawValue ^ other.rawValue)
    }
}
