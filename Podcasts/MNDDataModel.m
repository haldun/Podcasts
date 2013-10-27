//
//  MNDDataModel.m
//  Podcasts
//
//  Created by Haldun Bayhantopcu on 24/10/13.
//  Copyright (c) 2013 monoid. All rights reserved.
//

#import "MNDDataModel.h"

@interface MNDDataModel ()

@property (strong, nonatomic) NSManagedObjectContext *mainContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;

@end

@implementation MNDDataModel

+ (instancetype)sharedDataModel
{
  static MNDDataModel *dataModel;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dataModel = [[MNDDataModel alloc] init];
  });
  return dataModel;
}

- (NSManagedObjectContext *)mainContext
{
  if (!_mainContext) {
    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
  }
  return _mainContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
  if (!_persistentStoreCoordinator) {
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSString *dbFilename = @"db.sqlite3";
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pathToLocalStore = [documentsDirectory stringByAppendingPathComponent:dbFilename];
    NSURL *dbUrl = [NSURL fileURLWithPath:pathToLocalStore];
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES
                              };
    NSError *error;
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:dbUrl
                                                         options:options
                                                           error:&error]) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:NSUnderlyingErrorKey];
      NSString *reason = @"Could not create persistent store.";
      NSException *exc = [NSException exceptionWithName:NSInternalInconsistencyException
                                                 reason:reason
                                               userInfo:userInfo];
      NSLog(@"%@", error);
      @throw exc;
    }
  }
  
  return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
  if (!_managedObjectModel) {
    NSString *pathToModel = [[NSBundle mainBundle] pathForResource:@"Podcasts" ofType:@"momd"];
    NSURL *storeUrl = [NSURL fileURLWithPath:pathToModel];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:storeUrl];
  }
  return _managedObjectModel;
}

@end
