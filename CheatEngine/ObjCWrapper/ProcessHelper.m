#import "ProcessHelper.h"
#include <sys/sysctl.h>
#include <sys/types.h>
#include <stdlib.h>

// Thử include libproc.h nếu có (cho phép lấy pid chính xác hơn)
#if __has_include(<libproc.h>)
    #include <libproc.h>
    #define HAS_LIBPROC 1
#else
    #define HAS_LIBPROC 0
#endif

@implementation RunningProcessInfo
@end

@implementation ProcessHelper

+ (NSArray<RunningProcessInfo *> *)runningProcesses {
    NSMutableArray *list = [NSMutableArray array];
    
#if HAS_LIBPROC
    // Phương pháp dùng proc_listallpids (ưu tiên vì đáng tin cậy trên iOS)
    int numberOfProcesses = proc_listallpids(NULL, 0);
    if (numberOfProcesses <= 0) {
        // fallback sang sysctl nếu lỗi
        goto fallback_sysctl;
    }
    
    pid_t *pids = (pid_t *)malloc(sizeof(pid_t) * numberOfProcesses);
    numberOfProcesses = proc_listallpids(pids, numberOfProcesses * sizeof(pid_t));
    if (numberOfProcesses <= 0) {
        free(pids);
        goto fallback_sysctl;
    }
    
    int count = numberOfProcesses / sizeof(pid_t); // thực tế trả về số byte
    // proc_listallpids trả về số byte đã ghi, cần chia cho sizeof(pid_t) để có số pid
    count = numberOfProcesses / sizeof(pid_t);
    for (int i = 0; i < count; i++) {
        pid_t pid = pids[i];
        if (pid == 0) continue;
        
        char name[PROC_PIDPATHINFO_MAXSIZE] = {0};
        if (proc_pidpath(pid, name, sizeof(name)) > 0) {
            RunningProcessInfo *info = [[RunningProcessInfo alloc] init];
            info.pid = pid;
            info.name = [NSString stringWithUTF8String:name];
            [list addObject:info];
        } else {
            // Nếu không lấy được đường dẫn, dùng tên ngắn từ sysctl
            struct kinfo_proc kp;
            size_t len = sizeof(kp);
            int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
            if (sysctl(mib, 4, &kp, &len, NULL, 0) == 0) {
                RunningProcessInfo *info = [[RunningProcessInfo alloc] init];
                info.pid = pid;
                info.name = [NSString stringWithUTF8String:kp.kp_proc.p_comm];
                [list addObject:info];
            }
        }
    }
    free(pids);
    return list;
    
fallback_sysctl:
#endif

    // Fallback: dùng sysctl (có thể bị giới hạn trên iOS 15+)
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
        info.name = [NSString stringWithUTF8String:proc->kp_proc.p_comm];
        [list addObject:info];
    }
    free(procs);
    return list;
}

@end