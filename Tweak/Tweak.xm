#import "Tweak.h"
#import "AXNManager.h"

NSDictionary *prefs;
BOOL dpkgInvalid = NO;
BOOL initialized = NO;
BOOL enabled;
BOOL vertical;
BOOL badgesEnabled;
BOOL badgesShowBackground;
BOOL hapticFeedback;
BOOL darkMode;
NSInteger sortingMode;
NSInteger selectionStyle;
NSInteger style;
NSInteger showByDefault;
NSInteger alignment;
NSInteger verticalPosition;
NSInteger autoLayout;
NSInteger yAxis;
NSInteger location;
CGFloat spacing;

void updateViewConfiguration() {
    if (initialized && [AXNManager sharedInstance].view) {
        [AXNManager sharedInstance].view.hapticFeedback = hapticFeedback;
        [AXNManager sharedInstance].view.badgesEnabled = badgesEnabled;
        [AXNManager sharedInstance].view.badgesShowBackground = badgesShowBackground;
        [AXNManager sharedInstance].view.selectionStyle = selectionStyle;
        [AXNManager sharedInstance].view.sortingMode = sortingMode;
        [AXNManager sharedInstance].view.style = style;
        [AXNManager sharedInstance].view.darkMode = darkMode;
        [AXNManager sharedInstance].view.showByDefault = showByDefault;
        [AXNManager sharedInstance].view.spacing = spacing;
        [AXNManager sharedInstance].view.alignment = alignment;
    }
}

%group Axon

@interface NCNotificationListSectionHeaderView : UIView
@end

%hook NCNotificationListSectionHeaderView
- (void)layoutSubviews {
    self.hidden = 1;
}
-(CGRect)frame {
  return CGRectMake(0,0,0,0);
}
-(BOOL)hidden {
  return true;
}
%end

#pragma mark Legibility color

%hook SBFLockScreenDateView

-(id)initWithFrame:(CGRect)arg1 {
    %orig;
    if (self.legibilitySettings && self.legibilitySettings.primaryColor) {
        [AXNManager sharedInstance].fallbackColor = [self.legibilitySettings.primaryColor copy];
    }
    return self;
}

-(void)setLegibilitySettings:(_UILegibilitySettings *)arg1 {
    %orig;
    if (self.legibilitySettings && self.legibilitySettings.primaryColor) {
        [AXNManager sharedInstance].fallbackColor = [self.legibilitySettings.primaryColor copy];
    }
}

%end

#pragma mark Store dispatcher for future use

%hook SBNCNotificationDispatcher

-(id)init {
    %orig;
    [AXNManager sharedInstance].dispatcher = self.dispatcher;
    return self;
}

-(void)setDispatcher:(NCNotificationDispatcher *)arg1 {
    %orig;
    [AXNManager sharedInstance].dispatcher = arg1;
}

%end

#pragma mark Inject the Axon view into NC

%hook SBDashBoardNotificationAdjunctListViewController

%property (nonatomic, retain) AXNView *axnView;


-(BOOL)hasContent {
    return YES;
}

%end

// iOS13 Support
%hook CSNotificationAdjunctListViewController
%property (nonatomic, retain) AXNView *axnView;
%end

#pragma mark Notification management

%hook NCNotificationCombinedListViewController

%property (nonatomic,assign) BOOL axnAllowChanges;

/* Store this object for future use. */

-(id)init {
    %orig;
    [AXNManager sharedInstance].clvc = self;
    self.axnAllowChanges = NO;
    return self;
}

/* Replace notification management functions with our logic. */

-(bool)insertNotificationRequest:(NCNotificationRequest *)req forCoalescedNotification:(id)arg2 {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.
    [[AXNManager sharedInstance] insertNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if (![AXNManager sharedInstance].view.selectedBundleIdentifier && showByDefault == 1) {
        [[AXNManager sharedInstance].view reset];
    }

    return YES;
}

-(bool)removeNotificationRequest:(NCNotificationRequest *)req forCoalescedNotification:(id)arg2 {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] removeNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    }

    return YES;
}

-(bool)modifyNotificationRequest:(NCNotificationRequest *)req forCoalescedNotification:(id)arg2 {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] modifyNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    }

    return YES;
}

