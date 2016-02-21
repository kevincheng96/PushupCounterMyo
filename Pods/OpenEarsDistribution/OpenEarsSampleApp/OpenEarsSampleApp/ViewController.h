//  ViewController.h
//  OpenEarsSampleApp
//
//  ViewController.h demonstrates the use of the OpenEars framework. 
//
//  Copyright Politepix UG (haftungsbeschränkt) 2014. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  This file is licensed under the Politepix Shared Source license found in the root of the source distribution.

// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************
// IMPORTANT NOTE: Audio driver and hardware behavior is completely different between the Simulator and a real device. It is not informative to test OpenEars' accuracy on the Simulator, and please do not report Simulator-only bugs since I only actively support 
// the device driver. Please only do testing/bug reporting based on results on a real device such as an iPhone or iPod Touch. Thanks!
// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************

#import <UIKit/UIKit.h>

#import <OpenEars/OEEventsObserver.h> // We need to import this here in order to use the delegate.

@interface ViewController : UIViewController <OEEventsObserverDelegate> // This is how we implement the delegate protocol of OEEventsObserver.

@end

