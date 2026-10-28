#import "PPOBridgeClient.h"
#import "PPOBridgeProtocol.h"
#include "PPOBridgeIO.h"
#include <unistd.h>
#include <errno.h>
#include <time.h>

struct PPOBridgeDirectoryGuard {
    int descriptor;
    explicit PPOBridgeDirectoryGuard(int value) : descriptor(value) {}
    ~PPOBridgeDirectoryGuard() { if (descriptor >= 0) close(descriptor); }
};

static NSDictionary *PPOClientError(NSError **error, int code) {
    if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
    return nil;
}

NSDictionary *PPOBridgeSend(NSString *operation, NSString *identifier, NSError **error) {
    if (NSThread.isMainThread) return PPOClientError(error, EDEADLK);
    @try {
        NSString *nonce = NSUUID.UUID.UUIDString;
        NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
        NSData *request = PPOBridgeRequestData(nonce, operation, identifier, start, error);
        if (!request) return nil;
        int directory = PPOBridgeOpenDirectory(PPOBridgeMailboxPath().fileSystemRepresentation);
        if (directory < 0) return PPOClientError(error, errno);
        PPOBridgeDirectoryGuard guard(directory);
        int code = PPOBridgeWrite(directory, "request.json", request.bytes, request.length);
        NSDictionary *response = nil;
        while (!code && NSProcessInfo.processInfo.systemUptime - start < 8) {
            char bytes[4096];
            size_t count = 0;
            int readError = PPOBridgeRead(directory, "response.json", bytes, sizeof(bytes), &count);
            if (!readError) {
                response = PPOBridgeResponseFromData([NSData dataWithBytes:bytes length:count], nonce, NULL);
                if (response) break;
            } else if (readError != ENOENT) { code = readError; break; }
            const timespec pause = {0, 100000000};
            nanosleep(&pause, nullptr);
        }
        if (response) return response;
        return PPOClientError(error, code ? code : ETIMEDOUT);
    } @catch (NSException *exception) {
        (void)exception;
        return PPOClientError(error, EIO);
    }
}
