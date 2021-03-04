#import <AudioToolbox/AudioToolbox.h>
#import "AXNAppCell.h"
#import "AXNManager.h"

@implementation AXNAppCell

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    _style = -1;

    // for some unknown reason AXNView isn't able to set badgesEnabled, so i'm loading it from the preferences
    NSMutableDictionary* prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.nepeta.axon.plist"];
    self.badgesEnabled = prefs[@"BadgesEnabled"] != nil ? [prefs[@"BadgesEnabled"] boolValue] : true;

    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
    [self addGestureRecognizer:recognizer];

    self.layer.cornerRadius = 13;
    self.layer.continuousCorners = YES;
    self.layer.masksToBounds = YES;

    self.iconView = [[UIImageView alloc] initWithFrame:frame];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;

    if (self.badgesEnabled) {
      self.badgeLabel = [[UILabel alloc] initWithFrame:frame];
      self.badgeLabel.font = [UIFont boldSystemFontOfSize:14];
      self.badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
      self.badgeLabel.text = @"0";
      self.badgeLabel.textColor = [UIColor whiteColor];
      self.badgeLabel.backgroundColor = [UIColor blackColor];
      self.badgeLabel.layer.cornerRadius = 10;
      self.badgeLabel.layer.masksToBounds = YES;
      self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    }

    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    // self.blurView.bounds = self.bounds;

    if (self.badgesEnabled) {
      _styleConstraints = @[
        @[  // default
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-30],
            [self.badgeLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.badgeLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
            [self.badgeLabel.heightAnchor constraintEqualToConstant:20],
            [self.badgeLabel.widthAnchor constraintEqualToConstant:30],
        ],
        @[  // packed
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
            [self.badgeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
            [self.badgeLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
            [self.badgeLabel.heightAnchor constraintEqualToConstant:20],
            [self.badgeLabel.widthAnchor constraintEqualToConstant:30],
        ],
        @[  // compact
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
            [self.badgeLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.badgeLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
            [self.badgeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [self.badgeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
        ],
        @[  // tiny
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-25],
            [self.badgeLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.badgeLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
            [self.badgeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
            [self.badgeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
        ],
        @[  // group
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-28],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],

            [self.badgeLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.badgeLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.badgeLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
            [self.badgeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.badgeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
        ],
        @[  // group rounded
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-26],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],

            [self.badgeLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.badgeLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [self.badgeLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
            [self.badgeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:33],
            [self.badgeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-7],
        ]
      ];
    } else if (!self.badgesEnabled) {
      _styleConstraints = @[
        @[  // default
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
        ],
        @[  // packed
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
        ],
        @[  // compact
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
        ],
        @[  // tiny
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
        ],
        @[  // group
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
        ],
        @[  // group rounded
            [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
            [self.iconView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
            [self.iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
        ]
      ];
    }

    return self;
}

-(UISemanticContentAttribute)semanticContentAttribute {
  return UISemanticContentAttributeForceLeftToRight;
}

-(void)axnClearAll {
    [[AXNManager sharedInstance] clearAll:self.bundleIdentifier];
}
-(void)axnRealClearAll {
  [[AXNManager sharedInstance] clearAll];
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(axnClearAll));
}

-(NSString *)getAppName {
    return [AXNManager sharedInstance].names[self.bundleIdentifier];

  SBApplication *app = [[NSClassFromString(@"SBApplicationController") sharedInstance] applicationWithBundleIdentifier:self.bundleIdentifier];
  return app.displayName;
}

-(void)showMenu:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        AudioServicesPlaySystemSound(1519);

        float version = [[[UIDevice currentDevice] systemVersion] floatValue];

        if(version >= 13) {
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notification Option" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
      		[alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Clear All %@ notifications", [self getAppName]] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self axnClearAll];
      		}]];
      		[alert addAction:[UIAlertAction actionWithTitle:@"Clear All notifications" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self axnRealClearAll];
      		}]];
        	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        	}]];
          UIResponder *responder = self;
          while ([responder isKindOfClass:[UIView class]]) responder = [responder nextResponder];
          [(UIViewController *)responder presentViewController:alert animated:YES completion:nil];
        } else {
          [self becomeFirstResponder];
          UIMenuController *menu = [UIMenuController sharedMenuController];
          menu.menuItems = @[
              [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Clear All %@ notifications", [self getAppName]] action:@selector(axnClearAll)],
              [[UIMenuItem alloc] initWithTitle:@"Clear All notifications" action:@selector(axnRealClearAll)]
          ];
          [menu setTargetRect:self.bounds inView:self];
          [menu setMenuVisible:YES animated:YES];
        }
    }
}

