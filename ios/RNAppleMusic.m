#import "RNAppleMusic.h"
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
#import <StoreKit/StoreKit.h>

@interface RNAppleMusic () <MPMediaPickerControllerDelegate>
@property (nonatomic, strong) MPMediaItemCollection *playlist;
@property (nonatomic, strong) MPMusicPlayerController *player;
@property (nonatomic, strong) MPMediaPlaylist *mediaPlaylist;
@property (nonatomic, assign) NSString *playlistString;
@property (nonatomic, assign) BOOL *hasListeners;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *regionCode;
@property (nonatomic, strong) SKCloudServiceController *cloudController;
@property (nonatomic, assign) SKCloudServiceCapability *cloudCapability;
@property (nonatomic, assign) SKCloudServiceAuthorizationStatus *status;

@end

@implementation RNAppleMusic

@synthesize hasListeners = _hasListeners;

/// The base URL for all Apple Music API network calls.
NSString *appleMusicAPIBaseURLString = @"api.music.apple.com";

/// The Apple Music API endpoint for requesting a list of recently played items.
NSString *recentlyPlayedPathURLString = @"/v1/me/recent/played";

/// The Apple Music API endpoint for requesting the storefront of the currently logged in iTunes Store account.
NSString *userStorefrontPathURLString = @"/v1/me/storefront";

