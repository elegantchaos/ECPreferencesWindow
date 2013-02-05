//
//  ECPWPreferencesBundle.h
//  ECPreferencesWindow
//
//  Created by Sam Deane on 04/02/2013.
//  Copyright (c) 2013 Elegant Chaos. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECPWController;

@protocol ECPWBundle <NSObject>

+ (NSArray*)preferencesController:(ECPWController*)controller loadedBundle:(NSBundle*)bundle;

@end
