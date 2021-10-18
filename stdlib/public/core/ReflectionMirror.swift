@_silgen_name("swift_reflectionMirror_normalizedType")
internal func _getNormalizedType<T>(_: T, type: Any.Type) -> Any.Type

@_silgen_name("swift_reflectionMirror_count")
internal func _getChildCount<T>(_: T, type: Any.Type) -> Int

internal typealias NameFreeFunc = @convention(c) (UnsafePointer<CChar>?) -> Void

@_silgen_name("swift_reflectionMirror_subscript")
internal func _getChild<T>(
    of: T,
    type: Any.Type,
    index: Int,
    outName: UnsafeMutablePointer<UnsafePointer<CChar>?>,
    outFreeFunc: UnsafeMutablePointer<NameFreeFunc?>
) -> Any

// Returns 'c' (class), 'e' (enum), 's' (struct), 't' (tuple), or '\0' (none)
@_silgen_name("swift_reflectionMirror_displayStyle")
internal func _getDisplayStyle<T>(_: T) -> CChar

// getChild 的实现.
internal func getChild<T>(of value: T, type: Any.Type, index: Int) -> (label: String?, value: Any) {
    var nameC: UnsafePointer<CChar>? = nil
    var freeFunc: NameFreeFunc? = nil
    
    /*
     通过 _getChild 做真正的 name 获取, value 获取的工作.
     */
    let value = _getChild(of: value, type: type, index: index, outName: &nameC, outFreeFunc: &freeFunc)
    
    let name = nameC.flatMap({ String(validatingUTF8: $0) })
    freeFunc?(nameC)
    return (name, value)
}

#if _runtime(_ObjC)
@_silgen_name("swift_reflectionMirror_quickLookObject")
internal func _getQuickLookObject<T>(_: T) -> AnyObject?

@_silgen_name("_swift_stdlib_NSObject_isKindOfClass")
internal func _isImpl(_ object: AnyObject, kindOf: AnyObject) -> Bool

internal func _is(_ object: AnyObject, kindOf `class`: String) -> Bool {
    return _isImpl(object, kindOf: `class` as AnyObject)
}

internal func _getClassPlaygroundQuickLook(
    _ object: AnyObject
) -> _PlaygroundQuickLook? {
    if _is(object, kindOf: "NSNumber") {
        let number: _NSNumber = unsafeBitCast(object, to: _NSNumber.self)
        switch UInt8(number.objCType[0]) {
        case UInt8(ascii: "d"):
            return .double(number.doubleValue)
        case UInt8(ascii: "f"):
            return .float(number.floatValue)
        case UInt8(ascii: "Q"):
            return .uInt(number.unsignedLongLongValue)
        default:
            return .int(number.longLongValue)
        }
    }
    
    if _is(object, kindOf: "NSAttributedString") {
        return .attributedString(object)
    }
    
    if _is(object, kindOf: "NSImage") ||
        _is(object, kindOf: "UIImage") ||
        _is(object, kindOf: "NSImageView") ||
        _is(object, kindOf: "UIImageView") ||
        _is(object, kindOf: "CIImage") ||
        _is(object, kindOf: "NSBitmapImageRep") {
        return .image(object)
    }
    
    if _is(object, kindOf: "NSColor") ||
        _is(object, kindOf: "UIColor") {
        return .color(object)
    }
    
    if _is(object, kindOf: "NSBezierPath") ||
        _is(object, kindOf: "UIBezierPath") {
        return .bezierPath(object)
    }
    
    if _is(object, kindOf: "NSString") {
        return .text(_forceBridgeFromObjectiveC(object, String.self))
    }
    
    return .none
}
#endif

extension Mirror {
    
    /*
        将, 解析工作, 全都放到了这个分类里面, 
     */
    
    internal init(internalReflecting subject: Any,
                  subjectType: Any.Type? = nil,
                  customAncestor: Mirror? = nil)
    {
        /*
         在这个方法里面, 就是使用 C++ 的各种函数, 做元信息的抽取的工作.
         */
        // _getNormalizedType 这个函数, 用来获取 subject 的类型
        let subjectType = subjectType ?? _getNormalizedType(subject, type: type(of: subject))
        
        /*
         获取, 元信息的个数.
         getChild 获取, 元信息的内容. 这是一个 LazyMap, 存储的闭包, 是根据 示例对象, 示例对象的元类型, 以及位置信息, 生成一个新的对象.
         这个新的对象里面, 就有 key, value 的信息了.
         */
        let childCount = _getChildCount(subject, type: subjectType)
        let children = (0 ..< childCount).lazy.map({
            getChild(of: subject,
                     type: subjectType,
                     index: $0)
        })
        
        self.children = Children(children)
        
        self._makeSuperclassMirror = {
            // 首先, 根据当前的 元类型, 找到它的父类的元类型.
            guard let subjectClass = subjectType as? AnyClass,
                  let superclass = _getSuperclass(subjectClass) else {
                      return nil
                  }
            
            // Handle custom ancestors. If we've hit the custom ancestor's subject type,
            // or descendants are suppressed, return it. Otherwise continue reflecting.
            if let customAncestor = customAncestor {
                if superclass == customAncestor.subjectType {
                    return customAncestor
                }
                if customAncestor._defaultDescendantRepresentation == .suppressed {
                    return customAncestor
                }
            }
            
            // 然后就是, 重新生成一个 Mirror, 将父类的类型信息传递进去.
            return Mirror(internalReflecting: subject,
                          subjectType: superclass,
                          customAncestor: customAncestor)
        }
        
        let rawDisplayStyle = _getDisplayStyle(subject)
        switch UnicodeScalar(Int(rawDisplayStyle)) {
        case "c": self.displayStyle = .class
        case "e": self.displayStyle = .enum
        case "s": self.displayStyle = .struct
        case "t": self.displayStyle = .tuple
        case "\0": self.displayStyle = nil
        default: preconditionFailure("Unknown raw display style '\(rawDisplayStyle)'")
        }
        
        self.subjectType = subjectType
        self._defaultDescendantRepresentation = .generated
    }
    
    internal static func quickLookObject(_ subject: Any) -> _PlaygroundQuickLook? {
#if _runtime(_ObjC)
        let object = _getQuickLookObject(subject)
        return object.flatMap(_getClassPlaygroundQuickLook)
#else
        return nil
#endif
    }
}
