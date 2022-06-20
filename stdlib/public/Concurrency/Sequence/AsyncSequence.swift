
import Swift

/// A type that provides asynchronous, sequential, iterated access to its
/// elements.
///
/// An `AsyncSequence` resembles the `Sequence` type --- offering a list of
/// values you can step through one at a time --- and adds asynchronicity. An
/// `AsyncSequence` may have all, some, or none of its values available when
/// you first use it. Instead, you use `await` to receive values as they become
/// available.
///
/// As with `Sequence`, you typically iterate through an `AsyncSequence` with a
/// `for await`-`in` loop. However, because the caller must potentially wait for values,
/// you use the `await` keyword. The following example shows how to iterate
/// over `Counter`, a custom `AsyncSequence` that produces `Int` values from
/// `1` up to a `howHigh` value:
///
///     for await i in Counter(howHigh: 10) {
///         print(i, terminator: " ")
///     }
///     // Prints: 1 2 3 4 5 6 7 8 9 10


/// An `AsyncSequence` doesn't generate or contain the values; it just defines
/// how you access them. Along with defining the type of values as an associated
/// type called `Element`, the `AsyncSequence` defines a `makeAsyncIterator()`
/// method. This returns an instance of type `AsyncIterator`. Like the standard
/// `IteratorProtocol`, the `AsyncIteratorProtocol` defines a single `next()`
/// method to produce elements. The difference is that the `AsyncIterator`
/// defines its `next()` method as `async`, which requires a caller to wait for
/// the next value with the `await` keyword.
// 最重要的区别就是, 需要 wait. 在 async 的迭代中, 每一个取值操作, 都会伴随着 wait 的可能性.
// 如果, Buffter 有值, 直接将值传递过来. 如果没有, 这是直接尽心了协程的调度, 在值产生了之后, 进行 resume.

// 这里就是体现了, Protocol 的作用了. 就是在 Extension 里面, 定义各种快捷方便的方法, 给外界使用.
/// `AsyncSequence` also defines methods for processing the elements you
/// receive, modeled on the operations provided by the basic `Sequence` in the
/// standard library. There are two categories of methods: those that return a
/// single value, and those that return another `AsyncSequence`.

// 存储 base AsyncSequnce, 然后自己内部进行聚合. 当发现了结果之后, 例如 contains, filter 这种, 直接进行返回. 如果没有, 继续消耗存储的 base, 直到结束.
/// Single-value methods eliminate the need for a `for await`-`in` loop, and instead
/// let you make a single `await` call. For example, the `contains(_:)` method
/// returns a Boolean value that indicates if a given value exists in the
/// `AsyncSequence`. Given the `Counter` sequence from the previous example,
/// you can test for the existence of a sequence member with a one-line call:
///
///     let found = await Counter(howHigh: 10).contains(5) // true

// 存储了 base AsyncSequence, 然后接受上游的 element, 在进行了自己的业务逻辑之后, 将处理好的数据, 当做 element 返回.
/// Methods that return another `AsyncSequence` return a type specific to the
/// method's semantics. For example, the `.map(_:)` method returns a
/// `AsyncMapSequence` (or a `AsyncThrowingMapSequence`, if the closure you
/// provide to the `map(_:)` method can throw an error). These returned
/// sequences don't eagerly await the next member of the sequence, which allows
/// the caller to decide when to start work. Typically, you'll iterate over
/// these sequences with `for await`-`in`, like the base `AsyncSequence` you started
/// with. In the following example, the `map(_:)` method transforms each `Int`
/// received from a `Counter` sequence into a `String`:
///
///     let stream = Counter(howHigh: 10)
///         .map { $0 % 2 == 0 ? "Even" : "Odd" }
///     for await s in stream {
///         print(s, terminator: " ")
///     }
///     // Prints: Odd Even Odd Even Odd Even Odd Even Odd Even



@available(SwiftStdlib 5.1, *)
@rethrows
public protocol AsyncSequence {
    /// The type of asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    associatedtype AsyncIterator: AsyncIteratorProtocol where AsyncIterator.Element == Element
    /// The type of element produced by this asynchronous sequence.
    associatedtype Element
    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    __consuming func makeAsyncIterator() -> AsyncIterator
}

