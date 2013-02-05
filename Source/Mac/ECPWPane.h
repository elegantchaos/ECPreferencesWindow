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
 
 These values can be set from an info dictionary passed in to the pane.
 If keys are missing, default values are chosen, based on the name of
 the pane class.
 */

@interface ECPWPane : NSObject

/**
 The toolbar item for this pane.
 */

@property (strong, nonatomic) NSToolbarItem* toolbarItem;

/**
 The view for this pane.
 */

@property (assign, nonatomic) IBOutlet NSView* view;

/**
 Set up using information from a dictionary.
 @param info Dictionary defining the name, icon etc to use for the pane.
 @return The new pane.
 */

- (id)initWithInfo:(NSDictionary*)info;

/**
 Sent to the pane when it has loaded.
 */

- (void) paneDidLoad;

/**
 The identifier to use for the pane.
 @return Unique string identifying the pane.
 */

- (NSString*)identifier;

/**
 The name of the pane.
 @return String to display with the icon for the pane.
 */

- (NSString*)name;

/**
 Icon for the toolbar.
 @return Image to use as the toolbar icon.
 */

- (NSImage *)icon;

/**
 Text to display when the user hovers over the icon for the pane.
@return Tooltip text, or nil if none is supplied.
 */

- (NSString *)toolTip;

/**
 Can this pane be resized horizontally?
 @return YES if the pane can be resized horizontally.
 */

- (BOOL)allowsHorizontalResizing;

/**
 Can this pane be resized vertically?
 @return YES if the pane can be resized vertically.
 */

- (BOOL)allowsVerticalResizing;


@end
