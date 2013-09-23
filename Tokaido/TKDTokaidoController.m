//
//  TKDTokaidoController.m
//  Tokaido
//
//  Created by Mucho Besos on 10/23/12.
//  Copyright (c) 2012 Tilde. All rights reserved.
//

#import "TKDAppDelegate.h"
#import "TKDTokaidoController.h"
#import "TKDMuxrManager.h"
#import "TKDApp.h"
#import "LjsUnixOperation.h"
#import "LjsUnixOperationResult.h"

static NSString *const kCalabashIOSVersion = @"com.xamarin.Calabash - calabash iOS version";
static NSString *const kCalabashAndroidVersion = @"com.xamarin.Calabash - calabash Android version";
static NSString *const kCalabashRubyVersion = @"com.xamarin.Calabash - calabash Ruby version";

@interface TKDTokaidoController () <LjsUnixOperationCallbackDelegate>

@property (nonatomic, strong, readonly) NSOperationQueue *opqueue;

- (void) handleDidFinishInstallingSandboxNotification:(NSNotification *) aNotification;

- (void) launchVersionOperationWithPath:(NSString *) aLaunchPath
                             identifier:(NSString *) aIdentifer
                              arguments:(NSArray *) aArgs
                            environment:(NSDictionary *) aEnvironment;
@end

@implementation TKDTokaidoController

#pragma mark - Memory Management

@synthesize opqueue = _opqueue;

- (id) initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(handleDidFinishInstallingSandboxNotification:)
         name:TKDDidFinishInstallingSandboxNotification
         object:nil];
    }
    return self;
}

- (NSOperationQueue *) opqueue {
    if (_opqueue != nil) { return _opqueue; }
    _opqueue = [[NSOperationQueue alloc] init];
    return _opqueue;
}

- (void) handleDidFinishInstallingSandboxNotification:(NSNotification *) aNotification {
    NSLog(@"DEBUG: received sandbox did finish install notification");
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:TKDDidFinishInstallingSandboxNotification object:nil];

    NSString *rubyDir = [TKDAppDelegate tokaidoInstalledRubiesDirectory];
    NSString *rubySub = [NSString stringWithFormat:@"%@/bin/ruby", kTKDInstalledRubyVersion];
    NSString *rubyPath = [rubyDir stringByAppendingPathComponent:rubySub];
    NSArray *launchArgs = @[@"--version"];
    [self launchVersionOperationWithPath:rubyPath
                              identifier:kCalabashRubyVersion
                               arguments:launchArgs
                             environment:nil];


    NSString *gemDir = [TKDAppDelegate tokaidoInstalledGemsDirectory];
    NSString *gemBin = [gemDir stringByAppendingPathComponent:@"bin"];
    
    NSString *cal_ios = [gemBin stringByAppendingPathComponent:@"calabash-ios"];
    NSString *cal_and = [gemBin stringByAppendingPathComponent:@"calabash-android"];
    NSLog(@"cal ios = %@", cal_ios);
    NSLog(@"cal and = %@", cal_and);
    
    NSDictionary *env = @{@"GEM_HOME" : gemDir,
                          @"GEM_PATH" : gemDir,
                          @"RUBYPATH" : rubyPath,
                          @"HOME" : NSHomeDirectory()};
    
    [self launchVersionOperationWithPath:rubyPath
                              identifier:kCalabashIOSVersion
                               arguments:@[cal_ios, @"version"]
                             environment:env];
    
    [self launchVersionOperationWithPath:rubyPath
                              identifier:kCalabashAndroidVersion
                               arguments:@[cal_and, @"version"]
                             environment:env];

    
    [self.buttonStartTerminal setEnabled:YES];
}


- (void) launchVersionOperationWithPath:(NSString *) aLaunchPath
                             identifier:(NSString *) aIdentifer
                              arguments:(NSArray *) aArgs
                            environment:(NSDictionary *) aEnvironment {
    LjsUnixOperation *operation = [[LjsUnixOperation alloc]
                                   initWithLaunchPath:aLaunchPath
                                   launchArgs:aArgs
                                   commonName:aIdentifer
                                   callbackDelegate:self];
    if (aEnvironment) { operation.task.environment = aEnvironment; }
    
    [self.opqueue addOperation:operation];
}

#pragma mark - Ljs Unix Operation Callback Delegate

- (void) operationCompletedWithName:(NSString *)aName result:(LjsUnixOperationResult *)aResult {
    NSLog(@"DEBUG: received '%@'", aResult);
    
    NSTextField *textField = nil;
    if ([kCalabashIOSVersion isEqualToString:aName]) {
        NSLog(@"DEBUG: reveived IOS version: '%@'", [aResult stdOutput]);
        textField = [self labelIOSVersion];
    } else if ([kCalabashAndroidVersion isEqualToString:aName]) {
        NSLog(@"DEBUG: reveived Android version: '%@'", [aResult stdOutput]);
        textField = [self labelAndroidVersion];
    } else if ([kCalabashRubyVersion isEqualToString:aName]) {
        NSLog(@"DEBUG: reveived Ruby version: '%@'", [aResult stdOutput]);
        textField = [self labelRubyVersion];
    } else {
        NSLog(@"ERROR: did not recognize operation with name: '%@'", aName);
        NSLog(@"ERROR: dropping result on the floor");
        return;
    }
    if (textField != nil) {
        NSString *version = [aResult stdOutput];
        if ([kCalabashRubyVersion isEqualToString:aName]) {
            NSArray *tokens = [[aResult stdOutput] componentsSeparatedByString:@" "];
            if ([tokens count] > 2) {
                version = [tokens objectAtIndex:1];
            }
        }
        
        [textField setStringValue:version];
    }
}



- (IBAction) openTerminalPressed:(id)sender {
    TKDAppDelegate *delegate = (TKDAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSString *path = NSHomeDirectory();
    
    [delegate openTerminalWithPath:path];
}


- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}


#pragma mark - Window Life Cycle

- (void) awakeFromNib {
    NSButton *startTerminal = [self buttonStartTerminal];
    // will enable once the sandbox is installed (see the handle did finish notification)
    [startTerminal setEnabled:NO];
    
  
    NSRect stf = startTerminal.frame;
    
    NSImage *image = [NSImage imageNamed:@"calabash-128x128.tiff"];
    CGFloat wh = 110;
    CGFloat w = wh;
    CGFloat h = wh;
    CGFloat x = (stf.size.width/2.0) - (w/2.0);
    NSImageView *imageView = [[NSImageView alloc]
                              initWithFrame:NSMakeRect(x, 10, w, h)];
    imageView.image = image;
    [startTerminal addSubview:imageView];
    
    NSString *title = @"Start Terminal";
    
    h = 32;
    w = stf.size.width;
    NSTextField *textField = [[NSTextField alloc]
                              initWithFrame:NSMakeRect(0, 128, w, h)];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    [textField setBezeled:NO];
    [textField setAlignment:NSCenterTextAlignment];

    textField.font = [NSFont systemFontOfSize:15];
    textField.stringValue = title;
    [startTerminal addSubview:textField];
    
    NSString *gitRevKey = @"XAMGitShortRevision";
    NSString *versionKey = @"CFBundleShortVersionString";
    NSString *rev = [[NSBundle mainBundle] objectForInfoDictionaryKey:gitRevKey];
    NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:versionKey];
    NSString *versionInfo = [NSString stringWithFormat:@"%@ (%@)", ver, rev];
    [self.labelApplicationVersion setStringValue:versionInfo];
}


@end
