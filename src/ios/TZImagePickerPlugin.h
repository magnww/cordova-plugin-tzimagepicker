//
//  ImagePicker.h
//  SellHouseManager
//
//  Created by yangxu on 16/9/8.
//  Copyright © 2016年 JiCe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <UIKit/UIKit.h>
#import "TZImagePickerController.h"

@interface TZImagePickerPlugin : CDVPlugin

// 获取图片
- (void)getPictures:(CDVInvokedUrlCommand *)command;

// 删除图片文件
- (void)deleteFile:(CDVInvokedUrlCommand *)command;

@end
