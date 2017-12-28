#import "Hotspotting.h"


static BOOL canSystemSleep;
static BOOL isSpringBoard;
static BOOL isVisible;
static WirelessModemController* controller;
static MISManager *manager;
static NSInteger insideSwitch;
static NETRB_SVC_STATE stateHotspot;


%hook UIAlertView
- (void)show
{
	if (isSpringBoard && insideSwitch) {
		id<UIAlertViewDelegate> delegate = [self delegate];
		if (delegate && [delegate isKindOfClass:%c(WirelessModemController)] && [self numberOfButtons] == 2) {
			if ([delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
				[delegate alertView:self clickedButtonAtIndex:0];
				return;
			}
		}
	}
	%orig;
}
%end

%hook MISManager
-(void)sendStateUpdate
{
	%orig;
	notify_post("com.julioverne.hotspotting/SettingsChanged");
}
%end

%hook WirelessModemController
- (void)applicationDidBecomeActive:(id)arg1
{
	if(!isSpringBoard) {
		return;
	}
	%orig;
}
-(void)applicationWillResignOrTerminate:(id)arg1
{
	if(!isSpringBoard) {
		return;
	}
	%orig;
}
- (void)allowWirelessConnections:(BOOL)arg1
{
	if(manager) {
		arg1 = stateHotspot==NETRB_SVC_STATE_ON?isVisible:NO;
	}
	%orig(arg1);
}
- (void)_btPowerChangedHandler:(NSNotification *)notification
{
	if(isSpringBoard) {
		return;
	}
	%orig;
}
%end


#import <libactivator/libactivator.h>
#import <Flipswitch/Flipswitch.h>

static void settingsChangedHotspotting(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		[manager getState:&stateHotspot andReason:NULL];
		canSystemSleep = !((stateHotspot == NETRB_SVC_STATE_ON) && isVisible);
		if(isSpringBoard) {
			[[%c(FSSwitchPanel) sharedPanel] stateDidChangeForSwitchIdentifier:@"com.julioverne.hotspotting"];
		}
		notify_post("com.julioverne.hotspotting/SettingsChanged/Toogle");
		if(controller) {
			[controller allowWirelessConnections:NO];
		}
	}
}


@interface HotspottingActivatorSwitch : NSObject <FSSwitchDataSource>
+ (id)sharedInstance;
+ (BOOL)sharedInstanceExist;
- (void)RegisterActions;
@end

