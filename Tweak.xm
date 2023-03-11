#import <Cephei/HBPreferences.h>

@interface SBWiFiManager
+ (id)sharedInstance;
- (BOOL)isPowered;
- (void)_powerStateDidChange;
- (void)_linkDidChange;
- (id)currentNetworkName;
- (BOOL)isAssociated;
- (void)setWiFiEnabled:(BOOL)arg1;
- (void)mobileDataStatusHasChanged;
- (BOOL)isMobileDataEnabled;
- (void)setMobileDataEnabled:(BOOL)enabled;
- (void)getWiCellSwitcherPrefs;
@end

@interface WiFiUtils
+ (id)sharedInstance;
+ (bool)scanInfoIs5GHz:(id)arg1;
- (long)closeWiFi;
- (long)disassociateSync;
- (id)getLinkStatus;
- (id)getNetworkPasswordForNetworkNamed:(id)arg1;
- (int)joinNetworkWithNameAsync:(id)arg1 password:(id)arg2 rememberChoice:(int)arg3;
- (BOOL)isJoinInProgress;
- (BOOL)isScanInProgress;
- (BOOL)isScanningActive;
- (void)activateScanning:(BOOL)arg1;
- (void)triggerScan;
- (long)setAutoJoinState:(BOOL)arg1;
- (double)periodicScanInterval;
@end

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (void)_updateDataNetworkItem;
@end

HBPreferences *preferences;

BOOL cellularActive;
BOOL wiFiActive;
BOOL cellularActivePreviousState;
BOOL wiFiActivePreviousState;
BOOL justChangedStatus;
BOOL disconnectOption = YES;
id   wiFiButtonID;

extern "C" Boolean CTCellularDataPlanGetIsEnabled();
extern "C" void CTCellularDataPlanSetIsEnabled(Boolean enabled);
// extern "C" CFNotificationCenterRef CTTelephonyCenterGetDefault();
// extern "C" void CTTelephonyCenterAddObserver(CFNotificationCenterRef center, const void *observer, CFNotificationCallback callBack, CFStringRef name, const void *object, CFNotificationSuspensionBehavior suspensionBehavior);
// extern "C" void CTTelephonyCenterRemoveObserver(CFNotificationCenterRef center, const void *observer, CFStringRef name, const void *object);
// extern "C" CFStringRef const kCTRegistrationDataStatusChangedNotification;

// static void FSDataSwitchStatusDidChange(void)
// {
//   [[%c(SBWiFiManager) sharedInstance] mobileDataStatusHasChanged];
// }

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application
{
  %orig;
  if (!disconnectOption)
    wiFiActive = [[%c(SBWiFiManager) sharedInstance] isPowered];
  else
    wiFiActive = [[%c(SBWiFiManager) sharedInstance] currentNetworkName] != nil;
  cellularActive = [[%c(SBWiFiManager) sharedInstance] isMobileDataEnabled];
  if (wiFiActive && cellularActive) {
    justChangedStatus = YES;
    [[%c(SBWiFiManager) sharedInstance] setMobileDataEnabled:NO];
    cellularActivePreviousState = !cellularActive;
    wiFiActivePreviousState = wiFiActive;
  }
  // CTTelephonyCenterAddObserver(
  //   CTTelephonyCenterGetDefault(),
  //   NULL,
  //   (CFNotificationCallback)FSDataSwitchStatusDidChange,
  //   kCTRegistrationDataStatusChangedNotification,
  //   NULL,
  //   CFNotificationSuspensionBehaviorCoalesce
  // );
}
%end

%hook SBStatusBarStateAggregator
- (void)_updateDataNetworkItem
{
  %orig;
  [[%c(SBWiFiManager) sharedInstance] mobileDataStatusHasChanged];
}
%end

%hook SBWiFiManager
- (void)_powerStateDidChange
{
  %orig;
  if (!justChangedStatus && !disconnectOption)
  {
    cellularActive = [self isMobileDataEnabled];
    wiFiActive = ([self currentNetworkName] != nil);
    if (wiFiActive != wiFiActivePreviousState)
    {
      justChangedStatus = YES;
      [self setMobileDataEnabled:!wiFiActive];
      cellularActivePreviousState = [self isMobileDataEnabled];
      wiFiActivePreviousState = wiFiActive;
    }
  }
  else justChangedStatus = NO;
}

- (void)_linkDidChange
{
  %orig;
  if (!justChangedStatus && disconnectOption)
  {
    cellularActive = [self isMobileDataEnabled];
    wiFiActive = [self isAssociated];
    if (wiFiActive != wiFiActivePreviousState)
    {
      justChangedStatus = YES;
      [self setMobileDataEnabled:!wiFiActive];
      cellularActivePreviousState = [self isMobileDataEnabled];
      wiFiActivePreviousState = wiFiActive;
    }
  }
  else justChangedStatus = NO;
}

%new
- (void)mobileDataStatusHasChanged
{
  if (!justChangedStatus && disconnectOption)
  {
    cellularActive = [self isMobileDataEnabled];
    wiFiActive = [self isPowered];
    if (cellularActive != cellularActivePreviousState)
    {
      justChangedStatus = YES;
      if (cellularActive) {
        [self setWiFiEnabled:NO];
      } else {
        [self setWiFiEnabled:YES];
        [[%c(WiFiUtils) sharedInstance] setAutoJoinState:YES];
      }
      cellularActivePreviousState = cellularActive;
      wiFiActivePreviousState = [self isPowered];
    }
  }
  else justChangedStatus = NO;
}

%new
- (BOOL)isMobileDataEnabled
{
  return CTCellularDataPlanGetIsEnabled();
}

%new
- (void)setMobileDataEnabled:(BOOL)enabled
{
  CTCellularDataPlanSetIsEnabled(enabled);
}

%end

%ctor
{
  preferences = [[HBPreferences alloc] initWithIdentifier:@"com.brunonfl.wicellswitcher"];
  [preferences registerBool:&disconnectOption default:YES forKey:@"disconnectOptionSwitch"];
}
