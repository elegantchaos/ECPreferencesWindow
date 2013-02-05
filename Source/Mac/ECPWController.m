// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECPWController.h"
#import "ECPWBundle.h"
#import "ECPWPane.h"

@interface ECPWController()

@property (strong, nonatomic) NSDictionary* options;
@property (strong, nonatomic) NSMutableArray* paneNames;
@property (strong, nonatomic) NSMutableArray* panesToLoad;
@property (strong, nonatomic) NSMutableDictionary* panes;
@property (strong, nonatomic) NSToolbar* toolbar;
@property (strong, nonatomic, readwrite) NSWindow *window;

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


- (id)initLoadingPanesFromBundle:(NSBundle*)bundle
{
    if ((self = [super init]) != nil)
	{
		if (!bundle)
		{
			bundle = [NSBundle mainBundle];
		}

		self.options = bundle.infoDictionary[@"ECPreferencesWindow"];
		NSString* configKey = @"Panes" EC_CONFIGURATION_STRING;
		self.panesToLoad = [NSMutableArray arrayWithArray:(self.options[configKey] ?: self.options[@"Panes"])];

        self.toolbarDisplayMode = [self.options[@"ToolbarDisplayMode"] integerValue];
        self.toolbarSizeMode = [self.options[@"ToolbarSizeMode"] integerValue];
        self.usesTexturedWindow = [self.options[@"UsesTexturedWindow"] boolValue];
        self.alwaysShowsToolbar = [self.options[@"AlwaysShowsToolbar"] boolValue];
        self.centreFirstTimeOnly = [self.options[@"CentreFirstTimeOnly"] boolValue];


		[self loadPreferencesBundlesInBundle:bundle];
    }

    return self;
}


- (void)dealloc
{
	[_options release];
	[_paneNames release];
	[_panes release];
	[_toolbar release];
	[_window release];

    [super dealloc];
}


- (void)loadPreferencesBundlesInBundle:(NSBundle*)bundle
{
	NSString* extension = self.options[@"BundleExtension"] ?: @"preferences";
	NSString* directory = self.options[@"BundleDirectory"] ?: @"Preferences";

	ECDebug(ECPreferencesChannel, @"Loading preferences bundles *.%@ in %@ of %@", extension, directory, bundle);

	NSURL* prefsFolder = [[bundle bundleURL] URLByAppendingPathComponent:@"Contents/Preferences"];
	NSError* error;
	NSArray* bundles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:prefsFolder includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants error:&error];
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
			if ([paneClass isSubclassOfClass:[ECPWBundle class]])
			{
				ECDebug(ECPreferencesChannel, @"Loaded preferences bundle %@", paneClass);
				NSArray* additionalPanesToLoad = [paneClass preferencesController:self loadedBundle:bundle];
				if (additionalPanesToLoad)
				{
					[self.panesToLoad addObjectsFromArray:additionalPanesToLoad];
				}
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

- (NSString*)panesKey
{

}
- (void)loadPreferencesPanes
{

	ECDebug(ECPreferencesChannel, @"Attempting to load panes %@", self.panesToLoad);

	NSUInteger count = [self.panesToLoad count];
	self.paneNames = [NSMutableArray arrayWithCapacity:count];
	self.panes = [NSMutableDictionary dictionaryWithCapacity:count];
	for (NSDictionary* paneInfo in self.panesToLoad)
	{
		[self loadPaneWithInfo:paneInfo];
	}
}

- (void)loadPaneWithInfo:(NSDictionary*)info
{
	NSString* className = info[@"Class"];
	Class class = NSClassFromString(className);
	if (class)
	{
		ECPWPane* pane = [[class alloc] initWithInfo:info];
		if (pane)
		{
			if (pane.view)
			{
				ECDebug(ECPreferencesChannel, @"Loaded pane %@", pane);
				NSString* identfier = [pane identifier];
				[self.paneNames addObject:identfier];
				[self.panes setObject:pane forKey:identfier];
			}
			else
			{
				ECDebug(ECPreferencesChannel, @"Loaded pane %@ but couldn't load view.", pane);
			}
			[pane release];
		}
		else
		{
			ECDebug(ECPreferencesChannel, @"Couldn't load pane class %@", class);
		}
	}
	else
	{
		ECDebug(ECPreferencesChannel, @"Couldn't find pane class %@", className);
	}
}

// ************************************************
// Preferences methods
// ************************************************


- (void)showPreferencesWindow
{
    if (self.window)
	{
        if (!self.centreFirstTimeOnly && ![self.window isVisible])
		{
            [self.window center];
        }

        [self.window makeKeyAndOrderFront:nil];
	}
	else
	{
		[self createPreferencesWindowAndDisplay:YES];
	}
}

- (NSWindow*)createWindow
{
	[self loadPreferencesPanes];

    NSUInteger styleMask = (NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask);
    if (self.usesTexturedWindow)
	{
        styleMask = (styleMask | NSTexturedBackgroundWindowMask);
    }

    NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 350, 200) styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
	window.delegate = self;
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"Preferences"]; // initial default title
    [window center];

	return [window autorelease];
}

