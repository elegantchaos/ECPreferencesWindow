//
//  ECPWPreferencesBundle.h
//  ECPreferencesWindow
//
//  Created by Sam Deane on 04/02/2013.
//  Copyright (c) 2013 Elegant Chaos. All rights reserved.
//

#import "ECPWBundle.h"

@implementation ECPWBundle

+ (NSArray*)preferencesController:(ECPWController*)controller loadedBundle:(NSBundle*)bundle
{
	NSDictionary* info = bundle.infoDictionary[@"ECPreferencesWindow"];
	NSString* configKey = @"Panes" EC_CONFIGURATION_STRING;
	NSArray* result = info[configKey] ?: info[@"Panes"];

	return result;
}

@end
