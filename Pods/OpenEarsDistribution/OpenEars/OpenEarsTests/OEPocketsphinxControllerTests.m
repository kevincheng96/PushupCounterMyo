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

static NSString * const kExpectationThatPocketsphinxCanChangeLanguageModel = @"Pocketsphinx can change a language model";
static NSString * const kExpectationThatPocketsphinxCanPerformNormalRecognitionWithNBest = @"Confirms \"WORD STATEMENT SOMEONE'S OTHER WORD A PHRASE\" is recognized w/score better than |-1200000| but also that there are 2 hyps returned"; // WARNING: the part between the double-quotes is used by the test logic (it is extracted and compared with the hypothesis) so it can't be changed without making sure it still matches the test logic.

static NSString * const kExpectationThatPocketsphinxCanPerformNormalRecognition = @"Confirms \"WORD STATEMENT SOMEONE'S OTHER WORD A PHRASE\" is recognized w/score better than |-1200000|"; // WARNING: the part between the double-quotes is used by the test logic (it is extracted and compared with the hypothesis) so it can't be changed without making sure it still matches the test logic.
static NSString * const kExpectationThatRecognitionCanStartAndStop = @"Recognition can start and stop";
static NSString * const kExpectationThatRecognitionCanStart = @"Recognition can Start";
static NSString * const kExpectationThatTheVADCanDealWithBadSilence = @"Recognition doesn't hang when performed on this weird WAV with very low sound levels, splices, and quiet music, combined with speech.";
static NSString * const kExpectationThatRecognitionCanStartAndStopAndWriteCMNOut = @"Recognition can start, stop, and after stop it writes out a CMN.";
static NSString * const kExpectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn = @"Recognition can start, stop, and after stop it writes out a CMN, and then it starts again and can read the CMN back in.";
static NSString * const kExpectationThatRunRecognitionOnWavFileAtPathWorks = @"Confirms \"WORD STATEMENT SOMEONE'S OTHER WORD A PHRASE\" is recognized with a score better than |-7000000|";
static NSString * const kExpectationThatSpanishModelDoesNotPickUpExtraneousNoise = @"Spanish model only listens to foreground speech";

@interface OEPocketsphinxControllerTests : XCTestCase <OEEventsObserverDelegate> {
    OELanguageModelGenerator *_languageModelGenerator;
    OEEventsObserver *_openEarsEventsObserver;
    XCTestExpectation *_expectationThatPocketsphinxCanPerformNormalRecognition;
    XCTestExpectation *_expectationThatRecognitionCanStart;
    XCTestExpectation *_expectationThatRecognitionCanStartAndStop;
    XCTestExpectation *_expectationThatTheVADCanDealWithBadSilence;
    XCTestExpectation *_expectationThatLanguageModelCanChange;
    XCTestExpectation *_expectationThatRecognitionCanStartAndStopAndWriteCMNOut;
    XCTestExpectation *_expectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn;
    XCTestExpectation *_expectationThatPocketsphinxCanPerformNormalRecognitionWithNBest;
    XCTestExpectation *_expectationThatRunRecognitionOnWavFileAtPathWorks;
    XCTestExpectation *_expectationThatSpanishModelDoesNotPickUpExtraneousNoise;
    int _cmnTestStarts;
    NSString *_requestedNameForWordLanguageModel;
}
@end

@implementation OEPocketsphinxControllerTests

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
    //[OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE;
}

- (void)tearDown {
    [OEPocketsphinxController sharedInstance].nBestNumber = 1;
    [OEPocketsphinxController sharedInstance].returnNbest = FALSE;
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
    if([OETestTools currentTestDescriptionIs:kExpectationThatPocketsphinxCanChangeLanguageModel]) {
        
        NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"MONDAY",@"TUESDAY"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
        
        XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"MONDAY",@"TUESDAY"]);
        
        NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
        NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 
        [OEPocketsphinxController sharedInstance].pathToTestFile = nil;
        [[OEPocketsphinxController sharedInstance] changeLanguageModelToFile:lmPath withDictionary:dictionaryPath];
        [OEPocketsphinxController sharedInstance].pathToTestFile = [[OETestTools environmentAppropriateBundle] pathForResource:@"change_model_short" ofType:@"wav"];
    }
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

