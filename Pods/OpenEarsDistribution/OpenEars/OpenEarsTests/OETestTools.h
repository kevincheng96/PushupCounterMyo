//
//  OETestTools.h
//  OpenEars
//
//  Created by Halle Winkler on 11/10/14.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
@interface OETestTools : NSObject

+ (NSBundle *) environmentAppropriateBundle;
+ (XCTestExpectation *) setUpExpectationWithDescription:(NSString*)description sender:(id)sender;
+ (BOOL) currentTestDescriptionIs:(NSString*)description;
+ (void) fulfillExpectation:(XCTestExpectation *)expectation;
+ (BOOL) currentExpectationHasBeenFulfilled;
+ (NSString *) currentTestDescription;
+ (void) setCurrentExpectationHasBeenFulfilled:(BOOL)trueOrFalse;
+ (void) setCurrentTestDescriptionTo:(NSString*)testDescription;
+ (void) setLogInCallbacksTo:(BOOL)trueOrFalse;
+ (BOOL) logInCallbacks;
@end
