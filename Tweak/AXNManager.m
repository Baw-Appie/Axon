#import "AXNManager.h"
#import "AXNRequestWrapper.h"
#import "Tweak.h"

@implementation AXNManager

+(instancetype)sharedInstance {
    static AXNManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AXNManager alloc];
        sharedInstance.names = [NSMutableDictionary new];
        sharedInstance.timestamps = [NSMutableDictionary new];
        sharedInstance.notificationRequests = [NSMutableDictionary new];
        sharedInstance.iconStore = [NSMutableDictionary new];
        sharedInstance.backgroundColorCache = [NSMutableDictionary new];
        sharedInstance.textColorCache = [NSMutableDictionary new];
        sharedInstance.countCache = [NSMutableDictionary new];
        sharedInstance.fallbackColor = [UIColor whiteColor];
    });
    return sharedInstance;
}

-(id)init {
    return [AXNManager sharedInstance];
}

-(void)getRidOfWaste {
    for (NSString *bundleIdentifier in [self.notificationRequests allKeys]) {
        __weak NSMutableArray *requests = self.notificationRequests[bundleIdentifier];
        for (int i = [requests count] - 1; i >= 0; i--) {
            __weak AXNRequestWrapper *wrapped = requests[i];
            if (!wrapped || ![wrapped request]) [requests removeObjectAtIndex:i];
        }
    }
}

-(void)invalidateCountCache {
    [self.countCache removeAllObjects];
}

-(void)updateCountForBundleIdentifier:(NSString *)bundleIdentifier {
    NSArray *requests = [self requestsForBundleIdentifier:bundleIdentifier];
    NSInteger count = [requests count];
    if (count == 0) {
        self.countCache[bundleIdentifier] = @(0);
        return;
    }

    if ([self.dispatcher.notificationStore respondsToSelector:@selector(coalescedNotificationForRequest:)]) {
        count = 0;
        NSMutableArray *coalescedNotifications = [NSMutableArray new];
        for (NCNotificationRequest *req in requests) {
            NCCoalescedNotification *coalesced = [self coalescedNotificationForRequest:req];
            if (!coalesced) {
                count++;
                continue;
            }

            if (![coalescedNotifications containsObject:coalesced]) {
                count += [coalesced.notificationRequests count];
                [coalescedNotifications addObject:coalesced];
            }
        }
    }

    self.countCache[bundleIdentifier] = @(count);
}

-(NSInteger)countForBundleIdentifier:(NSString *)bundleIdentifier {
    if (self.countCache[bundleIdentifier]) return [self.countCache[bundleIdentifier] intValue];

    [self updateCountForBundleIdentifier:bundleIdentifier];

    if (self.countCache[bundleIdentifier]) return [self.countCache[bundleIdentifier] intValue];
    else return 0;
}

-(UIImage *)getIcon:(NSString *)bundleIdentifier {
    if (self.iconStore[bundleIdentifier]) return self.iconStore[bundleIdentifier];
    UIImage *image;
    SBIconModel *model;

    SBIconController *iconController = [NSClassFromString(@"SBIconController") sharedInstance];

    if([iconController respondsToSelector:@selector(homescreenIconViewMap)]) model = [[iconController homescreenIconViewMap] iconModel];
    else if([iconController respondsToSelector:@selector(model)]) model = [iconController model];
    SBIcon *icon = [model applicationIconForBundleIdentifier:bundleIdentifier];
    if([icon respondsToSelector:@selector(getIconImage:)]) image = [icon getIconImage:2];
    else if([icon respondsToSelector:@selector(iconImageWithInfo:)]) image = [icon iconImageWithInfo:(struct SBIconImageInfo){60,60,2,0}];

    if (!image) {
      NSLog(@"[Axon] Image Not Founded!");
        NSArray *requests = [self requestsForBundleIdentifier:bundleIdentifier];
        for (int i = 0; i < [requests count]; i++) {
            NCNotificationRequest *request = requests[i];
            if ([request.sectionIdentifier isEqualToString:bundleIdentifier] && request.content && request.content.icon) {
                image = request.content.icon;
                break;
            }
        }
    }

    if (!image && model) {
        icon = [model applicationIconForBundleIdentifier:@"com.apple.Preferences"];
        if([icon respondsToSelector:@selector(getIconImage:)]) image = [icon getIconImage:2];
        else if([icon respondsToSelector:@selector(iconImageWithInfo:)]) image = [icon iconImageWithInfo:(struct SBIconImageInfo){60,60,2,0}];
    }

    if (!image) {
        image = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifier format:0 scale:[UIScreen mainScreen].scale];
    }

    if (image) {
        self.iconStore[bundleIdentifier] = [image copy];
    }

    return image ?: [UIImage new];
}

