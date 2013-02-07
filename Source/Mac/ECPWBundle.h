//
//  ECPWPreferencesBundle.h
//  ECPreferencesWindow
//
//  Created by Sam Deane on 04/02/2013.
//  Copyright (c) 2013 Elegant Chaos. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 When it is created, an ECPWController object will scan a folder in the main application bundle
 looking for bundles with a given extension (by default, it scans Contents/Preferences for .preferences files).
 
 Each of these bundles is loaded. If the principal class of the bundle inherits from ECPWBundle, 
 the preferencesController:loadedBundle: method will be called. This method can return a list of dictionaries
 describing additional panes to load. Typically these panes will be managed by classes defined in
 the bundle, although in fact the pane classes can come from anywhere.

 The default implementation of the method looks in the bundle's Info.plist file
 for an ECPreferencesWindow key, and taking a list of panes to load from the Panes sub-key (this mirrors
 the process used by ECPWController to load panes from the main application's Info.plist).

 */


@class ECPWController;

@interface ECPWBundle : NSObject

/**
 Make a new bundle object.
 @param controller The controller doing the loading.
 @param bundle The NSBundle that this object was loaded from.
 @return The new object.
 */

- (id)initWithController:(ECPWController*)controller bundle:(NSBundle*)bundle;


/**
 Called when a preferences bundle is loaded.
 @return A list of dictionaries containing descriptions of panes to load. See ECPWController for the format of these dictionaries.
 */

- (NSArray*)panesToLoad;

@end
