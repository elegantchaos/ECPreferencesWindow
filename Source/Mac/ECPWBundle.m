//
//  ECPWPreferencesBundle.h
//  ECPreferencesWindow
//
//  Created by Sam Deane on 04/02/2013.
//  Copyright (c) 2013 Elegant Chaos. All rights reserved.
//

#import "ECPWBundle.h"

@interface ECPWBundle()

@property (strong, nonatomic) NSBundle* bundle;
@property (assign, nonatomic) ECPWController* controller; // weak reference

@end

@implementation ECPWBundle

- (id)initWithController:(ECPWController*)controller bundle:(NSBundle*)bundle
{
	if ((self = [super init]) != nil)
	{
		self.bundle = bundle;
		self.controller = controller;
	}

	return self;
}

- (NSArray*)panesToLoad
{
	NSDictionary* info = self.bundle.infoDictionary[@"ECPreferencesWindow"];
	NSString* configKey = @"Panes" EC_CONFIGURATION_STRING;
	NSArray* result = info[configKey] ?: info[@"Panes"];

	return result;
}

@end
