// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@class ECPWController;

/**
 Preference panes are the panels that are shown one at a time by the
 preferences window.

 Each pane has an identifier, used to keep track of it internally, and a 
 name, used for display purposes.
 
 Panes also have an icon and a tooltip.
 */

@interface ECPWPane : NSObject

@property (strong, nonatomic) NSDictionary* options;
@property (strong, nonatomic) NSToolbarItem* toolbarItem;
@property (assign, nonatomic) IBOutlet NSView* view;

- (void) paneDidLoad;

- (NSString*)identifier;
- (NSString*)name;
- (NSImage *)icon;
- (NSString *)toolTip;

- (BOOL)allowsHorizontalResizing;
- (BOOL)allowsVerticalResizing;


@end