-(bool)hasContent {
    if ([AXNManager sharedInstance].view.list && [[AXNManager sharedInstance].view.list count] > 0) return YES;
    return %orig;
}

-(void)viewDidAppear:(BOOL)animated {
    %orig;
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}

/* Fix pull to clear all tweaks. */

-(void)_clearAllPriorityListNotificationRequests {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self allNotificationRequests]];
}

-(void)_clearAllNotificationRequests {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self allNotificationRequests]];
}

-(void)clearAll {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self axnNotificationRequests]];
}

/* Compatibility thing for other tweaks. */

%new
-(id)axnNotificationRequests {
    NSMutableOrderedSet *allRequests = [NSMutableOrderedSet new];
    for (NSString *key in [[AXNManager sharedInstance].notificationRequests allKeys]) {
        [allRequests addObjectsFromArray:[[AXNManager sharedInstance] requestsForBundleIdentifier:key]];
    }
    return allRequests;
}

%new
-(void)revealNotificationHistory:(BOOL)revealed {
  [self setDidPlayRevealHaptic:YES];
  [self forceNotificationHistoryRevealed:revealed animated:NO];
  [self setNotificationHistorySectionNeedsReload:YES];
  [self _reloadNotificationHistorySectionIfNecessary];
  if (!revealed && [self respondsToSelector:@selector(clearAllCoalescingControlsCells)]) [self clearAllCoalescingControlsCells];
}

%new
-(void)updateNotifications {
  [self _resetNotificationsHistory];
}

%end

// iOS13 Support
@interface NCNotificationMasterList
@property(retain, nonatomic) NSMutableArray *notificationSections;
@end
@interface NCNotificationStructuredSectionList
@property (nonatomic,readonly) NSArray * allNotificationRequests;
@end
@interface NCNotificationStructuredListViewController : UIViewController <clvc>
@property (nonatomic,assign) BOOL axnAllowChanges;
@property (nonatomic,retain) NCNotificationMasterList * masterList;
-(void)revealNotificationHistory:(BOOL)arg1 animated:(BOOL)arg2 ;
-(void)_resetCellWithRevealedActions;
@end
%hook NCNotificationStructuredListViewController
%property (nonatomic,assign) BOOL axnAllowChanges;
-(id)init {
    %orig;
    [AXNManager sharedInstance].clvc = self;
    self.axnAllowChanges = NO;
    return self;
}
-(bool)insertNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.
    [[AXNManager sharedInstance] insertNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if (![AXNManager sharedInstance].view.selectedBundleIdentifier && showByDefault == 1) {
        [[AXNManager sharedInstance].view reset];
    }

    return YES;
}

-(bool)removeNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] removeNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    }

    return YES;
}

-(bool)modifyNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] modifyNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    }

    return YES;
}

-(void)viewDidAppear:(BOOL)animated {
    %orig;
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}

%new
-(id)axnNotificationRequests {
    NSMutableOrderedSet *allRequests = [NSMutableOrderedSet new];
    for (NSString *key in [[AXNManager sharedInstance].notificationRequests allKeys]) {
        [allRequests addObjectsFromArray:[[AXNManager sharedInstance] requestsForBundleIdentifier:key]];
    }
    return allRequests;
}

%new
-(NSSet *)allNotificationRequests {
  NSArray *array = [NSMutableArray new];
  NCNotificationMasterList *masterList = [self masterList];
  for(NCNotificationStructuredSectionList *item in [masterList notificationSections]) {
    array = [array arrayByAddingObjectsFromArray:[item allNotificationRequests]];
  }
  return [[NSSet alloc] initWithArray:array];
}

%new
-(void)revealNotificationHistory:(BOOL)revealed {
  [self revealNotificationHistory:revealed animated:true];
}

%new
-(void)updateNotifications {
  [self _resetCellWithRevealedActions];
}

%end

#pragma mark Compatibility stuff

%hook NCNotificationListViewController

/* FastUnlockX */

-(BOOL)hasVisibleContent {
    if ([AXNManager sharedInstance].view && [[AXNManager sharedInstance].view.list count] > 0) return YES;
    return %orig;
}

