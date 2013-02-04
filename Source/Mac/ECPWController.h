// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
//  Based on original code by Matt Gemmell.
// --------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

@interface ECPWController : NSObject<NSToolbarDelegate, NSWindowDelegate>

@property (assign, nonatomic) BOOL usesTexturedWindow;
@property (assign, nonatomic) BOOL alwaysShowsToolbar;
@property (assign, nonatomic) BOOL alwaysOpensCentered;
@property (assign, nonatomic) NSToolbarDisplayMode toolbarDisplayMode;
@property (assign, nonatomic) NSToolbarSizeMode toolbarSizeMode;

// Convenience constructors
+ (id)preferencesWindowController;

// Designated initializer
- (id)initLoadingPanesFromBundle:(NSBundle*)bundle;

- (void)showPreferencesWindow;
- (void)createPreferencesWindowAndDisplay:(BOOL)shouldDisplay;
- (void)createPreferencesWindow;
- (void)destroyPreferencesWindow;
- (BOOL)loadPrefsPaneNamed:(NSString *)name display:(BOOL)disp;
- (BOOL)loadPreferencePaneNamed:(NSString *)name;
- (void)activatePane:(NSString*)path;

float ToolbarHeightForWindow(NSWindow *window);
- (void)createPrefsToolbar;
- (void)prefsToolbarItemClicked:(NSToolbarItem*)item;

// Accessors
- (NSWindow *)preferencesWindow;

- (NSArray *)loadedPanes;

@end