@available(SwiftStdlib 5.1, *)
extension AsyncSequence {
    // combine 组合, 将数据组合成为一个数据.
    /// Returns the result of combining the elements of the asynchronous sequence
    /// using the given closure.
    ///
    /// Use the `reduce(_:_:)` method to produce a single value from the elements of
    /// an entire sequence. For example, you can use this method on an sequence of
    /// numbers to find their sum or product.
    
    /// The `nextPartialResult` closure executes sequentially with an accumulating
    /// value initialized to `initialResult` and each element of the sequence.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `4`. The `reduce(_:_:)` method sums the values
    /// received from the asynchronous sequence.
    ///
    ///     let sum = await Counter(howHigh: 4)
    ///         .reduce(0) {
    ///             $0 + $1
    ///         }
    ///     print(sum)
    ///     // Prints: 10
    ///
    
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///     The `nextPartialResult` closure receives `initialResult` the first
    ///     time the closure runs.
    ///
    ///   - nextPartialResult: A closure that combines an accumulating value and
    ///     an element of the asynchronous sequence into a new accumulating value,
    ///     for use in the next call of the `nextPartialResult` closure or
    ///     returned to the caller.
    /// - Returns: The final accumulated value. If the sequence has no elements,
    ///   the result is `initialResult`.
    // 这种写法, 应该是官方推荐的做法.
    // 在看熟悉了之后, 可以看到, 每个参数的参数名和类型, 其实可以得到很好地表达.
    public func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult:
        (_ partialResult: Result, Element) async throws -> Result
    ) async rethrows -> Result {
        // 可以看到, 在返回单个值的方法里面, 是直接在里面进行了消耗了. 
        var accumulator = initialResult
        var iterator = makeAsyncIterator()
        while let element = try await iterator.next() {
            accumulator = try await nextPartialResult(accumulator, element)
        }
        return accumulator
    }
    
    /// Returns the result of combining the elements of the asynchronous sequence
    /// using the given closure, given a mutable initial value.
    // 这个方法, 有着更加有效的内存利用.
    // Result 的值, 不再是每次进行复制, 而是可以每次都利用原来的值.
    /// Use the `reduce(into:_:)` method to produce a single value from the
    /// elements of an entire sequence. For example, you can use this method on a
    /// sequence of numbers to find their sum or product.
    ///
    /// The `nextPartialResult` closure executes sequentially with an accumulating
    /// value initialized to `initialResult` and each element of the sequence.
    ///
    /// Prefer this method over `reduce(_:_:)` for efficiency when the result is
    /// a copy-on-write type, for example an `Array` or `Dictionary`.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///     The `nextPartialResult` closure receives `initialResult` the first
    ///     time the closure executes.
    ///   - nextPartialResult: A closure that combines an accumulating value and
    ///     an element of the asynchronous sequence into a new accumulating value,
    ///     for use in the next call of the `nextPartialResult` closure or
    ///     returned to the caller.
    /// - Returns: The final accumulated value. If the sequence has no elements,
    ///   the result is `initialResult`.
    @inlinable
    public func reduce<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult:
        (_ partialResult: inout Result, Element) async throws -> Void
    ) async rethrows -> Result {
        var accumulator = initialResult
        var iterator = makeAsyncIterator()
        while let element = try await iterator.next() {
            try await updateAccumulatingResult(&accumulator, element)
        }
        return accumulator
    }
}

@available(SwiftStdlib 5.1, *)
@inlinable
@inline(__always)
func _contains<Source: AsyncSequence>(
    _ self: Source,
    where predicate: (Source.Element) async throws -> Bool
) async rethrows -> Bool {
    // 传递过来的闭包, 是一个 Async 类型的. 之所以这样, 是因为在真正的实现内部, prodicate 也可能会是一个异步函数.
    // 例如, 每次都要发送网络请求, 根据网络请求的值判断是否包含. 所以这里可能会进行 wait 的操作.
    for try await element in self {
        if try await predicate(element) {
            return true
        }
    }
    return false
}

