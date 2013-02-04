// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
//  Based on original code by Matt Gemmell.
// --------------------------------------------------------------------------

#import "ECPWController.h"
#import "ECPWPreferencesBundle.h"
#import "ECPreferencePaneProtocol.h"

@interface ECPWController()

@property (strong, nonatomic) NSDictionary* options;
@property (strong, nonatomic) NSMutableDictionary* preferencePanes;
@property (strong, nonatomic) NSMutableArray* panesOrder;

@property (strong, nonatomic) NSWindow *prefsWindow;

@property (strong, nonatomic) NSToolbar *prefsToolbar;
@property (strong, nonatomic) NSMutableDictionary *prefsToolbarItems;

@end

@implementation ECPWController

ECDefineDebugChannel(ECPreferencesChannel);

#define Last_Pane_Defaults_Key	[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@"_Preferences_Last_Pane_Defaults_Key"]

// ************************************************
// version/init/dealloc/constructors
// ************************************************


+ (id)preferencesWindowController
{
    ECPWController* result = [[ECPWController alloc] initLoadingPanesFromBundle:nil];

	return result;
}


- (id)initLoadingPanesFromBundle:(NSBundle *)bundle
{
    if ((self = [super init]) != nil)
	{
        self.preferencePanes = [NSMutableDictionary dictionary];
        self.panesOrder = [NSMutableArray array];

        self.toolbarDisplayMode = NSToolbarDisplayModeIconAndLabel;
        self.toolbarSizeMode = NSToolbarSizeModeDefault;
        self.usesTexturedWindow = NO;
        self.alwaysShowsToolbar = NO;
        self.alwaysOpensCentered = YES;

		NSURL* optionsURL = [[NSBundle mainBundle] URLForResource:@"ECPreferencesWindow" withExtension:@"plist"];
		self.options = [NSDictionary dictionaryWithContentsOfURL:optionsURL];

		[self loadPreferencesBundlesInBundle:bundle];
    }

    return self;
}


- (void)dealloc
{
	[_prefsWindow release];
	[_prefsToolbar release];
	[_prefsToolbarItems release];
	[_preferencePanes release];
	[_panesOrder release];
	[_options release];

    [super dealloc];
}


- (void)loadPreferencesBundlesInBundle:(NSBundle*)bundle
{
	NSString* extension = self.options[@"BundleExtension"] ?: @"preferencesPane";
	NSString* directory = self.options[@"BundleDirectory"] ?: @"Preferences";
	if (!bundle)
	{
		bundle = [NSBundle mainBundle];
	}

	ECDebug(ECPreferencesChannel, @"Loading preferences bundles *.%@ in %@ of %@", extension, directory, bundle);

	NSArray* bundles = [bundle URLsForResourcesWithExtension:extension subdirectory:directory];
	for (NSURL* url in bundles)
	{
		[self loadPreferencesBundleAtURL:url];
	}
}

- (void)loadPreferencesBundleAtURL:(NSURL*)url
{
    NSBundle* bundle = [NSBundle bundleWithURL:url];
    if (bundle)
	{
        NSDictionary* paneDict = [bundle infoDictionary];
		Class paneClass = [bundle principalClass];
		if (paneClass)
		{
			if ([paneClass conformsToProtocol:@protocol(ECPWPreferencesBundle)])
			{
				ECDebug(ECPreferencesChannel, @"Loaded preferences bundle %@", paneClass);
				[paneClass preferencesLoadedFromBundle:bundle];
			}
			else
			{
				ECDebug(ECPreferencesChannel, @"Preferences bundle %@ doesn't implement ECPWPreferencesBundle protocol.", bundle);
			}
		}

		else
		{
			ECDebug(ECPreferencesChannel, @"Preferences bundle %@ couldn't get principal class", bundle);
		}
    }
	else
	{
        ECDebug(ECPreferencesChannel, @"Could not load preferences bundle: %@", bundle);
    }
}


// ************************************************
// Preferences methods
// ************************************************


- (void)showPreferencesWindow
{
    [self createPreferencesWindowAndDisplay:YES];
}


- (void)createPreferencesWindow
{
    [self createPreferencesWindowAndDisplay:YES];
}


