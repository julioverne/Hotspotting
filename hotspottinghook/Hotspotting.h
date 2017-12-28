#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>

#import <prefs.h>

extern const char *__progname;

#define NSLog(...)

typedef enum {
	NETRB_SVC_STATE_ON = 1023,
	NETRB_SVC_STATE_OFF = 1022,
} NETRB_SVC_STATE;

@interface MISManager : NSObject
+ (MISManager *)sharedManager;
- (void)setState:(NETRB_SVC_STATE)state;
- (void)getState:(NETRB_SVC_STATE *)outState andReason:(int *)reason;
- (void)sendStateUpdate;
@end

@interface PSRootController : UINavigationController
- (id)initWithTitle:(id)arg1 identifier:(id)arg2;
@end

@interface WirelessModemController : PSListController
- (void)allowWirelessConnections:(BOOL)arg1;
- (void)setInternetTethering:(id)arg1 specifier:(id)arg2;
- (void)setRootController:(id)arg1;
- (void)setParentController:(id)arg1;
@end


#import <IOKit/IOKitLib.h>

extern "C" io_connect_t IORegisterForSystemPower(void * refcon, IONotificationPortRef * thePortRef, IOServiceInterestCallback callback, io_object_t * notifier );
extern "C" IOReturn IOAllowPowerChange( io_connect_t kernelPort, long notificationID );
extern "C" IOReturn IOCancelPowerChange(io_connect_t kernelPort, intptr_t notificationID);
extern "C" IOReturn IOPMSchedulePowerEvent(CFDateRef time_to_wake, CFStringRef my_id, CFStringRef type);
extern "C" IOReturn IOPMCancelScheduledPowerEvent(CFDateRef time_to_wake, CFStringRef my_id, CFStringRef type);
extern "C" IOReturn IODeregisterForSystemPower ( io_object_t * notifier );
extern "C" CFArrayRef IOPMCopyScheduledPowerEvents(void);

typedef uint32_t IOPMAssertionLevel;
typedef uint32_t IOPMAssertionID;
extern "C" IOReturn IOPMAssertionCreateWithName(CFStringRef AssertionType,IOPMAssertionLevel AssertionLevel, CFStringRef AssertionName, IOPMAssertionID *AssertionID);
extern "C" IOReturn IOPMAssertionRelease(IOPMAssertionID AssertionID);
#define iokit_common_msg(message)          (UInt32)(sys_iokit|sub_iokit_common|message)
#define kIOMessageCanSystemPowerOff iokit_common_msg( 0x240)
#define kIOMessageSystemWillPowerOff iokit_common_msg( 0x250) 
#define kIOMessageSystemWillNotPowerOff iokit_common_msg( 0x260)
#define kIOMessageCanSystemSleep iokit_common_msg( 0x270) 
#define kIOMessageSystemWillSleep iokit_common_msg( 0x280) 
#define kIOMessageSystemWillNotSleep iokit_common_msg( 0x290) 
#define kIOMessageSystemHasPoweredOn iokit_common_msg( 0x300) 
#define kIOMessageSystemWillRestart iokit_common_msg( 0x310) 
#define kIOMessageSystemWillPowerOn iokit_common_msg( 0x320)

#define kIOPMAutoPowerOn "poweron" 
#define kIOPMAutoShutdown "shutdown" 
#define kIOPMAutoSleep "sleep"
#define kIOPMAutoWake "wake"
#define kIOPMAutoWakeOrPowerOn "wakepoweron"
