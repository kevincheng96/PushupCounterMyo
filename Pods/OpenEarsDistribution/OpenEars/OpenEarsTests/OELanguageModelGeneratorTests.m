//
//  LanguageModelGeneratorTests.m
//  LanguageModelGeneratorTests
//
//  Created by Halle on 8/26/14.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import "OETestTools.h"

@interface OELanguageModelGeneratorTests : XCTestCase
@end

@implementation OELanguageModelGeneratorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    [super tearDown];
}

- (void) testCharacterProcessingForLargeTextLanguageModels {
    NSString *pathToAcousticModel = [[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"];
    
    OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    
    NSString *requestedName = @"SherlockLanguageModel";
    
    NSError *error = nil;
    
    error = [languageModelGenerator generateLanguageModelFromTextFile:[[OETestTools environmentAppropriateBundle] pathForResource:@"Sherlock" ofType:@"txt"] withFilesNamed:requestedName forAcousticModelAtPath:pathToAcousticModel];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a one-word LM without returning an error which isn't noErr. The error it gave was %@.", [error localizedDescription]);
    
    NSString *dictionaryPath = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:requestedName];
    NSString *lmPath = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:requestedName];   
    
    XCTAssert([[NSFileManager defaultManager] fileExistsAtPath:dictionaryPath], @"There is no .dic file at the requested dic path");
    XCTAssert([[NSFileManager defaultManager] fileExistsAtPath:lmPath], @"There is no .languagemodel file at the requested lm path");   
    
    NSError *fileToStringError = nil;
    NSString *importedDicFileAsString = [NSString stringWithContentsOfFile:dictionaryPath encoding:NSUTF8StringEncoding error:&fileToStringError];
    if(fileToStringError) NSLog(@"Error while converting dictionary file to string: %@", error);
    
    fileToStringError = nil;    
    NSString *importedLMFileAsString = [NSString stringWithContentsOfFile:[lmPath stringByReplacingOccurrencesOfString:@".DMP" withString:@".arpa"] encoding:NSUTF8StringEncoding error:&fileToStringError];    
    if(fileToStringError) NSLog(@"Error while converting lm file to string: %@", error);
        
    NSString *dictionaryComparisonString = [NSString stringWithContentsOfFile:[[OETestTools environmentAppropriateBundle] pathForResource:@"Sherlock" ofType:@"dic"] encoding:NSUTF8StringEncoding error:&fileToStringError];
    NSString *lmComparisonString = [NSString stringWithContentsOfFile:[[OETestTools environmentAppropriateBundle] pathForResource:@"Sherlock" ofType:@"arpa"] encoding:NSUTF8StringEncoding error:&fileToStringError];
    
    XCTAssert([importedDicFileAsString isEqualToString:dictionaryComparisonString], @"The contents of the dictionary file do not match what is expected.");
    XCTAssert([importedLMFileAsString isEqualToString:lmComparisonString], @"The contents of the lm file do not match what is expected.");     // I don't want to set the world on fire/I just want to see if this file has some signs of normalcy
}



- (void) testEnglishLanguageModelGenerationOfMultipleWords {

    NSString *requestedName = @"WordLanguageModel";
    NSString *pathToAcousticModel = [[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"];
    
    OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    NSError *error = [languageModelGenerator generateLanguageModelFromArray:@[@"WORD", @"ANOTHER"] withFilesNamed:requestedName forAcousticModelAtPath:pathToAcousticModel];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a one-word LM without returning an error which isn't noErr.");
    
    NSString *dictionaryPath = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:requestedName];
    NSString *lmPath = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:requestedName]; 
    
    XCTAssert([[NSFileManager defaultManager] fileExistsAtPath:dictionaryPath], @"There is no .dic file at the requested dic path");
    XCTAssert([[NSFileManager defaultManager] fileExistsAtPath:lmPath], @"There is no .languagemodel file at the requested lm path");   
    
    NSError *fileToStringError = nil;
    NSString *importedDicFileAsString = [NSString stringWithContentsOfFile:dictionaryPath encoding:NSUTF8StringEncoding error:&fileToStringError];
    if(fileToStringError) NSLog(@"Error while converting dictionary file to string: %@", error);
    
    fileToStringError = nil;    
    NSString *importedLMFileAsString = [NSString stringWithContentsOfFile:[lmPath stringByReplacingOccurrencesOfString:@".DMP" withString:@".arpa"] encoding:NSUTF8StringEncoding error:&fileToStringError];    
    if(fileToStringError) NSLog(@"Error while converting lm file to string: %@", error);
   
    NSString *dictionaryComparisonString = @"ANOTHER	AH N AH DH ER\nWORD	W ER D\n";
    NSString *lmComparisonString = @"<s> WORD 0.0000";
    
    XCTAssert([importedDicFileAsString isEqualToString:dictionaryComparisonString], @"The contents of the dictionary file do not match what is expected.");
    XCTAssert([importedLMFileAsString rangeOfString:lmComparisonString].location != NSNotFound, @"The contents of the lm file do not match what is expected.");     // I don't want to set the world on fire/I just want to see if this file has some signs of normalcy
    
}

- (void) testEnglishLanguageModelGenerationOfOneWord {
    
    
    NSString *pathToAcousticModel = [[OETestTools environmentAppropriateBundle] pathForResource:@"AcousticModelEnglish" ofType:@"bundle"];
    
    OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    
    NSString *requestedName = @"WordLanguageModel";
    
    
    
    NSError *error = [languageModelGenerator generateLanguageModelFromArray:@[@"WORD"] withFilesNamed:requestedName forAcousticModelAtPath:pathToAcousticModel];
    
    XCTAssert(error.code == noErr, @"generateLanguageModelFromArray couldn't create a one-word LM without returning an error which isn't noErr.");
    
    NSString *dictionaryPath = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:requestedName];
    NSString *lmPath = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:requestedName];   
    
    XCTAssert([[NSFileManager defaultManager] fileExistsAtPath:dictionaryPath], @"There is no .dic file at the requested dic path");
    XCTAssert([[NSFileManager defaultManager] fileExistsAtPath:lmPath], @"There is no .languagemodel file at the requested lm path");   
    
    NSError *fileToStringError = nil;
    NSString *importedDicFileAsString = [NSString stringWithContentsOfFile:dictionaryPath encoding:NSUTF8StringEncoding error:&fileToStringError];
    if(fileToStringError) NSLog(@"Error while converting dictionary file to string: %@", error);
    
    fileToStringError = nil;    
    NSString *importedLMFileAsString = [NSString stringWithContentsOfFile:[lmPath stringByReplacingOccurrencesOfString:@".DMP" withString:@".arpa"] encoding:NSUTF8StringEncoding error:&fileToStringError];    
    if(fileToStringError) NSLog(@"Error while converting lm file to string: %@", error);
    
    NSString *dictionaryComparisonString = @"WORD	W ER D\n";
    NSString *lmComparisonString = @"<s> WORD 0.0000";
    
    XCTAssert([importedDicFileAsString isEqualToString:dictionaryComparisonString], @"The contents of the dictionary file do not match what is expected.");
    XCTAssert([importedLMFileAsString rangeOfString:lmComparisonString].location != NSNotFound, @"The contents of the lm file do not match what is expected.");     // I don't want to set the world on fire/I just want to see if this file has some signs of normalcy
    
}
/*
- (void)testPerformanceEnglishLanguageModelGeneration {
    // Language model performance test case.
    [self measureBlock:^{

    }];
}*/

@end