- (void)createPreferencesWindowAndDisplay:(BOOL)shouldDisplay
{
    if (self.prefsWindow) {
        if (self.alwaysOpensCentered && ![self.prefsWindow isVisible]) {
            [self.prefsWindow center];
        }
        [self.prefsWindow makeKeyAndOrderFront:nil];
        return;
    }

    // Create prefs window
    unsigned int styleMask = (NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask);
    if (self.usesTexturedWindow) {
        styleMask = (styleMask | NSTexturedBackgroundWindowMask);
    }
    self.prefsWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 350, 200)
                                              styleMask:styleMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];

	self.prefsWindow.delegate = self;
    [self.prefsWindow setReleasedWhenClosed:NO];
    [self.prefsWindow setTitle:@"Preferences"]; // initial default title

    [self.prefsWindow center];
    [self createPrefsToolbar];

    // Register defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.panesOrder && ([self.panesOrder count] > 0)) {
        NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
        [defaultValues setObject:[self.panesOrder objectAtIndex:0] forKey:Last_Pane_Defaults_Key];
        [defaults registerDefaults:defaultValues];
    }

    // Load last view
    NSString *lastViewName = [defaults objectForKey:Last_Pane_Defaults_Key];

    if ([self.panesOrder containsObject:lastViewName] && [self loadPrefsPaneNamed:lastViewName display:NO])
	{
        if (shouldDisplay) {
            [self.prefsWindow makeKeyAndOrderFront:nil];
        }
        return;
    }

    ECDebug(ECPreferencesChannel, @"Could not load last-used preference pane \"%@\". Trying to load another pane instead.", lastViewName);

    // Try to load each prefpane in turn if loading the last-viewed one fails.
	for (NSString* pane in self.panesOrder)
	{
        if (![pane isEqualToString:lastViewName]) {
            if ([self loadPrefsPaneNamed:pane display:NO]) {
                if (shouldDisplay) {
                    [self.prefsWindow makeKeyAndOrderFront:nil];
                }
                return;
            }
        }
    }

    ECDebug(ECPreferencesChannel, @"Could not load any valid preference panes.");

    // Show alert dialog.
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSRunAlertPanel(@"Preferences",
                    [NSString stringWithFormat:@"Preferences are not available for %@.", appName],
                    @"OK",
                    nil,
                    nil);
    [self.prefsWindow release];
    self.prefsWindow = nil;
}


- (void)destroyPreferencesWindow
{
    self.prefsWindow = nil;
}


- (void)activatePane:(NSString*)path
{
    NSBundle* paneBundle = [NSBundle bundleWithPath:path];
    if (paneBundle) {
        NSDictionary* paneDict = [paneBundle infoDictionary];
        NSString* paneName = [paneDict objectForKey:@"NSPrincipalClass"];
        if (paneName) {
            Class paneClass = NSClassFromString(paneName);
            if (!paneClass) {
                paneClass = [paneBundle principalClass];
                if ([paneClass conformsToProtocol:@protocol(ECPreferencePaneProtocol)] && [paneClass isKindOfClass:[NSObject class]]) {
                    NSArray *panes = [paneClass preferencePanes];

                    for (id <ECPreferencePaneProtocol> aPane in panes)
					{
                        [self.panesOrder addObject:[aPane paneName]];
                        [self.preferencePanes setObject:aPane forKey:[aPane paneName]];
                    }
                } else {
                    ECDebug(ECPreferencesChannel, @"Did not load bundle: %@ because its Principal Class is either not an NSObject subclass, or does not conform to the PreferencePane Protocol.", paneBundle);
                }
            } else {
                ECDebug(ECPreferencesChannel, @"Did not load bundle: %@ because its Principal Class was already used in another Preference pane.", paneBundle);
            }
        } else {
            ECDebug(ECPreferencesChannel, @"Could not obtain name of Principal Class for bundle: %@", paneBundle);
        }
    } else {
        ECDebug(ECPreferencesChannel, @"Could not initialize bundle: %@", paneBundle);
    }
}


- (BOOL)loadPreferencePaneNamed:(NSString *)name
{
    return [self loadPrefsPaneNamed:(NSString *)name display:YES];
}


- (NSArray *)loadedPanes
{
    if (self.preferencePanes) {
        return [self.preferencePanes allKeys];
    }
    return nil;
}


- (BOOL)loadPrefsPaneNamed:(NSString *)name display:(BOOL)disp
{
	NSWindow* prefsWindow = self.prefsWindow;
    if (!prefsWindow) {
        NSBeep();
        ECDebug(ECPreferencesChannel, @"Could not load \"%@\" preference pane because the Preferences window seems to no longer exist.", name);
        return NO;
    }

    id tempPane = nil;
    tempPane = [self.preferencePanes objectForKey:name];
    if (!tempPane) {
        ECDebug(ECPreferencesChannel, @"Could not load preference pane \"%@\", because that pane does not exist.", name);
        return NO;
    }

    NSView *prefsView = nil;
    prefsView = [tempPane paneView];
    if (!prefsView) {
        ECDebug(ECPreferencesChannel, @"Could not load \"%@\" preference pane because its view could not be loaded from the bundle.", name);
        return NO;
    }

    // Get rid of old view before resizing, for display purposes.
    if (disp)
	{
        NSView *tempView = [(NSView*) [NSView alloc] initWithFrame:[(NSView*)[prefsWindow contentView] frame]];
        [prefsWindow setContentView:tempView];
        [tempView release];
    }

    // Preserve upper left point of window during resize.
    NSRect newFrame = [prefsWindow frame];
    newFrame.size.height = [prefsView frame].size.height + ([prefsWindow frame].size.height - [(NSView*)[prefsWindow contentView] frame].size.height);
    newFrame.size.width = [prefsView frame].size.width;
    newFrame.origin.y += ([(NSView*)[prefsWindow contentView] frame].size.height - [prefsView frame].size.height);

    id <ECPreferencePaneProtocol> pane = [self.preferencePanes objectForKey:name];
    [prefsWindow setShowsResizeIndicator:([pane allowsHorizontalResizing] || [pane allowsHorizontalResizing])];

    [prefsWindow setFrame:newFrame display:disp animate:disp];

    [prefsWindow setContentView:prefsView];

    // Set appropriate resizing on window.
    NSSize theSize = [prefsWindow frame].size;
    theSize.height -= ToolbarHeightForWindow(prefsWindow);
    [prefsWindow setMinSize:theSize];

    BOOL canResize = NO;
    if ([pane allowsHorizontalResizing]) {
        theSize.width = FLT_MAX;
        canResize = YES;
    }
    if ([pane allowsVerticalResizing]) {
        theSize.height = FLT_MAX;
        canResize = YES;
    }
    [prefsWindow setMaxSize:theSize];
    [prefsWindow setShowsResizeIndicator:canResize];

	NSString* app = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"];
    if ((self.prefsToolbarItems && ([self.prefsToolbarItems count] > 1)) || self.alwaysShowsToolbar)
	{
        [prefsWindow setTitle: [NSString stringWithFormat: @"%@ - %@", app, name]];
    }

    // Update defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:Last_Pane_Defaults_Key];

    [self.prefsToolbar setSelectedItemIdentifier:name];

    // Attempt to set the initial first responder.
	NSView* nextKey = [prefsView nextKeyView];
    [nextKey becomeFirstResponder];
	[prefsWindow setInitialFirstResponder: nextKey];

    return YES;
}


