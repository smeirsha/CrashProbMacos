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

#import "CRLMainWindowController.h"
#import "CRLCrashListViewController.h"
#import <CrashLib/CrashLib.h>
#import "CRLServerEnv.h"

#if TARGET_SXS
@import HockeySDK;
#else
@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
#endif

@interface CRLMainWindowController () <CRLCrashListViewControllerDelegate>

@property(nonatomic,strong) IBOutlet NSWindow *myWindow;
@property(nonatomic,strong) IBOutlet NSOutlineView *crashList;
@property(nonatomic,strong) IBOutlet NSSplitView *splitView;
@property(nonatomic,strong) IBOutlet NSTextField *titleText;
@property(nonatomic,strong) IBOutlet NSTextField *detailText;
@property(nonatomic,strong) IBOutlet NSImageView *detailImage;
@property(nonatomic,strong) IBOutlet NSButton *crashButton;
@property(nonatomic,strong) IBOutlet NSTextField *versionText;
@property(nonatomic,strong) IBOutlet NSTextField *sdkVersionLabel;
@property(nonatomic,strong) IBOutlet NSTextField *sdkCrashStateLabel;
@property(nonatomic,strong) IBOutlet NSTextField *sdkSecretLabel;
@property(nonatomic,strong) IBOutlet NSSegmentedControl *environmentSegment;
@property(nonatomic,strong) CRLCrashListViewController *listController;

@end

@implementation CRLMainWindowController
 
- (id)init
{
	return [super initWithWindowNibName:@"CRLMainWindow"];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	self.listController = [[CRLCrashListViewController alloc] initWithOutlineView:self.crashList];
	self.listController.delegate = self;
	[self.listController loadView];
	
  self.crashButton.target = self;
	self.crashButton.action = @selector(causeCrash:);
  
  self.environmentSegment.target = self;
  self.environmentSegment.action = @selector(switchEnvironment:);

  NSInteger selectedSegment = self.environmentSegment.selectedSegment;
  CRLServerEnvironment selectedEnvironment = (CRLServerEnvironment)selectedSegment;
  
  if (crl_storedServerEnvironment() != selectedEnvironment) {
    [self.environmentSegment setSelectedSegment:(NSInteger)crl_storedServerEnvironment()];
  }
  
  __weak typeof(self) weakSelf = self;
  [[NSNotificationCenter defaultCenter] addObserverForName:kSDKCrashStateUpdateNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *note) {
                                                  typeof(self) strongSelf = weakSelf;
                                                  
                                                  NSNumber *newStateObj = (NSNumber *)[[note userInfo] objectForKey:kUserInfoSDKCrashState];
                                                  CRLSDKCrashState newState = (CRLSDKCrashState)[newStateObj integerValue];
                                                  [strongSelf updateSDKCrashStateUI:newState];
                                                }];
  
  [self.versionText setStringValue:[NSString stringWithFormat:@"App v%@ (%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]];
  CRLServerEnvironment currentEnvironment = crl_storedServerEnvironment();
  NSString *appSecret = [NSString stringWithFormat:@"Secret: %@", crl_secretForEnvironment(currentEnvironment)];
  [self.sdkSecretLabel setStringValue:appSecret];
  
#if TARGET_SXS
  [[BITHockeyManager sharedHockeyManager].metricsManager trackEventWithName:@"App launched"];
  
  NSString *versionString = [[NSBundle bundleWithIdentifier:@"net.hockeyapp.sdk.mac"] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: nil;
  NSString *buildString = [[NSBundle bundleWithIdentifier:@"net.hockeyapp.sdk.mac"] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: nil;
  
  if (versionString && buildString) {
    [self.sdkVersionLabel setStringValue:[NSString stringWithFormat:@"SDK v%@ (%@)", versionString, buildString]];
  }
  self.myWindow.title = @"CrashProbe HockeyApp SxS";
  [self.environmentSegment setLabel:@"Rink" forSegment:0];
  [self.environmentSegment setLabel:@"Warmup" forSegment:1];
  [self.environmentSegment setLabel:@"Training" forSegment:2];
#else
  [MSAnalytics trackEvent:@"App launched"];

  NSString *versionString = mcSDKVersion();
  NSString *buildString = mcSDKBuildDate();
  
  if (versionString && buildString) {
    [self.sdkVersionLabel setStringValue:[NSString stringWithFormat:@"SDK v%@ (%@)", versionString, buildString]];
  }
  self.myWindow.title = @"CrashProbe Mobile Center";
  [self.environmentSegment setLabel:@"Prod" forSegment:0];
  [self.environmentSegment setLabel:@"Staging" forSegment:1];
  [self.environmentSegment setLabel:@"Int" forSegment:2];
#endif
  
	[self controller:self.listController didSelectCrash:nil];
  [self updateSDKCrashStateUI:currentSDKCrashState];
}

- (void)causeCrash:(id)sender
{
#if TARGET_SXS
  [[BITHockeyManager sharedHockeyManager].metricsManager trackEventWithName:@"Trigger Crash"];
#else
  [MSAnalytics trackEvent:@"Trigger Crash"];
#endif
  [self.listController.selectedCrash crash];
}

- (void)controller:(CRLCrashListViewController *)controller didSelectCrash:(CRLCrash *)crash
{
	self.titleText.stringValue = crash.title ?: @"";
	self.detailText.stringValue = crash.desc ?: @"";
  
  if (crash.title) {
    NSString *eventTitle = [NSString stringWithFormat:@"Selected %@", crash.title];
#if TARGET_SXS
    [[BITHockeyManager sharedHockeyManager].metricsManager trackEventWithName:eventTitle];
#else
    [MSAnalytics trackEvent:eventTitle];
#endif
  }
  
//	self.detailImage.image = crash.animation;
}

- (void)updateSDKCrashStateUI:(CRLSDKCrashState)newSDKCrashState {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *newStateString = crl_stringForSDKCrashState(newSDKCrashState);
    
    [self.sdkCrashStateLabel setStringValue:newStateString];
  });
}

- (IBAction)switchEnvironment:(id)sender
{
  NSInteger selectedSegment = self.environmentSegment.selectedSegment;
  CRLServerEnvironment newEnvironment = (CRLServerEnvironment)selectedSegment;
  
  if (crl_storedServerEnvironment() != newEnvironment) {
    NSLog(@"[SDK] Changing environment to %@", crl_stringForServerEnvironment(newEnvironment));
    crl_storeNewServerEnvironment(newEnvironment);
    NSString *logURLString = crl_URLStringForEnvironment(newEnvironment);
        
    if (logURLString) {
#if TARGET_SXS
      [[BITHockeyManager sharedHockeyManager] setServerURL:logURLString];
#else
      [MSMobileCenter setLogUrl:logURLString];
#endif
    }
  }
}

@end
