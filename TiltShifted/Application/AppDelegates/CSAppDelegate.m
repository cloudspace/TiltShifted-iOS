//
//  CSAppDelegate.m
//  TiltShifted
//
//  Created by Joseph Lorich on 4/1/13.
//  Copyright (c) 2013 Cloudspace. All rights reserved.
//
// Frameworks
#import <TestFlight.h>
#import <Crashlytics/Crashlytics.h>
#import "GAI.h"
#import "Appirater.h"

// Project
#import "CSAppDelegate.h"
#import "CSRootViewController.h"


@implementation CSAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
  //
  // Set up framework information
  //
  
  // Test Flight
  [TestFlight takeOff:@"546848a3-2ef8-4aec-b742-1d4b984170a0"];
  
  // Crashlytics
  [Crashlytics startWithAPIKey:@"9134f663abb42ba17c65ca0ee9fe3e7d74e427c2"];
  
  // Appirater
  [Appirater setAppId:@"674187263"];
  [Appirater setDaysUntilPrompt:3];
  [Appirater setUsesUntilPrompt:10];
  [Appirater setSignificantEventsUntilPrompt:3];
  [Appirater setTimeBeforeReminding:2];
  [Appirater setDebug:NO];
  
  // Google Analytics
  [GAI sharedInstance].trackUncaughtExceptions = YES;
  [GAI sharedInstance].dispatchInterval = 20;
  [GAI sharedInstance].debug = YES;
  [[GAI sharedInstance] trackerWithTrackingId:@"UA-5089710-7"];

  //
  // Set up window
  //
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
  // Set up root view controller
  CSRootViewController *rootVC = [[CSRootViewController alloc] init];
  
  self.window.rootViewController = rootVC;
  [self.window makeKeyAndVisible];

  //
  // Call Appirater
  //
  [Appirater appLaunched:YES];
  
  return YES;
}


@end
