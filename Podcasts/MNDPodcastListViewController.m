//
//  MNDPodcastListViewController.m
//  Podcasts
//
//  Created by Haldun Bayhantopcu on 24/10/13.
//  Copyright (c) 2013 monoid. All rights reserved.
//

#import "MNDPodcastListViewController.h"
#import "MNDDataModel.h"
#import "MNDPodcast.h"
#import "MNDPlayerViewController.h"
#import "MNDPodcastCell.h"

@interface MNDPodcastListViewController () <NSFetchedResultsControllerDelegate, NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSString *podcastsDirectoryPath;
@property (strong, nonatomic) NSCache *downloadTasks;

@end

@implementation MNDPodcastListViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.downloadTasks = [[NSCache alloc] init];
  [self fetchPodcasts];
}

- (void)fetchPodcasts
{
  NSError *error = nil;
  [self.fetchedResultsController performFetch:&error];
  
  if (error) {
    BLog(@"error: %@", error);
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleBackgroundTransfer:)
                                               name:@"BackgroundTransferNotification"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(managedObjectContextDidSaved:)
                                               name:NSManagedObjectContextDidSaveNotification
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)managedObjectContextDidSaved:(NSNotification *)notification
{
  NSManagedObjectContext *myContext = self.fetchedResultsController.managedObjectContext;
  NSManagedObjectContext *context = notification.object;
  
  if (context != myContext && context.persistentStoreCoordinator == myContext.persistentStoreCoordinator) {
    [myContext mergeChangesFromContextDidSaveNotification:notification];
  }
}

- (void)handleBackgroundTransfer:(NSNotification *)notification
{
  BLog();
  NSString *sessionIdentifier = notification.userInfo[@"sessionIdentifier"];
  NSNumber *podcastIdentifier = [self podcastIdentifierFromSessionIdentifier:sessionIdentifier];
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Podcast"];
  fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", podcastIdentifier];
  fetchRequest.fetchLimit = 1;
  
  NSError *error = nil;
  NSArray *podcasts = [self.fetchedResultsController.managedObjectContext executeFetchRequest:fetchRequest error:&error];
  
  if (error) {
    BLog(@"error: %@", error);
  } else {
    MNDPodcast *podcast = [podcasts firstObject];
    if (podcast) {
      podcast.state = @"Downloaded";
      [self.fetchedResultsController.managedObjectContext save:&error];
      
      if (error) {
        BLog(@"error: %@", error);
      }
    }
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    void (^completionHandler)(void) = notification.userInfo[@"completionHandler"];
    if (completionHandler) {
      completionHandler();
    }
  });
}

- (NSFetchedResultsController *)fetchedResultsController
{
  if (!_fetchedResultsController) {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Podcast"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:[[MNDDataModel sharedDataModel] mainContext]
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;
  }
  return _fetchedResultsController;
}

- (IBAction)downloadTapped:(id)sender
{
  CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
  MNDPodcast *podcast = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  if ([podcast.state isEqualToString:@"NotStarted"]) {
    [self startDownloadForPodcast:podcast];
  }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  BLog();
  [self.tableView reloadData];
}

- (IBAction)deleteAllTapped:(id)sender
{
  NSManagedObjectContext *context = [[MNDDataModel sharedDataModel] mainContext];
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Podcast"];
  NSError *error = nil;
  NSArray *podcasts = [context executeFetchRequest:fetchRequest error:&error];
  
  if (error) {
    BLog(@"error: %@", error);
    return;
  }
  
  for (NSManagedObject *podcast in podcasts) {
    [context deleteObject:podcast];
  }
  
  [context save:&error];
  
  if (error) {
    BLog(@"error: %@", error);
  }
}

- (IBAction)createSeedTapped:(id)sender
{
  NSArray *urls = @[@"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08062012.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08072011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08082011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08082013.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM0809.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM0810.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08102013.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM09092011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM09102012.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM09112011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM10062011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM10072012.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08062012.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08072011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08082011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08082013.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM0809.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM0810.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM08102013.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM09092011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM09102012.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM09112011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM10062011.mp3",
                    @"http://asset.powerfm.com.tr/CenkErdem/podcast/CENKERDEM10072012.mp3",];
  NSManagedObjectContext *context = [[MNDDataModel sharedDataModel] mainContext];
  
  [urls enumerateObjectsUsingBlock:^(NSString *url, NSUInteger index, BOOL *stop) {
    NSString *title = [[[[url componentsSeparatedByString:@"/"] lastObject] componentsSeparatedByString:@"."] firstObject];
    NSNumber *identifier = @(index + 1);
    
    MNDPodcast *podcast = [NSEntityDescription insertNewObjectForEntityForName:@"Podcast" inManagedObjectContext:context];
    podcast.remoteUrl = url;
    podcast.title = title;
    podcast.identifier = identifier;
  }];
  
  NSError *error = nil;
  [context save:&error];
  
  if (error) {
    BLog(@"error: %@", error);
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  id sectionInfo = self.fetchedResultsController.sections[section];
  return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"PodcastCell";
  MNDPodcastCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  MNDPodcast *podcast = [self.fetchedResultsController objectAtIndexPath:indexPath];
  cell.titleLabel.text = podcast.title;
  cell.subtitleLabel.text = @"";
  
  if ([podcast.state isEqualToString:@"Downloading"]) {
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ of %@",
                                 [NSByteCountFormatter stringFromByteCount:[podcast.totalBytesWritten longLongValue] countStyle:NSByteCountFormatterCountStyleFile],
                                 [NSByteCountFormatter stringFromByteCount:[podcast.totalBytesExpectedToWrite longLongValue] countStyle:NSByteCountFormatterCountStyleFile]];
    cell.downloadButton.hidden = YES;
  }
  
  if ([podcast.state isEqualToString:@"Waiting"] || [podcast.state isEqualToString:@"Downloaded"]) {
    cell.subtitleLabel.text = podcast.state;
    cell.downloadButton.hidden = YES;
  }
  
  if ([podcast.state isEqualToString:@"NotStarted"]) {
    cell.downloadButton.hidden = NO;
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  MNDPodcast *podcast = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  if ([podcast.state isEqualToString:@"Downloaded"]) {
    [self performSegueWithIdentifier:@"PlayPodcast" sender:podcast];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"PlayPodcast"] && [segue.destinationViewController isKindOfClass:[MNDPlayerViewController class]]) {
    MNDPlayerViewController *playerViewController = segue.destinationViewController;
    playerViewController.podcast = (MNDPodcast *)sender;
  }
}

