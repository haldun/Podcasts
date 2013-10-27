//
//  MNDDataModel.h
//  Podcasts
//
//  Created by Haldun Bayhantopcu on 24/10/13.
//  Copyright (c) 2013 monoid. All rights reserved.
//

@import CoreData;

@interface MNDDataModel : NSObject

@property (readonly, nonatomic) NSManagedObjectContext *mainContext;
@property (readonly, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (instancetype)sharedDataModel;

@end
