#import "../PPOFavoritesStore.h"
#import "../PPOFavoriteApps.h"
#import <dispatch/dispatch.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned checks;
static void Check(BOOL condition, const char *name) {
    ++checks;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}

static NSString *Child(NSString *directory, NSString *name) {
    return [directory stringByAppendingPathComponent:name];
}
static NSString *File(NSString *directory) { return Child(directory, @"favorites.plist"); }
static void MakeDirectory(NSString *path) {
    Check(mkdir(path.fileSystemRepresentation, 0700) == 0, "create isolated fixture directory");
    Check(chmod(path.fileSystemRepresentation, 0700) == 0, "set fixture directory permissions");
}
static mode_t Mode(NSString *path) {
    struct stat status = {};
    Check(lstat(path.fileSystemRepresentation, &status) == 0, "stat fixture path");
    return status.st_mode & 07777;
}
static BOOL Missing(NSString *path) {
    struct stat status = {};
    return lstat(path.fileSystemRepresentation, &status) < 0 && errno == ENOENT;
}
static void WriteBytes(NSString *path, NSData *data, mode_t mode = 0600) {
    int descriptor = open(path.fileSystemRepresentation, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, mode);
    Check(descriptor >= 0, "open fixture file");
    Check(fchmod(descriptor, mode) == 0, "set fixture file permissions");
    size_t offset = 0;
    while (offset < data.length) {
        ssize_t count = write(descriptor, static_cast<const unsigned char *>(data.bytes) + offset,
            data.length - offset);
        if (count < 0 && errno == EINTR) continue;
        Check(count > 0, "write fixture file");
        offset += static_cast<size_t>(count);
    }
    Check(close(descriptor) == 0, "close fixture file");
}
static NSData *Bytes(NSString *path) {
    NSData *data = [NSData dataWithContentsOfFile:path];
    Check(data != nil, "read fixture bytes");
    return data;
}
static void NoTemporaries(NSString *directory) {
    NSArray<NSString *> *names = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:NULL];
    Check(names != nil, "enumerate isolated fixture directory");
    for (NSString *name in names)
        Check(![name hasPrefix:@".favorites-"], "store leaves no temporary files");
}
static void Rejected(NSString *directory, NSArray<NSString *> *expected, NSData *preserved) {
    NSError *error = nil;
    Check(PPOFavoritesLoad(directory, &error) == nil && error != nil, "unsafe or corrupt load fails");
    error = nil;
    Check(!PPOFavoritesCommit(directory, expected, @[@"com.example.replacement"], &error) && error != nil,
        "unsafe or corrupt commit fails");
    if (preserved) Check([Bytes(File(directory)) isEqual:preserved], "failed commit preserves exact bytes");
    NoTemporaries(directory);
}