- (NSString *)sessionIdentifierForPodcast:(MNDPodcast *)podcast
{
  return [NSString stringWithFormat:@"co.monoid.podcasts.backgroundsession.%@", podcast.identifier];
}

- (NSNumber *)podcastIdentifierFromSessionIdentifier:(NSString *)sessionIdentifier
{
  NSArray *parts = [sessionIdentifier componentsSeparatedByString:@"."];
  return @([[parts lastObject] integerValue]);
}

- (void)startDownloadForPodcast:(MNDPodcast *)podcast
{
  BLog();
  
  // Start download task
  NSString *sessionIdentifier = [self sessionIdentifierForPodcast:podcast];
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionIdentifier];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
  NSURL *url = [NSURL URLWithString:podcast.remoteUrl];
  NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];
  [downloadTask resume];
  
  [self.downloadTasks setObject:downloadTask forKey:podcast.identifier];
  
  // Update podcast
  podcast.state = @"Waiting";
  NSError *error = nil;
  [podcast.managedObjectContext save:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
  
}

- (NSString *)podcastsDirectoryPath
{
  if (!_podcastsDirectoryPath) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _podcastsDirectoryPath = [[paths firstObject] stringByAppendingPathComponent:@"co.monoid.podcasts"];
    BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:_podcastsDirectoryPath];
    
    if (!directoryExists) {
      NSError *error = nil;
      
      if (![[NSFileManager defaultManager] createDirectoryAtPath:_podcastsDirectoryPath
                                     withIntermediateDirectories:NO
                                                      attributes:nil
                                                           error:&error]) {
        // TODO Handle data here
      }
      
      if (error) {
        BLog(@"error: %@", error);
      }
    }
  }
  return _podcastsDirectoryPath;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
  BLog();
  
  NSString *lastPathComponent = [downloadTask.originalRequest.URL lastPathComponent];
  NSString *destinationPath = [self.podcastsDirectoryPath stringByAppendingPathComponent:lastPathComponent];
  NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
  
  BLog(@"%@", destinationURL);
  
  NSError *error = nil;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
    [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
    if (error) {
      BLog(@"error: %@", error);
    }
  }
  
  BOOL copySuccesful = [[NSFileManager defaultManager] copyItemAtURL:location toURL:destinationURL error:&error];
  
  if (!copySuccesful) {
    BLog(@"Cannot copy file");
    if (error) {
      NSLog(@"error: %@", error);
      return;
    }
  }
  
  NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  context.persistentStoreCoordinator = self.fetchedResultsController.managedObjectContext.persistentStoreCoordinator;
  
  NSString *sessionIdentifier = session.configuration.identifier;
  NSNumber *podcastIdentifier = [self podcastIdentifierFromSessionIdentifier:sessionIdentifier];
  
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Podcast"];
  fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", podcastIdentifier];
  fetchRequest.fetchLimit = 1;
  
  NSArray *podcasts = [context executeFetchRequest:fetchRequest error:&error];
  
  if (error) {
    BLog(@"error: %@", error);
    return;
  }
  
  MNDPodcast *podcast = [podcasts firstObject];
  
  if (podcast) {
    podcast.state = @"Downloaded";
    podcast.localUrl = [destinationURL absoluteString];
    NSError *error = nil;
    [context save:&error];
    
    if (error) {
      BLog(@"error: %@", error);
    }
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  context.persistentStoreCoordinator = self.fetchedResultsController.managedObjectContext.persistentStoreCoordinator;
  
  NSString *sessionIdentifier = session.configuration.identifier;
  NSNumber *podcastIdentifier = [self podcastIdentifierFromSessionIdentifier:sessionIdentifier];
  
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Podcast"];
  fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", podcastIdentifier];
  fetchRequest.fetchLimit = 1;
  
  NSError *error = nil;
  NSArray *podcasts = [context executeFetchRequest:fetchRequest error:&error];
  
  if (error) {
    BLog(@"error: %@", error);
  } else {
    MNDPodcast *podcast = [podcasts firstObject];
//    BLog(@"%@: %4.2f", podcast.title, 100.0 * (double)totalBytesWritten / (double)totalBytesExpectedToWrite);
    podcast.state = @"Downloading";
    podcast.totalBytesWritten = @(totalBytesWritten);
    podcast.totalBytesExpectedToWrite = @(totalBytesExpectedToWrite);
    
    [context save:&error];
    
    if (error) {
      BLog(@"error: %@", error);
    }
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
  BLog();
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  BLog(@"didCompleteError: %@", error);
}

@end
