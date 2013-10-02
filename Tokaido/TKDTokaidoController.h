#import <Foundation/Foundation.h>

@interface TKDTokaidoController : NSWindowController


@property (weak) IBOutlet NSTextField *labelRubyVersion;
@property (weak) IBOutlet NSTextField *labelIOSVersion;
@property (weak) IBOutlet NSTextField *labelAndroidVersion;
@property (weak) IBOutlet NSTextField *labelXamTestCloudVersion;



@property (weak) IBOutlet NSButton *buttonStartTerminal;
- (IBAction)openTerminalPressed:(id)sender;
- (void) handleDidFinishInstallingSandbox;



@end
