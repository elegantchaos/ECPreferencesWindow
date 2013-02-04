// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECPWPane.h"


@implementation ECPWPane

- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) 
	{
		NSString* name = NSStringFromClass([self class]);
        loaded = [NSBundle loadNibNamed:name owner:self];
    }
    
    if (loaded) 
	{
		[self paneDidLoad];
        return prefsView;
    }
    
    return nil;
}

- (NSImage *)paneIcon
{
	NSString* name = NSStringFromClass([self class]);
    return [NSImage imageNamed:name];
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

- (NSString*) paneName
{
	NSString* name = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey: @"CFBundleName"];
	
    return name;
}

// --------------------------------------------------------------------------
// These methods must be overriden by the subclasses
// --------------------------------------------------------------------------

+ (NSArray*) preferencePanes
{
    return nil;
}


- (NSString*) paneToolTip
{
    return @"";
}
@end