static void RunFixtures(NSString *root) {
    Check(!NSThread.isMainThread, "all storage fixtures run on a worker");
    NSArray<NSString *> *first = @[@"com.example.alpha", @"com.example.beta"];
    NSString *directory = Child(root, @"round-trip");
    NSError *error = [NSError errorWithDomain:@"fixture" code:1 userInfo:nil];
    NSArray<NSString *> *empty = PPOFavoritesLoad(directory, &error);
    Check(empty != nil && empty.count == 0 && error == nil, "genuinely missing favorites are empty");
    Check(![empty isKindOfClass:NSMutableArray.class], "missing result is immutable");
    Check(Mode(directory) == 0700 && Missing(File(directory)), "load creates only a private directory");

    NSMutableString *mutableIdentifier = [@"com.example.alpha" mutableCopy];
    NSMutableArray *mutableReplacement = [NSMutableArray arrayWithObjects:mutableIdentifier,
        @"com.example.beta", nil];
    Check(PPOFavoritesCommit(directory, @[], mutableReplacement, &error) && error == nil,
        "commit normalized mutable input");
    [mutableIdentifier setString:@"com.example.changed"];
    [mutableReplacement removeAllObjects];
    NSArray<NSString *> *loaded = PPOFavoritesLoad([directory copy], &error);
    Check([loaded isEqual:first] && error == nil, "reopened store persists copied identifiers in order");
    Check(![loaded isKindOfClass:NSMutableArray.class] &&
        ![loaded.firstObject isKindOfClass:NSMutableString.class], "loaded identifiers are immutable");
    Check(Mode(File(directory)) == 0600 && Mode(directory) == 0700, "store retains exact private modes");
    NSData *original = Bytes(File(directory));
    Check([PPOFavoriteIdentifiersFromData(original, NULL) isEqual:first], "stored plist uses the pure data format");
    error = nil;
    Check(!PPOFavoritesCommit(directory, @[], @[@"com.example.stale"], &error) &&
        [error.domain isEqual:NSPOSIXErrorDomain] && error.code == ESTALE, "stale expected identifiers fail");
    Check([Bytes(File(directory)) isEqual:original], "expected conflict preserves original bytes");
    NSArray<NSString *> *reversed = @[first[1], first[0]];
    Check(PPOFavoritesCommit(directory, first, reversed, &error), "ordered replacement commits");
    Check([PPOFavoritesLoad(directory, NULL) isEqual:reversed], "order is persisted");
    Check(PPOFavoritesCommit(directory, reversed, @[], &error), "empty replacement commits");
    Check([PPOFavoritesLoad(directory, NULL) isEqual:@[]], "persisted empty list reopens");
    NSString *unrelated = Child(directory, @"unrelated.txt");
    NSData *sentinel = [@"do not change this file" dataUsingEncoding:NSUTF8StringEncoding];
    WriteBytes(unrelated, sentinel, 0644);
    Check(PPOFavoritesCommit(directory, @[], first, NULL), "commit with unrelated files present");
    Check([Bytes(unrelated) isEqual:sentinel] && Mode(unrelated) == 0644, "unrelated files remain unchanged");
    NoTemporaries(directory);

    NSData *badSchema = [NSPropertyListSerialization dataWithPropertyList:
        @{@"schema": @2, @"bundleIdentifiers": first}
        format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
    NSData *forbidden = [NSPropertyListSerialization dataWithPropertyList:
        @{@"schema": @1, @"bundleIdentifiers": @[@"com.apple.springboard"]}
        format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
    NSArray<NSData *> *corruptions = @[[NSData data],
        [@"invalid favorites" dataUsingEncoding:NSUTF8StringEncoding], badSchema, forbidden,
        [NSMutableData dataWithLength:PPOFavoriteDataLimit + 1]];
    NSUInteger index = 0;
    for (NSData *corruption in corruptions) {
        NSString *bad = Child(root, [NSString stringWithFormat:@"corruption-%lu", (unsigned long)index++]);
        MakeDirectory(bad);
        WriteBytes(File(bad), corruption);
        Rejected(bad, @[], corruption);
        Check(Mode(File(bad)) == 0600 && Mode(bad) == 0700, "corruption does not change modes");
    }

    for (NSNumber *modeValue in @[@0444, @0644]) {
        NSString *bad = Child(root, [NSString stringWithFormat:@"file-mode-%@", modeValue]);
        MakeDirectory(bad);
        WriteBytes(File(bad), original, static_cast<mode_t>(modeValue.unsignedIntValue));
        Rejected(bad, first, original);
        Check(Mode(File(bad)) == modeValue.unsignedIntValue, "invalid file permissions are not repaired");
    }
    NSString *badDirectory = Child(root, @"directory-mode");
    MakeDirectory(badDirectory);
    WriteBytes(File(badDirectory), original);
    Check(chmod(badDirectory.fileSystemRepresentation, 0755) == 0, "prepare wrong directory mode");
    Rejected(badDirectory, first, original);
    Check(Mode(badDirectory) == 0755, "invalid directory permissions are not repaired");

    NSString *actualDirectory = Child(root, @"actual-directory");
    MakeDirectory(actualDirectory);
    WriteBytes(File(actualDirectory), original);
    NSString *directoryLink = Child(root, @"directory-link");
    Check(symlink(actualDirectory.fileSystemRepresentation, directoryLink.fileSystemRepresentation) == 0,
        "prepare directory symlink");
    Rejected(directoryLink, first, original);
    struct stat status = {};
    Check(lstat(directoryLink.fileSystemRepresentation, &status) == 0 && S_ISLNK(status.st_mode),
        "directory symlink is not replaced");

    NSString *external = Child(root, @"external.plist");
    WriteBytes(external, original);
    NSString *fileLink = Child(root, @"file-link");
    MakeDirectory(fileLink);
    Check(symlink(external.fileSystemRepresentation, File(fileLink).fileSystemRepresentation) == 0,
        "prepare file symlink");
    Rejected(fileLink, first, original);
    Check(lstat(File(fileLink).fileSystemRepresentation, &status) == 0 && S_ISLNK(status.st_mode) &&
        [Bytes(external) isEqual:original], "file symlink and external target are preserved");

    NSString *fifo = Child(root, @"fifo");
    MakeDirectory(fifo);
    Check(mkfifo(File(fifo).fileSystemRepresentation, 0600) == 0, "prepare FIFO");
    Rejected(fifo, @[], nil);
    Check(lstat(File(fifo).fileSystemRepresentation, &status) == 0 && S_ISFIFO(status.st_mode),
        "FIFO is rejected without replacement or blocking");

    NSString *hardLink = Child(root, @"hard-link");
    MakeDirectory(hardLink);
    Check(link(external.fileSystemRepresentation, File(hardLink).fileSystemRepresentation) == 0,
        "prepare hard link");
    Rejected(hardLink, first, original);
    Check(lstat(File(hardLink).fileSystemRepresentation, &status) == 0 && status.st_nlink == 2 &&
        [Bytes(external) isEqual:original], "hard links remain untouched");

    NSString *invalidTarget = Child(root, @"invalid-input-must-not-create");
    unichar nulPathCharacters[] = {'/', 't', 'm', 'p', '/', 0, 'x'};
    NSString *nulPath = [NSString stringWithCharacters:nulPathCharacters
        length:sizeof(nulPathCharacters) / sizeof(nulPathCharacters[0])];
    NSString *longPath = [invalidTarget stringByPaddingToLength:4097 withString:@"x" startingAtIndex:0];
    NSString *longEncodedPath = [root stringByAppendingPathComponent:
        [@"é" stringByPaddingToLength:2050 withString:@"é" startingAtIndex:0]];
    NSArray *invalidPaths = @[@"relative", @"/", [invalidTarget stringByAppendingString:@"/"],
        [root stringByAppendingString:@"/./invalid"], [root stringByAppendingString:@"/../invalid"],
        [root stringByAppendingString:@"//invalid"], nulPath, longPath, longEncodedPath, @7];
    for (id path in invalidPaths) {
        error = nil;
        Check(PPOFavoritesLoad(path, &error) == nil && error.code == EINVAL, "invalid directory path is refused");
        error = nil;
        Check(!PPOFavoritesCommit(path, @[], first, &error) && error.code == EINVAL,
            "invalid commit path is refused");
    }
    Check(PPOFavoritesLoad(nil, &error) == nil && error.code == EINVAL, "nil path is refused");
    NSArray *invalidLists = @[@7, @[@"com.example.same", @"com.example.same"],
        @[@"com.apple.springboard"], @[@7]];
    for (id list in invalidLists) {
        Check(!PPOFavoritesCommit(invalidTarget, list, first, &error) && error.code == EINVAL,
            "invalid expected list is refused before I/O");
        Check(!PPOFavoritesCommit(invalidTarget, @[], list, &error) && error.code == EINVAL,
            "invalid replacement list is refused before I/O");
    }
    NSMutableArray *tooMany = [NSMutableArray array];
    for (NSUInteger i = 0; i <= PPOFavoriteIdentifiersLimit; ++i)
        [tooMany addObject:[NSString stringWithFormat:@"com.example.app%lu", (unsigned long)i]];
    Check(!PPOFavoritesCommit(invalidTarget, @[], tooMany, &error) && error.code == EINVAL,
        "too many favorites are refused");
    Check(!PPOFavoritesCommit(invalidTarget, nil, first, &error) && error.code == EINVAL,
        "nil expected list is refused");
    Check(!PPOFavoritesCommit(invalidTarget, @[], nil, &error) && error.code == EINVAL,
        "nil replacement list is refused");
    Check(Missing(invalidTarget), "invalid input does not create a directory");

    // Force a failure after O_EXCL creation without changing the store's code or
    // other files. The fixture restores the process mask before any assertion.
    NSString *cleanup = Child(root, @"temp-cleanup");
    MakeDirectory(cleanup);
    WriteBytes(Child(cleanup, @"unrelated.txt"), sentinel);
    mode_t previousMask = umask(0777);
    BOOL restrictiveResult = PPOFavoritesCommit(cleanup, @[], first, &error);
    umask(previousMask);
    Check(!restrictiveResult && error.code == EPERM, "restrictive creation mask fails safely");
    Check(Missing(File(cleanup)) && [Bytes(Child(cleanup, @"unrelated.txt")) isEqual:sentinel],
        "failed temporary creation preserves missing target and unrelated file");
    NoTemporaries(cleanup);
    Check(PPOFavoritesCommit(cleanup, @[], first, NULL), "store remains usable after temporary cleanup");

    NSString *locked = Child(root, @"locked");
    MakeDirectory(locked);
    int lockDescriptor = open(locked.fileSystemRepresentation, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    Check(lockDescriptor >= 0 && flock(lockDescriptor, LOCK_EX | LOCK_NB) == 0, "hold competing directory lock");
    __block BOOL lockCommit = YES;
    __block NSArray *lockLoad = @[];
    __block NSError *lockCommitError = nil, *lockLoadError = nil;
    dispatch_group_t lockGroup = dispatch_group_create();
    dispatch_group_async(lockGroup, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        @autoreleasepool {
            lockCommit = PPOFavoritesCommit(locked, @[], first, &lockCommitError);
            lockLoad = PPOFavoritesLoad(locked, &lockLoadError);
        }
    });
    Check(dispatch_group_wait(lockGroup, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC)) == 0,
        "contending operations return without waiting for a lock");
    Check(!lockCommit && lockLoad == nil &&
        (lockCommitError.code == EWOULDBLOCK || lockCommitError.code == EAGAIN) &&
        (lockLoadError.code == EWOULDBLOCK || lockLoadError.code == EAGAIN), "directory contention fails closed");
    Check(Missing(File(locked)), "lock contention does not write favorites");
    Check(close(lockDescriptor) == 0, "release competing lock");
    NoTemporaries(locked);

    NSString *concurrent = Child(root, @"concurrent");
    MakeDirectory(concurrent);
    dispatch_group_t writers = dispatch_group_create();
    dispatch_semaphore_t start = dispatch_semaphore_create(0);
    __block BOOL firstResult = NO, secondResult = NO;
    __block NSError *firstError = nil, *secondError = nil;
    NSArray *second = @[@"com.example.other"];
    dispatch_group_async(writers, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        @autoreleasepool {
            dispatch_semaphore_wait(start, DISPATCH_TIME_FOREVER);
            firstResult = PPOFavoritesCommit(concurrent, @[], first, &firstError);
        }
    });
    dispatch_group_async(writers, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        @autoreleasepool {
            dispatch_semaphore_wait(start, DISPATCH_TIME_FOREVER);
            secondResult = PPOFavoritesCommit(concurrent, @[], second, &secondError);
        }
    });
    dispatch_semaphore_signal(start);
    dispatch_semaphore_signal(start);
    Check(dispatch_group_wait(writers, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) == 0,
        "concurrent writers finish promptly");
    Check(firstResult != secondResult, "only one writer can commit the same expected state");
    NSError *loser = firstResult ? secondError : firstError;
    Check(loser != nil && (loser.code == ESTALE || loser.code == EWOULDBLOCK || loser.code == EAGAIN),
        "losing writer reports conflict or contention");
    Check([PPOFavoritesLoad(concurrent, NULL) isEqual:(firstResult ? first : second)],
        "winner is durable and losing writer cannot overwrite it");
    NoTemporaries(concurrent);
}

