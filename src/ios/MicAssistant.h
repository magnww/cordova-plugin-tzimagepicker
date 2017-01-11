//
//  MicLocationAssistant.h
//  HKMember
//
//  Created by apple on 14-4-14.
//  Copyright (c) 2014年 惠卡. All rights reserved.
//

#import <Foundation/Foundation.h>
//对应权限类型
typedef NS_ENUM(NSInteger, NoAccessType) {
    NoAccessPhotoType = 0,  //相册访问权限
    NoAccessCamaratype,     //相机访问权限
    NoAccessLocationType,   //定位使用权限
    NoAccessMailType,       //通讯录访问权限
    NoAccessMicrophoneType  //麦克风访问权限
};


@interface MicAssistant : NSObject

+ (id)sharedInstance;

/**
 *  总定位服务是否开始
 *  @return
 */
- (BOOL)isLocationServiceOn;

/**
 *  当前app服务定位是否开启
 *  @return
 */
- (BOOL)isCurrentAppLocatonServiceOn;

/**
 *  当前app服务定位是否已决定
 *  @return
 */
- (BOOL)isLocationServiceDetermined;

/**
 *  当前app相册是否允许访问
 *  @return
 */
- (BOOL)isCurrentAppALAssetsLibraryServiceOn;


/**
 * 当前app相机服务是否拒绝
 * @return
 */
- (BOOL)isCameraServiceOn;

/**
 *  检测麦克风
 *  @return
 */
- (void)checkMicrophoneServeceOnCompletion:(void (^)(BOOL isPermision, BOOL isFirstAsked))completion;

/**
 *  统一处理(相册，照片，定位，通讯录，麦克风等)没有权限情况
 */
- (BOOL)checkAccessPermissions:(NoAccessType)type;

@end
