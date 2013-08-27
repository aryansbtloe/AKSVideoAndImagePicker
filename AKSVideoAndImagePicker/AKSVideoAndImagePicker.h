//
//  Betify
//
//  Created by Alok on 17/06/13.
//  Copyright (c) 2013 Konstant Info Private Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^AKSVideoAndImagePickerOperationFinishedBlock)(NSString *filePath, NSString *fileType);

@interface AKSVideoAndImagePicker : NSObject {
	UIImagePickerController *imagePickerController;
	NSString *lastVideoPath;
}

@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (nonatomic, retain) NSString *lastVideoPath;
@property (nonatomic, copy) AKSVideoAndImagePickerOperationFinishedBlock operationFinishedBlockAKSVIPicker;

+ (void)needImage:(BOOL)imageNeeded needVideo:(BOOL)videoNeeded FromLibrary:(BOOL)fromLibrary from:(UIViewController *)viewController didFinished:(AKSVideoAndImagePickerOperationFinishedBlock)operationFinishedBlock;
+ (void)resetCachedMediaFiles;

@end