-(void)clearAll:(NSString *)bundleIdentifier {
    if (self.notificationRequests[bundleIdentifier]) {
        [self.dispatcher destination:nil requestsClearingNotificationRequests:[self allRequestsForBundleIdentifier:bundleIdentifier]];
    }
}

-(void)insertNotificationRequest:(NCNotificationRequest *)req {
    if (!req || ![req notificationIdentifier] || !req.bulletin || !req.bulletin.sectionID) return;
    NSString *bundleIdentifier = req.bulletin.sectionID;

    if (req.content && req.content.header) {
        self.names[bundleIdentifier] = [req.content.header copy];
    }

    if (req.timestamp) {
        if (!self.timestamps[bundleIdentifier] || [req.timestamp compare:self.timestamps[bundleIdentifier]] == NSOrderedDescending) {
            self.timestamps[bundleIdentifier] = [req.timestamp copy];
        }

        if (!self.latestRequest || [req.timestamp compare:self.latestRequest.timestamp] == NSOrderedDescending) {
            self.latestRequest = req;
        }
    }

    [self getRidOfWaste];
    if (self.notificationRequests[bundleIdentifier]) {
        BOOL found = NO;
        for (int i = 0; i < [self.notificationRequests[bundleIdentifier] count]; i++) {
            __weak AXNRequestWrapper *wrapped = self.notificationRequests[bundleIdentifier][i];
            if (wrapped && [[req notificationIdentifier] isEqualToString:[wrapped notificationIdentifier]]) {
                found = YES;
                break;
            }
        }

        if (!found) [self.notificationRequests[bundleIdentifier] addObject:[AXNRequestWrapper wrapRequest:req]];
    } else {
        self.notificationRequests[bundleIdentifier] = [NSMutableArray new];
        [self.notificationRequests[bundleIdentifier] addObject:[AXNRequestWrapper wrapRequest:req]];
    }

    [self updateCountForBundleIdentifier:bundleIdentifier];
}

-(void)removeNotificationRequest:(NCNotificationRequest *)req {
    if (!req || ![req notificationIdentifier] || !req.bulletin || !req.bulletin.sectionID) return;
    NSString *bundleIdentifier = req.bulletin.sectionID;

    if (self.latestRequest && [[self.latestRequest notificationIdentifier] isEqualToString:[req notificationIdentifier]]) {
        self.latestRequest = nil;
    }

    [self getRidOfWaste];
    if (self.notificationRequests[bundleIdentifier]) {
        __weak NSMutableArray *requests = self.notificationRequests[bundleIdentifier];
        for (int i = [requests count] - 1; i >= 0; i--) {
            __weak AXNRequestWrapper *wrapped = requests[i];
            if (wrapped && [[req notificationIdentifier] isEqualToString:[wrapped notificationIdentifier]]) {
                [requests removeObjectAtIndex:i];
            }
        }
    }

    [self updateCountForBundleIdentifier:bundleIdentifier];
}

-(void)modifyNotificationRequest:(NCNotificationRequest *)req {
    if (!req || ![req notificationIdentifier] || !req.bulletin || !req.bulletin.sectionID) return;
    NSString *bundleIdentifier = req.bulletin.sectionID;

    if (self.latestRequest && [[self.latestRequest notificationIdentifier] isEqualToString:[req notificationIdentifier]]) {
        self.latestRequest = req;
    }

    [self getRidOfWaste];
    if (self.notificationRequests[bundleIdentifier]) {
        __weak NSMutableArray *requests = self.notificationRequests[bundleIdentifier];
        for (int i = [requests count] - 1; i >= 0; i--) {
            __weak AXNRequestWrapper *wrapped = requests[i];
            if (wrapped && [wrapped notificationIdentifier] && [[req notificationIdentifier] isEqualToString:[wrapped notificationIdentifier]]) {
                [requests removeObjectAtIndex:i];
                [requests insertObject:[AXNRequestWrapper wrapRequest:req] atIndex:i];
                return;
            }
        }
    }
}

-(void)setLatestRequest:(NCNotificationRequest *)request {
    _latestRequest = request;

    if (self.view.showingLatestRequest) {
        [self.view reset];
    }
}