@available(SwiftStdlib 5.1, *)
extension AsyncSequence {
    /// Returns a Boolean value that indicates whether the asynchronous sequence
    /// contains an element that satisfies the given predicate.
    ///
    /// You can use the predicate to check for an element of a type that doesn’t
    /// conform to the `Equatable` protocol, or to find an element that satisfies
    /// a general condition.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `contains(where:)` method checks to see
    /// whether the sequence produces a value divisible by `3`:
    ///
    ///     let containsDivisibleByThree = await Counter(howHigh: 10)
    ///         .contains { $0 % 3 == 0 }
    ///     print(containsDivisibleByThree)
    ///     // Prints: true
    ///
    /// The predicate executes each time the asynchronous sequence produces an
    /// element, until either the predicate finds a match or the sequence ends.
    ///
    /// - Parameter predicate: A closure that takes an element of the asynchronous
    ///   sequence as its argument and returns a Boolean value that indicates
    ///   whether the passed element represents a match.
    /// - Returns: `true` if the sequence contains an element that satisfies
    ///   predicate; otherwise, `false`.
    @inlinable
    public func contains(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Bool {
        return try await _contains(self, where: predicate)
    }
    
    /// Returns a Boolean value that indicates whether all elements produced by the
    /// asynchronous sequence satisfy the given predicate.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `allSatisfy(_:)` method checks to see whether
    /// all elements produced by the sequence are less than `10`.
    ///
    ///     let allLessThanTen = await Counter(howHigh: 10)
    ///         .allSatisfy { $0 < 10 }
    ///     print(allLessThanTen)
    ///     // Prints: false
    ///
    /// The predicate executes each time the asynchronous sequence produces an
    /// element, until either the predicate returns `false` or the sequence ends.
    ///
    /// If the asynchronous sequence is empty, this method returns `true`.
    ///
    /// - Parameter predicate: A closure that takes an element of the asynchronous
    ///   sequence as its argument and returns a Boolean value that indicates
    ///   whether the passed element satisfies a condition.
    /// - Returns: `true` if the sequence contains only elements that satisfy
    ///   `predicate`; otherwise, `false`.
    // 能够正确的理解, 这些已经构建出来的小方法, 在使用的时候, 能够大大的减少编码的复杂度.
    public func allSatisfy(
        _ predicate: (Element) async throws -> Bool
    ) async rethrows -> Bool {
        // predicate 符合 !predicate 不符合
        // contains 包含 !contains 不包含.
        // 不包含, 不符合的数据, 就是 allSatisfy
        return try await ! contains { try await !predicate($0) }
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncSequence where Element: Equatable {
    /// Returns a Boolean value that indicates whether the asynchronous sequence
    /// contains the given element.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `contains(_:)` method checks to see whether
    /// the sequence produces the value `5`:
    ///
    ///     let containsFive = await Counter(howHigh: 10)
    ///         .contains(5)
    ///     print(containsFive)
    ///     // Prints: true
    ///
    /// - Parameter search: The element to find in the asynchronous sequence.
    /// - Returns: `true` if the method found the element in the asynchronous
    ///   sequence; otherwise, `false`.
    @inlinable
    public func contains(_ search: Element) async rethrows -> Bool {
        for try await element in self {
            if element == search {
                return true
            }
        }
        return false
    }
}

@available(SwiftStdlib 5.1, *)
@inlinable
@inline(__always)
func _first<Source: AsyncSequence>(
    _ self: Source,
    where predicate: (Source.Element) async throws -> Bool
) async rethrows -> Source.Element? {
    for try await element in self {
        if try await predicate(element) {
            return element
        }
    }
    return nil
}

@available(SwiftStdlib 5.1, *)
extension AsyncSequence {
    /// Returns the first element of the sequence that satisfies the given
    /// predicate.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `first(where:)` method returns the first
    /// member of the sequence that's evenly divisible by both `2` and `3`.
    ///
    ///     let divisibleBy2And3 = await Counter(howHigh: 10)
    ///         .first { $0 % 2 == 0 && $0 % 3 == 0 }
    ///     print(divisibleBy2And3 ?? "none")
    ///     // Prints: 6
    ///
    /// The predicate executes each time the asynchronous sequence produces an
    /// element, until either the predicate finds a match or the sequence ends.
    ///
    /// - Parameter predicate: A closure that takes an element of the asynchronous
    ///  sequence as its argument and returns a Boolean value that indicates
    ///  whether the element is a match.
    /// - Returns: The first element of the sequence that satisfies `predicate`,
    ///   or `nil` if there is no element that satisfies `predicate`.
    @inlinable
    public func first(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Element? {
        return try await _first(self, where: predicate)
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncSequence {
    /// Returns the minimum element in the asynchronous sequence, using the given
    /// predicate as the comparison between elements.
    ///
    /// Use this method when the asynchronous sequence's values don't conform
    /// to `Comparable`, or when you want to apply a custom ordering to the
    /// sequence.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That is,
    /// for any elements `a`, `b`, and `c`, the following conditions must hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// The following example uses an enumeration of playing cards ranks, `Rank`,
    /// which ranges from `ace` (low) to `king` (high). An asynchronous sequence
    /// called `RankCounter` produces all elements of the array. The predicate
    /// provided to the `min(by:)` method sorts ranks based on their `rawValue`:
    ///
    ///     enum Rank: Int {
    ///         case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king
    ///     }
    ///
    ///     let min = await RankCounter()
    ///         .min { $0.rawValue < $1.rawValue }
    ///     print(min ?? "none")
    ///     // Prints: ace
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its
    ///   first argument should be ordered before its second argument; otherwise,
    ///   `false`.
    /// - Returns: The sequence’s minimum element, according to
    ///   `areInIncreasingOrder`. If the sequence has no elements, returns `nil`.
    @inlinable
    @warn_unqualified_access
    public func min(
        by areInIncreasingOrder: (Element, Element) async throws -> Bool
    ) async rethrows -> Element? {
        var it = makeAsyncIterator()
        guard var result = try await it.next() else {
            return nil
        }
        while let e = try await it.next() {
            if try await areInIncreasingOrder(e, result) {
                result = e
            }
        }
        return result
    }
    
    /// Returns the maximum element in the asynchronous sequence, using the given
    /// predicate as the comparison between elements.
    ///
    /// Use this method when the asynchronous sequence's values don't conform
    /// to `Comparable`, or when you want to apply a custom ordering to the
    /// sequence.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That is,
    /// for any elements `a`, `b`, and `c`, the following conditions must hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// The following example uses an enumeration of playing cards ranks, `Rank`,
    /// which ranges from `ace` (low) to `king` (high). An asynchronous sequence
    /// called `RankCounter` produces all elements of the array. The predicate
    /// provided to the `max(by:)` method sorts ranks based on their `rawValue`:
    ///
    ///     enum Rank: Int {
    ///         case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king
    ///     }
    ///
    ///     let max = await RankCounter()
    ///         .max { $0.rawValue < $1.rawValue }
    ///     print(max ?? "none")
    ///     // Prints: king
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its
    ///   first argument should be ordered before its second argument; otherwise,
    ///   `false`.
    /// - Returns: The sequence’s minimum element, according to
    ///   `areInIncreasingOrder`. If the sequence has no elements, returns `nil`.
    @inlinable
    @warn_unqualified_access
    public func max(
        by areInIncreasingOrder: (Element, Element) async throws -> Bool
    ) async rethrows -> Element? {
        var it = makeAsyncIterator()
        guard var result = try await it.next() else {
            return nil
        }
        while let e = try await it.next() {
            if try await areInIncreasingOrder(result, e) {
                result = e
            }
        }
        return result
    }
}

@available(SwiftStdlib 5.1, *)
extension AsyncSequence where Element: Comparable {
    /// Returns the minimum element in an asynchronous sequence of comparable
    /// elements.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `min()` method returns the minimum value
    /// of the sequence.
    ///
    ///     let min = await Counter(howHigh: 10)
    ///         .min()
    ///     print(min ?? "none")
    ///     // Prints: 1
    ///
    /// - Returns: The sequence’s minimum element. If the sequence has no
    ///   elements, returns `nil`.
    @inlinable
    @warn_unqualified_access
    public func min() async rethrows -> Element? {
        return try await self.min(by: <)
    }
    
    /// Returns the maximum element in an asynchronous sequence of comparable
    /// elements.
    ///
    /// In this example, an asynchronous sequence called `Counter` produces `Int`
    /// values from `1` to `10`. The `max()` method returns the max value
    /// of the sequence.
    ///
    ///     let max = await Counter(howHigh: 10)
    ///         .max()
    ///     print(max ?? "none")
    ///     // Prints: 10
    ///
    /// - Returns: The sequence’s maximum element. If the sequence has no
    ///   elements, returns `nil`.
    @inlinable
    @warn_unqualified_access
    public func max() async rethrows -> Element? {
        return try await self.max(by: <)
    }
}
