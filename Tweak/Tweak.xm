#import "Tweak.h"
#import "AXNManager.h"

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

%end

%group AxonVertical

%hook NCNotificationCombinedListViewController

%property (nonatomic,assign) BOOL axnAllowChanges;

-(UIEdgeInsets)insetMargins {
    if (verticalPosition == 0) return UIEdgeInsetsMake(0, -96, 0, 0);
    else return UIEdgeInsetsMake(0, 0, 0, -96);
}

-(CGSize)collectionView:(id)arg1 layout:(id)arg2 sizeForItemAtIndexPath:(id)arg3 {
    CGSize orig = %orig;
    return CGSizeMake(orig.width - 96, orig.height);
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

%end

%group AxonHorizontal

%hook SBDashBoardCombinedListViewController

-(void)viewDidLoad{
    %orig;
    [AXNManager sharedInstance].sbclvc = self;
}

%end

%hook SBDashBoardNotificationAdjunctListViewController

%property (nonatomic, retain) AXNView *axnView;

-(void)viewDidLoad {
    %orig;

    if (!initialized) {
        initialized = YES;
        UIStackView *stackView = [self valueForKey:@"_stackView"];
        self.axnView = [[AXNView alloc] initWithFrame:CGRectMake(0,0,64,90)];
        self.axnView.translatesAutoresizingMaskIntoConstraints = NO;
        [AXNManager sharedInstance].view = self.axnView;
        updateViewConfiguration();

        [stackView addArrangedSubview:self.axnView];

        [NSLayoutConstraint activateConstraints:@[
            [self.axnView.centerXAnchor constraintEqualToAnchor:stackView.centerXAnchor],
            [self.axnView.leadingAnchor constraintEqualToAnchor:stackView.leadingAnchor constant:10],
            [self.axnView.trailingAnchor constraintEqualToAnchor:stackView.trailingAnchor constant:-10],
            [self.axnView.heightAnchor constraintEqualToConstant:90]
        ]];
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

%end

%group AxonIntegrityFail

%hook SBIconController

%property (retain,nonatomic) WKWebView *axnIntegrityView;

-(void)loadView{
    %orig;
    if (!dpkgInvalid) return;
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self.axnIntegrityView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://piracy.nepeta.me/"]];
    [self.axnIntegrityView loadRequest:request];
    [self.view addSubview:self.axnIntegrityView];
    [self.view sendSubviewToBack:self.axnIntegrityView];
}

-(void)viewDidAppear:(BOOL)animated{
    %orig;
    if (!dpkgInvalid) return;
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:@"😡😡😡"
        message:@"The build of Axon you're using comes from an untrusted source. Pirate repositories can distribute malware and you will get subpar user experience using any tweaks from them.\nRemember: Axon is free. Uninstall this build and install the proper version of Axon from:\nhttps://repo.nepeta.me/\n(it's free, damnit, why would you pirate that!?)\n\nIf you're seeing this message but have obtained Axon from an official source, add https://repo.nepeta.me/ to Cydia or Sileo and respring."
        preferredStyle:UIAlertControllerStyleAlert
    ];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Damn!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIApplication *application = [UIApplication sharedApplication];
        [application openURL:[NSURL URLWithString:@"https://repo.nepeta.me/"] options:@{} completionHandler:nil];

        [self dismissViewControllerAnimated:YES completion:NULL];
    }]];

    [self presentViewController:alertController animated:YES completion:NULL];
}

%end

%end

/* Hide all notifications on open. */

static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}

%ctor{
    NSLog(@"[Axon] init");

    dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.axon.list"];
    /*if (!dpkgInvalid) dpkgInvalid = !([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/lib/apt/lists/repo.nepeta.me_._Release"]
    || [[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/Library/Caches/com.saurik.Cydia/lists/repo.nepeta.me_._Release"]
    || [[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/Documents/xyz.willy.Zebra/zebra.db"]);*/
    if (!dpkgInvalid) dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.axon.md5sums"];

    HBPreferences *preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.axon"];
    [preferences registerBool:&enabled default:YES forKey:@"Enabled"];
    [preferences registerBool:&vertical default:NO forKey:@"Vertical"];
    [preferences registerBool:&hapticFeedback default:YES forKey:@"HapticFeedback"];
    [preferences registerBool:&badgesEnabled default:YES forKey:@"BadgesEnabled"];
    [preferences registerBool:&badgesShowBackground default:YES forKey:@"BadgesShowBackground"];
    [preferences registerBool:&darkMode default:NO forKey:@"DarkMode"];
    [preferences registerInteger:&sortingMode default:0 forKey:@"SortingMode"];
    [preferences registerInteger:&selectionStyle default:0 forKey:@"SelectionStyle"];
    [preferences registerInteger:&style default:0 forKey:@"Style"];
    [preferences registerInteger:&showByDefault default:0 forKey:@"ShowByDefault"];
    [preferences registerInteger:&alignment default:1 forKey:@"Alignment"];
    [preferences registerInteger:&verticalPosition default:0 forKey:@"VerticalPosition"];
    [preferences registerFloat:&spacing default:10.0 forKey:@"Spacing"];
    [preferences registerPreferenceChangeBlock:^() {
        updateViewConfiguration();
    }];

    if (!dpkgInvalid && enabled) {
        BOOL ok = false;
        
        ok = ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/var/lib/dpkg/info/%@%@%@%@%@%@%@%@%@.axon.md5sums", @"m", @"e", @".", @"n", @"e", @"p", @"e", @"t", @"a"]]
                /* &&
                ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/private/var/lib/apt/lists/repo.%@%@%@%@%@%@.me_._Release", @"n", @"e", @"p", @"e", @"t", @"a"]] ||
                [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/private/var/mobile/Library/Caches/com.saurik.Cydia/lists/repo.%@%@%@%@%@%@.me_._Release", @"n", @"e", @"p", @"e", @"t", @"a"]] ||
                [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/private/var/mobile/Documents/xyz.willy.Zebra/%@%@%@%@%@.db", @"z", @"e", @"b", @"r", @"a"]])*/
        );

        if (ok && [@"nepeta" isEqualToString:@"nepeta"]) {
            %init(Axon);
            if (!vertical) {
                %init(AxonHorizontal);
            } else {
                %init(AxonVertical);
            }
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, displayStatusChanged, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
            return;
        } else {
            dpkgInvalid = YES;
        }
    }

    if (enabled) %init(AxonIntegrityFail);
}