-(NSArray *)requestsForBundleIdentifier:(NSString *)bundleIdentifier {
    NSMutableArray *array = [NSMutableArray new];
    if (!self.notificationRequests[bundleIdentifier]) return array;

    [self getRidOfWaste];

    for (int i = 0; i < [self.notificationRequests[bundleIdentifier] count]; i++) {
        __weak AXNRequestWrapper *wrapped = self.notificationRequests[bundleIdentifier][i];
        if (wrapped && [wrapped request]) [array addObject:[wrapped request]];
    }

    return array;
}

-(NSArray *)allRequestsForBundleIdentifier:(NSString *)bundleIdentifier {
    NSArray *requests = [self requestsForBundleIdentifier:bundleIdentifier];

    if ([self.dispatcher.notificationStore respondsToSelector:@selector(coalescedNotificationForRequest:)]) {
        NSMutableArray *allRequests = [NSMutableArray new];
        NSMutableArray *coalescedNotifications = [NSMutableArray new];

        for (NCNotificationRequest *req in requests) {
            NCCoalescedNotification *coalesced = [self coalescedNotificationForRequest:req];
            if (!coalesced) {
                BOOL found = NO;
                for (int i = 0; i < [allRequests count]; i++) {
                    if ([[req notificationIdentifier] isEqualToString:[allRequests[i] notificationIdentifier]]) {
                        found = YES;
                        break;
                    }
                }

                if (!found) {
                    [allRequests addObject:req];
                }
                continue;
            }

            if (![coalescedNotifications containsObject:coalesced]) {
                for (NCNotificationRequest *request in coalesced.notificationRequests) {
                    BOOL found = NO;
                    for (int i = 0; i < [allRequests count]; i++) {
                        if ([[request notificationIdentifier] isEqualToString:[allRequests[i] notificationIdentifier]]) {
                            found = YES;
                            break;
                        }
                    }

                    if (!found) {
                        [allRequests addObject:request];
                    }
                }
                [coalescedNotifications addObject:coalesced];
            }
        }

        return allRequests;
    } else {
        return requests;
    }
}

-(id)coalescedNotificationForRequest:(id)req {
    NCCoalescedNotification *coalesced = nil;
    if ([self.dispatcher.notificationStore respondsToSelector:@selector(coalescedNotificationForRequest:)]) {
        coalesced = [self.dispatcher.notificationStore coalescedNotificationForRequest:req];
    }
    return coalesced;
}

-(void)showNotificationRequest:(NCNotificationRequest *)req {
    if (!req) return;
    self.clvc.axnAllowChanges = YES;
    if ([self.clvc respondsToSelector:@selector(insertNotificationRequest:forCoalescedNotification:)]) [self.clvc insertNotificationRequest:req forCoalescedNotification:[self coalescedNotificationForRequest:req]];
    else [self.clvc insertNotificationRequest:req];
    self.clvc.axnAllowChanges = NO;
}

-(void)hideNotificationRequest:(NCNotificationRequest *)req {
    if (!req) return;
    self.clvc.axnAllowChanges = YES;
    [self insertNotificationRequest:req];
    if ([self.clvc respondsToSelector:@selector(removeNotificationRequest:forCoalescedNotification:)]) [self.clvc removeNotificationRequest:req forCoalescedNotification:[self coalescedNotificationForRequest:req]];
    else [self.clvc removeNotificationRequest:req];
    self.clvc.axnAllowChanges = NO;

}

-(void)showNotificationRequests:(id)reqs {
    if (!reqs) return;
    for (id req in reqs) {
        [self showNotificationRequest:req];
    }
}

-(void)hideNotificationRequests:(id)reqs {
    if (!reqs) return;
    for (id req in reqs) {
        [self hideNotificationRequest:req];
    }
}

-(void)showNotificationRequestsForBundleIdentifier:(NSString *)bundleIdentifier {
    [self showNotificationRequests:[self requestsForBundleIdentifier:bundleIdentifier]];
}

-(void)hideAllNotificationRequests {
    [self hideNotificationRequests:[self.clvc allNotificationRequests]];
}

-(void)hideAllNotificationRequestsExcept:(id)notification {
  NSMutableSet *set = [[self.clvc allNotificationRequests] mutableCopy];
  [set removeObject:notification];
  [self hideNotificationRequests:set];
}

-(void)revealNotificationHistory:(BOOL)revealed {
    [self.clvc revealNotificationHistory:revealed];
}

@end
