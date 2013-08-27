//
//  Betify
//
//  Created by Alok on 17/06/13.
//  Copyright (c) 2013 Konstant Info Private Limited. All rights reserved.
//

#import "AKSVideoAndImagePicker.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

#define IS_CAMERA_AVAILABLE [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]

static AKSVideoAndImagePicker *aKSVideoAndImagePicker_ = nil;

@implementation AKSVideoAndImagePicker

@synthesize operationFinishedBlockAKSVIPicker;
@synthesize imagePickerController;
@synthesize lastVideoPath;

+ (AKSVideoAndImagePicker *)sharedAKSVideoAndImagePicker {
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
	    if (aKSVideoAndImagePicker_ == nil) {
	        aKSVideoAndImagePicker_ = [[AKSVideoAndImagePicker alloc]init];
			[AKSVideoAndImagePicker resetCachedMediaFiles];
		}
	});
	return aKSVideoAndImagePicker_;
}

+ (void)needImage:(BOOL)imageNeeded needVideo:(BOOL)videoNeeded FromLibrary:(BOOL)fromLibrary from:(UIViewController *)viewController didFinished:(AKSVideoAndImagePickerOperationFinishedBlock)operationFinishedBlock{

	if ((fromLibrary == NO) && (IS_CAMERA_AVAILABLE == NO)) {
		UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"Camera" message:@"Camera not available" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
		[alertView show];
		return;
	}


	[AKSVideoAndImagePicker sharedAKSVideoAndImagePicker];

	aKSVideoAndImagePicker_.operationFinishedBlockAKSVIPicker = operationFinishedBlock;
	[[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/UnUpdatedItems/", [AKSVideoAndImagePicker documentsDirectory]] withIntermediateDirectories:YES attributes:nil error:nil];

	aKSVideoAndImagePicker_.imagePickerController                      = [[UIImagePickerController alloc]init];
	aKSVideoAndImagePicker_.imagePickerController.videoQuality         = UIImagePickerControllerQualityTypeLow;
	aKSVideoAndImagePicker_.imagePickerController.videoMaximumDuration = 1800;
	aKSVideoAndImagePicker_.imagePickerController.delegate             = aKSVideoAndImagePicker_;

	if (fromLibrary) aKSVideoAndImagePicker_.imagePickerController.sourceType           = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	else aKSVideoAndImagePicker_.imagePickerController.sourceType           = UIImagePickerControllerSourceTypeCamera;

	NSMutableArray *mediaType = [[NSMutableArray alloc]init];
	if (videoNeeded) [mediaType addObject:@"public.movie"];
	if (imageNeeded) [mediaType addObject:@"public.image"];

	aKSVideoAndImagePicker_.imagePickerController.mediaTypes = mediaType;

	[viewController presentViewController:aKSVideoAndImagePicker_.imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
	    [AKSVideoAndImagePicker didFinishPickingMediaWithInfo:info];
	});

	[picker dismissViewControllerAnimated:YES completion:nil];
	imagePickerController = nil;
}

+ (void)didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSString *mediaType = [info objectForKey:@"UIImagePickerControllerMediaType"];

	if ([mediaType isEqualToString:@"public.movie"]) {
		[AKSVideoAndImagePicker showActivityIndicatorWithText:@"optimising video for network use"];
		[AKSVideoAndImagePicker saveVideoInDocumentsTemporarily:info];
		[AKSVideoAndImagePicker compressVideo];
	}
	else if ([mediaType isEqualToString:@"public.image"]) {
		[AKSVideoAndImagePicker showActivityIndicatorWithText:@"processing"];
		UIImage *image = info[UIImagePickerControllerOriginalImage];
		image = [AKSVideoAndImagePicker compressThisImage:image];
		if (image) {
			NSString *pathToUnupdatedDirectory = [AKSVideoAndImagePicker getFilePathToSaveUnUpdatedImage];
			[UIImagePNGRepresentation(image) writeToFile:pathToUnupdatedDirectory atomically:YES];
			aKSVideoAndImagePicker_.operationFinishedBlockAKSVIPicker(pathToUnupdatedDirectory, @"image");
		}
		[AKSVideoAndImagePicker removeActivityIndicator];
	}
}