// ************************************************
// Prefs Toolbar methods
// ************************************************


float ToolbarHeightForWindow(NSWindow *window)
{
    NSToolbar *toolbar;
    float toolbarHeight = 0.0f;
    NSRect windowFrame;

    toolbar = [window toolbar];

    if(toolbar && [toolbar isVisible])
    {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame]
                                              styleMask:[window styleMask]];
        toolbarHeight = (float) (NSHeight(windowFrame) - NSHeight([(NSView*)[window contentView] frame]));
    }

    return toolbarHeight;
}


- (void)createPrefsToolbar
{
    // Create toolbar items
    self.prefsToolbarItems = [[NSMutableDictionary alloc] init];
    NSImage *itemImage;
    for (NSString* name in self.panesOrder)
	{
        if ([self.preferencePanes objectForKey:name] != nil)
		{
            NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:name];
            [item setPaletteLabel:name]; // item's label in the "Customize Toolbar" sheet (not relevant here, but we set it anyway)
            [item setLabel:name]; // item's label in the toolbar
            NSString *tempTip = [[self.preferencePanes objectForKey:name] paneToolTip];
            if (!tempTip || [tempTip isEqualToString:@""]) {
                [item setToolTip:nil];
            } else {
                [item setToolTip:tempTip];
            }
            itemImage = [[self.preferencePanes objectForKey:name] paneIcon];
            [item setImage:itemImage];

            [item setTarget:self];
            [item setAction:@selector(prefsToolbarItemClicked:)]; // action called when item is clicked
            [self.prefsToolbarItems setObject:item forKey:name]; // add to items
            [item release];
        } else {
            ECDebug(ECPreferencesChannel, @"Could not create toolbar item for preference pane \"%@\", because that pane does not exist.", name);
        }
    }

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	NSString* identifier = [bundleIdentifier stringByAppendingString:@"_Preferences_Toolbar_Identifier"];
    self.prefsToolbar = [(NSToolbar*) [NSToolbar alloc] initWithIdentifier: identifier];
    [self.prefsToolbar setDelegate:self];
    [self.prefsToolbar setAllowsUserCustomization:NO];
    [self.prefsToolbar setAutosavesConfiguration:NO];
    [self.prefsToolbar setDisplayMode:self.toolbarDisplayMode];
    [self.prefsToolbar setSizeMode:self.toolbarSizeMode];

    if ((self.prefsToolbarItems && ([self.prefsToolbarItems count] > 1)) || self.alwaysShowsToolbar) {
        [self.prefsWindow setToolbar:self.prefsToolbar];
    } else if (!self.alwaysShowsToolbar && self.prefsToolbarItems && ([self.prefsToolbarItems count] == 1))
	{
		ECDebug(ECPreferencesChannel, @"Not showing toolbar in Preferences window because there is only one preference pane loaded. You can override this behaviour using -[setAlwaysShowsToolbar:YES].");
    }
}



- (void)prefsToolbarItemClicked:(NSToolbarItem*)item
{
    if (![[item itemIdentifier] isEqualToString:[self.prefsWindow title]]) {
        [self loadPrefsPaneNamed:[item itemIdentifier] display:YES];
    }
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return self.panesOrder;
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return self.panesOrder;
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return self.panesOrder;
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [self.prefsToolbarItems objectForKey:itemIdentifier];
}


// ************************************************
// Accessors
// ************************************************


- (NSWindow *)preferencesWindow
{
    return self.prefsWindow;
}


// --------------------------------------------------------------------------
//! Close the window.
// --------------------------------------------------------------------------

- (IBAction) alternatePerformClose: (id) sender
{
	[self.preferencesWindow performClose: sender];
}

@end