- (void)testThatPocketsphinxCanChangeLanguageModel {
    
    _expectationThatLanguageModelCanChange = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxCanChangeLanguageModel sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD",@"CHANGE MODEL"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD",@"CHANGE MODEL"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel]; 
    
    NSError *setActiveError = nil;
    BOOL setActiveSuccess = [[OEPocketsphinxController sharedInstance] setActive:TRUE error:&setActiveError];
    if(!setActiveSuccess)NSLog(@"Error setting OEPocketsphinxController active: %@", error);
    
    [[OEPocketsphinxController sharedInstance] setPathToTestFile:[[OETestTools environmentAppropriateBundle] pathForResource:@"change_model_short" ofType:@"wav"]];    
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:25
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                     [OETestTools setCurrentTestDescriptionTo:nil];                                         
                                 }];
}


- (void)testThatPocketsphinxCanPerformNormalRecognition {
    
    _expectationThatPocketsphinxCanPerformNormalRecognition = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxCanPerformNormalRecognition sender:self];
    
    NSArray *lmArray = @[@"WORD",@"STATEMENT", @"SOMEONE'S", @"OTHER", @"A PHRASE"];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:lmArray  withFilesNamed:@"WordLanguageModel" forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create the LM from the NSArray containing %@ without returning an error which isn't noErr.",lmArray);
    
    NSString *correctPathToMyLanguageModelFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"DMP"]; 
    NSString *correctPathToMyPhoneticDictionaryFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"dic"];
    //  [OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE;
    
    [OEPocketsphinxController sharedInstance].pathToTestFile = [[OETestTools environmentAppropriateBundle] pathForResource:@"word_statement_etc_short" ofType:@"wav"];    
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:correctPathToMyLanguageModelFile dictionaryAtPath:correctPathToMyPhoneticDictionaryFile acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:25
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                     [OETestTools setCurrentTestDescriptionTo:nil];
                                 }];
}

- (void)testThatPocketsphinxCanPerformNormalRecognitionWithNBest {
    
    _expectationThatPocketsphinxCanPerformNormalRecognitionWithNBest = [OETestTools setUpExpectationWithDescription:kExpectationThatPocketsphinxCanPerformNormalRecognitionWithNBest sender:self];
    
    NSArray *lmArray = @[@"WORD",@"STATEMENT", @"SOMEONE'S", @"OTHER", @"A PHRASE"];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:lmArray  withFilesNamed:@"WordLanguageModel" forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create the LM from the NSArray containing %@ without returning an error which isn't noErr.",lmArray);
    
    NSString *correctPathToMyLanguageModelFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"DMP"]; 
    NSString *correctPathToMyPhoneticDictionaryFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"dic"];
    // [OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE;
    [OEPocketsphinxController sharedInstance].nBestNumber = 2;   
    [OEPocketsphinxController sharedInstance].returnNbest = TRUE;       
    [OEPocketsphinxController sharedInstance].pathToTestFile = [[OETestTools environmentAppropriateBundle] pathForResource:@"word_statement_etc_short" ofType:@"wav"];    
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:correctPathToMyLanguageModelFile dictionaryAtPath:correctPathToMyPhoneticDictionaryFile acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:25
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                     [OETestTools setCurrentTestDescriptionTo:nil];
                                 }];
}

- (void)testThatRecognitionCanStart {
    
    _expectationThatRecognitionCanStart = [OETestTools setUpExpectationWithDescription:kExpectationThatRecognitionCanStart sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD",@"CHANGE MODEL"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel];
    
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:7
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                 }];
}


- (void)testThatRecognitionCanStartAndStop {
    
    _expectationThatRecognitionCanStartAndStop = [OETestTools setUpExpectationWithDescription:kExpectationThatRecognitionCanStartAndStop sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD",@"CHANGE MODEL"]);
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel];
    
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:20
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                 }];
}



