//
//  CRLServerEnv.c
//  CrashProbe
//
//  Created by Andreas Linde on 02/02/2017.
//  Copyright © 2017 Bit Stadium GmbH. All rights reserved.
//

#include <stdio.h>
#import "CRLServerEnv.h"

#if !TARGET_SXS
@import MobileCenter;
#endif

#if TARGET_OS_IOS
#if TARGET_SXS
NSString *const kProdAppSecret = @"1577ad5af2204cada66f7d262c46310f";
NSString *const kStagingAppSecret = @"a8bfb523889b455797d96c88066fc5c1";
NSString *const kIntAppSecret = @"5c73def5583a4248b34d7ad294efcfe1";
#else
NSString *const kProdAppSecret = @"316fdef9-d451-4b75-bf8c-c2bb0ef0b01f";
NSString *const kStagingAppSecret = @"2f610c67-95f2-45e9-aeca-fbed172971d1";
NSString *const kIntAppSecret = @"dae1f94a-1248-4e3d-963b-79824a1b0ff4";
// NSString *const kIntAppSecret = @"7bf0a77e-6556-4155-8715-409796c79b75"; // https://asgard-int.trafficmanager.net/orgs/troublemakers/apps/CrashProbe-Test-Never-Upload-Symbols/
#endif
#endif

#if TARGET_OS_TV
#if TARGET_SXS
NSString *const kProdAppSecret = @"06a0616ed7da4c0ea80016e4a6ec6d96";
NSString *const kStagingAppSecret = @"dd9d3e3368b74b7192d5ba5102ad6631";
NSString *const kIntAppSecret = @"afe2508c3ef248989a09a23eb6c5e330";
#else
NSString *const kProdAppSecret = @"90e4576c-353f-4633-b33f-9501ae5e94f0";
NSString *const kStagingAppSecret = @"48b90458-5984-4598-bd4c-45652c029fbd";
NSString *const kIntAppSecret = @"203d7b8b-528a-4f7c-8988-ebd80d5c1484";
#endif
#endif

#if TARGET_OS_OSX
#if TARGET_SXS
NSString *const kProdAppSecret = @"26faf935f06d40f7b8a045e02938d75a";
NSString *const kStagingAppSecret = @"5ca8894db9f3429aa92bcc50f5b4ded4";
NSString *const kIntAppSecret = @"355fd5c642f7b13d07115faa77fa48cd";
#else
NSString *const kProdAppSecret = @"f5146844-a9fe-4ef5-88e8-d5269aa7145c";
NSString *const kStagingAppSecret = @"b309ef54-a9cb-49e0-babf-bc37edb96704";
NSString *const kIntAppSecret = @"542bbbbc-e19a-4fa0-a971-5354af27f34c";
#endif
#endif

#if TARGET_SXS
NSString *const kStagingServerURL = @"https://warmup.hockeyapp.net";
NSString *const kIntServerURL = @"https://training.hockeyapp.net";
#else
NSString *const kStagingServerURL = @"https://in-staging-south-centralus.staging.avalanch.es";
NSString *const kIntServerURL = @"https://in-integration.dev.avalanch.es";

typedef struct {
  uint8_t       info_version;
  const char    mcsdk_build_date[24];
} mcsdk_info_t;

mcsdk_info_t mcsdk_library_info __attribute__((section("__TEXT,__mc_sdk,regular,no_dead_strip"))) = {
  .info_version = 1,
  .mcsdk_build_date = MC_SDK_BUILD_DATE
};
#endif

NSString *const kServerEnvironment = @"MobileCenterServerEnvironment";
NSString *const kSDKCrashStateUpdateNotification = @"SDKCrashStateUpdateNotification";
NSString *const kUserInfoSDKCrashState = @"UserInfoSDKCrashState";

CRLSDKCrashState currentSDKCrashState;

CRLServerEnvironment crl_storedServerEnvironment(void) {
  CRLServerEnvironment currentEnvironment = CRLServerEnvironmentProd;
  
  if ([[NSUserDefaults standardUserDefaults] valueForKey:kServerEnvironment]) {
    currentEnvironment = (CRLServerEnvironment)[[NSUserDefaults standardUserDefaults] integerForKey:kServerEnvironment];
  }

  return currentEnvironment;
}

void crl_storeNewServerEnvironment(CRLServerEnvironment serverEnvironment) {
  [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)serverEnvironment forKey:kServerEnvironment];
}

NSString *crl_stringForServerEnvironment(CRLServerEnvironment serverEnvironment) {
  switch (serverEnvironment) {
    case CRLServerEnvironmentProd:
#if TARGET_SXS
      return @"Rink";
#else
      return @"PROD";
#endif
      break;
    case CRLServerEnvironmentStaging:
#if TARGET_SXS
      return @"Warmup";
#else
      return @"STAGING";
#endif
      break;
    case CRLServerEnvironmentInt:
#if TARGET_SXS
      return @"Training";
#else
      return @"INT";
#endif
      break;
      
    default:
      return @"unknown";
      break;
  }
}

NSString *crl_secretForEnvironment(CRLServerEnvironment serverEnvironment) {
  switch (serverEnvironment) {
    case CRLServerEnvironmentProd:
      return kProdAppSecret;
      break;
    case CRLServerEnvironmentStaging:
      return kStagingAppSecret;
      break;
    case CRLServerEnvironmentInt:
      return kIntAppSecret;
      break;
      
    default:
      return @"unknown";
      break;
  }
}

NSString *crl_URLStringForEnvironment(CRLServerEnvironment serverEnvironment) {
  switch (serverEnvironment) {
    case CRLServerEnvironmentProd:
      return nil;
      break;
    case CRLServerEnvironmentStaging:
      return kStagingServerURL;
      break;
    case CRLServerEnvironmentInt:
      return kIntServerURL;
      break;
      
    default:
      return nil;
      break;
  }
}

void crl_updateSDKCrashState(CRLSDKCrashState newSDKCrashState) {
  currentSDKCrashState = newSDKCrashState;
  [[NSNotificationCenter defaultCenter] postNotificationName:kSDKCrashStateUpdateNotification object:nil userInfo:@{kUserInfoSDKCrashState: [NSNumber numberWithInteger: newSDKCrashState]}];
}

NSString *crl_stringForSDKCrashState(CRLSDKCrashState sdkCrashState) {
  switch (sdkCrashState) {
    case CRLSDKCrashStateNotCrashed:
      return @"Did not crash";
      break;
    case CRLSDKCrashStateCrashDetected:
      return @"Crash detected";
      break;
    case CRLSDKCrashStateCrashWillSend:
      return @"Sending crash";
      break;
    case CRLSDKCrashStateCrashSendSucceeded:
      return @"Crash sent";
      break;
    case CRLSDKCrashStateCrashSendFailed:
      return @"Sending crash failed";
      break;
      
    default:
      return @"Unknown";
      break;
  }
}

NSString *mcSDKVersion(void) {
  NSString *result = nil;

#if !TARGET_SXS

  result = [MSMobileCenter sdkVersion];
  
#endif
  
  return result;
}

NSString *mcSDKBuildDate(void) {
  NSString *result = @"Unknown";
  
#if !TARGET_SXS

  result = [[NSString stringWithUTF8String:mcsdk_library_info.mcsdk_build_date] substringToIndex:24];
  
#endif
  
  return result;
}
