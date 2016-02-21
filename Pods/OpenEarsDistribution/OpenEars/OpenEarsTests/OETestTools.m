//
//  OETestTools.m
//  OpenEars
//
//  Created by Halle Winkler on 11/10/14.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import "OETestTools.h"
#import "TargetConditionals.h"
@implementation OETestTools

static NSString *_currentTestDescription = nil;
static BOOL _currentExpectationHasBeenFulfilled = FALSE;
static BOOL _logInCallbacks = TRUE;

+ (NSBundle *) environmentAppropriateBundle {
#if TARGET_IPHONE_SIMULATOR
    return [NSBundle bundleForClass:[self class]];
#else
    return [NSBundle mainBundle];
#endif
}

+ (XCTestExpectation *) setUpExpectationWithDescription:(NSString*)description sender:(id)sender{
    _currentTestDescription = description;
    _currentExpectationHasBeenFulfilled = FALSE;
    return [sender expectationWithDescription:description];
}

+ (BOOL) currentTestDescriptionIs:(NSString*)description { // Let's have prettier semantics.
    if([_currentTestDescription isEqualToString:description]) {
        return TRUE;
    } else {
        return FALSE;        
    }
}

+ (void) fulfillExpectation:(XCTestExpectation *)expectation { // Let's make sure we only fulfill a single expectation once.
    if(!_currentExpectationHasBeenFulfilled) {
        _currentExpectationHasBeenFulfilled = TRUE;
        [expectation fulfill];   
    }
}

+ (BOOL) currentExpectationHasBeenFulfilled {
    return _currentExpectationHasBeenFulfilled;
}

+ (void) setCurrentExpectationHasBeenFulfilled:(BOOL)trueOrFalse {
    _currentExpectationHasBeenFulfilled = trueOrFalse;
}

+ (NSString *) currentTestDescription {
    return _currentTestDescription;
}

+ (void) setCurrentTestDescriptionTo:(NSString*)testDescription {
    _currentTestDescription = testDescription;
}

+ (void) setLogInCallbacksTo:(BOOL)trueOrFalse {
    _logInCallbacks = trueOrFalse;
}

+ (BOOL) logInCallbacks {
    if(_logInCallbacks) {
        return TRUE;
    } else {
        return FALSE;        
    }
}

@end
