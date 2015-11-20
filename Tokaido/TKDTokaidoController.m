#import "TKDAppDelegate.h"
#import "TKDTokaidoController.h"

@interface TKDTokaidoController ()

@property (nonatomic, strong, readonly) NSView *mask;
@property (nonatomic, strong, readonly) NSProgressIndicator *progressIndicator;

@end

@implementation TKDTokaidoController

#pragma mark - Memory Management

@synthesize mask = _mask;
@synthesize progressIndicator = _progressIndicator;

- (id) initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
       
    }
    return self;
}


- (void) handleDidFinishInstallingSandbox {
    NSLog(@"DEBUG: sandbox did finish installing");
    NSLog(@"DEBUG: removing progress indicator and mask");
    NSProgressIndicator *pi = [self progressIndicator];
    [pi stopAnimation:nil];
    NSView *mask = [self mask];
    [mask removeFromSuperview];
    NSButton *stb = [self buttonStartTerminal];
    [stb setEnabled:YES];
}


- (IBAction) openTerminalPressed:(id)sender {
    TKDAppDelegate *delegate = (TKDAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSString *path = NSHomeDirectory();
    
    [delegate openTerminalWithPath:path];
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
    
    NSWindow *win = [self window];
    win.title = [@"Calabash " stringByAppendingString:versionInfo];
}


@end
