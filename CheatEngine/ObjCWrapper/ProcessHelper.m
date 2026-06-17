#import "ProcessHelper.h"
#include <sys/sysctl.h>
#include <sys/types.h>

@implementation RunningProcessInfo
@end

@implementation ProcessHelper

+ (NSArray<RunningProcessInfo *> *)runningProcesses {
    NSMutableArray *list = [NSMutableArray array];
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size;
    if (sysctl(mib, 4, NULL, &size, NULL, 0) < 0) return list;
    
    struct kinfo_proc *procs = (struct kinfo_proc *)malloc(size);
    if (sysctl(mib, 4, procs, &size, NULL, 0) < 0) {
        free(procs);
        return list;
    }
    
    int count = (int)(size / sizeof(struct kinfo_proc));
    for (int i = 0; i < count; i++) {
        struct kinfo_proc *proc = &procs[i];
        if (proc->kp_proc.p_pid == 0) continue;
        
        RunningProcessInfo *info = [[RunningProcessInfo alloc] init];
        info.pid = proc->kp_proc.p_pid;
        
        // Sử dụng tên ngắn từ p_comm (không cần proc_pidpath)
        info.name = [NSString stringWithUTF8String:proc->kp_proc.p_comm];
        
        [list addObject:info];
    }
    free(procs);
    return list;
}

@end
