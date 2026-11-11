#import "PPOMenuBinding.h"

@interface PPOMenuBinding ()
- (void)invalidateBinding;
@end

@implementation PPOMenuBinding {
    __strong id _source;
    __weak id _owner;
    __weak id _destination;
    BOOL _hasBinding;
    BOOL _applying;
}

- (void)invalidateBinding {
    _hasBinding = NO;
    _owner = nil;
    _destination = nil;
    _source = nil;
}

- (BOOL)bindSource:(id)source owner:(id)owner destination:(id)destination
           setter:(void (^)(id destination, id source))setter {
    // Even a reentrant clear must not overwrite the outer request's eventual
    // cache commit. The next ordinary refresh reconciles the current UI state.
    if (!NSThread.isMainThread || _applying) return NO;
    if (!destination) {
        // Releasing a retained model can itself run caller code during dealloc.
        _applying = YES;
        @try { [self invalidateBinding]; }
        @finally { _applying = NO; }
        return NO;
    }
    if (!setter) return NO;

    // A missing source or owner is one canonical clear, independent of which
    // stale source/owner happened to be supplied alongside the missing value.
    id original = source && owner ? source : nil;
    id boundOwner = original ? owner : nil;
    if (_hasBinding && _source == original && _owner == boundOwner &&
        _destination == destination) return NO;

    _applying = YES;
    @try {
        // A setter may partially mutate then throw any Objective-C object.
        // Forget the old success before the call; only a normal return can
        // establish a new success. Exceptions propagate without translation.
        [self invalidateBinding];
        setter(destination, original);
        // The destination may now contain an unequal copy. Do not read it back
        // to decide whether a later refresh needs to apply the same model.
        _source = original;
        _owner = boundOwner;
        _destination = destination;
        _hasBinding = YES;
        return YES;
    } @finally {
        _applying = NO;
    }
}
@end
