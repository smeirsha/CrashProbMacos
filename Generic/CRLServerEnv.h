//
//  CRLServerEnv.h
//  CrashProbe
//
//  Created by Andreas Linde on 02/02/2017.
//  Copyright © 2017 Bit Stadium GmbH. All rights reserved.
//

#ifndef CRLServerEnv_h
#define CRLServerEnv_h

extern NSString *const kProdAppSecret;
extern NSString *const kIntAppSecret;
extern NSString *const kIntServerURL;
extern NSString *const kStagingAppSecret;
extern NSString *const kStagingServerURL;

extern NSString *const kServerEnvironment;

typedef NS_ENUM(NSUInteger, CRLServerEnvironment) {
  CRLServerEnvironmentProd = 0,
  CRLServerEnvironmentStaging = 1,
  CRLServerEnvironmentInt = 2
};

typedef NS_ENUM(NSUInteger, CRLSDKCrashState) {
  CRLSDKCrashStateNotCrashed = 0,
  CRLSDKCrashStateCrashDetected = 1,
  CRLSDKCrashStateCrashWillSend = 2,
  CRLSDKCrashStateCrashSendSucceeded = 3,
  CRLSDKCrashStateCrashSendFailed = 4
};

extern CRLSDKCrashState currentSDKCrashState;
extern NSString *const kUserInfoSDKCrashState;
extern NSString *const kSDKCrashStateUpdateNotification;

CRLServerEnvironment crl_storedServerEnvironment(void);
void crl_storeNewServerEnvironment(CRLServerEnvironment serverEnvironment);
NSString *crl_stringForServerEnvironment(CRLServerEnvironment serverEnvironment);
NSString *crl_secretForEnvironment(CRLServerEnvironment serverEnvironment);
NSString *crl_URLStringForEnvironment(CRLServerEnvironment serverEnvironment);

void crl_updateSDKCrashState(CRLSDKCrashState newSDKCrashState);
NSString *crl_stringForSDKCrashState(CRLSDKCrashState sdkCrashState);

NSString *mcSDKVersion(void);
NSString *mcSDKBuildDate(void);

#endif /* CRLServerEnv_h */
