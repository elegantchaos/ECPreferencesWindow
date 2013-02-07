// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

/**
 Manages a preferences window.
 
 The window consists of a toolbar of icons, and an area below the toolbar
 which is replaced by the <ECPWPane> that corresponds to the selected
 toolbar icon.

 # Usage

 The class isn't a singleton, although typically you'll simply make one instance
 and store it somewhere (eg in your application delegate).

 Call showPreferencesWindow to show the preferences window.

	ECPWController* controller = [ECPWController preferencesWindowController];
	[controller showPreferencesWindow];


 # Initialisation And Configuration

 Most configuration is done via the ECPreferencesWindow key of the application's
 Info.plist file.
 
 This key should contain a dictionary.
 
 A number of values in this dictionary configure the behaviour of the window:
 
 - UsesTexturedWindow: should the preferences window be textured? Defaults to NO.
 - AlwaysShowsToolbar: should the toolbar be visible even if there is just one pane? Defaults to NO.
 - CentreFirstTimeOnly: should the window only be centered when it's created (YES), or every time it is shown (NO). Defaults to NO.
 - BundleDirectory: the name of the directory to look for preference bundles in. Defaults to "PlugIns".
 - BundleExtension: the extension to look for in the bundle directory. Defaults to "preferences".
 - ToolbarDisplayMode: the display mode to use for the toolbar. Defaults to NSToolbarDisplayModeDefault.
 - ToolbarSizeMode: the display size mode to use for the toolbar. Defaults to NSToolbarSizeModeDefault.
 - Panes: a list of panes to load. See below.

 The Panes key should contain a list of dictionaries. Each of these
 describes a pane to add to the preferences window.

 Each pane dictionary can contain the following keys:

 - Class (required): the class to use for the pane.
 - Identifier: the identifier to use for the pane. Defaults to the class name.
 - Name: the text label to use for the pane. Defaults to the class name.
 - Icon: the name of the icon image to use for the panel. Defaults to the class name.
 - ToolTip: tooltip text to use for the pane. Defaults to nil.


# Preference Bundles
 
 In addition to loading the panes described in main application's Info.plist, the
 controller also scans a folder for preference bundles, and loads any that it finds.
 
 The principal class for each of these bundles should inherit from ECPWBundle.

 When a preferences bundle is loaded, [ECPWBundle preferencesController:loadedBundle:] is called on this class.

 This method should return a list of dictionaries with additional panes to load.
 
 The default implementation of the method does this by looking in the bundle's Info.plist file
 for an ECPreferencesWindow key, and taking a list of panes from the Panes sub-key (this mirrors
 the process used to load panes from the main application's Info.plist).

 # Loading

 The bundles folder is scanned when the controller is first created, and any preference
 bundles that are found get loaded and called at this point in order to set themselves up.
 
 This allows preferences bundles to add features to an application when it first starts up,
 rather than only doing something when the preferences window is shown.
 
 The pane classes themselves are created lazily when the preferences window is first shown,
 so it's quite possible that they will never be created at all for a given run of an application.
 

 When a pane is loaded, [ECPWPane paneDidLoad] is called on it.

 */

@interface ECPWController : NSObject<NSToolbarDelegate, NSWindowDelegate>

/**
 Should the preferences window be textured?
 */

@property (assign, nonatomic) BOOL usesTexturedWindow;

/** 
 Should the toolbar be visible even if there's only one panel?
 */

@property (assign, nonatomic) BOOL alwaysShowsToolbar;

/**
 Should the window be centred when it's first created, or every time it's shown?
 */

@property (assign, nonatomic) BOOL centreFirstTimeOnly;

/**
 How the toolbar should be displayed.
 */

@property (assign, nonatomic) NSToolbarDisplayMode toolbarDisplayMode;

/**
 How the toolbar should be sized.
 */

@property (assign, nonatomic) NSToolbarSizeMode toolbarSizeMode;

/**
 The preferences window.
 */

@property (strong, nonatomic, readonly) NSWindow *window;

/**
 Return a new window controller.
 
 @return A new instance of ECPWController.
 */

+ (id)preferencesWindowController;

/**
 Initialise a new controller.
 
 Settings for the controller are read from the Info.plist of the given
 bundle, and the bundle is scanned for additional preferences bundles to load.

 @param bundle Bundle to load settings and additional preference bundles from. Defaults to [NSBundle mainBundle].
 @return The new controller.
 */

- (id)initLoadingPanesFromBundle:(NSBundle*)bundle;

/**
 Show the preferences window.
 The previously selected pane is shown by default, or the first pane if none was previously selected.
 */

- (void)showPreferencesWindow;

/**
 Show the preferences window and select a given pane.

 @param identifier The identifier of the pane to select.
 */

- (void)showPaneWithIdentifier:(NSString*)identifier;

/**
 Hide the preferences window.
 */

- (void)hidePreferencesWindow;

@end
