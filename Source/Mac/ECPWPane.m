// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECPWPane.h"


@implementation ECPWPane

@synthesize view = _view;

- (void)dealloc
{
	[_options release];
	[_toolbarItem release];

	[super dealloc];
}

- (NSView*)view
{
    BOOL loaded = YES;
    
    if (!_view)
	{
		NSString* bundle = self.options[@"Bundle"];
		if (!bundle)
		{
			bundle = [self identifier];
		}

        loaded = [NSBundle loadNibNamed:bundle owner:self];
    }
    
    if (loaded) 
	{
		[self paneDidLoad];
    }
    
    return _view;
}

- (NSString*)identifier
{
	NSString* result = self.options[@"Identifier"];
	if (!result)
	{
		result = NSStringFromClass([self class]);
	}

	return result;
}


- (NSString*)name
{
	NSString* name = self.options[@"Name"];
	if (!name)
	{
		name = [self identifier];
	}

    return name;
}

- (NSImage *)icon
{
	NSString* name = self.options[@"Icon"];
	if (!name)
	{
		name = [self identifier];
	}

	NSImage* result = [NSImage imageNamed:name];
	if (!result)
	{
		NSURL* url = [[NSBundle bundleForClass:[self class]] URLForImageResource:name];
		result = [[[NSImage alloc] initByReferencingURL:url] autorelease];
	}

    return result;
}

- (NSString*)toolTip
{
	NSString* result = self.options[@"ToolTip"];

    return result;
}

- (NSToolbarItem*)toolbarItem
{
	if (!_toolbarItem)
	{
		NSString* identifier = self.identifier;
		NSString* name = self.name;
		NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
		[item setLabel:name];
		[item setToolTip:self.toolTip];
		[item setImage:self.icon];
		self.toolbarItem = item;
		[item release];
	}

	return _toolbarItem;
}

- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}

- (void) paneDidLoad
{
	
}

@end