%end

%hook SparkAutoUnlockX

/* The only way I know of... AutoUnlockX */

-(BOOL)externalBlocksUnlock {
    if ([AXNManager sharedInstance].view && [[AXNManager sharedInstance].view.list count] > 0) return YES;
    return %orig;
}

%end

%hook NCNotificationListSectionRevealHintView

/* Hide "No older notifications." */

-(void)layoutSubviews {
    %orig;
    MSHookIvar<UILabel *>(self, "_revealHintTitle").hidden = YES;
}

%end

%hook SBDashBoardViewController

/* Hide all notifications on open. */

-(void)viewWillAppear:(BOOL)animated {
    %orig;
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}

%end

// iOS13 Support
%hook CSPageViewController
-(void)viewWillAppear:(BOOL)animated {
    %orig;
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}
%end


%end
@interface NCNotificationContentView : NSObject
@end
@interface UIView (Private)
-(NSArray *)allSubviews;
@end
%group AxonVertical

%hook NCNotificationCombinedListViewController

%property (nonatomic,assign) BOOL axnAllowChanges;

-(UIEdgeInsets)insetMargins {
    if (verticalPosition == 0) return UIEdgeInsetsMake(0, -96, 0, 0);
    else return UIEdgeInsetsMake(0, 0, 0, -96);
}

-(CGSize)collectionView:(UICollectionView *)arg1 layout:(UICollectionViewLayout*)arg2 sizeForItemAtIndexPath:(id)arg3 {
    CGSize orig = %orig;
    UIView *view = [arg1 cellForItemAtIndexPath:arg3].contentView;
    for(id item in view.allSubviews) {
      if([item isKindOfClass:[objc_getClass("NCNotificationContentView") class]]) {
        return CGSizeMake(orig.width - 96, ((UIView *)item).frame.size.height+30);
      }
    }
    return CGSizeMake(orig.width - 96, orig.height);
}

%end

// iOS 13 Support
%hook NCNotificationStructuredListViewController
%property (nonatomic,assign) BOOL axnAllowChanges;
-(UIEdgeInsets)insetMargins {
    if (verticalPosition == 0) return UIEdgeInsetsMake(0, -96, 0, 0);
    else return UIEdgeInsetsMake(0, 0, 0, -96);
}
%end

%hook SBDashBoardCombinedListViewController

%property (nonatomic, retain) AXNView *axnView;

