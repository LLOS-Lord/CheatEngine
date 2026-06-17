#import <Foundation/Foundation.h>

@interface RunningProcessInfo : NSObject
@property (nonatomic, assign) int pid;
@property (nonatomic, strong) NSString *name;
@end

@interface ProcessHelper : NSObject
+ (NSArray<RunningProcessInfo *> *)runningProcesses;
@end