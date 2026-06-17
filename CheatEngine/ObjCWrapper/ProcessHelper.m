#import "ProcessHelper.h"
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <sys/types.h>

@implementation RunningProcessInfo
@end

@implementation ProcessHelper

+ (NSArray<RunningProcessInfo *> *)runningProcesses {
    NSMutableArray *list = [NSMutableArray array];
    
    // Phương pháp mới: duyệt tất cả PID khả dĩ, dùng task_for_pid để kiểm tra sự tồn tại
    // Do có entitlement task_for_pid-allow, ta có thể lấy task port của tiến trình khác
    for (pid_t pid = 1; pid < 65536; pid++) {
        mach_port_t task = MACH_PORT_NULL;
        kern_return_t kr = task_for_pid(mach_task_self_, pid, &task);
        if (kr == KERN_SUCCESS) {
            // Nếu lấy được task port, PID đó tồn tại và ta có quyền truy cập
            // Giải phóng task port ngay vì không cần giữ
            mach_port_deallocate(mach_task_self_, task);
            
            // Lấy tên tiến trình
            char name[PROC_PIDPATHINFO_MAXSIZE] = {0};
            NSString *procName = nil;
            // Dùng proc_pidpath nếu có (từ libproc)
#if __has_include(<libproc.h>)
            if (proc_pidpath(pid, name, sizeof(name)) > 0) {
                procName = [NSString stringWithUTF8String:name];
            }
#endif
            // Nếu không lấy được đường dẫn, dùng tên ngắn từ sysctl
            if (procName == nil) {
                struct kinfo_proc kp;
                size_t len = sizeof(kp);
                int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
                if (sysctl(mib, 4, &kp, &len, NULL, 0) == 0) {
                    procName = [NSString stringWithUTF8String:kp.kp_proc.p_comm];
                } else {
                    procName = [NSString stringWithFormat:@"PID %d", pid];
                }
            }
            
            RunningProcessInfo *info = [[RunningProcessInfo alloc] init];
            info.pid = pid;
            info.name = procName;
            [list addObject:info];
        }
        // Nếu kr != KERN_SUCCESS, bỏ qua PID này (không tồn tại hoặc không có quyền)
    }
    
    return list;
}

@end
