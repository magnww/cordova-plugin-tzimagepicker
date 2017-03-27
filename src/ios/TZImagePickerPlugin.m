//
//  ImagePicker.m
//  SellHouseManager
//
//  Created by yangxu on 16/9/8.
//  Copyright © 2016年 JiCe. All rights reserved.
//

#import "TZImagePickerPlugin.h"
#import "TZImageManager.h"
#import "MicAssistant.h"
#import "HUDManager.h"

@interface TZImagePickerPlugin()<TZImagePickerControllerDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,UIActionSheetDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerVc;
@property (nonatomic, strong) CDVInvokedUrlCommand *pCommand;
@end

@implementation TZImagePickerPlugin

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
- (void)getPictures:(CDVInvokedUrlCommand *)command
{
    self.pCommand = command;
    
    // 最多可选择的数目
    BOOL isSelectOriginalPhoto = NO;
    BOOL allowTakePicture = YES;
    NSInteger barTintColor = 0x00b2f5;
    NSInteger oKButtonTitleColorDisabled = 0xaaaaaa;
    NSInteger oKButtonTitleColorNormal = 0x00b2f5;
    BOOL allowPickingVideo = YES;
    BOOL allowPickingImage = YES;
    BOOL allowPickingOriginalPhoto = NO;
    BOOL allowPickingGif = YES;
    BOOL sortAscendingByModificationDate = NO;
    NSInteger maxImagesCount = 9;
    
    NSDictionary *options = [[NSDictionary alloc] init];
    options = [self.pCommand.arguments objectAtIndex:0];
    
    maxImagesCount = [[options objectForKey:@"maxImagesCount"] integerValue];
    maxImagesCount = maxImagesCount<0?0:maxImagesCount;
    
    if([options valueForKey:@"isSelectOriginalPhoto"] != nil){
        isSelectOriginalPhoto = [[options objectForKey:@"isSelectOriginalPhoto"] boolValue];
    }
    if([options valueForKey:@"allowTakePicture"] != nil){
        allowTakePicture = [[options objectForKey:@"allowTakePicture"] boolValue];
    }
    if([options valueForKey:@"barTintColor"] != nil){
        barTintColor = [[options objectForKey:@"barTintColor"] integerValue];
    }
    if([options valueForKey:@"oKButtonTitleColorDisabled"] != nil){
        oKButtonTitleColorDisabled = [[options objectForKey:@"oKButtonTitleColorDisabled"] integerValue];
    }
    if([options valueForKey:@"oKButtonTitleColorNormal"] != nil){
        oKButtonTitleColorNormal = [[options objectForKey:@"oKButtonTitleColorNormal"] integerValue];
    }
    if([options valueForKey:@"allowPickingVideo"] != nil){
        allowPickingVideo = [[options objectForKey:@"allowPickingVideo"] boolValue];
    }
    if([options valueForKey:@"allowPickingImage"] != nil){
        allowPickingImage = [[options objectForKey:@"allowPickingImage"] boolValue];
    }
    if([options valueForKey:@"allowPickingOriginalPhoto"] != nil){
        allowPickingOriginalPhoto = [[options objectForKey:@"allowPickingOriginalPhoto"] boolValue];
    }
    if([options valueForKey:@"allowPickingGif"] != nil){
        allowPickingGif = [[options objectForKey:@"allowPickingGif"] boolValue];
    }
    if([options valueForKey:@"sortAscendingByModificationDate"] != nil){
        sortAscendingByModificationDate = [[options objectForKey:@"sortAscendingByModificationDate"] boolValue];
    }
    
    [self.commandDelegate runInBackground:^{
        TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:maxImagesCount delegate:self];
        imagePickerVc.isSelectOriginalPhoto = isSelectOriginalPhoto;
        imagePickerVc.allowTakePicture = allowTakePicture;
        imagePickerVc.navigationBar.barTintColor = UIColorFromRGB(barTintColor);
        imagePickerVc.oKButtonTitleColorDisabled = UIColorFromRGB(oKButtonTitleColorDisabled);
        imagePickerVc.oKButtonTitleColorNormal = UIColorFromRGB(oKButtonTitleColorNormal);
        imagePickerVc.allowPickingVideo = allowPickingVideo;
        imagePickerVc.allowPickingImage = allowPickingImage;
        imagePickerVc.allowPickingOriginalPhoto = allowPickingOriginalPhoto;
        imagePickerVc.allowPickingGif = allowPickingGif;
        imagePickerVc.sortAscendingByModificationDate = sortAscendingByModificationDate;
        imagePickerVc.maxImagesCount = maxImagesCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.viewController presentViewController:imagePickerVc animated:YES completion:nil];
        });
    }];
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto
{
    CDVPluginResult* result = nil;
    NSMutableArray *resultStrings = [[NSMutableArray alloc] init];
    NSData* data = nil;
    NSError* err = nil;
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSString* filePath;
    
    NSDate* date = [NSDate date];
    NSString* filename = [NSString stringWithFormat:@"%f",[date timeIntervalSinceReferenceDate]];
    int i = 0;
    for (UIImage *image in photos) {
        filePath = [NSString stringWithFormat:@"%@%@%@%04d.%@", NSTemporaryDirectory(), @"cdv_photo_",filename , i++, @"jpg"];
        
        @autoreleasepool {
            data = UIImageJPEGRepresentation(image,0.5);
            if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                break;
            } else {
                [resultStrings addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
            }
        }
    }
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultStrings];
    [self.commandDelegate sendPluginResult:result callbackId:self.pCommand.callbackId];
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset
{
    [[TZImageManager manager] getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath) {
        CDVPluginResult* result = nil;
        NSMutableArray *resultStrings = [[NSMutableArray alloc] init];
        NSError* err = nil;
        
        @autoreleasepool {
            NSString *thumbnailPath = [self getFileThumbnailPath:outputPath];
            NSData *thumbnailData = UIImageJPEGRepresentation(coverImage, 0.5);
            if (![thumbnailData writeToFile:thumbnailPath options:NSAtomicWrite error:&err]) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                return;
            }
        }
        
        [resultStrings addObject:outputPath];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultStrings];
        [self.commandDelegate sendPluginResult:result callbackId:self.pCommand.callbackId];
    }];
}
#pragma mark 拍照
- (void)takePhoto
{    
    if (![[MicAssistant sharedInstance] checkAccessPermissions:NoAccessCamaratype]) {
        return;
    }
    
    [self.commandDelegate runInBackground:^{
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            self.imagePickerVc.sourceType = sourceType;
            if(iOS8Later) {
                _imagePickerVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            [self.viewController presentViewController:_imagePickerVc animated:YES completion:nil];
        } else {
            NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        }
    }];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if ([[MicAssistant sharedInstance] isCurrentAppALAssetsLibraryServiceOn]) {
            [HUDManager showHUDWithMessage:@"请稍候..."];
            [[TZImageManager manager] savePhotoWithImage:image completion:(void (^)(NSError *error))^{
                [HUDManager hiddenHUD];
                NSFileManager* fileMgr = [[NSFileManager alloc] init];
                NSError* err = nil;
                CDVPluginResult *result = nil;
                NSString* filePath = nil;
                
                int i = 1;
                do {
                    filePath = [NSString stringWithFormat:@"%@/%@%04d.%@", [self getFileDocPath], @"cdv_photo_", i++, @"jpg"];
                } while ([fileMgr fileExistsAtPath:filePath]);
                
                @autoreleasepool {
                    NSData* data = UIImageJPEGRepresentation(image,0.2);
                    if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                    } else {
                        filePath = [[NSURL fileURLWithPath:filePath] absoluteString];
                    }
                }
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[filePath]];
                [self.commandDelegate sendPluginResult:result callbackId:self.pCommand.callbackId];
            }];
        } else {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"保存图片失败"];
            [self.commandDelegate sendPluginResult:result callbackId:self.pCommand.callbackId];
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIImagePickerController
- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        _imagePickerVc.navigationBar.barTintColor = self.viewController.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.viewController.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        if (iOS9Later) {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
            BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
            BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}

