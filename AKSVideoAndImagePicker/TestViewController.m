//
//  TestViewController.m
//  BlockBasedImagePicker
//
//  Created by Alok on 27/08/13.
//  Copyright (c) 2013 Konstant Info Private Limited. All rights reserved.
//

#import "TestViewController.h"
#import "AKSVideoAndImagePicker.h"

@implementation TestViewController
- (void)viewDidLoad{
    [super viewDidLoad];
	double delayInSeconds = 5.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[AKSVideoAndImagePicker needImage:TRUE needVideo:TRUE FromLibrary:YES from:self didFinished:^(NSString *filePath, NSString *fileType) {
			NSLog(@"%@",filePath);
			NSLog(@"%@",fileType);
		}];
	});
}

@end