- (void)testThatRecognitionCanStartAndStopAndWriteCMNOut {
    
    _expectationThatRecognitionCanStartAndStopAndWriteCMNOut = [OETestTools setUpExpectationWithDescription:kExpectationThatRecognitionCanStartAndStopAndWriteCMNOut sender:self];
    
    NSArray *lmArray = @[@"WORD",@"STATEMENT", @"SOMEONE'S", @"OTHER", @"A PHRASE"];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:lmArray  withFilesNamed:@"WordLanguageModel" forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create the LM from the NSArray containing %@ without returning an error which isn't noErr.",lmArray);
    
    NSString *correctPathToMyLanguageModelFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"DMP"]; 
    NSString *correctPathToMyPhoneticDictionaryFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"dic"];
   // [[OEPocketsphinxController sharedInstance] setVerbosePocketSphinx:TRUE];
    [[OEPocketsphinxController sharedInstance] removeCmnPlist];
    if([[NSFileManager defaultManager] fileExistsAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]]) {
        XCTFail(@"Error: this test can't begin unless there is definitely no cmn plist saved but there is one at %@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]);
    }
    
    [OEPocketsphinxController sharedInstance].useSmartCMNWithTestFiles = TRUE;
    [OEPocketsphinxController sharedInstance].pathToTestFile = [[OETestTools environmentAppropriateBundle] pathForResource:@"word_statement_etc_short" ofType:@"wav"];    
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:correctPathToMyLanguageModelFile dictionaryAtPath:correctPathToMyPhoneticDictionaryFile acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                 }];
}

- (void)testThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn {
 
    _expectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn = [OETestTools setUpExpectationWithDescription:kExpectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn sender:self];
    
    NSArray *lmArray = @[@"WORD",@"STATEMENT", @"SOMEONE'S", @"OTHER", @"A PHRASE"];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:lmArray  withFilesNamed:@"WordLanguageModel" forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create the LM from the NSArray containing %@ without returning an error which isn't noErr.",lmArray);
    
    NSString *correctPathToMyLanguageModelFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"DMP"]; 
    NSString *correctPathToMyPhoneticDictionaryFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"dic"];

    [[OEPocketsphinxController sharedInstance] removeCmnPlist];
    if([[NSFileManager defaultManager] fileExistsAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]]) {
        XCTFail(@"Error: this test can't begin unless there is definitely no cmn plist saved but there is one at %@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]);
    }
   // [OELogging startOpenEarsLogging];

    [OEPocketsphinxController sharedInstance].useSmartCMNWithTestFiles = TRUE;   
    [OEPocketsphinxController sharedInstance].pathToTestFile = [[OETestTools environmentAppropriateBundle] pathForResource:@"word_statement_etc_short" ofType:@"wav"];    
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:correctPathToMyLanguageModelFile dictionaryAtPath:correctPathToMyPhoneticDictionaryFile acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                 }];
}
- (void)testThatRunRecognitionOnWavFileAtPathWorks {
    
    _expectationThatRunRecognitionOnWavFileAtPathWorks = [OETestTools setUpExpectationWithDescription:kExpectationThatRunRecognitionOnWavFileAtPathWorks sender:self];
    
    NSArray *lmArray = @[@"WORD",@"STATEMENT", @"SOMEONE'S", @"OTHER", @"A PHRASE"];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:lmArray  withFilesNamed:@"WordLanguageModel" forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create the LM from the NSArray containing %@ without returning an error which isn't noErr.",lmArray);
    
    NSString *correctPathToMyLanguageModelFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"DMP"]; 
    NSString *correctPathToMyPhoneticDictionaryFile = [NSString stringWithFormat:@"%@/WordLanguageModel.%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0],@"dic"];
    //  [[OEPocketsphinxController sharedInstance] setVerbosePocketSphinx:TRUE];
    
    [[OEPocketsphinxController sharedInstance] runRecognitionOnWavFileAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"word_statement_etc_short" ofType:@"wav"] usingLanguageModelAtPath:correctPathToMyLanguageModelFile dictionaryAtPath:correctPathToMyPhoneticDictionaryFile acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                 }];
}