/// The Apple Music API endpoint for requesting the playlists of the currently logged in iTunes Store account.
NSString *userPlaylistsPathURLString = @"/v1/me/playlists";

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
-(void)setAuthToken:(NSString *)authToken {
    _authToken = authToken;
}
-(void)setUserToken:(NSString *)userToken {
    _userToken = userToken;
}
-(void)setRegionCode:(NSString *)regionCode {
    _regionCode = regionCode;
}
-(void)setCountryCode:(NSString *)countryCode {
    _countryCode = countryCode;
}
-(void)setCloudController:(SKCloudServiceController *)cloudController {
    _cloudController = cloudController;
}
-(void)setCloudCapability:(SKCloudServiceCapability *)cloudCapability {
    _cloudCapability = cloudCapability;
}
+ (id)sharedManager {
    static RNAppleMusic *sharedMyManager = nil;
    @synchronized(self) {
        if (sharedMyManager == nil)
            sharedMyManager = [[self alloc] init];
    }
    return sharedMyManager;
}
-(void)requestCloudServiceAuthorization {
    //if (self.status != SKCloudServiceAuthorizationStatusAuthorized) {
    [SKCloudServiceController requestAuthorization:^(SKCloudServiceAuthorizationStatus status) {
        switch (status) {
            case SKCloudServiceAuthorizationStatusDenied:
                break;
            case SKCloudServiceAuthorizationStatusRestricted:
                break;
            case SKCloudServiceAuthorizationStatusAuthorized:
                //Woo! We can makes requests to Apple Music.
                self.status = &(status);
                [self requestCloudServiceCapabilities];
                break;
            default:
                break;
        }
    }];
    //}
}
-(void)requestCloudServiceCapabilities {
    [self.cloudController requestCapabilitiesWithCompletionHandler:^(SKCloudServiceCapability capabilities, NSError * _Nullable error) {
        if (error == nil) {
            self.cloudCapability = &(capabilities);
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}
RCT_EXPORT_MODULE()
- (NSArray<NSString *> *)supportedEvents {
    NSString *AppleMusicResponse = @"AppleMusicResponse";
    return @[AppleMusicResponse];
}
- (NSString *)fetchDeveloperToken {
    //We will need to fetch token using a server script (see https://clients.dodoapps.io/playlist-precis/generate-token.php) as an example.
    return @"eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjcyUkU0NDc3WVkifQ.eyJpc3MiOiIyNEU3Vkg0MzQ3IiwiaWF0IjoxNTAyMjA0ODI3LCJleHAiOjE1MDIyNDgwMjd9.8BOm4QIykH0ovRHhrvY8_AIHpIfFphGeXV3gzJopX3t2ilIVIqHZ963pEbbtZ8cyxiBgO8kfajqIKgmLpYd_ZA";
}
RCT_EXPORT_METHOD(fetchUserToken) {
    SKCloudServiceController *cloud = [[SKCloudServiceController alloc] init];
    [self setCloudController:cloud];
    [self requestCloudServiceAuthorization];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (!self.hasListeners) {
        [self createPlaylistIfNeeded];
        [self startObservingAppleMusic];
        [center addObserverForName:@"AppleMusicResponse" object:nil queue:nil usingBlock:^(NSNotification *notification) {
            [self handleNotification:notification];
        }];
    }
    NSMutableDictionary *loginRes =  [NSMutableDictionary dictionary];
    //Write request to apple music api for user token.
    NSString *devToken = [self fetchDeveloperToken];
    if (@available(iOS 11.0, *)) {
        [[self cloudController] requestUserTokenForDeveloperToken:devToken completionHandler:^(NSString *userToken, NSError *error) {
            if (error == nil && userToken != nil) {
                NSLog(@"%@", userToken);
                loginRes[@"user_token"] = userToken;
                loginRes[@"dev_token"] = devToken;
                [center postNotificationName:@"AppleMusicResponse" object:self userInfo:loginRes];
            } else {
                NSLog(@"%@", error.debugDescription);
                loginRes[@"error"] = @"Error fetching user token";
                [center postNotificationName:@"AppleMusicResponse" object:self userInfo:loginRes];
            }
        }];
    } else {
        [[self cloudController] requestPersonalizationTokenForClientToken: devToken withCompletionHandler:^(NSString *personalizationToken, NSError *error) {
            if (error == nil && personalizationToken != nil) {
                NSLog(@"%@", personalizationToken);
                loginRes[@"user_token"] = personalizationToken;
                loginRes[@"dev_token"] = devToken;
                [center postNotificationName:@"AppleMusicResponse" object:self userInfo:loginRes];
            } else {
                NSLog(@"%@", error.localizedDescription);
                loginRes[@"error"] = error.localizedDescription;
                [center postNotificationName:@"AppleMusicResponse" object:self userInfo:loginRes];
            }
        }];
    }
}
-(void)fetchStoreFront {
    //NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //NSMutableDictionary *loginRes =  [NSMutableDictionary dictionary];
    //Write request to apple music api for user token.
    //    if (@available(iOS 11.0, *)) {
    //        [self.cloudController requestStorefrontCountryCodeWithCompletionHandler:^(NSString *storefrontCountryCode, NSError *error) {
    //            if (error == nil) {
    //                self.countryCode = storefrontCountryCode;
    //            } else {
    //                NSLog(@"%@", error.localizedDescription);
    //            }
    //        }];
    //    } else {
    NSURL *baseUrl = [[NSURL alloc] initWithString:@"https://api.music.apple.com/v1/me/storefront"];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL: baseUrl];
    req.HTTPMethod = @"GET";
    NSMutableString *bearer = [[NSMutableString alloc] initWithString:@"Bearer "];
    [bearer appendString:[self fetchDeveloperToken]];
    [req addValue:bearer forHTTPHeaderField:@"Authorization"];
    [req addValue:self.userToken forHTTPHeaderField:@"Music-User-Token"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Peform the request
        NSURLResponse *response;
        NSError *error = nil;
        NSData *receivedData = [NSURLConnection sendSynchronousRequest:req                                                         returningResponse:&response
                                                                 error:&error];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (error) {
            // Deal with your error
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSLog(@"HTTP Error: %ld %@", (long)httpResponse.statusCode, error);
                return;
            }
            NSLog(@"Error %@", error);
            return;
        }
        if ((long)httpResponse.statusCode == 200) {
            NSArray *dict = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingAllowFragments error:&error];
            NSLog(@"%@", dict);
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    });
    //  }
}
RCT_EXPORT_METHOD(addMusic) {
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.prompt = @"Add music to your playlist";
    mediaPicker.showsCloudItems = YES;
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
        [self createPlaylistIfNeeded];
        [self startObservingAppleMusic];
        [center addObserverForName:@"AppleMusicResponse" object:nil queue:nil usingBlock:^(NSNotification *notification) {
            [self handleNotification:notification];
        }];
    }
}
-(void)createPlaylistIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    
    if (self.mediaPlaylist != nil) {
        if ([defaults stringForKey:@"playlistUUIDKey"] != nil) {
            // In this case, the sample already created a playlist in a previous run.  In this case we lookup the UUID that was used before.
            uuidString = [defaults stringForKey:@"playlistUUIDKey"];
            NSLog(@"%@", uuidString);
        }
        self.playlistString = uuidString;
    } else {
        // Create an instance of `MPMediaPlaylistCreationMetadata`, this represents the metadata to associate with the new playlist.
        MPMediaPlaylistCreationMetadata *meta = [[MPMediaPlaylistCreationMetadata alloc] initWithName:@"Playlistt"];
        meta.descriptionText = @"Created using Playlistt.";
        [defaults setValue:uuidString forKey:@"playlistUUIDKey"];
        [defaults synchronize];
        // Request the new or existing playlist from the device.
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[defaults valueForKey:@"playlistUUIDKey"]];
        [[MPMediaLibrary defaultMediaLibrary] getPlaylistWithUUID: uuid creationMetadata:meta completionHandler:^(MPMediaPlaylist *playlist, NSError *error) {
            if (error == nil && playlist != nil) {
                self.mediaPlaylist = playlist;
            } else {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
}
-(void)addItemsToPlaylist:(MPMediaItemCollection *)mediaItemCollection {
    if (self.mediaPlaylist != nil && mediaItemCollection.items.count > 0) {
        [self.mediaPlaylist addMediaItems:mediaItemCollection.items completionHandler:^(NSError * _Nullable error) {
            if (error == nil) {
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                NSMutableDictionary *playlistRes =  [NSMutableDictionary dictionary];
                playlistRes[@"playlist"] = mediaItemCollection.items;
                [center postNotificationName:@"AppleMusicResponse" object:nil userInfo:playlistRes];
            } else {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    } else {
        NSLog(@"Not enough songs to create playlist.");
    }
}

#pragma mark - MPMediaPickerControllerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    //    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.playlist.count + mediaItemCollection.count];
    //    [items addObjectsFromArray:self.playlist.items];
    //    [items addObjectsFromArray:mediaItemCollection.items];
    //    MPMediaItemCollection *collection = [MPMediaItemCollection collectionWithItems:items];
    //
    //    self.playlist = collection;
    
    [self addItemsToPlaylist:mediaItemCollection];
    
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    //NSLog(@"%@", NSStringFromSelector(_cmd));
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
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:SKCloudServiceCapabilitiesDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
        [self requestCloudServiceCapabilities];
    }];
    //    if (@available(iOS 11.0, *)) {
    //        [center addObserverForName:SKStorefrontCountryCodeDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
    //            [self requestCloudServiceCapabilities];
    //        }];
    //    }
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

