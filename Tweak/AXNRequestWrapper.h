#import "RandomHeaders.h"

@interface AXNRequestWrapper : NSObject

@property (nonatomic, strong) NSString *notificationIdentifier;
@property (nonatomic, weak) NCNotificationRequest *request;

+(AXNRequestWrapper *)wrapRequest:(NCNotificationRequest *)request;

@end