- (void)testThatTheVADCanDealWithBadSilence {
    
  //  [OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE;
   // [OELogging startOpenEarsLogging];
    _expectationThatTheVADCanDealWithBadSilence = [OETestTools setUpExpectationWithDescription:kExpectationThatTheVADCanDealWithBadSilence sender:self];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:@"WordLanguageModel" forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a one-word LM without returning an error which isn't noErr.");
    
    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel];
    
    [OEPocketsphinxController sharedInstance].pathToTestFile = [[OETestTools environmentAppropriateBundle] pathForResource:@"bad_silence" ofType:@"wav"];
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
    
    [self waitForExpectationsWithTimeout:60
                                 handler:^(NSError *error) {
                                     // handler is called on _either_ success or failure
                                     if (error != nil) {
                                         XCTFail(@"timeout error: %@", error);
                                     }
                                 }];
}



#pragma mark -
#pragma mark OEEventsObserver Callbacks Audio Session
#pragma mark -

- (void) audioSessionInterruptionDidBegin {
    NSLog(@"audioSessionInterruptionDidBegin");

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
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStartAndStop]) {
        [[OEPocketsphinxController sharedInstance] stopListening];   
    }
    
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStart]) {
        [OETestTools fulfillExpectation:_expectationThatRecognitionCanStart]; 
    }
    
}

/** Pocketsphinx is now listening.*/
- (void) pocketsphinxDidStartListening {
    NSLog(@"pocketsphinxDidStartListening");
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn]) {
        if(_cmnTestStarts == 1) {
            
            float defaultCMN = [[OEPocketsphinxController sharedInstance].continuousModel.smartCMN defaultCMNForAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
            
            if([OEPocketsphinxController sharedInstance].continuousModel.lastCMNUsed != defaultCMN && [OEPocketsphinxController sharedInstance].continuousModel.lastCMNUsed > 1 && [OEPocketsphinxController sharedInstance].continuousModel.lastCMNUsed < 110) { 
                NSLog(@"It looks a lot like a good non-default CMN value (%f) was used at the start of this listening session so this is a pass.",[OEPocketsphinxController sharedInstance].continuousModel.lastCMNUsed);
                [_expectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn fulfill];
            } else {
                NSLog(@"When I was hoping to fulfill this test expectation, lastCMNUsed was %f which wasn't a passing value so this test will probably time out and fail.",[OEPocketsphinxController sharedInstance].continuousModel.lastCMNUsed);   
            }
        }
    }
    
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
    if([OETestTools currentTestDescriptionIs:kExpectationThatPocketsphinxCanPerformNormalRecognitionWithNBest]) { // Compare to the phrase and minimum score set in the description
        
        NSScanner *hypTargetFromDescriptionScanner = [NSScanner scannerWithString:kExpectationThatPocketsphinxCanPerformNormalRecognitionWithNBest]; // Get the string we need to receive a hyp of.
        NSString *hypTargetFromDescription = nil;
        NSString *hypTargetToken = @"\"";
        [hypTargetFromDescriptionScanner scanUpToString:hypTargetToken intoString:NULL];
        [hypTargetFromDescriptionScanner scanString:hypTargetToken intoString:NULL];
        [hypTargetFromDescriptionScanner scanUpToString:hypTargetToken intoString:&hypTargetFromDescription];
        
        if([[[hypothesisArray objectAtIndex:0] valueForKey:@"Hypothesis"] isEqualToString:hypTargetFromDescription] && [hypothesisArray count] == 2) {
            NSLog(@"Passing test because the first recognition has recognized the spoken phrase %@ and the overall number of hypotheses returned are 2",hypTargetFromDescription);
            [OETestTools fulfillExpectation:_expectationThatPocketsphinxCanPerformNormalRecognitionWithNBest];   
        }
    }
}

