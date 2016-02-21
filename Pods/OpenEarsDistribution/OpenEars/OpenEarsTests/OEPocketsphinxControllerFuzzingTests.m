//
//  PocketsphinxControllerTests.m
//  OpenEars
//
//  Created by Halle on 8/29/14.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "XCTestCase+HWHorrorShow.h"
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEEventsObserver.h>
#import <OpenEars/OELogging.h>
#import <OpenEars/OERuntimeVerbosity.h>
#import "OETestTools.h"

// These NSString values should all be unique.

#pragma mark -
#pragma mark Expectation constants
#pragma mark -

static NSString * const kExpectationThatPocketsphinxCanRandomlyStartAndStopWithoutCrashing = @"No matter the order and timings of stops and starts, there is no attempt to start an utterance with a null ps.";
static NSString * const kExpectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccess = @"Pocketsphinx will not crash on audio unit render if accessed across threads";
static NSString * const kExpectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccessDueToDoubleStart = @"Pocketsphinx will not crash on audio unit render if accessed across threads with a double start.";
static NSString * const kExpectationThatPocketsphinxCanDealWithRouteChangesAndInterruptionsAndResets = @"Pocketsphinx will not crash during a random assortment of stops, starts, and various kinds of external interruptions";
static NSString * const kExpectationThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption = @"Pocketsphinx will not crash when resuming after an interruption";
static NSString * const kExpectationThatPocketsphinxDoesntCrashRepeatedlyChangingRoutes = @"Pocketsphinx will not crash when repeatedly changing routes";


@interface OEPocketsphinxControllerFuzzingTests : XCTestCase <OEEventsObserverDelegate> {
    OELanguageModelGenerator *_languageModelGenerator;
    OEEventsObserver *_openEarsEventsObserver;
    XCTestExpectation *_expectationThatPocketsphinxCanRandomlyStartAndStopWithoutCrashing;
    XCTestExpectation *_expectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccessDueToDoubleStart;
    XCTestExpectation *_expectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccess;
    XCTestExpectation *_expectationThatPocketsphinxCanDealWithRouteChangesAndInterruptionsAndResets;
    XCTestExpectation *_expectationThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption;
    XCTestExpectation *_expectationThatPocketsphinxDoesntCrashRepeatedlyChangingRoutes;
    int _cmnTestStarts;
    NSString *_requestedNameForWordLanguageModel;
}
@end

@implementation OEPocketsphinxControllerFuzzingTests

#pragma mark -
#pragma mark Setup and teardown
#pragma mark -

- (void)setUp {
    [super setUp];
    
    _cmnTestStarts = 0;
    _requestedNameForWordLanguageModel = @"WordLanguageModel";
    [[OEPocketsphinxController sharedInstance]setActive:TRUE error:nil];
    _languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    _openEarsEventsObserver = [[OEEventsObserver alloc] init];   
    _openEarsEventsObserver.delegate = self;
    [OETestTools setCurrentExpectationHasBeenFulfilled:FALSE];
    [OEPocketsphinxController sharedInstance].returnNullHypotheses = TRUE;
}

- (void)tearDown {
    [OEPocketsphinxController sharedInstance].pathToTestFile = nil;
    [[OEPocketsphinxController sharedInstance]stopListening];
    _openEarsEventsObserver.delegate = nil;
    [[OEPocketsphinxController sharedInstance]setActive:FALSE error:nil];    
    [super tearDown];
}

#pragma mark -
#pragma mark OEPocketsphinxController-specific Test Management Convenience Methods
#pragma mark -

- (void) changeModel {

}

- (NSString *)pathToCachesDirectory {
    return [NSString stringWithFormat:@"%@",NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]];
};

- (void) notifyInterruption {
    [[NSNotificationCenter defaultCenter] postNotificationName:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
}

- (void) notifyRouteChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
}

- (void) notifyMediaServicesReset {
    [[NSNotificationCenter defaultCenter] postNotificationName:AVAudioSessionMediaServicesWereResetNotification object:[AVAudioSession sharedInstance]];
}




#pragma mark -
#pragma mark Tests
#pragma mark -

