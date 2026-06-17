#import <Foundation/Foundation.h>
#include <mach/mach.h>

typedef NS_ENUM(NSInteger, ScanDataType) {
    ScanDataTypeInt32,
    ScanDataTypeFloat,
    ScanDataTypeString
};

@interface MemoryResult : NSObject
@property (nonatomic, assign) mach_vm_address_t address;
@property (nonatomic, strong) id value;
@end

@interface MemoryEngine : NSObject

+ (kern_return_t)getTaskPortForPID:(int)pid taskPort:(mach_port_t *)task;

+ (NSArray<MemoryResult *> *)scanMemoryOfTask:(mach_port_t)task
                                         dataType:(ScanDataType)type
                                     targetValue:(id)value;

+ (kern_return_t)writeInt32ToTask:(mach_port_t)task
                          address:(mach_vm_address_t)address
                             value:(int32_t)newValue;

+ (kern_return_t)writeFloatToTask:(mach_port_t)task
                           address:(mach_vm_address_t)address
                             value:(float)newValue;

@end