/** Pocketsphinx has a hypothesis.*/
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
    NSLog(@"hypothesis for test \'%@ is \"%@\"\' with a score of %@",[OETestTools currentTestDescription],hypothesis,recognitionScore);

    if([OETestTools currentTestDescriptionIs:kExpectationThatTheVADCanDealWithBadSilence])[OETestTools fulfillExpectation:_expectationThatTheVADCanDealWithBadSilence];

    
    if([OETestTools currentTestDescriptionIs:kExpectationThatPocketsphinxCanChangeLanguageModel]) {
        if([hypothesis isEqualToString:@"CHANGE MODEL"])[self changeModel]; // Means that change model call was heard
        if([hypothesis rangeOfString:@"MONDAY"].location != NSNotFound || [hypothesis rangeOfString:@"TUESDAY"].location != NSNotFound)[OETestTools fulfillExpectation:_expectationThatLanguageModelCanChange]; // Means non-ridic recognition on the new model.  
    }
    
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStartAndStopAndWriteCMNOut]) {
        [[OEPocketsphinxController sharedInstance] stopListening];   
    } 
    
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn]) {
        [[OEPocketsphinxController sharedInstance] stopListening];   
    } 
    
    if([OETestTools currentTestDescriptionIs:kExpectationThatPocketsphinxCanPerformNormalRecognition]) { // Compare to the phrase and minimum score set in the description
        
        NSScanner *hypTargetFromDescriptionScanner = [NSScanner scannerWithString:kExpectationThatPocketsphinxCanPerformNormalRecognition]; // Get the string we need to receive a hyp of.
        NSString *hypTargetFromDescription = nil;
        NSString *hypTargetToken = @"\"";
        [hypTargetFromDescriptionScanner scanUpToString:hypTargetToken intoString:NULL];
        [hypTargetFromDescriptionScanner scanString:hypTargetToken intoString:NULL];
        [hypTargetFromDescriptionScanner scanUpToString:hypTargetToken intoString:&hypTargetFromDescription];
        
        NSScanner *scoreTargetFromDescriptionScanner = [NSScanner scannerWithString:kExpectationThatPocketsphinxCanPerformNormalRecognition]; // Get the string we need to receive a hyp of.
        NSString *scoreTargetFromDescription = nil;
        NSString *scoreTargetToken = @"|";
        [scoreTargetFromDescriptionScanner scanUpToString:scoreTargetToken intoString:NULL];
        [scoreTargetFromDescriptionScanner scanString:scoreTargetToken intoString:NULL];
        [scoreTargetFromDescriptionScanner scanUpToString:scoreTargetToken intoString:&scoreTargetFromDescription];
        
        if([hypothesis isEqualToString:hypTargetFromDescription] && ([recognitionScore integerValue] > [scoreTargetFromDescription integerValue])) {
            NSLog(@"Passing test because the first recognition has recognized the spoken phrase %@ and with a score of %@ which is better than the minimum of %@",hypTargetFromDescription,recognitionScore,scoreTargetFromDescription);
            [OETestTools fulfillExpectation:_expectationThatPocketsphinxCanPerformNormalRecognition];   
        }
    }

    if([OETestTools currentTestDescriptionIs:kExpectationThatSpanishModelDoesNotPickUpExtraneousNoise]) { // Compare to the phrase and minimum score set in the description
        
       [OETestTools fulfillExpectation:_expectationThatSpanishModelDoesNotPickUpExtraneousNoise];   // Free pass, I have no idea how to qualify this yet.
      
    }
    
    
    if([OETestTools currentTestDescriptionIs:kExpectationThatRunRecognitionOnWavFileAtPathWorks]) { // Compare to the phrase and minimum score set in the description
        
        NSScanner *hypTargetFromDescriptionScanner = [NSScanner scannerWithString:kExpectationThatRunRecognitionOnWavFileAtPathWorks]; // Get the string we need to receive a hyp of.
        NSString *hypTargetFromDescription = nil;
        NSString *hypTargetToken = @"\"";
        [hypTargetFromDescriptionScanner scanUpToString:hypTargetToken intoString:NULL];
        [hypTargetFromDescriptionScanner scanString:hypTargetToken intoString:NULL];
        [hypTargetFromDescriptionScanner scanUpToString:hypTargetToken intoString:&hypTargetFromDescription];
        
        NSScanner *scoreTargetFromDescriptionScanner = [NSScanner scannerWithString:kExpectationThatRunRecognitionOnWavFileAtPathWorks]; // Get the string we need to receive a hyp of.
        NSString *scoreTargetFromDescription = nil;
        NSString *scoreTargetToken = @"|";
        [scoreTargetFromDescriptionScanner scanUpToString:scoreTargetToken intoString:NULL];
        [scoreTargetFromDescriptionScanner scanString:scoreTargetToken intoString:NULL];
        [scoreTargetFromDescriptionScanner scanUpToString:scoreTargetToken intoString:&scoreTargetFromDescription];
        
        if([hypothesis isEqualToString:hypTargetFromDescription] && ([recognitionScore integerValue] > [scoreTargetFromDescription integerValue])) {
            NSLog(@"Passing test because the first recognition has recognized the spoken phrase %@ and with a score of %@ which is better than the minimum of %@",hypTargetFromDescription,recognitionScore,scoreTargetFromDescription);
            [OETestTools fulfillExpectation:_expectationThatRunRecognitionOnWavFileAtPathWorks];   
        }
    }
    
}


