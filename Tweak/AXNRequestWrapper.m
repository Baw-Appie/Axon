#import "AXNRequestWrapper.h"

@implementation AXNRequestWrapper

+(AXNRequestWrapper *)wrapRequest:(NCNotificationRequest *)request {
    if (!request || ![request notificationIdentifier]) return nil;
    AXNRequestWrapper *wrapped = [AXNRequestWrapper alloc];
    wrapped.request = request;
    wrapped.notificationIdentifier = [[request notificationIdentifier] copy];
    return wrapped;
}

@end