// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
//  Based on original code by Matt Gemmell.
// --------------------------------------------------------------------------

#import "ECPWController.h"
#import "ECPWPreferencesBundle.h"
#import "ECPWPane.h"

@interface ECPWController()

@property (strong, nonatomic) NSDictionary* options;
@property (strong, nonatomic) NSMutableArray* panes;
@property (strong, nonatomic) NSDictionary* panesIndex;

@property (strong, nonatomic) NSWindow *prefsWindow;

@property (strong, nonatomic) NSToolbar *prefsToolbar;
@property (strong, nonatomic) NSMutableDictionary *prefsToolbarItems;

- (void)createPreferencesWindowAndDisplay:(BOOL)shouldDisplay;

@end

@implementation ECPWController

ECDefineDebugChannel(ECPreferencesChannel);

NSString *const SelectedPaneKey = @"SelectedPane";

// ************************************************
// version/init/dealloc/constructors
// ************************************************


+ (id)preferencesWindowController
{
    ECPWController* result = [[ECPWController alloc] initLoadingPanesFromBundle:nil];

	return [result autorelease];
}


- (id)initLoadingPanesFromBundle:(NSBundle *)bundle
{
    if ((self = [super init]) != nil)
	{
        self.panes = [NSMutableArray array];

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
	[_panes release];
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

- (void)loadPreferencesPanes
{
	NSString* configKey = @"Panes" EC_CONFIGURATION_STRING;
	NSDictionary* panes = self.options[configKey] ?: self.options[@"Panes"];

	ECDebug(ECPreferencesChannel, @"Attempting to load panes %@", panes);

	NSUInteger count = [panes count];
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:count];
	NSMutableDictionary* index = [NSMutableDictionary dictionaryWithCapacity:count];
	for (NSString* name in panes)
	{
		ECPWPane* pane = nil;
		Class class = NSClassFromString(name);
		if (class)
		{
			pane = [[class alloc] init];
		}

		if (pane)
		{
			ECDebug(ECPreferencesChannel, @"Loaded pane %@", pane);
			pane.options = panes[name];
			[items addObject:pane];
			[index setObject:pane forKey:name];
		}
		else
		{
			ECDebug(ECPreferencesChannel, @"Couldn't load pane class %@", name);
		}
	}

	self.panes = items;
	self.panesIndex = index;
}

// ************************************************
// Preferences methods
// ************************************************


- (void)showPreferencesWindow
{
    if (self.prefsWindow)
	{
        if (self.alwaysOpensCentered && ![self.prefsWindow isVisible])
		{
            [self.prefsWindow center];
        }

        [self.prefsWindow makeKeyAndOrderFront:nil];
	}
	else
	{
		[self createPreferencesWindowAndDisplay:YES];
	}
}

- (void)createPreferencesWindowAndDisplay:(BOOL)shouldDisplay
{
	[self loadPreferencesPanes];
	
    // Create prefs window
    NSUInteger styleMask = (NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask);
    if (self.usesTexturedWindow)
	{
        styleMask = (styleMask | NSTexturedBackgroundWindowMask);
    }

    NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 350, 200) styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
	window.delegate = self;
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"Preferences"]; // initial default title
	self.prefsWindow = window;
    [window center];
    [self createPrefsToolbar];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* lastViewName = [defaults objectForKey:SelectedPaneKey];

	ECPWPane* paneToLoad = [self paneNamed:lastViewName];
	if (!paneToLoad && [self.panes count] > 0)
	{
		ECDebug(ECPreferencesChannel, @"Could not load last-used preference pane \"%@\". Trying to load another pane instead.", lastViewName);
		paneToLoad = self.panes[0];
	}

    if ([self loadPrefsPane:paneToLoad display:NO])
	{
        if (shouldDisplay)
		{
            [window makeKeyAndOrderFront:nil];
        }
    }
	else
	{
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
}


- (void)destroyPreferencesWindow
{
    self.prefsWindow = nil;
}



- (ECPWPane*)paneNamed:(NSString*)name
{
	ECPWPane* result = self.panesIndex[name];

	return result;
}

- (BOOL)loadPrefsPaneNamed:(NSString *)name display:(BOOL)disp
{
	ECPWPane* pane = [self paneNamed:name];
	BOOL result;
    if (pane)
	{
		result = [self loadPrefsPane:pane display:disp];
	}
	else
	{
        ECDebug(ECPreferencesChannel, @"Could not load preference pane named %@.", name);
        result = NO;
    }

	return result;
}

- (BOOL)loadPrefsPane:(ECPWPane*)pane display:(BOOL)disp
{
	ECAssertNonNil(self.prefsWindow);

	NSWindow* prefsWindow = self.prefsWindow;

    NSView *prefsView = nil;
    prefsView = [pane paneView];
    if (!prefsView) {
        ECDebug(ECPreferencesChannel, @"Could not load preference pane %@ because its view could not be loaded from the bundle.", pane);
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
        [prefsWindow setTitle: [NSString stringWithFormat: @"%@ - %@", app, [pane name]]];
    }

    // Update defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString* name = NSStringFromClass([pane class]);
    [defaults setObject:name forKey:SelectedPaneKey];

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
	NSMutableDictionary* items = [[NSMutableDictionary alloc] initWithCapacity:[self.panes count]];
    for (ECPWPane* pane in self.panes)
	{
		NSToolbarItem* item = [pane toolbarItem];
		[item setTarget:self];
		[item setAction:@selector(prefsToolbarItemClicked:)]; // action called when item is clicked
		[items setObject:item forKey:pane.identifier];
    }

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	NSString* identifier = [bundleIdentifier stringByAppendingString:@"_Preferences_Toolbar_Identifier"];
    NSToolbar* toolbar = [(NSToolbar*) [NSToolbar alloc] initWithIdentifier: identifier];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:self.toolbarDisplayMode];
    [toolbar setSizeMode:self.toolbarSizeMode];
	self.prefsToolbar = toolbar;
    self.prefsToolbarItems = items;
	[items release];

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
    return [self.prefsToolbarItems allKeys];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [self.prefsToolbarItems allKeys];
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return [self.prefsToolbarItems allKeys];
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

