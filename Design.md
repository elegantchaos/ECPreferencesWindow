# Usage:

 ECPWController* controller = [ECPWController preferencesWindowController];
 [controller showPreferencesWindow];
 
 
Not a singleton, although typically only one instance will exist.

# Initialisation

Automatically scans preferences plugins folder and loads any plugin found.

List of panels to display is read from ECPreferencesWindow.plist, in the app's resources. List consists of a list of class names.


