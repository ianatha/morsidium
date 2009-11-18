#import "MorsidiumPreferences.h"
#import "MorsidiumPlugin.h"
#import <AIUtilities/AIImageTextCell.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIServiceMenu.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

@interface MorsidiumPreferences ()
- (void)updateControls;
@end

@implementation MorsidiumPreferences

static MorsidiumPreferences *sharedInstance = nil;

/*!
 * @brief Shows the preference window using a shared instance
 */
+ (void)showWindow
{
	if(!sharedInstance) {
		sharedInstance = [[self alloc] initWithWindowNibName:@"MorsidiumPreferences"];
	}
	
	[sharedInstance showWindow:nil];
	[[sharedInstance window] makeKeyAndOrderFront:nil];
}

/*!
 * @brief Set up our defaults when we load
 */
- (void)windowDidLoad
{
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREFERENCE_GROUP];
	
	[self updateControls];
	
	serviceMenu = [AIServiceMenu menuOfServicesWithTarget:self 
									   activeServicesOnly:NO
										  longDescription:NO
												   format:nil];
	
	[serviceMenu setAutoenablesItems:YES];
	
	[super windowDidLoad];
}

/*!
 * @brief Unregister ourselves, unset our shared instance
 */
- (void)windowWillClose:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[sharedInstance release]; sharedInstance = nil;
	
	[super windowWillClose:sender];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{	
	[super dealloc];
}

/*!
 * @brief Frame autosave name
 */
- (NSString *)adiumFrameAutosaveName
{
	return @"Morsidium Preferences";
}

/*!
 * @brief Save our whitelist, update controls
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(object)
		return;
		
	[self updateControls];
}

/*!
 * @brief Target of the AIServiceMenu, required to validate the menu item
 */
- (void)selectServiceType:(id)service { }

#pragma mark Control updating
/*!
 * @brief Update controls when tableview selection cahnges
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateControls];
}

/*!
 * @brief Update control availability
 */
- (void)updateControls
{
	NSDictionary *preferences = [[adium preferenceController] preferencesForGroup:PREFERENCE_GROUP];
	
	[button_enableDecoding setState:[[preferences objectForKey:PREFERENCE_ENABLE_DECODING] boolValue]];
}

#define View methods
/*!
 * @brief Target when preference controls change
 */
- (IBAction)updatePreferences:(id)sender
{
	if(sender == button_enableDecoding) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:PREFERENCE_ENABLE_DECODING
											  group:PREFERENCE_GROUP];
		
	}
}

@end
