//
//  TKDAppDelegate.m
//  Tokaido
//
//  Created by Mucho Besos on 10/23/12.
//  Copyright (c) 2012 Tilde. All rights reserved.
//

#import "TKDAppDelegate.h"
#import "Terminal.h"

#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

// plist replacement constants
static NSString * const kTokaidoBootstrapFirewallPlistCommandString = @"TOKAIDO_FIREWALL_COMMAND";
static NSString * const kTokaidoBootstrapFirewallPlistTmpDir = @"TOKAIDO_FIREWALL_TMPDIR";
static NSString * const kTokaidoBootstrapFirewallPlistSetupString = @"TOKAIDO_FIREWALL_SETUP";
static NSString * const kTokaidoBootstrapFirewallPlistScriptString = @"TOKAIDO_FIREWALL_SCRIPT";

// tokaido-bootstrap label
static NSString * const kTokaidoBootstrapLabel = @"io.tilde.tokaido.bootstrap";


typedef enum : u_int16_t {
    k_tkd_error_could_not_create_sandbox_dir
} TKDErrorCondition;

@interface TKDAppDelegate ()

@property (nonatomic, copy, readonly) NSString *calabashDirUUID;

- (void) handleErrorCondition:(TKDErrorCondition) aErrorCondition
                        error:(NSError *) aError;

@end


@implementation TKDAppDelegate

@synthesize calabashDirUUID = _calabashDirUUID;

- (NSString *) calabashDirUUID {
    if (_calabashDirUUID != nil) { return _calabashDirUUID; }
    _calabashDirUUID =  [[NSUUID UUID] UUIDString];
    return _calabashDirUUID;
}

- (void) handleErrorCondition:(TKDErrorCondition) aErrorCondition
                        error:(NSError *)aError {
    NSLog(@"ERROR: '%d' - nothing to do (yet)", aErrorCondition);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self ensureTokaidoAppSupportDirectoryIsUpToDate];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    
}

#pragma mark Launch Steps


- (void) ensureTokaidoAppSupportDirectoryIsUpToDate
{
    
    /*** TODO ***
     we can probably remove a bunch of this
     ************/
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Go through the ruby bundles already in our app support directory
    // and create a list of already installed rubies.
    NSString *installedRubiesDirectory = [TKDAppDelegate tokaidoInstalledRubiesDirectory];
    NSMutableSet *installedRubies = [NSMutableSet set];
    
    NSDirectoryEnumerator *installedRubiesEnum = [fm enumeratorAtPath:installedRubiesDirectory];
    NSString *installedFile;
    while (installedFile = [installedRubiesEnum nextObject]) {
        BOOL isDirectory = NO;
        NSString *fullInstalledPath = [installedRubiesDirectory stringByAppendingPathComponent:installedFile];
        if ([fm fileExistsAtPath:fullInstalledPath isDirectory:&isDirectory] && isDirectory) {
            [installedRubiesEnum skipDescendents];
            [installedRubies addObject:installedFile];
        }
    }
    
    // Go through all the ruby bundles we shipped with.
    // If there are any that aren't already installed, then install them.
    NSString *bundledRubiesDirectory = [TKDAppDelegate tokaidoBundledRubiesDirectory];
    
    NSLog(@"Bundled Rubies Directory: %@", bundledRubiesDirectory);
    
    NSDirectoryEnumerator *bundledRubiesEnum = [fm enumeratorAtPath:bundledRubiesDirectory];
    NSString *bundledFile;
    while (bundledFile = [bundledRubiesEnum nextObject]) {
        if ([[bundledFile pathExtension] isEqualToString: @"zip"]) {
            NSString *rubyName = [bundledFile stringByDeletingPathExtension];
            if ([installedRubies containsObject:rubyName]) {
                continue;
            } else {
                NSLog(@"Installing Ruby: %@...", rubyName);
                [self installRubyWithName:rubyName];
            }
        }
    }
    
    // Make sure we have a gems directory. If we don't, extract our default gems to that directory.
    BOOL gemsDirectoryExists = [fm fileExistsAtPath:[TKDAppDelegate tokaidoInstalledGemsDirectory]];
    if (!gemsDirectoryExists) {
        [TKDAppDelegate createDirectoryAtPathIfNonExistant:[TKDAppDelegate tokaidoInstalledGemsDirectory]];
        [self unzipFileAtPath:[TKDAppDelegate tokaidoBundledGemsFile]
              inDirectoryPath:[TKDAppDelegate tokaidoAppSupportDirectory]];
    }
}


