//
//  MicLocationAssistant.m
//  HKMember
//
//  Created by apple on 14-4-14.
//  Copyright (c) 2014年 惠卡. All rights reserved.
//

#import "MicAssistant.h"
#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PHPhotoLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@implementation MicAssistant

+ (id)sharedInstance
{
    static MicAssistant *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (BOOL)isLocationServiceOn
{
    return [CLLocationManager locationServicesEnabled];
}

- (BOOL)isCurrentAppLocatonServiceOn
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusDenied == status || kCLAuthorizationStatusRestricted == status) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isLocationServiceDetermined
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (kCLAuthorizationStatusNotDetermined == status) {
        return NO;
    } else {
        return YES;
    }
    
}

- (BOOL)isCurrentAppALAssetsLibraryServiceOn
{
    BOOL isServiceOn;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        // 此处只应判断拒绝的情况，第一次未决定时返回YES，不做任何弹框，系统自己弹
        if (status == PHAuthorizationStatusDenied) {
            isServiceOn = NO;
        } else {
            isServiceOn = YES;
        }
    } else {
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        // 此处只应判断拒绝的情况，第一次未决定时返回YES，不做任何弹框，系统自己弹
        if (status == kCLAuthorizationStatusDenied) {
            isServiceOn = NO;
        } else {
            isServiceOn = YES;
        }
    }
    return isServiceOn;
}

- (BOOL)isCameraServiceOn
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        return NO;
    }else{
        return YES;
    }
}

- (BOOL)isMailServiceOn
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
    __block BOOL isCan = NO;
    
    if (authStatus != kABAuthorizationStatusAuthorized) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                 if (error) {
                     NSLog(@"Error: %@", (__bridge NSError *)error);
                 } else if (!granted) {
                     isCan = NO;
                 } else {
                     isCan = YES;
                 }
            });
        });
    } else {
        isCan = NO;
        CFRelease(addressBook);
    }
    
    return isCan;
}

- (void)checkMicrophoneServeceOnCompletion:(void (^)(BOOL isPermision, BOOL isFirstAsked))completion
{
    __block BOOL permision = NO;
    __block BOOL firstAsked = NO;
    // ios7 是利用 requestRecordPermission,回调只能判断允许或者未被允许
    NSDate *date = [NSDate date];
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            // ios7无法判断是否是出于未决定的状态,但是一旦判断，很快回调，所以可以用一个比较短的时间差来达到比较精准的判断
            NSDate *date2 = [NSDate date];
            NSTimeInterval timeGap = [date2 timeIntervalSinceDate:date];
            if (timeGap > 0.5) {
                firstAsked = YES;
            } else {
                firstAsked = NO;
            }
            permision = granted;
            
            if (completion) {
                completion(permision, firstAsked);
            }
        }];
        
    } else {
        // 7以前不用检测权限
        permision = YES;
        firstAsked = NO;
        if (completion) {
            completion(permision, firstAsked);
        }
    }
}

- (BOOL)checkAccessPermissions:(NoAccessType)type
{
    NSURL *url;
    BOOL isCanOpen = NO;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        isCanOpen = [[UIApplication sharedApplication] canOpenURL:url];
    }
    __block BOOL isCan = NO;
    if (type == NoAccessPhotoType) {
        // 相相册权限判断
        // 此处只应判断拒绝的情况，未决定时，不做任何弹框，系统自己弹
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            if (status == PHAuthorizationStatusDenied) {
                isCan = NO;
                isCanOpen = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            } else if (status == PHAuthorizationStatusNotDetermined){
                return YES;
            } else {
                isCan = YES;
            }
        } else {
            ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
            if (status == kCLAuthorizationStatusDenied) {
                isCan = NO;
            } else if (status == kCLAuthorizationStatusNotDetermined){
                return YES;
            } else {
                isCan = YES;
            }
        }
    } else if (type == NoAccessCamaratype) {
        // 相机权限判断
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusDenied) {
            isCan = NO;
        } else if (status == AVAuthorizationStatusNotDetermined){
            return YES;
        } else {
            isCan = YES;
        }
    } else if (type == NoAccessLocationType) {
        // 定位服务判断
        // 先判断用户是否决定，再手机定位是否开启，最后判断是否允许APP使用定位
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == AVAuthorizationStatusNotDetermined) {
            return YES;
        } else {
            // 是否打开定位
            BOOL isServerOn = [CLLocationManager locationServicesEnabled];
            if (isServerOn) {
                if (status == AVAuthorizationStatusDenied) {
                    isCan = NO;
                } else {
                    isCan = YES;
                }
            } else {
                isCan = NO;
                url = [NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"];
                isCanOpen = [[UIApplication sharedApplication] canOpenURL:url];
            }
        }
    } else if (type == NoAccessMailType) {
        isCan = [self isMailServiceOn];
    } else if (type == NoAccessMicrophoneType) {
        [self checkMicrophoneServeceOnCompletion:^(BOOL isPermision, BOOL isFirstAsked) {
            if (isFirstAsked) {
                isCan = isFirstAsked;
            } else {
                isCan = isPermision;
            }
        }];
    }
    //权限未打开
    if (!isCan) {
        NSArray *titleArray = @[@"没有相册访问权限", @"没有相机访问权限", @"没有打开定位服务", @"没有通讯录访问权限", @"没有麦克风访问权限"];
        NSArray *messageNot = @[@"请在iPhone的“设置-隐私-照片”\n允许访问您的手机照片",
                                @"请在iPhone的“设置-隐私-相机”\n允许访问您的手机相机",
                                @"请在iPhone的“设置-隐私-定位服务”\n允许使用您的手机定位服务",
                                @"请在iPhone的“设置-隐私-通讯录”\n允许访问您的手机通讯录",
                                @"请在iPhone的“设置-隐私-麦克风”\n允许访问您的手机麦克风"];
        NSArray *messageCan = @[@"立即前往iPhone的“卖房管家-照片”\n允许访问您的手机照片",
                                @"立即前往iPhone的“卖房管家-相机”\n允许访问您的手机相机",
                                @"立即前往iPhone的“卖房管家-定位服务”\n允许使用您的手机定位服务",
                                @"立即前往iPhone的“卖房管家-通讯录”\n允许访问您的手机通讯录",
                                @"立即前往iPhone的“卖房管家-麦克风”\n允许访问您的手机麦克风"];
        
        NSString *title, *message, *otherStr;
        if (isCanOpen) {
            message = messageCan[type];
            otherStr = @"去设置";
        } else {
            otherStr = @"确定";
            message = messageNot[type];
        }
        title = titleArray[type];
//        [UIAlertView bk_showAlertViewWithTitle:title message:message cancelButtonTitle:@"取消" otherButtonTitles:@[otherStr] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
//            if (isCanOpen && buttonIndex == 1) {
//                dispatch_after(0.01, dispatch_get_main_queue(), ^{
//                    [[UIApplication sharedApplication] openURL:url];
//                });
//            }
//        }];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alert show];
        
//        [UIAlertView alertViewWithTitle:title
//                                message:message
//                      cancelButtonTitle:@"取消"
//                      otherButtonTitles:@[otherStr]
//                              onDismiss:^(int buttonIndex, NSString *buttonTitle){
//                                  if (isCanOpen) {
//                                      dispatch_after(0.01, dispatch_get_main_queue(), ^{
//                                          [[UIApplication sharedApplication] openURL:url];
//                                      });
//                                  }
//                              }
//                               onCancel:^{
//                               }];
    }

    return isCan;
}
@end
