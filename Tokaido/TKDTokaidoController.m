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
static NSString *const kCalabashBriarVersion = @"com.xamarin.Calabash - calabash briar version";

@interface TKDTokaidoController () <LjsUnixOperationCallbackDelegate>

@property (nonatomic, strong, readonly) NSOperationQueue *opqueue;
@property (nonatomic, strong, readonly) NSView *mask;
@property (nonatomic, strong, readonly) NSProgressIndicator *progressIndicator;

- (void) handleDidFinishInstallingSandboxNotification:(NSNotification *) aNotification;

- (void) launchVersionOperationWithPath:(NSString *) aLaunchPath
                             identifier:(NSString *) aIdentifer
                              arguments:(NSArray *) aArgs
                            environment:(NSDictionary *) aEnvironment;
@end

@implementation TKDTokaidoController

#pragma mark - Memory Management

@synthesize opqueue = _opqueue;
@synthesize mask = _mask;
@synthesize progressIndicator = _progressIndicator;

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
    NSString *briar = [gemBin stringByAppendingPathComponent:@"briar"];
  
    
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

    
    [self launchVersionOperationWithPath:rubyPath
                              identifier:kCalabashBriarVersion
                               arguments:@[briar, @"version"]
                             environment:env];

    // punting on this
    // we want to wait for the gems and ruby to report the versions
    // with some effort i could make this based the return of the NSTasks
    // but then i would have to spend time handing NSTask errors...
    // better to let the user touch the button and have the app blow up if it
    // needs to
    __weak typeof(self) wself = self;
    double delayInSeconds = 1.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSProgressIndicator *pi = [wself progressIndicator];
        [pi stopAnimation:nil];
        NSView *mask = [wself mask];
        [mask removeFromSuperview];
        NSButton *stb = [wself buttonStartTerminal];
        [stb setEnabled:YES];
    });
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
    /*
     calabash android returns 711?!?
    if (aResult.exitCode != 0) {
        NSLog(@"ERROR: found an error in result");
        NSLog(@"ERROR: exit code: '%d'", (int)aResult.exitCode);
        NSLog(@"ERROR: %@", aResult);
        NSLog(@"ERROR: nothing to do");
        NSLog(@"ERROR: dropping on the floor");
        return;
    }
     */
    
    NSTextField *textField = nil;
    if ([kCalabashIOSVersion isEqualToString:aName]) {
        NSLog(@"DEBUG: received IOS version: '%@'", [aResult stdOutput]);
        textField = [self labelIOSVersion];
    } else if ([kCalabashAndroidVersion isEqualToString:aName]) {
        NSLog(@"DEBUG: received Android version: '%@'", [aResult stdOutput]);
        textField = [self labelAndroidVersion];
    } else if ([kCalabashRubyVersion isEqualToString:aName]) {
        NSLog(@"DEBUG: received Ruby version: '%@'", [aResult stdOutput]);
        textField = [self labelRubyVersion];
    } else if ([kCalabashBriarVersion isEqualToString:aName]) {
        NSLog(@"DEBUG: received Briar version: '%@'", [aResult stdOutput]);
        textField = [self labelBriarVersion];
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

- (NSView *) mask {
    if (_mask != nil) { return _mask; }
    NSButton *startTerminal = [self buttonStartTerminal];
    NSRect stf = startTerminal.frame;
    NSView *mask = [[NSView alloc] initWithFrame:NSMakeRect(stf.origin.x + 1.5, stf.origin.y + 2,
                                                            stf.size.width - 3, stf.size.height - 4)];
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.4)];
    [viewLayer setCornerRadius:4.0f];
    [mask setWantsLayer:YES];
    [mask setLayer:viewLayer];
    _mask = mask;
    return mask;
}

- (NSProgressIndicator *) progressIndicator {
    if (_progressIndicator != nil) { return _progressIndicator; }
    NSView *mask = [self mask];
    NSRect maskF = mask.frame;
    CGFloat piW = 32;
    CGFloat piH = 32;
    CGFloat piX = (maskF.size.width/2) - (piW/2);
    CGFloat piY = (maskF.size.height/2) - (piH/2);
    NSRect frame = NSMakeRect(piX, piY, piW, piH);
    NSProgressIndicator *pi = [[NSProgressIndicator alloc]
                               initWithFrame:frame];
    pi.controlSize = NSRegularControlSize;
    pi.controlTint = [NSColor whiteColor];
    [pi setDisplayedWhenStopped:NO];
    [pi setStyle:NSProgressIndicatorSpinningStyle];
    _progressIndicator = pi;
    return _progressIndicator;
}

- (void) awakeFromNib {
    NSButton *startTerminal = [self buttonStartTerminal];
    // will enable once the sandbox is installed (see the handle did finish notification)
    [startTerminal setEnabled:NO];
    
    NSRect stf = startTerminal.frame;
    
    NSView *mask = [self mask];
    NSProgressIndicator *pi = [self progressIndicator];
    [mask addSubview:pi];
    
    [self.window.contentView addSubview:mask positioned:NSWindowAbove relativeTo:startTerminal];
    
    [pi startAnimation:nil];
    
    
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
