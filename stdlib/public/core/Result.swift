/// A value that represents either a success or a failure, including an
/// associated value in each case.
@frozen
public enum Result<Success, Failure: Error> {
    /// A success, storing a `Success` value.
    // 一个专门的 case, 代表 Right, 附带的数据是对应的场景的模型
    case success(Success)
    
    /// A failure, storing a `Failure` value.
    // 一个专门的 case, 代表 Wrong, 附带的数据, 是表示 error 的模型.
    case failure(Failure)
    
    // Map, 就是保留 failure 的值不变, 如果是 success 的话, 就抽取里面的值, 然后进行 transform 进行变化.
    // 最终生成一个 Result, 来包含上面的逻辑.
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
    
    // 这个就是上面的另外一个 side.
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
    
    // Flat 的版本, 就是接受一个值, 然后直接生成 Result.
    // 使用 Flat, 就是避免, 再次进行封包的过程. 再次封包, 会导致使用者要进行两次解包.
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
    
    public func get() throws -> Success {
        switch self {
            case let .success(success):
                return success
            case let .failure(failure):
                throw failure
        }
    }
}

// 非常方便的封装, Result 的生成过程, 就是 body 的调用过程.
// Body 的调用, 会直接变为 Result 的数据.
extension Result where Failure == Swift.Error {
    @_transparent
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
