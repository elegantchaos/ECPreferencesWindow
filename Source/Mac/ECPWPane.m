// --------------------------------------------------------------------------
//  Copyright 2014 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECPWPane.h"

@interface ECPWPane()


@property (strong, nonatomic) NSDictionary* info;

@end

@implementation ECPWPane

@synthesize view = _view;

- (id)initWithInfo:(NSDictionary *)info
{
	if ((self = [super init]) != nil)
	{
		self.info = info;
	}

	return self;
}

- (NSView*)view
{
    BOOL loaded = YES;
    
    if (!_view)
	{
		NSString* bundle = self.info[@"Bundle"];
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
	NSString* result = self.info[@"Identifier"];
	if (!result)
	{
		result = NSStringFromClass([self class]);
	}

	return result;
}


- (NSString*)name
{
	NSString* name = self.info[@"Name"];
	if (!name)
	{
		name = [self identifier];
	}

    return name;
}

- (NSImage *)icon
{
	NSString* name = self.info[@"Icon"];
	if (!name)
	{
		name = [self identifier];
	}

	NSImage* result = [NSImage imageNamed:name];
	if (!result)
	{
		NSURL* url = [[NSBundle bundleForClass:[self class]] URLForImageResource:name];
		result = [[NSImage alloc] initByReferencingURL:url];
	}

    return result;
}

- (NSString*)toolTip
{
	NSString* result = self.info[@"ToolTip"];

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
	}

	return _toolbarItem;
}

- (void)paneDidLoad
{
	
}

- (void)paneWillShow
{

}

- (void)paneDidShow
{

}

- (void)paneWillHide
{

}

- (void)paneDidHide
{

}

- (BOOL)allowsHorizontalResizing
{
	return [self.info[@"AllowsHorizontalResizing"] boolValue];
}

- (BOOL)allowsVerticalResizing
{
	return [self.info[@"AllowsVerticalResizing"] boolValue];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<ECPWPane: %@>", self.name];
}

@end
