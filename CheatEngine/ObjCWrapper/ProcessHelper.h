#import <Foundation/Foundation.h>

@interface ProcessInfo : NSObject
@property (nonatomic, assign) int pid;
@property (nonatomic, strong) NSString *name;
@end

@interface ProcessHelper : NSObject
+ (NSArray<ProcessInfo *> *)runningProcesses;
@end