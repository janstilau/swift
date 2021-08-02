/// A value that represents either a success or a failure
/// Including an associated value in each case.

/*
    Throw 是漂亮的多类型返回值的表现形式.
    泛型类型, 是模板类型, 只有里面的子类型确认之后, 才真正确定了一个类型.
 */

@frozen
public enum Result<Success, Failure: Error> {
    // 每次, 确定 Result 的时候, 都要显式指明, Success, Error 的类型.
    // 例如, KF 里面, memoryCache 操作不会失败, Error 也指定了是 Never.
    
    /// A success, storing a `Success` value.
    // 一个专门的 case, 代表 Right, 附带的数据是对应的场景的模型
    case success(Success)
    
    /// A failure, storing a `Failure` value.
    // 一个专门的 case, 代表 Wrong, 附带的数据, 是表示 error 的模型.
    case failure(Failure)
    
    // Map, 就是保留 failure 的值不变, 如果是 success 的话, 就抽取里面的值, 然后进行 transform 进行变化.
    // 最终生成一个 Result, 来包含上面的逻辑.
    // 所以, map 的结果是, success 的时候, 业务值可以继续处理.
    // fail 的时候, 原来的 error 信息保持不变
    // 这个逻辑是一脉相承自 Optinal 的.
    public func map<NewSuccess>(
        _ transform: (Success) -> NewSuccess
    ) -> Result<NewSuccess, Failure> {
        // 里面的逻辑, 也是很简单. 就是分类型处理.
        // 如果是 success, 那么取出 success 进行变化然后塞回到 Success 里面.
        // 如果是 failed, 那么返回原始的 failuer 的值.
        switch self {
        case let .success(success):
            return .success(transform(success))
        case let .failure(failure):
            return .failure(failure)
        }
    }
    
    // 这个就是上面的另外一个 side.
    // success 的时候, 业务值保持不变.
    // fail 的时候, error 的值继续处理
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
    
    /*
        FlatMap 可以实现, 时间线上对于 Success 值进行判断的逻辑.
        map 函数, 用于值的转化工作.
        而面对不同的业务值, 不同的场景下, 对于 Success 的要求是不一样的.
        这种场景下, 就是存储不同阶段的对于业务值的判断 block. 然后在时间线的逻辑上, 取出各种对于 Block, 各种 Block 自己完成对于业务值的判断, 返回对应的 Result 类型.
     */
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
    
    // get 就是拿去 success 情况下的值. 如果是失败的话, 就抛出异常.
    // Throws 就是双返回值的一个函数.
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