-(void)setBundleIdentifier:(NSString *)value {
    _bundleIdentifier = value;

    if(self.iconStyle == 0) self.iconView.image = [[AXNManager sharedInstance] getIcon:value rounded:_style == 5];
    else if(self.iconStyle == 1) self.iconView.image = [[AXNManager sharedInstance] getIcon:value rounded:true];
    else if(self.iconStyle == 2) self.iconView.image = [[AXNManager sharedInstance] getIcon:value rounded:false];

    self.badgeLabel.backgroundColor = [UIColor clearColor];
    if(_style != 4) self.badgeLabel.textColor = [[AXNManager sharedInstance] fallbackColor];
    if(_style == 5) self.badgeLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];

    BOOL iOS13 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 13;

    if (self.badgesShowBackground && self.iconView.image && _style != 4) {
        if ([AXNManager sharedInstance].backgroundColorCache[value] && [AXNManager sharedInstance].textColorCache[value]) {
            self.badgeLabel.backgroundColor = [[AXNManager sharedInstance].backgroundColorCache[value] copy];
            self.badgeLabel.textColor = [[AXNManager sharedInstance].textColorCache[value] copy];
        } else {
          if(iOS13) {
            CGSize size = {1, 1};
            UIGraphicsBeginImageContext(size);
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
            [[self.iconView.image copy] drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
            uint8_t *data = CGBitmapContextGetData(ctx);
            UIColor *backgroundColor = [UIColor colorWithRed:data[2] / 255.0f green:data[1] / 255.0f blue:data[0] / 255.0f alpha:1];
            UIGraphicsEndImageContext();
            CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
            [backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
            int threshold = 105;
            int bgDelta = ((red * 0.299) + (green * 0.587) + (blue * 0.114));
            UIColor *textColor = (255 - bgDelta < threshold) ? [UIColor blackColor] : [UIColor whiteColor];
            self.badgeLabel.backgroundColor = [backgroundColor copy];
            self.badgeLabel.textColor = [textColor copy];
          } else {
            __weak AXNAppCell *weakSelf = self;
            MPArtworkColorAnalyzer *colorAnalyzer = [[MPArtworkColorAnalyzer alloc] initWithImage:self.iconView.image algorithm:0];
            [colorAnalyzer analyzeWithCompletionHandler:^(MPArtworkColorAnalyzer *analyzer, MPArtworkColorAnalysis *analysis) {
                [AXNManager sharedInstance].backgroundColorCache[value] = [analysis.backgroundColor copy];
                [AXNManager sharedInstance].textColorCache[value] = [analysis.primaryTextColor copy];
                [weakSelf badgeLabel].backgroundColor = [analysis.backgroundColor copy];
                [weakSelf badgeLabel].textColor = [analysis.primaryTextColor copy];
            }];
          }
        }
    }
}

-(void)setNotificationCount:(NSInteger)value {
    _notificationCount = value;

    if (value <= 99) {
        self.badgeLabel.text = [NSString stringWithFormat:@"%ld", value];
    } else {
        self.badgeLabel.text = @"99+";
    }
}

-(void)setSelectionStyle:(NSInteger)style {
    _selectionStyle = style;

    self.iconView.alpha = 1.0;
    self.badgeLabel.alpha = 1.0;
    self.backgroundColor = [UIColor clearColor];
}

-(void)setStyle:(NSInteger)style {
    if (_style == style) return;
    NSInteger oldStyle = _style;

    if (style >= [_styleConstraints count] || style < 0) _style = 0;
    else _style = style;

    if (style == 2) self.badgeLabel.layer.cornerRadius = 8;
    if(style == 3 || style == 4 || style == 5) {
      if (style == 3) {
        self.layer.cornerRadius = 10;
        self.badgeLabel.layer.cornerRadius = 8;
      } else if(style == 4) {
        self.layer.cornerRadius = 10;
        self.badgeLabel.textAlignment = NSTextAlignmentRight;
        self.badgeLabel.backgroundColor = [UIColor clearColor];
        self.badgeLabel.textColor = [UIColor whiteColor];
      } else {
        self.layer.cornerRadius = 18;
        self.alpha = 0.5;
        self.badgeLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
      }
      if (self.addBlur || style == 4 || style == 5) [self addSubview:self.blurView];
      if (self.badgesEnabled) [self addSubview:self.badgeLabel];
      [self addSubview:self.iconView];
    } else {
      if (self.addBlur || style == 4 || style == 5) [self addSubview:self.blurView];
      [self addSubview:self.iconView];
      if (self.badgesEnabled) [self addSubview:self.badgeLabel];
    }

    if (oldStyle != -1) [NSLayoutConstraint deactivateConstraints:_styleConstraints[oldStyle]];
    [NSLayoutConstraint activateConstraints:_styleConstraints[_style]];
    [self setNeedsLayout];
}

-(void)setDarkMode:(BOOL)darkMode {
    if (_darkMode == darkMode) return;

    CGRect frame = self.blurView.frame;
    if(darkMode) {
      id materialView = objc_getClass("MTMaterialView");
      if([materialView respondsToSelector:@selector(materialViewWithRecipe:options:)]) {
        self.blurView = [materialView materialViewWithRecipe:MTMaterialRecipeNotifications options:MTMaterialOptionsBlur];
      } else {
        self.blurView = [materialView materialViewWithRecipe:MTMaterialRecipeNotifications configuration:1];
      }
      self.blurView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    } else self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = frame;
    self.badgeLabel.textColor = darkMode ? [UIColor whiteColor] : [UIColor blackColor];
    self.badgeLabel.alpha = 0.4f;

    [self setNeedsDisplay];
}

-(void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if(self.selectionStyle == 2) return;

    if (selected) {
        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            switch (self.selectionStyle) {
                case 1:
                    self.iconView.alpha = 1.0;
                    self.badgeLabel.alpha = 1.0;
                    break;
                default:
                    if (!self.darkMode) self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
                    else if (self.darkMode) self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
            }
        } completion:NULL];
    } else {
        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            switch (self.selectionStyle) {
                case 1:
                    self.iconView.alpha = 0.5;
                    self.badgeLabel.alpha = 0.5;
                    break;
                default:
                    self.backgroundColor = [UIColor clearColor];
            }
        } completion:NULL];
    }
}

@end
