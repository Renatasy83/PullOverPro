// Debug builds log each step to /var/tmp/pulloverpro.log (release builds: no-op).
#import <Foundation/Foundation.h>
#if DEBUG
static inline void POLogLine(NSString *line) {
    static dispatch_queue_t q;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ q = dispatch_queue_create("pulloverpro.log", DISPATCH_QUEUE_SERIAL); });
    NSString *stamped = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], line];
    dispatch_async(q, ^{
        NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:@"/var/tmp/pulloverpro.log"];
        if (!h) { [stamped writeToFile:@"/var/tmp/pulloverpro.log" atomically:NO encoding:NSUTF8StringEncoding error:nil]; return; }
        [h seekToEndOfFile];
        [h writeData:[stamped dataUsingEncoding:NSUTF8StringEncoding]];
        [h closeFile];
    });
}
#define POLog(fmt, ...) POLogLine([NSString stringWithFormat:fmt, ##__VA_ARGS__])
#else
#define POLog(fmt, ...) do {} while (0)
#endif
