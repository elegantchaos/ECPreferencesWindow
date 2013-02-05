// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

@interface ECPWController : NSObject<NSToolbarDelegate, NSWindowDelegate>

@property (assign, nonatomic) BOOL usesTexturedWindow;
@property (assign, nonatomic) BOOL alwaysShowsToolbar;
@property (assign, nonatomic) BOOL centreFirstTimeOnly;
@property (assign, nonatomic) NSToolbarDisplayMode toolbarDisplayMode;
@property (assign, nonatomic) NSToolbarSizeMode toolbarSizeMode;
@property (strong, nonatomic, readonly) NSWindow *window;

+ (id)preferencesWindowController;

- (id)initLoadingPanesFromBundle:(NSBundle*)bundle;

- (void)showPreferencesWindow;
- (void)selectPaneWithIdentifier:(NSString*)identifier;


@end
