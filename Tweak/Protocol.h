@protocol clvc <NSObject>
@property (nonatomic,assign) BOOL axnAllowChanges;

@optional
-(void)insertNotificationRequest:(id)arg1 ;
-(void)modifyNotificationRequest:(id)arg1 ;
-(void)removeNotificationRequest:(id)arg1 ;
-(void)insertNotificationRequest:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(void)modifyNotificationRequest:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(void)removeNotificationRequest:(id)arg1 forCoalescedNotification:(id)arg2 ;
-(NSSet *)allNotificationRequests;
-(id)collectionView;
-(void)revealNotificationHistory:(BOOL)revealed;

@end
