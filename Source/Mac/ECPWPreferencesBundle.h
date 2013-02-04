//
//  ECPWPreferencesBundle.h
//  ECPreferencesWindow
//
//  Created by Sam Deane on 04/02/2013.
//  Copyright (c) 2013 Elegant Chaos. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ECPWPreferencesBundle <NSObject>

- (void)preferencesLoadedFromBundle:(NSBundle*)bundle;

@end