int main(void) {
    @autoreleasepool {
        NSString *pattern = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ppo-favorites-XXXXXX"];
        char *temporary = strdup(pattern.fileSystemRepresentation);
        Check(temporary != NULL && mkdtemp(temporary) != NULL, "create isolated fixture parent");
        NSString *root = [NSFileManager.defaultManager stringWithFileSystemRepresentation:temporary
            length:strlen(temporary)];
        free(temporary);
        NSString *untouched = Child(root, @"main-must-not-create");
        NSError *error = nil;
        Check(NSThread.isMainThread, "main orchestrates the worker fixtures");
        Check(PPOFavoritesLoad(untouched, &error) == nil &&
            [error.domain isEqual:NSPOSIXErrorDomain] && error.code == EDEADLK,
            "main-thread load is refused before file I/O");
        Check(!PPOFavoritesCommit(untouched, @[], @[@"com.example.main"], &error) && error.code == EDEADLK,
            "main-thread commit is refused before file I/O");
        Check(Missing(untouched), "main-thread calls create no directory or files");

        dispatch_group_t fixtures = dispatch_group_create();
        dispatch_group_async(fixtures, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            @autoreleasepool { RunFixtures(root); }
        });
        Check(dispatch_group_wait(fixtures, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC)) == 0,
            "worker fixtures finish within deadline, including FIFO rejection");
        Check([NSFileManager.defaultManager removeItemAtPath:root error:NULL], "remove isolated fixtures");
        printf("Favorites store tests passed: %u checks; Foundation and isolated filesystem fixtures only\n", checks);
    }
    return 0;
}