-(void)viewDidLoad{
    %orig;
    if (!initialized) {
        initialized = YES;
        self.axnView = [[AXNView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 96, 0, 96, 500)];
        self.axnView.translatesAutoresizingMaskIntoConstraints = NO;
        self.axnView.collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        [AXNManager sharedInstance].view = self.axnView;
        updateViewConfiguration();

        [self.view addSubview:self.axnView];

        [NSLayoutConstraint activateConstraints:@[
            [self.axnView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [self.axnView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
            [self.axnView.widthAnchor constraintEqualToConstant:90]
        ]];

        if (verticalPosition == 0) {
            [NSLayoutConstraint activateConstraints:@[
                [self.axnView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            ]];
        } else {
            [NSLayoutConstraint activateConstraints:@[
                [self.axnView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            ]];
        }
    }
    [AXNManager sharedInstance].sbclvc = self;
}

%end

// iOS 13 Support
%hook CSCombinedListViewController
%property (nonatomic, retain) AXNView *axnView;
-(void)viewDidLoad{
    %orig;
    if (!initialized) {
        initialized = YES;
        self.axnView = [[AXNView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 96, 0, 96, 500)];
        self.axnView.translatesAutoresizingMaskIntoConstraints = NO;
        self.axnView.collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        [AXNManager sharedInstance].view = self.axnView;
        updateViewConfiguration();

        [self.view addSubview:self.axnView];

        [NSLayoutConstraint activateConstraints:@[
            [self.axnView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [self.axnView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
            [self.axnView.widthAnchor constraintEqualToConstant:90]
        ]];

        if (verticalPosition == 0) {
            [NSLayoutConstraint activateConstraints:@[
                [self.axnView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            ]];
        } else {
            [NSLayoutConstraint activateConstraints:@[
                [self.axnView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            ]];
        }
    }
    [AXNManager sharedInstance].sbclvc = self;
}
%end

%end






%group AxonHorizontal

%hook SBDashBoardCombinedListViewController

-(void)viewDidLoad{
    %orig;
    [AXNManager sharedInstance].sbclvc = self;
}

%end

// iOS 13 Support
%hook CSCombinedListViewController
-(void)viewDidLoad{
    %orig;
    [AXNManager sharedInstance].sbclvc = self;
}
%end

%hook SBDashBoardNotificationAdjunctListViewController

%property (nonatomic, retain) AXNView *axnView;

-(void)viewDidLoad {
    %orig;

    if (!initialized && location == 0) {
        initialized = YES;
        UIStackView *stackView = [self valueForKey:@"_stackView"];
        self.axnView = [[AXNView alloc] initWithFrame:CGRectMake(0,0,64,90)];
        self.axnView.translatesAutoresizingMaskIntoConstraints = NO;
        [AXNManager sharedInstance].view = self.axnView;
        updateViewConfiguration();

        NSMutableArray *constraints = [@[
          [self.axnView.centerXAnchor constraintEqualToAnchor:stackView.centerXAnchor],
          [self.axnView.leadingAnchor constraintEqualToAnchor:stackView.leadingAnchor constant:10],
          [self.axnView.trailingAnchor constraintEqualToAnchor:stackView.trailingAnchor constant:-10],
          [self.axnView.heightAnchor constraintEqualToConstant:style == 4 ? 30 : (style == 5 ? 36 : 90)]
        ] mutableCopy];

        [stackView addArrangedSubview:self.axnView];
        [NSLayoutConstraint activateConstraints:constraints];
    }
}

/* This is used to make the Axon view last, e.g. when media controls are presented. */

-(void)_updatePresentingContent {
    %orig;
    UIStackView *stackView = [self valueForKey:@"_stackView"];
    [stackView removeArrangedSubview:self.axnView];
    [stackView addArrangedSubview:self.axnView];
}

-(void)_insertItem:(id)arg1 animated:(BOOL)arg2 {
    %orig;
    UIStackView *stackView = [self valueForKey:@"_stackView"];
    [stackView removeArrangedSubview:self.axnView];
    [stackView addArrangedSubview:self.axnView];
}

/* Let Springboard know we have a little surprise for it. */

-(BOOL)isPresentingContent {
    return YES;
}

%end

%hook NCNotificationCombinedListViewController
-(void)viewDidLoad{
    %orig;
    if (!initialized && location == 1) {
        initialized = YES;
        AXNView *axnView = [[AXNView alloc] initWithFrame:CGRectMake(0,0,64,90)];
        axnView.translatesAutoresizingMaskIntoConstraints = NO;
        [AXNManager sharedInstance].view = axnView;
        updateViewConfiguration();

        NSMutableArray *constraints = [@[
          [axnView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
          [axnView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
          [axnView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
          [axnView.heightAnchor constraintEqualToConstant:style == 4 ? 30 : (style == 5 ? 36 : 90)]
        ] mutableCopy];

        if(autoLayout) [constraints addObject:[axnView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-55]];
        else [constraints addObject:[axnView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:yAxis]];

        [self.view addSubview:axnView];
        [NSLayoutConstraint activateConstraints:constraints];
    }
}
%end
%hook NCNotificationStructuredListViewController
-(void)viewDidLoad{
    %orig;
    if (!initialized && location == 1) {
        initialized = YES;
        AXNView *axnView = [[AXNView alloc] initWithFrame:CGRectMake(0,0,64,90)];
        axnView.translatesAutoresizingMaskIntoConstraints = NO;
        [AXNManager sharedInstance].view = axnView;
        updateViewConfiguration();

        NSMutableArray *constraints = [@[
          [axnView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
          [axnView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
          [axnView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
          [axnView.heightAnchor constraintEqualToConstant:style == 4 ? 30 : (style == 5 ? 36 : 90)]
        ] mutableCopy];

        if(autoLayout) [constraints addObject:[axnView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-55]];
        else [constraints addObject:[axnView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:yAxis]];

        [self.view addSubview:axnView];
        [NSLayoutConstraint activateConstraints:constraints];
    }
}
%end

%hook CSNotificationAdjunctListViewController
%property (nonatomic, retain) AXNView *axnView;
-(void)viewDidLoad {
    %orig;

    if (!initialized && location == 0) {
        initialized = YES;
        UIStackView *stackView = [self valueForKey:@"_stackView"];
        self.axnView = [[AXNView alloc] initWithFrame:CGRectMake(0,0,64,90)];
        self.axnView.translatesAutoresizingMaskIntoConstraints = NO;
        [AXNManager sharedInstance].view = self.axnView;
        updateViewConfiguration();

        NSMutableArray *constraints = [@[
          [self.axnView.centerXAnchor constraintEqualToAnchor:stackView.centerXAnchor],
          [self.axnView.leadingAnchor constraintEqualToAnchor:stackView.leadingAnchor constant:10],
          [self.axnView.trailingAnchor constraintEqualToAnchor:stackView.trailingAnchor constant:-10],
          [self.axnView.heightAnchor constraintEqualToConstant:style == 4 ? 30 : (style == 5 ? 36 : 90)]
        ] mutableCopy];

        [stackView addArrangedSubview:self.axnView];
        [NSLayoutConstraint activateConstraints:constraints];
    }
}

-(void)_updatePresentingContent {
    %orig;
    if(location == 1) return;
    UIStackView *stackView = [self valueForKey:@"_stackView"];
    [stackView removeArrangedSubview:self.axnView];
    [stackView addArrangedSubview:self.axnView];
}
-(void)_insertItem:(id)arg1 animated:(BOOL)arg2 {
    %orig;
    if(location == 1) return;
    UIStackView *stackView = [self valueForKey:@"_stackView"];
    [stackView removeArrangedSubview:self.axnView];
    [stackView addArrangedSubview:self.axnView];
}

-(BOOL)isPresentingContent {
    return YES;
}
%end


%end

/* Hide all notifications on open. */

static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}


void loadPrefs() {
	prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.nepeta.axon.plist"];
  enabled = prefs[@"Enabled"] != nil ? [prefs[@"Enabled"] boolValue] : true;
  vertical = prefs[@"Vertical"] != nil ? [prefs[@"Vertical"] boolValue] : false;
  hapticFeedback = prefs[@"HapticFeedback"] != nil ? [prefs[@"HapticFeedback"] boolValue] : true;
  badgesEnabled = prefs[@"BadgesEnabled"] != nil ? [prefs[@"BadgesEnabled"] boolValue] : true;
  badgesShowBackground = prefs[@"BadgesShowBackground"] != nil ? [prefs[@"BadgesShowBackground"] boolValue] : true;
  darkMode = prefs[@"DarkMode"] != nil ? [prefs[@"DarkMode"] boolValue] : false;
  sortingMode = [prefs[@"SortingMode"] intValue] ?: 0;
  selectionStyle = [prefs[@"SelectionStyle"] intValue] ?: 0;
  style = [prefs[@"Style"] intValue] ?: 0;
  showByDefault = [prefs[@"ShowByDefault"] intValue] ?: 0;
  alignment = [prefs[@"Alignment"] intValue] ?: 0;
  verticalPosition = [prefs[@"VerticalPosition"] intValue] ?: 0;
  spacing = [prefs[@"Spacing"] floatValue] ?: 10;
  autoLayout = prefs[@"autoLayout"] != nil ? [prefs[@"autoLayout"] boolValue] : true;
  location = [prefs[@"location"] intValue] ?: 0;
  if(autoLayout == false) location = 1;
  yAxis = [prefs[@"yAxis"] intValue] ?: 0;
  if(style > 5) style = 4;
  updateViewConfiguration();
}


%ctor {
  NSLog(@"[Axon] init");
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("me.nepeta.axon/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  loadPrefs();

  if(enabled) {
    %init(Axon);
    if (!vertical) %init(AxonHorizontal);
    else %init(AxonVertical);
  }
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, displayStatusChanged, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
