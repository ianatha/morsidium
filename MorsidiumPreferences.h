#import <Adium/AISharedAdium.h>
#import <Adium/AIWindowController.h>
#import <Adium/AIPreferenceControllerProtocol.h>

@interface MorsidiumPreferences : AIWindowController {
	IBOutlet		NSWindow		*window;
	
	IBOutlet		NSButton		*button_enableDecoding;
		
	// Service popup
	NSMenu			*serviceMenu;
}

+ (void)showWindow;

- (IBAction)updatePreferences:(id)sender;

@end