@implementation HotspottingActivatorSwitch
__strong static id _sharedObject;
+ (id)sharedInstance
{
	if (!_sharedObject) {
		_sharedObject = [[self alloc] init];
	}
	return _sharedObject;
}
+ (BOOL)sharedInstanceExist
{
	if (_sharedObject) {
		return YES;
	}
	return NO;
}
- (void)RegisterActions
{
    if (access("/usr/lib/libactivator.dylib", F_OK) == 0) {
		dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	    if (Class la = objc_getClass("LAActivator")) {
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.toggle"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.visible.toggle"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.on"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.off"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.on.visible.on"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.off.visible.off"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.off.visible.on"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.on.visible.off"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.visible.on"];
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.hotspotting.visible.off"];
		}
	}
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName
{
	return @"Hotspotting";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName
{
	if([listenerName isEqualToString:@"com.julioverne.hotspotting.toggle"]) {
		return @"Hotspot: Toggle Enabled/Disabled";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.visible.toggle"]) {
		return @"Hotspot Visible: Toggle On/Off";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.on"]) {
		return @"Hotspot: Enable";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.off"]) {
		return @"Hotspot: Disable";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.on.visible.on"]) {
		return @"Hotspot: Enable + Visible On";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.off.visible.off"]) {
		return @"Hotspot: Disable + Visible Off";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.off.visible.on"]) {
		return @"Hotspot: Disable + Visible On";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.on.visible.off"]) {
		return @"Hotspot: Enable + Visible Off";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.visible.on"]) {
		return @"Hotspot Visible: On";
	} else if([listenerName isEqualToString:@"com.julioverne.hotspotting.visible.off"]) {
		return @"Hotspot Visible: Off";
	}	
	return nil;
}
- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    static __strong UIImage* listenerIcon;
    if (!listenerIcon) {
		listenerIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/HotspottingSettings.bundle"] pathForResource:scale==2.0f?@"icon@2x":@"icon" ofType:@"png"]];
	}
    return listenerIcon;
}
- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    static __strong UIImage* listenerIcon;
    if (!listenerIcon) {
		listenerIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/HotspottingSettings.bundle"] pathForResource:scale==2.0f?@"icon@2x":@"icon" ofType:@"png"]];
	}
    return listenerIcon;
}
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName
{
	@autoreleasepool {
		BOOL EnableDisable = (stateHotspot == NETRB_SVC_STATE_ON);
		if(listenerName) {
			if([listenerName rangeOfString:@"hotspotting.toggle"].location != NSNotFound) {
				EnableDisable = !EnableDisable;
			}
			if([listenerName rangeOfString:@"visible.toggle"].location != NSNotFound) {
				isVisible = !isVisible;
			}
			if([listenerName rangeOfString:@"visible.on"].location != NSNotFound) {
				isVisible = YES;
			}
			if([listenerName rangeOfString:@"visible.off"].location != NSNotFound) {
				isVisible = NO;
			}
			if([listenerName rangeOfString:@"hotspotting.on"].location != NSNotFound) {
				EnableDisable = YES;
			}
			if([listenerName rangeOfString:@"hotspotting.off"].location != NSNotFound) {
				EnableDisable = NO;
			}
		}
		if(manager) {
			insideSwitch++;
			[controller setInternetTethering:@(EnableDisable) specifier:[controller specifierForID:@"TETHERING_SWITCH"]];
			insideSwitch--;
		}
		notify_post("com.julioverne.hotspotting/SettingsChanged");
	}
}
- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
	switch (stateHotspot) {
		case NETRB_SVC_STATE_ON: {
			return FSSwitchStateOn;
		}
		case NETRB_SVC_STATE_OFF: {
			return FSSwitchStateOff;
		}
		default: {
			return FSSwitchStateIndeterminate;
		}
	}
	return FSSwitchStateIndeterminate;
}
- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	[self activator:nil receiveEvent:nil forListenerName:(newState==FSSwitchStateOn)?@"com.julioverne.hotspotting.on.visible.on":@"com.julioverne.hotspotting.off.visible.off"];
}
- (void)applyAlternateActionForSwitchIdentifier:(NSString *)switchIdentifier
{
	[[%c(FSSwitchPanel) sharedPanel] openURLAsAlternateAction:[NSURL URLWithString:@"prefs:root=Hotspotting"]];
}
@end



static io_connect_t gRootPort = MACH_PORT_NULL;
static io_object_t notifier;

static void HandlePowerManagerEvent(void *inContext, io_service_t inIOService, natural_t inMessageType, void *inMessageArgument)
{
    if(inMessageType == kIOMessageSystemWillSleep) {
		IOAllowPowerChange(gRootPort, (long)inMessageArgument);
		NSLog(@"*** kIOMessageSystemWillSleep");
	} else if(inMessageType == kIOMessageCanSystemSleep) {
		if(canSystemSleep) {
			IOAllowPowerChange(gRootPort, (long)inMessageArgument);
		} else {
			IOCancelPowerChange(gRootPort, (long)inMessageArgument);
		}
		NSLog(@"*** kIOMessageCanSystemSleep %@", @(canSystemSleep));
	}
}

static void preventSystemSleep()
{
	IONotificationPortRef notify;
	gRootPort = IORegisterForSystemPower(NULL, &notify, HandlePowerManagerEvent, &notifier);
    if(gRootPort == MACH_PORT_NULL) {
        NSLog (@"IORegisterForSystemPower failed.");
    } else {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notify), kCFRunLoopDefaultMode);
    }
}

%ctor
{
	@autoreleasepool {
		dlopen("/System/Library/PreferenceBundles/WirelessModemSettings.bundle/WirelessModemSettings", RTLD_GLOBAL);
		isSpringBoard = !strcmp(__progname, "SpringBoard");
		
		isVisible = YES;
		
		if(isSpringBoard) {
			canSystemSleep = YES;
			preventSystemSleep();
		}
		
		
		
		manager = [%c(MISManager) sharedManager];
		
		PSRootController *rootController = [[%c(PSRootController) alloc] initWithTitle:@"Preferences" identifier:@"com.apple.Preferences"];
		controller = [[%c(WirelessModemController) alloc] init];
		[controller setRootController:rootController];
		[controller setParentController:rootController];
		
		%init;
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, settingsChangedHotspotting, CFSTR("SBNetworkTetheringStateChangedNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChangedHotspotting, CFSTR("com.julioverne.hotspotting/SettingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		settingsChangedHotspotting(NULL, NULL, NULL, NULL, NULL);
		
		if(isSpringBoard) {
			[[HotspottingActivatorSwitch sharedInstance] RegisterActions];
		}
	}
}
