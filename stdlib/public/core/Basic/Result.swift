/// A value that represents either a success or a failure, including an
/// associated value in each case.

// 这是一个数据包装类.
/*
 如果, 是 Success, 那么取 Case 为 Success 的关联值.
 如果, 是 Fail, 那么取 Case 为 Fail 的关联值.
 */

/*
 Enum, 当做一个盒子. 这个盒子里面有着两个大分类, Success, Failure.
 但是两个分类之下的盒子里面, 可以装任意类型的值.
 */
public enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
    
    // 注意, 返回值的类型, 其实是收到了原来的 Result 类型的限制的
    // 这种使用方法, 其实和 Optional 的 Map 的使用, 没有任何的区别.
    public func map<NewSuccess>(
        _ transform: (Success) -> NewSuccess
    ) -> Result<NewSuccess, Failure> {
        switch self {
        case let .success(success):
            return .success(transform(success))
        case let .failure(failure):
            return .failure(failure)
        }
    }
    
    public func mapError<NewFailure>(
        _ transform: (Failure) -> NewFailure
    ) -> Result<Success, NewFailure> {
        switch self {
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return .failure(transform(failure))
        }
    }
    
    // Flat 多一层解包的逻辑.
    // 这在 Sequence 里面, 也是一样的.
    public func flatMap<NewSuccess>(
        _ transform: (Success) -> Result<NewSuccess, Failure>
    ) -> Result<NewSuccess, Failure> {
        switch self {
        case let .success(success):
            return transform(success)
        case let .failure(failure):
            return .failure(failure)
        }
    }
    
    public func flatMapError<NewFailure>(
        _ transform: (Failure) -> Result<Success, NewFailure>
    ) -> Result<Success, NewFailure> {
        switch self {
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return transform(failure)
        }
    }
    
    // 使用这个方法, try? 可以将一个 throw 方法的值提取出来. 这样要比 case 的方式更加的方便.
    // 这里的 Get, 和下面的 Init 方法, 分别代表着, Result 这个包装对象, 和最原始的 Success 对象直接桥接的方式.
    @inlinable
    public func get() throws -> Success {
        switch self {
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }
}

extension Result where Failure == Swift.Error {
    public init(catching body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch {
            self = .failure(error)
        }
    }
}

extension Result: Equatable where Success: Equatable, Failure: Equatable { }

extension Result: Hashable where Success: Hashable, Failure: Hashable { }

extension Result: Sendable where Success: Sendable, Failure: Sendable { }
