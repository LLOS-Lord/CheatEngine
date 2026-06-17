#import "MemoryEngine.h"
#import <mach/mach_vm.h>
#import <stdlib.h>

@implementation MemoryResult
@end

@implementation MemoryEngine

+ (kern_return_t)getTaskPortForPID:(int)pid taskPort:(mach_port_t *)task {
    return task_for_pid(mach_task_self_, pid, task);
}

+ (NSArray<MemoryResult *> *)scanMemoryOfTask:(mach_port_t)task
                                         dataType:(ScanDataType)type
                                     targetValue:(id)value {
    NSMutableArray *results = [NSMutableArray array];
    mach_vm_address_t address = 1; // bắt đầu từ 1, tránh NULL
    mach_vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name = MACH_PORT_NULL;
    kern_return_t kr;

    while (true) {
        kr = mach_vm_region(task, &address, &size, VM_REGION_BASIC_INFO_64,
                            (vm_region_info_t)&info, &info_count, &object_name);
        if (kr != KERN_SUCCESS) break;

        // Chỉ đọc nếu vùng có quyền đọc và không phải guard/reserved
        if (info.protection & VM_PROT_READ && !(info.protection & VM_PROT_WRITE) == NO) {
            size_t data_size = (size_t)size;
            uint8_t *buffer = (uint8_t *)malloc(data_size);
            mach_vm_size_t bytes_read = 0;
            kr = mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)buffer, &bytes_read);
            if (kr == KERN_SUCCESS && bytes_read > 0) {
                [self scanBuffer:buffer length:bytes_read baseAddress:address
                         dataType:type targetValue:value intoResults:results];
            }
            free(buffer);
        }
        address += size;
    }
    return results;
}

+ (void)scanBuffer:(const uint8_t *)buffer length:(size_t)length baseAddress:(mach_vm_address_t)base
          dataType:(ScanDataType)type targetValue:(id)value intoResults:(NSMutableArray *)results {
    size_t step = 0;
    switch (type) {
        case ScanDataTypeInt32: step = sizeof(int32_t); break;
        case ScanDataTypeFloat: step = sizeof(float); break;
        case ScanDataTypeString: step = 1; break; // sẽ xử lý riêng
    }
    if (type != ScanDataTypeString) {
        for (size_t i = 0; i + step <= length; i++) {
            if (type == ScanDataTypeInt32) {
                int32_t current = *(int32_t *)(buffer + i);
                if (current == [value intValue]) {
                    MemoryResult *res = [MemoryResult new];
                    res.address = base + i;
                    res.value = @(current);
                    [results addObject:res];
                }
            } else if (type == ScanDataTypeFloat) {
                float current = *(float *)(buffer + i);
                if (fabsf(current - [value floatValue]) < 0.0001f) {
                    MemoryResult *res = [MemoryResult new];
                    res.address = base + i;
                    res.value = @(current);
                    [results addObject:res];
                }
            }
        }
    } else {
        // Tìm chuỗi UTF-8
        const char *search = [value UTF8String];
        size_t searchLen = strlen(search);
        for (size_t i = 0; i + searchLen <= length; i++) {
            if (memcmp(buffer + i, search, searchLen) == 0) {
                MemoryResult *res = [MemoryResult new];
                res.address = base + i;
                res.value = [NSString stringWithUTF8String:(const char *)(buffer + i)];
                [results addObject:res];
            }
        }
    }
}

+ (kern_return_t)writeInt32ToTask:(mach_port_t)task
                          address:(mach_vm_address_t)address
                             value:(int32_t)newValue {
    return mach_vm_write(task, address, (vm_offset_t)&newValue, sizeof(newValue));
}

+ (kern_return_t)writeFloatToTask:(mach_port_t)task
                           address:(mach_vm_address_t)address
                             value:(float)newValue {
    return mach_vm_write(task, address, (vm_offset_t)&newValue, sizeof(newValue));
}

@end