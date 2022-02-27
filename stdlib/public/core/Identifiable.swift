
// 系统提供了一个, 使用某个值来标明自己唯一身份的协议 
public protocol Identifiable {
    
    /// A type representing the stable identity of the entity associated with
    /// an instance.
    associatedtype ID: Hashable
    
    /// The stable identity of the entity associated with this instance.
    var id: ID { get }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Identifiable where Self: AnyObject {
    public var id: ObjectIdentifier {
        return ObjectIdentifier(self)
    }
}
