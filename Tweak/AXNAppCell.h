@interface MPArtworkColorAnalyzer : NSObject
- (void)analyzeWithCompletionHandler:(id /* block */)arg1;
- (id)initWithImage:(id)arg1 algorithm:(long long)arg2;
@end

@interface MTMaterialView : UIView
+(id)materialViewWithRecipe:(long long)arg1 options:(unsigned long long)arg2 ;
+(id)materialViewWithRecipe:(long long)arg1 configuration:(unsigned long long)arg2 ;
@end

@interface MPArtworkColorAnalysis : NSObject
@property (nonatomic, readonly) UIColor *backgroundColor;
@property (nonatomic, readonly) UIColor *primaryTextColor;
@property (nonatomic, readonly) UIColor *secondaryTextColor;
@end

@interface AXNAppCell : UICollectionViewCell {
    NSArray *_styleConstraints;
}

@property (nonatomic, retain) UIImageView *iconView;
@property (nonatomic, retain) UIView *blurView;
@property (nonatomic, retain) UILabel *badgeLabel;
@property (nonatomic, retain) NSString *bundleIdentifier;
@property (nonatomic, assign) NSInteger notificationCount;
@property (nonatomic, assign) NSInteger selectionStyle;
@property (nonatomic, assign) NSInteger style;
@property (nonatomic, assign) BOOL badgesShowBackground;
@property (nonatomic, assign) BOOL darkMode;
@property (nonatomic, assign) BOOL isSetupComplete;

@end
@interface SBApplicationController
+(id)sharedInstance;
-(id)applicationWithBundleIdentifier:(id)arg1;
@end
@interface SBApplication
@property (nonatomic,readonly) NSString * displayName;
@end
