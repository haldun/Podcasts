//
//  MNDAppDelegate.m
//  Podcasts
//
//  Created by Haldun Bayhantopcu on 24/10/13.
//  Copyright (c) 2013 monoid. All rights reserved.
//

#import "MNDAppDelegate.h"

@implementation MNDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
  NSDictionary *userInfo = @{@"completionHandler": completionHandler,
                             @"sessionIdentifier": identifier};
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BackgroundTransferNotification"
                                                      object:nil
                                                    userInfo:userInfo];
}

@end
