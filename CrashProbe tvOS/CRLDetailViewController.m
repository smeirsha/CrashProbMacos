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

#import "CRLDetailViewController.h"
#if TARGET_SXS
@import HockeySDK;
#else
@import MobileCenterAnalytics;
#endif

@interface CRLDetailViewController ()

@property(strong,nonatomic) IBOutlet UILabel *titleLabel;
@property(strong,nonatomic) IBOutlet UILabel *descriptionLabel;
@property(strong,nonatomic) IBOutlet UIImageView *descriptionImage;

- (IBAction)doCrash;

@end

@implementation CRLDetailViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

  NSString *eventTitle = [NSString stringWithFormat:@"Page %@", self.detailItem.title];
#if TARGET_SXS
  [[BITHockeyManager sharedHockeyManager].metricsManager trackEventWithName:eventTitle];
#else
  [MSAnalytics trackEvent:eventTitle];
#endif
  
	self.titleLabel.text = self.detailItem.title;
	self.descriptionLabel.text = self.detailItem.desc;
  //	self.descriptionImage.image = nil;
	self.navigationItem.title = @"Crash Detail";
}

- (IBAction)doCrash
{
#if TARGET_SXS
  [[BITHockeyManager sharedHockeyManager].metricsManager trackEventWithName:@"Trigger Crash"];
#else
  [MSAnalytics trackEvent:@"Trigger Crash"];
#endif
	[self.detailItem crash];
}

@end
