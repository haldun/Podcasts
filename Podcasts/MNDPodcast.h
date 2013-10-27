//
//  MNDPodcast.h
//  Podcasts
//
//  Created by Haldun Bayhantopcu on 24/10/13.
//  Copyright (c) 2013 monoid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MNDPodcast : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSNumber * totalBytesWritten;
@property (nonatomic, retain) NSNumber * totalBytesExpectedToWrite;
@property (nonatomic, retain) NSString * remoteUrl;
@property (nonatomic, retain) NSString * localUrl;

@end
