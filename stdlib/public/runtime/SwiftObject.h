#ifndef SWIFT_RUNTIME_SWIFTOBJECT_H
#define SWIFT_RUNTIME_SWIFTOBJECT_H

#include "swift/Runtime/Config.h"
#include <cstdint>
#include <utility>
#include "swift/Runtime/HeapObject.h"
#if SWIFT_OBJC_INTEROP
#include "llvm/Support/Compiler.h"
#include <objc/NSObject.h>
#endif


#if SWIFT_OBJC_INTEROP

// Source code: "SwiftObject"
// Real class name: mangled "Swift._SwiftObject"
#define SwiftObject _TtCs12_SwiftObject

#if __has_attribute(objc_root_class)
__attribute__((__objc_root_class__))
#endif

/*
        Swfit 里面的对象, 为什么可以到 OC 环境里面, 是因为, 在这里.
 */
SWIFT_RUNTIME_EXPORT @interface SwiftObject<NSObject> {
@private
    Class isa;
    SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS;
}

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

- (Class)superclass;
- (Class)class;
- (instancetype)self;
- (struct _NSZone *)zone;

- (id)performSelector:(SEL)aSelector;
- (id)performSelector:(SEL)aSelector withObject:(id)object;
- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

- (BOOL)isProxy;

+ (BOOL)isSubclassOfClass:(Class)aClass;
- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)isMemberOfClass:(Class)aClass;
- (BOOL)conformsToProtocol:(Protocol *)aProtocol;

- (BOOL)respondsToSelector:(SEL)aSelector;
+ (BOOL)instancesRespondToSelector:(SEL)aSelector;
- (IMP)methodForSelector:(SEL)aSelector;
+ (IMP)instanceMethodForSelector:(SEL)aSelector;

- (instancetype)retain;
- (oneway void)release;
- (instancetype)autorelease;
- (NSUInteger)retainCount;

- (NSString *)description;
- (NSString *)debugDescription;

@end

namespace swift {

NSString *getDescription(OpaqueValue *value, const Metadata *type);

}

#endif

#endif