- (void) testThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccessDueToDoubleStart {
  //  [OELogging startOpenEarsLogging]; 
  //  [OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE;
    _expectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccessDueToDoubleStart = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccessDueToDoubleStart sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:5];
        [OETestTools fulfillExpectation:_expectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccessDueToDoubleStart];  // Pass if we're still alive when completed. 
    });
    
//    The order of these events:
    
//    1. a call to start on a background thread
//    2. a call to start on a background thread    
//    3. a call to stop on a background thread    
//    4. a call to start on a background thread
//    5. a call to start on a background thread
//    6. a call to start on a background thread
//    7. a call to start on a background thread

//    It is the last call to start which crashes. Every time it crashes, this error can be seen from the start at position 4:
//    Error in render callback: -1
    
    // The cause of this crash was the double-start right at the beginning – both simultaneous calls are able to access start unsafely if they are perfectly synchronized. I fixed this with a @synchronized block and it needs to stay here as a regression test.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });

    [self waitForExpectationsWithTimeout:7
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                     [OETestTools setCurrentTestDescriptionTo:nil];                                         
                                 }];
}




- (void) testThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccess {
   // [OELogging startOpenEarsLogging];
    _expectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccess = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccess sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:27];
        [OETestTools fulfillExpectation:_expectationThatPocketsphinxDoesNotCrashOnAudioUnitRenderDuringCrossThreadAccess];  // Pass if we're still alive when completed. 
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:13];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:12];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:15];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:16];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:20];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:15];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:11];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:11];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:14];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:12];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:12];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:18];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:13];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:15];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:18];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:15];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:20];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:15];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:11];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:20];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:17];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];    
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1];
        [[OEPocketsphinxController sharedInstance] stopListening];  
    });
    [self waitForExpectationsWithTimeout:60
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                     [OETestTools setCurrentTestDescriptionTo:nil];                                         
                                 }];
}


- (void) testThatPocketsphinxDoesntCrashRepeatedlyChangingRoutes {
    
    _expectationThatPocketsphinxDoesntCrashRepeatedlyChangingRoutes = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxDoesntCrashRepeatedlyChangingRoutes sender:self];
 
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30];
        [OETestTools fulfillExpectation:_expectationThatPocketsphinxDoesntCrashRepeatedlyChangingRoutes];
    });
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 
    
  //  [OELogging startOpenEarsLogging];
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:16.303886];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.404340];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2.905627];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:43.429798];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:27.308830];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8.269774];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6.813404];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6.903671];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:35.558426];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:17.051107];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:32.118671];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:31.849644];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:14.376183];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.501553];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:14.119847];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:31.337404];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:16.683920];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:41.164406];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:37.802586];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:23.034994];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9.999291];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:21.197765];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:22.005436];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:28.279625];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:29.171394];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.592539];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:14.290951];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:28.149618];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:44.195644];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3.514402];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:39.575153];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:12.796776];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10.488252];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:43.378628];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:18.571699];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:28.590395];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:43.273815];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:27.573130];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:43.574673];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19.665634];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:24.450899];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:34.867546];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:15.149318];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:24.225454];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:42.681561];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:29.756199];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:42.160713];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:16.141565];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3.365887];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6.094271];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:23.490511];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:20.540709];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:34.671295];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:37.985073];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3.860638];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:17.902260];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8.327502];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:44.706093];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.047842];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:12.920216];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:39.118484];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:21.990170];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:32.017273];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6.581956];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:18.617311];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.648718];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:42.813030];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:20.481865];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:31.827774];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3.143623];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:38.215736];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.368990];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:28.960714];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.287354];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:40.066349];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1.209504];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:24.705854];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:7.544207];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2.673144];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2.881811];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:31.489964];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:40.549446];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:16.003006];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:26.768118];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:42.007416];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:24.105463];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:5.152513];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3.367685];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.972149];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:14.562784];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:35.813473];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:31.655602];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:31.562346];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:16.902847];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:40.827938];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:5.847098];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:35.020954];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6.056922];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10.138702];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:21.815971];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:43.125607];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:7.008851];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4.075358];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2.673954];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10.582727];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:36.847668];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:36.778725];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:26.514412];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:29.171169];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19.673128];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:43.267498];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10.857401];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:23.715580];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:15.057199];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:27.745258];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.302668];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4.762386];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:35.691330];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4.551815];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:17.883188];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:30.954021];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:21.754654];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:32.431591];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:22.706051];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:24.711987];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:14.383135];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:18.868999];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:11.903882];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:43.977646];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:17.072214];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19.644917];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:19.151653];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9.452705];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:39.267845];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10.393163];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2.040087];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:12.787264];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:22.547998];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10.983944];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:27.953941];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:25.460014];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:21.226093];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:21.315466];
        [self notifyRouteChange];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.129298];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:23.400145];
        [self notifyMediaServicesReset];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6.683848];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:5.768648];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:23.442680];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:28.040873];
        [self notifyInterruption];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:44.834061];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    });
    
    


    [self waitForExpectationsWithTimeout:46
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                 }];
}

