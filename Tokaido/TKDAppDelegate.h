//
//  TKDAppDelegate.h
//  Tokaido
//
//  Created by Mucho Besos on 10/23/12.
//  Copyright (c) 2012 Tilde. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TKDTokaidoController.h"

extern NSString *const TKDDidFinishInstallingSandboxNotification;
extern NSString *const kTKDInstalledRubyVersion;

@interface TKDAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet TKDTokaidoController *tokaidoController;

// TODO: Move those to TKDDirectories or something
+ (NSString *)tokaidoInstalledGemsDirectory;
+ (NSString *)tokaidoInstalledRubiesDirectory;
+ (NSString *)tokaidoInstalledBootstrapDirectory;
+ (NSString *)tokaidoInstalledBinDirectory;
+ (NSString *)tokaidoInstalledFirewallDirectory;
+ (NSString *)tokaidoMuxrSocketPath;
+ (NSString *)tokaidoBundledRubiesDirectory;
+ (NSString *)tokaidoBundledGemsFile;
+ (NSString *)tokaidoBundledBootstrapFile;
+ (NSString *)tokaidoAppSupportDirectory;

- (void) openTerminalWithPath:(NSString *)path;

- (void) saveAppSettings;

@end