// 删除图片文件
- (void)deleteFile:(CDVInvokedUrlCommand *)command
{
    self.pCommand = command;
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSArray *filePaths = self.pCommand.arguments;
    for (int i = 0; i<filePaths.count; i++) {
        NSString *filePath = [filePaths objectAtIndex:i];
        NSString *fileName = [fileMgr displayNameAtPath:filePath];
        NSLog(@"fileName = %@",fileName);
        NSString *file = [NSString stringWithFormat:@"%@/%@",[self getFileDocPath],fileName];
        if ([fileMgr fileExistsAtPath:file]) {
            [fileMgr removeItemAtPath:file error:nil];
        }
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:self.pCommand.callbackId];
}

- (NSString *)getFileDocPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsFile = [NSString stringWithFormat:@"%@/tzimagepicker",documentsDirectory];
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    BOOL isDir = YES;
    if (![fileMgr fileExistsAtPath:documentsFile isDirectory:&isDir]) {
        [fileMgr createDirectoryAtPath:documentsFile withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return documentsFile;
}

- (NSString *)getFileThumbnailPath:(NSString *) filePath
{
    NSString *directory = [NSString stringWithFormat:@"%@/thumbnail/",[filePath substringToIndex:[filePath rangeOfString:@"/" options:NSBackwardsSearch].location]];
    NSString *fileName = [filePath substringFromIndex:[filePath rangeOfString:@"/" options:NSBackwardsSearch].location + 1];
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    BOOL isDir = YES;
    if (![fileMgr fileExistsAtPath:directory isDirectory:&isDir]) {
        [fileMgr createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSString stringWithFormat:@"%@%@.thumbnail", directory, fileName];
}

@end
