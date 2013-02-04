// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@class ECPWController;

@interface ECPWPane : NSObject
{
    IBOutlet NSView *prefsView;
}

@property (strong, nonatomic) NSDictionary* options;
@property (strong, nonatomic) NSToolbarItem* toolbarItem;

- (void) paneDidLoad;


//	paneView returns a preference pane's view. This must not be nil.

- (NSView *)paneView;

- (NSString*)identifier;
- (NSString*)name;
- (NSImage *)icon;
- (NSString *)toolTip;

- (BOOL)allowsHorizontalResizing;
- (BOOL)allowsVerticalResizing;


@end
