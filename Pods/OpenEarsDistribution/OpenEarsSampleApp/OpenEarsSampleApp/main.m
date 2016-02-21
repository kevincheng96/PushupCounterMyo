//
//  main.m
//  OpenEarsSampleApp
//
//  Created by Halle Winkler on 3/7/12.
//  Copyright (c) 2012 Politepix. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        BOOL runningTests = NSClassFromString(@"XCTestCase") != nil;
        if(!runningTests)
        {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
        else
        {
            return UIApplicationMain(argc, argv, nil, @"TestAppDelegate");
        }
    }
}