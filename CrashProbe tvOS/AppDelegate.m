//
//  AppDelegate.m
//  CrashProbetvOS
//
//  Created by Andreas Linde on 19.09.17.
//  Copyright © 2017 Bit Stadium GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "CRLServerEnv.h"

#if TARGET_SXS
@import HockeySDK;

@interface AppDelegate(Private) <BITHockeyManagerDelegate>
#else
@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;

@interface AppDelegate (Private)  <MSCrashesDelegate>
#endif

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  CRLServerEnvironment currentEnvironment = crl_storedServerEnvironment();
  NSString *appSecret = crl_secretForEnvironment(currentEnvironment);
  NSString *logURLString = crl_URLStringForEnvironment(currentEnvironment);
  
  NSLog(@"[SDK] Launching with environment %@", crl_stringForServerEnvironment(currentEnvironment));

  crl_updateSDKCrashState(CRLSDKCrashStateNotCrashed);

#if TARGET_SXS
  [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:appSecret];
  if (logURLString) {
    [[BITHockeyManager sharedHockeyManager] setServerURL:logURLString];
  }
  [[BITHockeyManager sharedHockeyManager] setDelegate:self];
  [[BITHockeyManager sharedHockeyManager] setLogLevel:BITLogLevelVerbose];
  [[BITHockeyManager sharedHockeyManager] startManager];
#else
  if (logURLString) {
    [MSMobileCenter setLogUrl:logURLString];
  }
  
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSCrashes setDelegate:self];
  [MSMobileCenter start:appSecret withServices:@[
                                                 [MSAnalytics class],
                                                 [MSCrashes class]
                                                 ]];
#endif

#if TARGET_SXS
  if ([[BITHockeyManager sharedHockeyManager].crashManager didCrashInLastSession]) {
#else
  if ([MSCrashes hasCrashedInLastSession]) {
#endif
    crl_updateSDKCrashState(CRLSDKCrashStateCrashDetected);
  }
  
  return YES;
}

  
#if TARGET_SXS

#pragma mark BITHockeyManagerDelegate
  
- (void)crashManagerWillSendCrashReport:(BITCrashManager *)crashManager {
  crl_updateSDKCrashState(CRLSDKCrashStateCrashWillSend);
}

- (void)crashManager:(BITCrashManager *)crashManager didFailWithError:(NSError *)error {
  crl_updateSDKCrashState(CRLSDKCrashStateCrashSendFailed);
}

- (void)crashManagerDidFinishSendingCrashReport:(BITCrashManager *)crashManager {
  crl_updateSDKCrashState(CRLSDKCrashStateCrashSendSucceeded);
}

#else

#pragma mark - MSCrashesDelegate

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes
                                             forErrorReport:(MSErrorReport *)errorReport {
  
  NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
  
  // attach a sample text file
  NSString *logFilename = @"README.md";
  NSString *logFilePath = [resourcePath stringByAppendingPathComponent:logFilename];
  NSString *logFileContent = [NSString stringWithContentsOfFile:logFilePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
  if (!logFileContent)
    logFileContent = @"Error reading log file. Awesome content yay!";
  
  MSErrorAttachmentLog *attachment = [[MSErrorAttachmentLog alloc] initWithFilename:@"console.log"
                                                                     attachmentText:logFileContent];
  
  // attach the app icon
  NSString *imageName = @"144x144.png";
  NSString *imagePath = [resourcePath stringByAppendingPathComponent:imageName];
  NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
  
  MSErrorAttachmentLog *binaryAttachment = [[MSErrorAttachmentLog alloc] initWithFilename:imageName
                                                                         attachmentBinary:imageData
                                                                              contentType:@"image/png"];
  return @[attachment, binaryAttachment];
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
  crl_updateSDKCrashState(CRLSDKCrashStateCrashWillSend);
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  crl_updateSDKCrashState(CRLSDKCrashStateCrashSendSucceeded);
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  crl_updateSDKCrashState(CRLSDKCrashStateCrashSendFailed);
}

#endif
  
@end
