#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Immutable operation snapshots. Only the state that issued a ticket can consume it.
@interface PPOPickerTicket : NSObject
@property(nonatomic, copy, readonly, nullable) NSDictionary *selection;
@property(nonatomic, copy, readonly) NSArray<NSString *> *expectedFavorites;
@property(nonatomic, copy, readonly) NSArray<NSString *> *replacementFavorites;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

// Foundation-only coordinator. Call its methods on one serial queue.
@interface PPOPickerState : NSObject
@property(nonatomic, copy, readonly) NSArray<NSDictionary *> *apps;
@property(nonatomic, copy, readonly) NSArray<NSString *> *favoriteIdentifiers;
@property(nonatomic, copy, readonly, nullable) NSString *selectedIdentifier;
@property(nonatomic, readonly) NSUInteger selectionGeneration;
@property(nonatomic, readonly, getter=isLoading) BOOL loading;
@property(nonatomic, readonly, getter=isSelectionSaving) BOOL selectionSaving;
@property(nonatomic, readonly, getter=isFavoritesSaving) BOOL favoritesSaving;
@property(nonatomic, readonly) BOOL favoritesReadable;
@property(nonatomic, readonly) BOOL listRequested;
@property(nonatomic, readonly) BOOL favoritesOnly;

- (void)requestListFavoritesOnly:(BOOL)favoritesOnly;
- (void)closeList;
- (nullable PPOPickerTicket *)beginLoad;
// Nil apps is a failed refresh; nil favorites is an unreadable favorites file.
- (BOOL)finishLoad:(nullable PPOPickerTicket *)ticket
              apps:(nullable NSArray *)apps
         selection:(nullable NSDictionary *)diskSelection
         favorites:(nullable NSArray *)diskFavorites;
- (nullable PPOPickerTicket *)beginSelection:(nullable NSString *)identifier;
- (BOOL)finishSelection:(nullable PPOPickerTicket *)ticket saved:(BOOL)saved;
- (nullable PPOPickerTicket *)beginFavoriteToggle:(nullable NSString *)identifier;
- (BOOL)finishFavorite:(nullable PPOPickerTicket *)ticket saved:(BOOL)saved;
- (NSArray<NSDictionary *> *)rows;
@end

NS_ASSUME_NONNULL_END
