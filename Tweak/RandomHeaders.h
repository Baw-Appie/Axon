#import <WebKit/WebKit.h>

@interface BBBulletin : NSObject

@property (nonatomic,readonly) NSString * sectionDisplayName; 
@property (nonatomic,copy) NSString * section; 
@property (nonatomic,copy) NSString * sectionID;
@property (nonatomic,copy) NSSet * subsectionIDs;
@property (nonatomic,copy) NSString * recordID;
@property (nonatomic,copy) NSString * publisherBulletinID;
@property (nonatomic,copy) NSString * dismissalID;
@property (nonatomic,copy) NSString * categoryID;
@property (nonatomic,copy) NSString * threadID;
@property (nonatomic,copy) NSArray * peopleIDs;
@property (nonatomic,copy) NSString * bulletinID;   

@end

@interface NCNotificationContent : NSObject

@property (nonatomic,readonly) UIImage * icon;
@property (nonatomic,copy,readonly) NSString * header;

@end

@interface NCNotificationRequest : NSObject

@property (nonatomic,readonly) NCNotificationContent * content;
@property (nonatomic,copy,readonly) NSString * sectionIdentifier;
@property (nonatomic,copy,readonly) NSString * notificationIdentifier;
@property (nonatomic,copy,readonly) NSString * threadIdentifier;
@property (nonatomic,copy,readonly) NSString * categoryIdentifier;
@property (nonatomic,readonly) BBBulletin * bulletin;
@property (nonatomic,readonly) NSDate * timestamp;

@end

@interface NCCoalescedNotification : NSObject

@property (nonatomic,copy,readonly) NSArray * notificationRequests;

@end

@interface NCNotificationCombinedListViewController : UIViewController

@property (nonatomic, assign) BOOL axnAllowChanges;
-(id)allNotificationRequests;
-(id)axnNotificationRequests;
-(bool)insertNotificationRequest:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(void)removeNotificationRequest:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(bool)modifyNotificationRequest:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(void)insertNotificationRequestIntoRecentsSection:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(void)_performNotificationHistorySectionOperation:(/*^block*/ id)arg1 animated:(bool)arg2 delayAnimation:(bool)arg3 ;
-(void)removeNotificationRequestFromRecentsSection:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(void)forceNotificationHistoryRevealed:(bool)arg1 animated:(bool)arg2 ;
-(void)_revealNotificationsHistory;
-(void)setShouldAllowNotificationsHistoryReveal:(bool)arg1 ;
-(void)_setShowingNotificationsHistory:(bool)arg1 animated:(bool)arg2 ;
-(void)_setShowingNotificationsHistory:(bool)arg1 ;
-(bool)shouldAllowNotificationsHistoryReveal;
-(void)setDidPlayRevealHaptic:(bool)arg1 ;
-(void)setNotificationHistorySectionNeedsReload:(bool)arg1 ;
-(void)_reloadNotificationHistorySectionIfNecessary;
-(id)_coalescingIdentifierForNotificationRequest:(id)arg1 ;
-(bool)hasContent;
-(void)clearAllCoalescingControlsCells;
-(void)clearAll;
-(UICollectionView*)collectionView;

@end

@interface SBDashBoardCombinedListViewController : UIViewController
-(void)_setListHasContent:(BOOL)arg1;
-(bool)hasContent;
@end

@interface NCNotificationStore : NSObject

-(NCCoalescedNotification *)coalescedNotificationForRequest:(id)arg1 ;

@end

@interface NCNotificationDispatcher : NSObject

@property (nonatomic,retain) NCNotificationStore * notificationStore;
-(void)destination:(id)arg1 requestsClearingNotificationRequests:(id)arg2 ;
-(void)destination:(id)arg1 requestsClearingNotificationRequests:(id)arg2 fromDestinations:(id)arg3 ;

@end

@interface SBNCNotificationDispatcher : NSObject

@property (nonatomic,retain) NCNotificationDispatcher * dispatcher;

@end

@interface SBIcon : NSObject

-(UIImage *)getIconImage:(int)arg1 ;

@end

@interface SBIconModel : NSObject

-(SBIcon *)applicationIconForBundleIdentifier:(id)arg1 ;

@end

@interface SBIconViewMap : NSObject

@property (nonatomic,readonly) SBIconModel * iconModel;

@end

@interface SBIconController : UIViewController

@property (nonatomic, retain) WKWebView *axnIntegrityView;
+(id)sharedInstance;
-(SBIconViewMap *)homescreenIconViewMap;

@end

@interface UIImage (Private)

+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;

@end

@interface CALayer (Private)

@property (nonatomic, assign) BOOL continuousCorners;

@end

@interface _UILegibilitySettings : NSObject

@property (nonatomic,retain) UIColor * primaryColor;

@end

@interface SBFLockScreenDateView : UIView

@property (nonatomic,retain) _UILegibilitySettings * legibilitySettings;
-(id)initWithFrame:(CGRect)arg1 ;
-(void)setLegibilitySettings:(_UILegibilitySettings *)arg1 ;

@end

@interface SBIdleTimerGlobalCoordinator : NSObject

+(id)sharedInstance;
-(void)resetIdleTimer;

@end

@interface UIScrollView(Private)

-(BOOL)_scrollToTopIfPossible:(BOOL)arg1;

@end