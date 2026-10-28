#import <Foundation/Foundation.h>
#import "../../PPOBridgeProtocol.h"
#include "../../PPOBridgeIO.h"
#import "PPOBridgeService.h"
#include <unistd.h>
#include <sys/file.h>
#include <sys/event.h>
#include <errno.h>
#include <stdio.h>
#include <time.h>

static NSData *PPOReadMessage(int directory, const char *name) {
    char bytes[4096]; size_t count = 0;
    return PPOBridgeRead(directory, name, bytes, sizeof(bytes), &count) == 0
        ? [NSData dataWithBytes:bytes length:count] : nil;
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
#if defined(PPO_BRIDGE_TESTING)
        BOOL validUser = getuid() == geteuid();
#else
        BOOL validUser = getuid() == 501 && geteuid() == 501;
#endif
        if (argc != 2 || strcmp(argv[1], "--serve") || !validUser) {
            fprintf(stderr, "ppo-bridge --serve requires mobile (uid 501).\n"); return 2;
        }
        NSString *parent = PPOBridgeMailboxPath().stringByDeletingLastPathComponent;
        if (![NSFileManager.defaultManager createDirectoryAtPath:parent
            withIntermediateDirectories:YES attributes:nil error:NULL]) return 3;
        int directory = PPOBridgeOpenDirectory(PPOBridgeMailboxPath().fileSystemRepresentation);
        if (directory < 0) return 3;
        // One service owns this mailbox; never take over a running instance.
        if (flock(directory, LOCK_EX | LOCK_NB)) { close(directory); return 4; }
        int events = kqueue();
        if (events < 0) { close(directory); return 5; }
        struct kevent change;
        EV_SET(&change, directory, EVFILT_VNODE, EV_ADD | EV_CLEAR,
            NOTE_WRITE | NOTE_RENAME | NOTE_DELETE, 0, nullptr);
        if (kevent(events, &change, 1, nullptr, 0, nullptr) < 0) {
            close(events); close(directory); return 5;
        }
        // Requests surviving service restart are NEVER replayed, even if recent.
        NSData *previous = PPOReadMessage(directory, "request.json");
        NSData *ready = PPOBridgeResponseData(NSUUID.UUID.UUIDString, @"ready", @"service-ready",
            nil, NSProcessInfo.processInfo.systemUptime, NULL);
        if (!ready || PPOBridgeWrite(directory, "heartbeat.json", ready.bytes, ready.length)) return 7;
        NSMutableDictionary<NSString *, NSNumber *> *seen = [NSMutableDictionary dictionary];
        for (;;) {
            @autoreleasepool {
                NSData *request = PPOReadMessage(directory, "request.json");
                if (request && ![request isEqual:previous]) {
                    previous = request;
                    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
                    for (NSString *nonce in [seen.allKeys copy]) {
                        if (now - seen[nonce].doubleValue > 30) [seen removeObjectForKey:nonce];
                    }
                    NSError *validationError = nil;
                    NSDictionary *validated = PPOBridgeRequestFromData(request, now, &validationError);
                    BOOL expired = !validated && [validationError.domain isEqual:@"PullOverPro.BridgeProtocol"] && validationError.code == 2;
                    if (expired) {
                        NSDictionary *envelope = [NSJSONSerialization JSONObjectWithData:request options:0 error:NULL];
                        validated = PPOBridgeRequestFromData(request, [envelope[@"createdUptime"] doubleValue], NULL);
                    }
                    NSString *nonce = validated[@"nonce"];
                    NSData *response = nil;
                    if (nonce && expired) {
                        response = PPOBridgeResponseData(nonce, @"stale", @"request-expired", nil, now, NULL);
                    } else if (nonce && seen[nonce]) {
                        response = PPOBridgeResponseData(nonce, @"rejected", @"replayed-request", nil, now, NULL);
                    } else if (nonce && seen.count >= 128) {
                        response = PPOBridgeResponseData(nonce, @"busy", @"request-limit", nil, now, NULL);
                    } else if (nonce) {
                        seen[nonce] = @(now); // Consume before any private call.
                        // Alarm affects only this service, never SpringBoard.
                        alarm(20);
#if defined(PPO_BRIDGE_TESTING)
                        response = PPOBridgeServiceResponseWithDisablePath(request,
                            [parent stringByAppendingPathComponent:@"apps-0.5.7.json"],
                            [parent stringByAppendingPathComponent:@".ppo_disable"]);
#else
                        response = PPOBridgeServiceResponse(request,
                            [parent stringByAppendingPathComponent:@"apps-0.5.7.json"]);
#endif
                        alarm(0);
                    }
                    if (response) {
                        int code = PPOBridgeWrite(directory, "response.json", response.bytes, response.length);
                        if (code) NSLog(@"[PPO bridge] response-write-error=%d", code);
                    }
                }
            }
            struct kevent event;
            int ready = kevent(events, nullptr, 0, &event, 1, nullptr);
            if (ready < 0 && errno != EINTR) return 6;
            if (ready > 0 && (event.fflags & (NOTE_DELETE | NOTE_RENAME))) return 6;
        }
    }
}