- (void) targetMethod {
    [OETestTools fulfillExpectation:_expectationThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption];

}

- (void) testThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption {
    
    
    _expectationThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption sender:self];
    
    
    [NSTimer scheduledTimerWithTimeInterval:11.0
                                     target:self
                                   selector:@selector(targetMethod)
                                   userInfo:nil
                                    repeats:NO]; // I have literally no idea why I have to fulfill this with a timer for it to work, but I do.
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 
    
    //[OELogging startOpenEarsLogging];
    
  
    

    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE]; 
    });
    
    

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        [self notifyInterruption];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:3];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:4];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE]; 
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:5];
        [self notifyMediaServicesReset];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:6];
        [[OEPocketsphinxController sharedInstance] stopListening];
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:7];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE]; 
    });
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:8];
        [self notifyRouteChange];
    });
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:9];
        [[OEPocketsphinxController sharedInstance] stopListening]; 
    });
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE]; 
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:11];
        [[OEPocketsphinxController sharedInstance] stopListening]; 
    });
    
    
    [self waitForExpectationsWithTimeout:15
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                     [OETestTools setCurrentTestDescriptionTo:nil];                                         
                                 }];
    
}

- (void)testThatPocketsphinxCanDealWithRouteChangesAndInterruptionsAndResets {
    
    _expectationThatPocketsphinxCanDealWithRouteChangesAndInterruptionsAndResets = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxCanDealWithRouteChangesAndInterruptionsAndResets sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 
    
  //  [OELogging startOpenEarsLogging];
    
    SEL startSelector;
    NSMethodSignature *startSignature;
    NSInvocation *startInvocation;
    BOOL languageModelIsJSGF = FALSE;
    NSString *acousticModel = [[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"];
    startSelector = @selector(startListeningWithLanguageModelAtPath:dictionaryAtPath:acousticModelAtPath:languageModelIsJSGF:);
    startSignature = [[OEPocketsphinxController sharedInstance] methodSignatureForSelector:startSelector];
    startInvocation = [NSInvocation invocationWithMethodSignature:startSignature];
    [startInvocation setSelector:startSelector];
    [startInvocation setTarget:[OEPocketsphinxController sharedInstance]];
    [startInvocation setArgument:&lmPath atIndex:2];
    [startInvocation setArgument:&dictionaryPath atIndex:3];
    [startInvocation setArgument:&acousticModel atIndex:4];
    [startInvocation setArgument:&languageModelIsJSGF atIndex:5];
    
    SEL stopSelector;
    NSMethodSignature *stopSignature;
    NSInvocation *stopInvocation;
    
    stopSelector = @selector(stopListening);
    stopSignature = [[OEPocketsphinxController sharedInstance] methodSignatureForSelector:stopSelector];
    stopInvocation = [NSInvocation invocationWithMethodSignature:stopSignature];
    [stopInvocation setSelector:stopSelector];
    [stopInvocation setTarget:[OEPocketsphinxController sharedInstance]];

    SEL interruptSelector;
    NSMethodSignature *interruptSignature;
    NSInvocation *interruptInvocation;
    
    interruptSelector = @selector(notifyInterruption);
    interruptSignature = [self methodSignatureForSelector:interruptSelector];
    interruptInvocation = [NSInvocation invocationWithMethodSignature:interruptSignature];
    [interruptInvocation setSelector:interruptSelector];
    [interruptInvocation setTarget:self];
    
    SEL resetSelector;
    NSMethodSignature *resetSignature;
    NSInvocation *resetInvocation;
    
    resetSelector = @selector(notifyMediaServicesReset);
    resetSignature = [self methodSignatureForSelector:resetSelector];
    resetInvocation = [NSInvocation invocationWithMethodSignature:resetSignature];
    [resetInvocation setSelector:resetSelector];
    [resetInvocation setTarget:self];

    SEL routeSelector;
    NSMethodSignature *routeSignature;
    NSInvocation *routeInvocation;
    
    routeSelector = @selector(notifyRouteChange);
    routeSignature = [self methodSignatureForSelector:routeSelector];
    routeInvocation = [NSInvocation invocationWithMethodSignature:routeSignature];
    [routeInvocation setSelector:routeSelector];
    [routeInvocation setTarget:self];
    
    
    [self fuzzCrossThreadInvocationsFromArray:@[startInvocation,stopInvocation,interruptInvocation,resetInvocation,routeInvocation] expectation:_expectationThatPocketsphinxCanDealWithRouteChangesAndInterruptionsAndResets permutations:100 testDuration:45];    
}


- (void)testThatPocketsphinxCanRandomlyStartAndStopWithoutCrashingAndHoldUp {
    
    _expectationThatPocketsphinxCanRandomlyStartAndStopWithoutCrashing = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxCanRandomlyStartAndStopWithoutCrashing sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 
  
    SEL startSelector;
    NSMethodSignature *startSignature;
    NSInvocation *startInvocation;
    BOOL languageModelIsJSGF = FALSE;
    NSString *acousticModel = [[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"];
    startSelector = @selector(startListeningWithLanguageModelAtPath:dictionaryAtPath:acousticModelAtPath:languageModelIsJSGF:);
    startSignature = [[OEPocketsphinxController sharedInstance] methodSignatureForSelector:startSelector];
    startInvocation = [NSInvocation invocationWithMethodSignature:startSignature];
    [startInvocation setSelector:startSelector];
    [startInvocation setTarget:[OEPocketsphinxController sharedInstance]];
    [startInvocation setArgument:&lmPath atIndex:2];
    [startInvocation setArgument:&dictionaryPath atIndex:3];
    [startInvocation setArgument:&acousticModel atIndex:4];
    [startInvocation setArgument:&languageModelIsJSGF atIndex:5];

    SEL stopSelector;
    NSMethodSignature *stopSignature;
    NSInvocation *stopInvocation;
    
    stopSelector = @selector(stopListening);
    stopSignature = [[OEPocketsphinxController sharedInstance] methodSignatureForSelector:stopSelector];
    stopInvocation = [NSInvocation invocationWithMethodSignature:stopSignature];
    [stopInvocation setSelector:stopSelector];
    [stopInvocation setTarget:[OEPocketsphinxController sharedInstance]];
    
    [self fuzzCrossThreadInvocationsFromArray:@[startInvocation,stopInvocation] expectation:_expectationThatPocketsphinxCanRandomlyStartAndStopWithoutCrashing permutations:100 testDuration:30];    
}

#pragma mark -
#pragma mark OEEventsObserver Callbacks Audio Session
#pragma mark -

- (void) audioSessionInterruptionDidBegin {
    NSLog(@"audioSessionInterruptionDidBegin");
    if([OETestTools currentTestDescriptionIs:kExpectationThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption]) [[OEPocketsphinxController sharedInstance] stopListening];
}
/** The interruption ended.*/
- (void) audioSessionInterruptionDidEnd {
        NSLog(@"audioSessionInterruptionDidBegin");
    if([OETestTools currentTestDescriptionIs:kExpectationThatPocketsphinxDoesntCrashWhenRestartingAfterAnAudioSessionInterruption]) {
        NSArray *lmArray = @[@"WORD",@"STATEMENT", @"SOMEONE'S", @"OTHER", @"A PHRASE"];
        NSError *error = [_languageModelGenerator generateLanguageModelFromArray:lmArray  withFilesNamed:@"WordLanguageModel" forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
        if(error)NSLog(@"Error while creating language model: %@", error);
        NSString *correctPathToMyLanguageModelFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"DMP"]; 
        NSString *correctPathToMyPhoneticDictionaryFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"dic"];
        [OEPocketsphinxController sharedInstance].pathToTestFile = [[OETestTools environmentAppropriateBundle] pathForResource:@"word_statement_etc_short" ofType:@"wav"];    
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:correctPathToMyLanguageModelFile dictionaryAtPath:correctPathToMyPhoneticDictionaryFile acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    }
}
/** The input became unavailable.*/
- (void) audioInputDidBecomeUnavailable {
    NSLog(@"audioInputDidBecomeUnavailable");
}
/** The input became available again.*/
- (void) audioInputDidBecomeAvailable {
    NSLog(@"audioInputDidBecomeAvailable");
}
/** The audio route changed.*/
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
    NSLog(@"audioRouteDidChangeToRoute: %@", newRoute);
}

#pragma mark -
#pragma mark OEEventsObserver Callbacks OEPocketsphinx Statuses
#pragma mark -

// Pocketsphinx Status Methods.

/** Pocketsphinx isn't listening yet but it has entered the main recognition loop.*/
- (void) pocketsphinxRecognitionLoopDidStart {
    NSLog(@"pocketsphinxRecognitionLoopDidStart");

    
}

/** Pocketsphinx is now listening.*/
- (void) pocketsphinxDidStartListening {
    NSLog(@"pocketsphinxDidStartListening");

    
}
/** Pocketsphinx heard speech and is about to process it.*/
- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"pocketsphinxDidDetectSpeech");
}
/** Pocketsphinx detected a second of silence indicating the end of an utterance*/
- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"pocketsphinxDidDetectFinishedSpeech");
}
- (void) pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray {
    NSLog(@"hypothesisArray for test \'%@ is \"%@\"\'",[OETestTools currentTestDescription],hypothesisArray);

}

