import SwiftShims

/// When providing new APIs that use randomness, provide a version that accepts
/// a generator conforming to the `RandomNumberGenerator` protocol as well as a
/// version that uses the default system generator. For example, this `Weekday`
/// enumeration provides static methods that return a random day of the week:
///
///     enum Weekday: CaseIterable {
///         case sunday, monday, tuesday, wednesday, thursday, friday, saturday
///
///         static func random<G: RandomNumberGenerator>(using generator: inout G) -> Weekday {
///             return Weekday.allCases.randomElement(using: &generator)!
///         }
///
///         static func random() -> Weekday {
///             var g = SystemRandomNumberGenerator()
///             return Weekday.random(using: &g)
///         }
///     }
///
/// Conforming to the RandomNumberGenerator Protocol
/// ================================================
///
/// A custom `RandomNumberGenerator` type can have different characteristics
/// than the default `SystemRandomNumberGenerator` type. For example, a
/// seedable generator can be used to generate a repeatable sequence of random
/// values for testing purposes.
///
/// To make a custom type conform to the `RandomNumberGenerator` protocol,
/// implement the required `next()` method. Each call to `next()` must produce
/// a uniform and independent random value.

public protocol RandomNumberGenerator {
    /// Returns a value from a uniform, independent distribution of binary data.
    ///
    /// Use this method when you need random binary data to generate another
    /// value. If you need an integer value within a specific range, use the
    /// static `random(in:using:)` method on that integer type instead of this
    /// method.
    ///
    /// - Returns: An unsigned 64-bit random value.
    mutating func next() -> UInt64
}

extension RandomNumberGenerator {
    
    // An unavailable default implementation of next() prevents types that do
    // not implement the RandomNumberGenerator interface from conforming to the
    // protocol; without this, the default next() method returning a generic
    // unsigned integer will be used, recursing infinitely and probably blowing
    // the stack.
    @available(*, unavailable)
    @_alwaysEmitIntoClient
    public mutating func next() -> UInt64 { fatalError() }
    
    /// Returns a value from a uniform, independent distribution of binary data.
    ///
    /// Use this method when you need random binary data to generate another
    /// value. If you need an integer value within a specific range, use the
    /// static `random(in:using:)` method on that integer type instead of this
    /// method.
    ///
    /// - Returns: A random value of `T`. Bits are randomly distributed so that
    ///   every value of `T` is equally likely to be returned.
    @inlinable
    public mutating func next<T: FixedWidthInteger & UnsignedInteger>() -> T {
        return T._random(using: &self)
    }
    
    /// Returns a random value that is less than the given upper bound.
    ///
    /// Use this method when you need random binary data to generate another
    /// value. If you need an integer value within a specific range, use the
    /// static `random(in:using:)` method on that integer type instead of this
    /// method.
    ///
    /// - Parameter upperBound: The upper bound for the randomly generated value.
    ///   Must be non-zero.
    /// - Returns: A random value of `T` in the range `0..<upperBound`. Every
    ///   value in the range `0..<upperBound` is equally likely to be returned.
    @inlinable
    public mutating func next<T: FixedWidthInteger & UnsignedInteger>(
        upperBound: T
    ) -> T {
        _precondition(upperBound != 0, "upperBound cannot be zero.")
#if arch(i386) || arch(arm) || arch(arm64_32) // TODO(FIXME) SR-10912
        let tmp = (T.max % upperBound) + 1
        let range = tmp == upperBound ? 0 : tmp
        var random: T = 0
        
        repeat {
            random = next()
        } while random < range
        
        return random % upperBound
#else
        var random: T = next()
        var m = random.multipliedFullWidth(by: upperBound)
        if m.low < upperBound {
            let t = (0 &- upperBound) % upperBound
            while m.low < t {
                random = next()
                m = random.multipliedFullWidth(by: upperBound)
            }
        }
        return m.high
#endif
    }
}

// 系统的 Random 的实现, 是使用了 swift_stdlib_random, 而这我们不知道实现.
public struct SystemRandomNumberGenerator: RandomNumberGenerator, Sendable {
    /// Creates a new instance of the system's default random number generator.
    @inlinable
    public init() { }
    
    /// Returns a value from a uniform, independent distribution of binary data.
    ///
    /// - Returns: An unsigned 64-bit random value.
    @inlinable
    public mutating func next() -> UInt64 {
        var random: UInt64 = 0
        swift_stdlib_random(&random, MemoryLayout<UInt64>.size)
        return random
    }
}
