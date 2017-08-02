#import <Foundation/Foundation.h>
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#import "RCTEventEmitter.h"
#import "RCTConvert.h"
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTConvert.h>
#endif

@interface RNAppleMusic : RCTEventEmitter <RCTBridgeModule>
@property (nonatomic, strong) UIViewController *rootViewController;
@end