+ (void)compressVideo {
	aKSVideoAndImagePicker_.lastVideoPath = [AKSVideoAndImagePicker getFilePathToSaveUnUpdatedVideo];
	[AKSVideoAndImagePicker convertVideoToLowQuailtyWithInputURL:[NSURL fileURLWithPath:[AKSVideoAndImagePicker getTemporaryFilePathToSaveVideo]] outputURL:[NSURL fileURLWithPath:aKSVideoAndImagePicker_.lastVideoPath] handler: ^(AVAssetExportSession *exportSession) {
	    [aKSVideoAndImagePicker_ performSelectorOnMainThread:@selector(compressionSuccessFull) withObject:nil waitUntilDone:NO];
	}];
}

+ (void)convertVideoToLowQuailtyWithInputURL:(NSURL *)inputURL outputURL:(NSURL *)outputURL handler:(void (^)(AVAssetExportSession *))handler {
	[[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetLowQuality];
	exportSession.outputURL = outputURL;
	exportSession.outputFileType = AVFileTypeQuickTimeMovie;
	exportSession.shouldOptimizeForNetworkUse = YES;
	[exportSession exportAsynchronouslyWithCompletionHandler: ^(void) {
	    handler(exportSession);
	}];
}

- (void)compressionSuccessFull {
	[AKSVideoAndImagePicker removeActivityIndicator];
	aKSVideoAndImagePicker_.operationFinishedBlockAKSVIPicker(aKSVideoAndImagePicker_.lastVideoPath, @"video");
}

+ (void)saveVideoInDocumentsTemporarily:(NSDictionary *)info {
	[[[NSData alloc] initWithContentsOfURL:info[UIImagePickerControllerMediaURL]] writeToFile:[[NSMutableString alloc] initWithString:[AKSVideoAndImagePicker getTemporaryFilePathToSaveVideo]] atomically:YES];
}

+ (NSString *)getTemporaryFilePathToSaveVideo {
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"capturedvideo.MOV"];
}

+ (NSString *)getFilePathToSaveUnUpdatedVideo {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *directory = [paths objectAtIndex:0];
	for (int i = 0; TRUE; i++) {
		if (![[NSFileManager defaultManager]fileExistsAtPath:[NSString stringWithFormat:@"%@/UnUpdatedItems/Video%d.mp4", directory, i]]) return [NSString stringWithFormat:@"%@/UnUpdatedItems/Video%d.mp4", directory, i];
	}
}

+ (NSString *)getFilePathToSaveUnUpdatedImage {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *directory = [paths objectAtIndex:0];
	for (int i = 0; TRUE; i++) {
		if (![[NSFileManager defaultManager]fileExistsAtPath:[NSString stringWithFormat:@"%@/UnUpdatedItems/Image%d.jpg", directory, i]]) return [NSString stringWithFormat:@"%@/UnUpdatedItems/Image%d.jpg", directory, i];
	}
}

+ (void)showActivityIndicatorWithText:(NSString *)text {
	[AKSVideoAndImagePicker removeActivityIndicator];
}

+ (void)removeActivityIndicator {
}

+ (void)resetCachedMediaFiles {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
		NSError *error = nil;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *directory = [paths objectAtIndex:0];
		directory = [directory stringByAppendingString:@"/UnUpdatedItems/"];
		for (NSString *file in[fileManager contentsOfDirectoryAtPath : directory error : &error]) {
			NSString *filePath = [directory stringByAppendingPathComponent:file];
			BOOL fileDeleted = [fileManager removeItemAtPath:filePath error:&error];
			if (fileDeleted != YES || error != nil) {
			}
		}
	}
}

+ (UIImage *)compressThisImage:(UIImage *)image {
	return (image.size.width > 640) ? ([AKSVideoAndImagePicker imageWithImage:image scaledToWidth:640]) : image;
}
+ (UIImage *)imageWithImage:(UIImage *)sourceImage scaledToWidth:(float)i_width {
	float oldWidth = sourceImage.size.width;
	float scaleFactor = i_width / oldWidth;
	float newHeight = sourceImage.size.height * scaleFactor;
	float newWidth = oldWidth * scaleFactor;
	UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
	[sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

+ (NSMutableString *)documentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
}

@end