- (void)createPreferencesWindowAndDisplay:(BOOL)shouldDisplay
{
	NSWindow* window = [self createWindow];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* selectedName = [defaults objectForKey:SelectedPaneKey];
	ECPWPane* pane = [self paneWithIdentifier:selectedName];
	if (!pane && [self.panes count] > 0)
	{
		pane = self.panes[self.paneNames[0]];
		if (!selectedName)
		{
			ECDebug(ECPreferencesChannel, @"No preference pane selected. Using default %@.", [pane name]);
		}
		else
		{
			ECDebug(ECPreferencesChannel, @"Couldn't find pane %@. Using default %@.", selectedName, [pane name]);
		}
	}

    if (pane)
	{
		self.window = window;
		[self createToolbar];
		[self showPane:pane display:NO];
        if (shouldDisplay)
		{
            [window makeKeyAndOrderFront:nil];
        }
    }
	else
	{
		ECDebug(ECPreferencesChannel, @"Could not load any valid preference panes.");

		NSString* appName = [[NSApplication sharedApplication] applicationName];
		NSRunAlertPanel(@"Preferences",
						[NSString stringWithFormat:@"Preferences are not available for %@.", appName],
						@"OK",
						nil,
						nil);
	}
}


- (ECPWPane*)paneWithIdentifier:(NSString*)identifier
{
	ECPWPane* result = self.panes[identifier];

	return result;
}

- (void)selectPaneWithIdentifier:(NSString*)identifier
{
	[self showPaneWithIdentifier:identifier display:YES];
}

- (void)showPaneWithIdentifier:(NSString*)name display:(BOOL)display
{
	ECPWPane* pane = [self paneWithIdentifier:name];
	BOOL result;
    if (pane)
	{
		[self showPane:pane display:display];
	}
	else
	{
        ECDebug(ECPreferencesChannel, @"Could not load preference pane named %@.", name);
    }
}

- (void)showPane:(ECPWPane*)pane display:(BOOL)display
{
	NSWindow* window = self.window;
    NSView* view = pane.view;

	ECAssertNonNil(window);
	ECAssertNonNil(view);

    // Get rid of old view before resizing, for display purposes.
    if (display)
	{
        NSView *tempView = [(NSView*) [NSView alloc] initWithFrame:[(NSView*)[window contentView] frame]];
        [window setContentView:tempView];
        [tempView release];
    }

    // Preserve upper left point of window during resize.
    NSRect newFrame = [window frame];
    newFrame.size.height = [view frame].size.height + ([window frame].size.height - [(NSView*)[window contentView] frame].size.height);
    newFrame.size.width = [view frame].size.width;
    newFrame.origin.y += ([(NSView*)[window contentView] frame].size.height - [view frame].size.height);

	BOOL canResize = NO;
    NSSize minMaxSize = newFrame.size;
    if ([pane allowsHorizontalResizing])
	{
        minMaxSize.width = FLT_MAX;
        canResize = YES;
    }
    if ([pane allowsVerticalResizing])
	{
        minMaxSize.height = FLT_MAX;
        canResize = YES;
    }

    [window setFrame:newFrame display:display animate:display];
    [window setContentView:view];

    minMaxSize.height -= [window toolbarHeight];
    [window setShowsResizeIndicator:canResize];
    [window setMinSize:minMaxSize];
    [window setMaxSize:minMaxSize];

    if (([self.panes count] > 1) || self.alwaysShowsToolbar)
	{
		NSString* appName = [[NSApplication sharedApplication] applicationName];
        [window setTitle: [NSString stringWithFormat: @"%@ - %@", appName, [pane name]]];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:pane.identifier forKey:SelectedPaneKey];

    [self.toolbar setSelectedItemIdentifier:pane.identifier];

    // Attempt to set the initial first responder.
	NSView* nextKey = [view nextKeyView];
    [nextKey becomeFirstResponder];
	[window setInitialFirstResponder: nextKey];
}


#pragma mark - Toolbar

- (void)createToolbar
{
	NSUInteger count = [self.panes count];
    if ((count > 1) || self.alwaysShowsToolbar)
	{
		NSArray* panes = [self.panes allValues];
		for (ECPWPane* pane in panes)
		{
			NSToolbarItem* item = [pane toolbarItem];
			[item setTarget:self];
			[item setAction:@selector(selectPaneWithItem:)];
		}

		NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
		NSString* identifier = [bundleIdentifier stringByAppendingString:@"_Preferences_Toolbar_Identifier"];
		NSToolbar* toolbar = [(NSToolbar*) [NSToolbar alloc] initWithIdentifier: identifier];
		[toolbar setDelegate:self];
		[toolbar setAllowsUserCustomization:NO];
		[toolbar setAutosavesConfiguration:NO];
		[toolbar setDisplayMode:self.toolbarDisplayMode];
		[toolbar setSizeMode:self.toolbarSizeMode];
		self.toolbar = toolbar;

        [self.window setToolbar:self.toolbar];
    }
	else if (!self.alwaysShowsToolbar)
	{
		ECDebug(ECPreferencesChannel, @"Not showing toolbar in Preferences window because there are %ld panes", count);
    }
}



- (void)selectPaneWithItem:(NSToolbarItem*)item
{
	[self showPaneWithIdentifier:[item itemIdentifier] display:YES];
}

// --------------------------------------------------------------------------
//! Close the window.
// --------------------------------------------------------------------------

- (IBAction) alternatePerformClose: (id) sender
{
	[self.window performClose:sender];
}

#pragma mark - Toolbar Delegate Methods

- (NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return self.paneNames;
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return self.paneNames;
}

- (NSArray*)toolbarSelectableItemIdentifiers:(NSToolbar*)toolbar
{
    return self.paneNames;
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	ECPWPane* pane = self.panes[itemIdentifier];
    return pane.toolbarItem;
}


@end

