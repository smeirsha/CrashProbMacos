/*
 * Copyright (c) 2014 HockeyApp, Bit Stadium GmbH.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


#import "CRLAppDelegate.h"
#import "CRLServerEnv.h"

#if TARGET_SXS
@import HockeySDK;

@interface CRLAppDelegate(Private) <BITHockeyManagerDelegate>
#else
@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterDistribute;

@interface CRLAppDelegate(Private) <MSCrashesDelegate>
#endif
  
@end

@implementation CRLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
  [[BITHockeyManager sharedHockeyManager].crashManager setEnableMachExceptionHandler:YES];
  [[BITHockeyManager sharedHockeyManager] startManager];
  [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#else
  if (currentEnvironment != CRLServerEnvironmentProd) {
    [MSDistribute setEnabled:NO];
  }
  
  if (logURLString) {
    [MSMobileCenter setLogUrl:logURLString];
  }
  
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSCrashes setDelegate:self];
  [MSMobileCenter start:appSecret withServices:@[
                                                     [MSAnalytics class],
                                                     [MSCrashes class],
                                                     [MSDistribute class]
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

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  // Pass the url to MSDistribute.
  [MSDistribute openURL:url];
  return YES;
}

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
