#import "RandomHeaders.h"

@interface AXNRequestWrapper : NSObject

@property (nonatomic, strong) NSString *notificationIdentifier;
@property (nonatomic, strong) NCNotificationRequest *request;

+(AXNRequestWrapper *)wrapRequest:(NCNotificationRequest *)request;

@end