#pragma mark App Settings

- (void) saveAppSettings
{

}

#pragma mark Helper Methods

- (void)installRubyWithName:(NSString *)rubyName
{
    NSString *fullPathToRubyZip = [[TKDAppDelegate tokaidoBundledRubiesDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", rubyName]];
    [self unzipFileAtPath:fullPathToRubyZip inDirectoryPath:[TKDAppDelegate tokaidoInstalledRubiesDirectory]];
    
    // We need a better way to decide what the default ruby should be. Right now we only have one, so just set it as default.
    NSTask *linkTask = [[NSTask alloc] init];
    [linkTask setLaunchPath:@"/bin/ln"];
    [linkTask setCurrentDirectoryPath:[TKDAppDelegate tokaidoAppSupportDirectory]];
    [linkTask setArguments:@[ @"-s", [@"Rubies" stringByAppendingPathComponent:[rubyName stringByAppendingPathComponent:@"bin/ruby"]], @"ruby" ] ];
    [linkTask launch];
}

+ (void)createDirectoryAtPathIfNonExistant:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    
    // If the directory doesn't exist try to create it
    if ( !([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) ) {
        // Create the directory
        NSError *error = nil;
        BOOL success = [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success && error) {
            NSLog(@"ERROR: Couldn't create the Tokaido directory at %@: %@", path, [error localizedDescription]);
        }
    }
}

- (void)openTerminalWithPath:(NSString *)path;
{
    
    NSString *rubyVersion = @"2.0.0-p195";
    
    // First, set up a variable for our ruby installation.
    NSString *tokaidoSetupStep0 = [NSString stringWithFormat:@"export TOKAIDO_PATH=%@",
                                   [self rubyBinDirectory:rubyVersion]];
    
    NSString *tokaidoSetupStep1 = [NSString stringWithFormat:@"export TOKAIDO_SANDBOX_PATH=%@",
                                   [TKDAppDelegate tokaidoAppSupportDirectory]];
    
    // Second, set up the directory we will cd to
    NSString *tokaidoSetupStep2 = [NSString stringWithFormat:@"export TOKAIDO_APP_DIR=%@",
                                   [self sanitizePath:path]];
    
    NSString *tokaidoSetupStep3 = [NSString stringWithFormat:@"source %@/SetupTokaido.sh",
                                   [[NSBundle mainBundle] resourcePath]];

    NSArray *steps = @[tokaidoSetupStep0, tokaidoSetupStep1, tokaidoSetupStep2, tokaidoSetupStep3];
    NSString *stepStr = [steps componentsJoinedByString:@"; "];
    
    // Finally run everything.
    TerminalApplication *terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
    [terminal doScript:stepStr in:nil];
    [terminal activate];
}

- (NSString *)rubyBinDirectory:(NSString *)rubyVersion;
{
    NSString *installedRubies = [TKDAppDelegate tokaidoInstalledRubiesDirectory];
    NSString *sanitizedInstalledRubies = [self sanitizePath:installedRubies];
    NSString *rubyBinDirectory = [rubyVersion stringByAppendingPathComponent:@"bin"];
    
    return [sanitizedInstalledRubies stringByAppendingPathComponent:rubyBinDirectory];
}

- (NSString *)sanitizePath:(NSString *)input;
{
    return [input stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
}

#pragma mark Directories

+ (NSString *)tokaidoInstalledGemsDirectory;
{
    NSString *tokaidoInstalledGemsDirectory = [[self tokaidoAppSupportDirectory] stringByAppendingPathComponent:@"Gems"];
    return tokaidoInstalledGemsDirectory;
}

+ (NSString *)tokaidoInstalledRubiesDirectory;
{
    NSString *tokaidoInstalledRubiesDirectory = [[self tokaidoAppSupportDirectory] stringByAppendingPathComponent:@"Rubies"];
    [self createDirectoryAtPathIfNonExistant:tokaidoInstalledRubiesDirectory];
    return tokaidoInstalledRubiesDirectory;
}


+ (NSString *)tokaidoInstalledBootstrapDirectory;
{
    NSString *tokaidoInstalledBootstrapDirectory = [[self tokaidoAppSupportDirectory] stringByAppendingPathComponent:@"Bootstrap"];
    [self createDirectoryAtPathIfNonExistant:tokaidoInstalledBootstrapDirectory];
    return tokaidoInstalledBootstrapDirectory;
}

+ (NSString *)tokaidoInstalledBinDirectory; {
    NSString *tokaidoInstalledBinDirectory = [[self tokaidoAppSupportDirectory] stringByAppendingPathComponent:@"bin"];
    return tokaidoInstalledBinDirectory;
}

+ (NSString *)tokaidoInstalledFirewallDirectory;
{
    NSString *tokaidoInstalledFirewallDirectory = [[self tokaidoAppSupportDirectory] stringByAppendingPathComponent:@"Firewall"];
    [self createDirectoryAtPathIfNonExistant:tokaidoInstalledFirewallDirectory];
    return tokaidoInstalledFirewallDirectory;
}

+ (NSString *)tokaidoBundledBootstrapFile
{
    NSString *tokaidoBundledRubiesDirectory = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tokaido-bootstrap.zip"];
    return tokaidoBundledRubiesDirectory;
}

+ (NSString *)tokaidoMuxrSocketPath;
{
    return [[self tokaidoAppSupportDirectory] stringByAppendingPathComponent:@"Firewall/muxr.sock"];
}

+ (NSString *)tokaidoBundledRubiesDirectory;
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Rubies"];
}

+ (NSString *)tokaidoBundledGemsFile;
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tokaido-gems.zip"];
}


+ (NSString *)tokaidoAppSupportDirectory;
{

    /*** UNEXPECTED ***
     what we want for calabash is a sandboxed directory where the ruby version
     and the various required gems can be installed. 
     
     i think what we want to use a temporary directory that is unique for each run
     
     that way multiple instances of the Calabash.app without clobbering each 
     other's gem/ruby sandbox
     
     CONS: 
      * it is a temp directory - it disappears after 3 days
      * we are creating ~100M of stuff every time we launch the app
      * launch time is longer (but it is not terrible)
     
     PROS:
      * it is easy

     ******************/
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *tmpDir = NSTemporaryDirectory();
    if (tmpDir == nil) { tmpDir = @"/tmp"; }
    TKDAppDelegate *del = (TKDAppDelegate *)[NSApplication sharedApplication].delegate;
    NSString *subdir = [NSString stringWithFormat:@"%@-%@", appName, [del calabashDirUUID]];
    NSString *workspaceDir = [tmpDir stringByAppendingPathComponent:subdir];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:workspaceDir] == YES) { return workspaceDir; }

    NSError *error = nil;
    if ([fm createDirectoryAtPath:workspaceDir withIntermediateDirectories:YES
                       attributes:nil error:&error] == NO) {
        NSLog(@"ERROR: could not create a sandbox directory");
        NSLog(@"ERROR: path: %@", workspaceDir);
        NSLog(@"ERROR: returning nil");
        [del handleErrorCondition:k_tkd_error_could_not_create_sandbox_dir error:error];
        return nil;
    }
    return workspaceDir;
}

#pragma mark start/stop tokaido-bootstrap


- (void)stopTokaidoBootstrap
{
    NSLog(@"tokaido-bootstrap shutting down...");
    SMJobRemove(kSMDomainUserLaunchd, (__bridge CFStringRef)kTokaidoBootstrapLabel, NULL, false, NULL);
}


#pragma mark Helpers

- (void)unzipFileAtPath:(NSString *)path inDirectoryPath:(NSString *)directory
{
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:10];
    [arguments addObject:@"-u"];
    [arguments addObject:path];
    
    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setCurrentDirectoryPath:directory];
    [unzipTask setArguments:arguments];
    [unzipTask launch];
    [unzipTask waitUntilExit];
}

@end