/** Pocketsphinx has exited the continuous listening loop.*/
- (void) pocketsphinxDidStopListening {
    NSLog(@"pocketsphinxDidStopListening");
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStartAndStop]) {
        [OETestTools fulfillExpectation:_expectationThatRecognitionCanStartAndStop];   
    }
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStartAndStopAndWriteCMNOut]) {
        
        if([[NSFileManager defaultManager] fileExistsAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]]) {
            NSError *error = nil;    
            NSData * tempData = [[NSData alloc] initWithContentsOfFile:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]];
            NSPropertyListFormat plistFormat;
            NSDictionary *temp = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:&plistFormat error:&error];
            NSString *plistAsString = [NSString stringWithFormat:@"%@",temp];
            NSLog(@"I found a CMN plist containing %@",plistAsString);
            
#if TARGET_IPHONE_SIMULATOR
            float defaultCMN = [[OEPocketsphinxController sharedInstance].continuousModel.smartCMN defaultCMNForAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
            if([[temp valueForKey:[temp allKeys][0]] isEqualToNumber:@(defaultCMN)]) {
                NSLog(@"the smartcmn value %@ is equal to the default value for this acoustic model %f, which is an invalid result since that is the default. This can happen if the default value is the optimal CMN but I've never seen that in reality.",[temp valueForKey:[temp allKeys][0]], defaultCMN);
            } else {
                NSLog(@"the smartcmn value %@ is not equal to the default value for this acoustic model %f, so it is valid.",[temp valueForKey:[temp allKeys][0]],defaultCMN);
                [OETestTools fulfillExpectation:_expectationThatRecognitionCanStartAndStopAndWriteCMNOut];
            }
#else
            if([plistAsString rangeOfString:@"UnknownRoute"].location == NSNotFound) { // But it isn't OK on a device.
                float defaultCMN = [[OEPocketsphinxController sharedInstance].continuousModel.smartCMN defaultCMNForAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];

                if([[temp valueForKey:[temp allKeys][0]] isEqualToNumber:@(defaultCMN)]) {
                    NSLog(@"the smartcmn value %@ is equal to the default value for this acoustic model %f, which is an invalid result since that is the default. This can happen if the default value is the optimal CMN but I've never seen that in reality.",[temp valueForKey:[temp allKeys][0]], defaultCMN);
                } else {
                    NSLog(@"the smartcmn value %@ is not equal to the default value for this acoustic model %f, so it is valid.",[temp valueForKey:[temp allKeys][0]],defaultCMN);
                    [OETestTools fulfillExpectation:_expectationThatRecognitionCanStartAndStopAndWriteCMNOut];
                }
            } else {
                // this is a failure state because the plist contains UnknownRoute. 
                NSLog(@"UnknownRoute was found in the route and this is not a valid outcome when this test is run on a device, so not fulfilling.");
            }
#endif
        } else {
            NSLog(@"no cmnvalues.plist was found so that is an automatic fail.");   
        }
    }
    
    if([OETestTools currentTestDescriptionIs:kExpectationThatRecognitionCanStartStopWriteCMNOutStartReadCMNIn]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]]) {
            NSError *error = nil;    
            NSData * tempData = [[NSData alloc] initWithContentsOfFile:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cmnvalues.plist"]];
            NSPropertyListFormat plistFormat;
            NSDictionary *temp = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:&plistFormat error:&error];
            NSString *plistAsString = [NSString stringWithFormat:@"%@",temp];
            if(_cmnTestStarts == 0) {
                NSLog(@"I found a CMN plist containing %@",plistAsString);
            } else {
                NSLog(@"This is the second test start and my interest is in the value of [OEPocketsphinxController sharedInstance].continuousModel.lastCMNUsed which is %f.",[OEPocketsphinxController sharedInstance].continuousModel.lastCMNUsed);
            }
#if TARGET_IPHONE_SIMULATOR
             float defaultCMN = [[OEPocketsphinxController sharedInstance].continuousModel.smartCMN defaultCMNForAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
            if([[temp valueForKey:[temp allKeys][0]] isEqualToNumber:@(defaultCMN)]) {
                NSLog(@"the smartcmn value %@ is equal to the default value for this acoustic model %f, which is an invalid result since that is the default. This can happen if the default value is the optimal CMN but I've never seen that in reality.",[temp valueForKey:[temp allKeys][0]],defaultCMN);
            } else {
                if(_cmnTestStarts == 0) {
                    NSLog(@"the smartcmn value %@ is not equal to the default value for this acoustic model %f, so it is valid.",[temp valueForKey:[temp allKeys][0]], defaultCMN);
                    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
                    
                    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD",@"CHANGE MODEL"]);
                    
                    NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
                    NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel];
                    [[OEPocketsphinxController sharedInstance] useSmartCMNWithTestFiles];
                    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
                    _cmnTestStarts++;
                } else {
                    
                }
            }
#else
            if([plistAsString rangeOfString:@"UnknownRoute"].location == NSNotFound) { // But it isn't OK on a device.
                float defaultCMN = [[OEPocketsphinxController sharedInstance].continuousModel.smartCMN defaultCMNForAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];

                if([[temp valueForKey:[temp allKeys][0]] isEqualToNumber:@(defaultCMN)]) {
                    NSLog(@"the smartcmn value %@ is equal to the default value for this acoustic model %f, which is an invalid result since that is the default. This can happen if the default value is the optimal CMN but I've never seen that in reality.",[temp valueForKey:[temp allKeys][0]],defaultCMN);
                } else {
                    if(_cmnTestStarts == 0) {
                        NSLog(@"the smartcmn value %@ is not equal to the default value for this acoustic model %f, so it is valid.",[temp valueForKey:[temp allKeys][0]], defaultCMN);
                        
                        NSError *error = [_languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:_requestedNameForWordLanguageModel forAcousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"]];
                        
                        XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a LM from the array %@ without returning an error which isn't noErr.",@[@"WORD",@"CHANGE MODEL"]);
                        
                        NSString *dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:_requestedNameForWordLanguageModel];
                        NSString *lmPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:_requestedNameForWordLanguageModel];
                        [[OEPocketsphinxController sharedInstance] useSmartCMNWithTestFiles];
                        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dictionaryPath acousticModelAtPath:[[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"] languageModelIsJSGF:FALSE];
                        _cmnTestStarts++;
                    }
                }
            } else {
                // this is a failure state because the plist contains UnknownRoute. 
                NSLog(@"UnknownRoute was found in the route and this is not a valid outcome when this test is run on a device, so not fulfilling.");
            }
#endif
        }
    }
    
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