/** Pocketsphinx has a hypothesis.*/
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
    NSLog(@"hypothesis for test \'%@ is \"%@\"\'",[OETestTools currentTestDescription],hypothesis);

}


/** Pocketsphinx has exited the continuous listening loop.*/
- (void) pocketsphinxDidStopListening {
    NSLog(@"pocketsphinxDidStopListening");
       
}

/** Pocketsphinx has not exited the continuous listening loop but it will not attempt recognition.*/
- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"pocketsphinxDidSuspendRecognition");
}
/** Pocketsphinx has not existed the continuous listening loop and it will now start attempting recognition again.*/
- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"pocketsphinxDidResumeRecognition");
}
/** Pocketsphinx switched language models inline.*/
- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
    NSLog(@"pocketsphinxDidChangeLanguageModelToFile:%@ andDictionary:%@",newLanguageModelPathAsString,newDictionaryPathAsString);
}
/** Some aspect of setting up the continuous loop failed, turn on OELogging for more info.*/
- (void) pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"pocketSphinxContinuousSetupDidFail, reason given: %@", reasonForFailure);
}
/** Some aspect of setting up the continuous loop failed, turn on OELogging for more info.*/
- (void) pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"pocketSphinxContinuousTeardownDidFail, reason given: %@", reasonForFailure);
}
/** Your test recognition run has completed.*/
- (void) pocketsphinxTestRecognitionCompleted {
    NSLog(@"pocketsphinxTestRecognitionCompleted");
}
/** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
- (void) pocketsphinxFailedNoMicPermissions {
    NSLog(@"pocketsphinxFailedNoMicPermissions");
}
/** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a TRUE or a FALSE result  (will only be returned on iOS7 or later).*/
- (void) micPermissionCheckCompleted:(BOOL)result {
    NSLog(@"micPermissionCheckCompleted:%@",OEBoolStr(result));
}

#pragma mark -
#pragma mark OEEventsObserver Callbacks OEFliteController Statuses
#pragma mark -

// Flite Status Methods.
/** Flite started speaking. You probably don't have to do anything about this.*/
- (void) fliteDidStartSpeaking {
    NSLog(@"fliteDidStartSpeaking");
}
/** Flite finished speaking. You probably don't have to do anything about this.*/
- (void) fliteDidFinishSpeaking {
    NSLog(@"fliteDidFinishSpeaking");
}

@end
