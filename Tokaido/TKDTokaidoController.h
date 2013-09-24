//
//  TKDTokaidoController.h
//  Tokaido
//
//  Created by Mucho Besos on 10/23/12.
//  Copyright (c) 2012 Tilde. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TKDApp.h"
#import "TKDEditAppController.h"

@interface TKDTokaidoController : NSWindowController


@property (weak) IBOutlet NSTextField *labelRubyVersion;
@property (weak) IBOutlet NSTextField *labelIOSVersion;
@property (weak) IBOutlet NSTextField *labelAndroidVersion;
@property (weak) IBOutlet NSTextField *labelApplicationVersion;
@property (weak) IBOutlet NSTextField *labelBriarVersion;

@property (weak) IBOutlet NSButton *buttonStartTerminal;
- (IBAction)openTerminalPressed:(id)sender;



@end
