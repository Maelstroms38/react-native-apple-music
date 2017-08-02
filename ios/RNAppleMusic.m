#import "RNAppleMusic.h"
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>

@interface RNAppleMusic () <MPMediaPickerControllerDelegate>
@property (nonatomic, strong) MPMediaItemCollection *playlist;
@property (nonatomic, strong) MPMusicPlayerController *player;
@property (nonatomic, assign) BOOL *hasListeners;

@end

@implementation RNAppleMusic

@synthesize hasListeners = _hasListeners;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()
- (NSArray<NSString *> *)supportedEvents {
    NSString *AppleMusicResponse = @"AppleMusicResponse";
    return @[AppleMusicResponse];
}
RCT_EXPORT_METHOD(addMusic)
{
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.prompt = @"Add music to your playlist";
    mediaPicker.showsCloudItems = NO;
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = YES;
    self.rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    // init the webView with the loginURL
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Present the webView over the rootView
        [self.rootViewController presentViewController: mediaPicker animated:YES completion:nil];
    });
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    if (!self.hasListeners) {
        [self startObservingAppleMusic];
        [center addObserverForName:@"AppleMusicResponse" object:nil queue:nil usingBlock:^(NSNotification *notification) {
            [self handleNotification:notification];
        }];
    }
}

#pragma mark - MPMediaPickerControllerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.playlist.count + mediaItemCollection.count];
    [items addObjectsFromArray:self.playlist.items];
    [items addObjectsFromArray:mediaItemCollection.items];
    MPMediaItemCollection *collection = [MPMediaItemCollection collectionWithItems:items];
    
    self.playlist = collection;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSMutableDictionary *loginRes =  [NSMutableDictionary dictionary];
    loginRes[@"tracks"] = collection;
    [center postNotificationName:@"AppleMusicResponse" object:self userInfo:loginRes];
    
    int index = 1;
    for (MPMediaItem *item in self.playlist.items) {
        NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
    }
    
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSMutableDictionary *loginRes =  [NSMutableDictionary dictionary];
    loginRes[@"error"] = @"Selection cancelled.";
    [center postNotificationName:@"AppleMusicResponse" object:self userInfo:loginRes];
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Notification handlers

// Will be called when this module's first listener is added.
-(void)startObservingAppleMusic {
    self.hasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObservingAppleMusic {
    self.hasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}

- (void)handleNotification:(NSNotification *)notification {
    if (self.hasListeners) { // Only send events if anyone is listening
        //NSLog(@"Name: %@, Object: %@", notification.name, notification.userInfo);
        [self sendEventWithName:notification.name body:notification.userInfo];
    }
}
@end
