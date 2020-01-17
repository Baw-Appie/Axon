#import <AppList/AppList.h>
#import "AXNController.h"
NSMutableDictionary *prefs;

@interface AXNLocationController : PSListController {
	PSSpecifier *_autoLayoutLocationSpecifier;
	PSSpecifier *_yAxisSpecifier;
}
@property (nonatomic, strong) PSSpecifier *autoLayoutLocationSpecifier;
@property (nonatomic, strong) PSSpecifier *yAxisSpecifier;
@end



@implementation AXNLocationController
-(id)specifiers {
	if(_specifiers == nil)
	{
		NSMutableArray *specifiers = [[NSMutableArray alloc] init];

		if(![[NSFileManager defaultManager] fileExistsAtPath:PREFERENCE_IDENTIFIER]) prefs = [[NSMutableDictionary alloc] init];
		else prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCE_IDENTIFIER];

		[specifiers addObject:({
			PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"Location" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
			specifier;
		})];

		[specifiers addObject:({
			PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"Auto Layout" target:self set:@selector(setSwitch:forSpecifier:) get:@selector(getSwitch:) detail:nil cell:PSSwitchCell edit:nil];
			[specifier.properties setValue:@"autoLayout" forKey:@"displayIdentifier"];
			specifier;
		})];


		[specifiers addObject:({
			PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"Y-Axis" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
			specifier;
		})];

		self.autoLayoutLocationSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Location" target:self set:@selector(setSwitch:forSpecifier:) get:@selector(getSwitch:) detail:nil cell:PSSegmentCell edit:nil];
		[self.autoLayoutLocationSpecifier setValues:@[@0, @1] titles:@[@"Top", @"Bottom (Beta)"]];
		[self.autoLayoutLocationSpecifier.properties setValue:@"location" forKey:@"displayIdentifier"];

		self.yAxisSpecifier = [PSSpecifier preferenceSpecifierNamed:@"size" target:self set:@selector(setNumber:forSpecifier:) get:@selector(getSwitch:) detail:Nil cell:PSSliderCell edit:Nil];
		[self.yAxisSpecifier setProperty:@"yAxis" forKey:@"displayIdentifier"];
		[self.yAxisSpecifier setProperty:@500 forKey:@"default"];
		[self.yAxisSpecifier setProperty:@0 forKey:@"min"];
		[self.yAxisSpecifier setProperty:[NSNumber numberWithFloat:[UIScreen mainScreen].bounds.size.height] forKey:@"max"];
		[self.yAxisSpecifier setProperty:@YES forKey:@"showValue"];

		if([[self getValue:@"autoLayout"] isEqual:@1]) {
			[specifiers addObject:self.autoLayoutLocationSpecifier];
		} else {
			[specifiers addObject:self.yAxisSpecifier];
		}

		_specifiers = [specifiers copy];
	}

	return _specifiers;
}

-(void)setSwitch:(NSNumber *)value forSpecifier:(PSSpecifier *)specifier {
	prefs[[specifier propertyForKey:@"displayIdentifier"]] = [NSNumber numberWithBool:[value boolValue]];
	[[prefs copy] writeToFile:PREFERENCE_IDENTIFIER atomically:FALSE];

	if([[specifier propertyForKey:@"displayIdentifier"] isEqualToString:@"autoLayout"]) {
		if([[self getValue:@"autoLayout"] isEqual:@1]) {
			[self removeSpecifier:self.yAxisSpecifier animated:true];
			[self addSpecifier:self.autoLayoutLocationSpecifier animated:true];
		} else {
			[self removeSpecifier:self.autoLayoutLocationSpecifier animated:true];
			[self addSpecifier:self.yAxisSpecifier animated:true];
		}
	}
}
-(void)setNumber:(NSNumber *)value forSpecifier:(PSSpecifier *)specifier {
	prefs[[specifier propertyForKey:@"displayIdentifier"]] = value;
	[[prefs copy] writeToFile:PREFERENCE_IDENTIFIER atomically:FALSE];
}
-(NSNumber *)getSwitch:(PSSpecifier *)specifier {
	return [self getValue:[specifier propertyForKey:@"displayIdentifier"]];
}
-(NSNumber *)getValue:(NSString *)name {
	return prefs[name] ? [NSNumber numberWithInteger:[prefs[name] intValue]] : @(1);
}
@end
