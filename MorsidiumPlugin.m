#import "MorsidiumPlugin.h"
#import "MorsidiumPreferences.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIAdiumProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIListObject.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentObject.h>

@implementation MorsidiumPlugin

NSComparisonResult invertedLengthSort(NSString *s1, NSString *s2, void *context) {
	NSUInteger l1 = [s1 length];
	NSUInteger l2 = [s2 length];
	
	if (l1 > l2) {
		return NSOrderedAscending;
	} else if (l1 < l2) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}


/*!
 * @brief Initialize default values and register observers
 */
- (void)installPlugin
{
	NSArray *morse = [NSArray arrayWithObjects:@".-", @"-...", @"-.-.", @"-..", @".", @"..-.", @"--.", @"....", @"..", @".---", @"-.-", @".-..", @"--", @"-.", @"---", @".--.", @"--.-", @".-.", @"...", @"-", @"..-", @"...-", @".--", @"-..-", @"-.--", @"--..", @".--.-", @".-.-", @"..-..", @"--.--", @"---.", @"..--", @".----", @"..---", @"...--", @"....-", @".....", @"-....", @"--...", @"---..", @"----.", @"-----", @"--..--", @".-.-.-", @"..--..", @"-.-.-", @"---...", @"-..-.", @"-....-", @".----.", @"-.--.-", @"..--.-", nil];
	NSArray *latin = [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"Á", @"Ä", @"É", @"Ñ", @"Ö", @"Ü", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", @",", @".", @"?", @";", @":", @"/", @"-", @"'", @"()", @"_", nil];

	morse2latin = [[NSDictionary alloc] initWithObjects:latin forKeys:morse];	
	latin2morse = [[NSDictionary alloc] initWithObjects:morse forKeys:latin];
	sortedMorse = [morse sortedArrayUsingFunction:invertedLengthSort context:nil];
	[sortedMorse retain];

	menuItem = [[NSMenuItem alloc] initWithTitle:@"Morsidium..."
										  target:self
										  action:@selector(showPreferences:)
								   keyEquivalent:@""];
	
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Adium_Preferences];
		
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREFERENCE_GROUP];
}

/*!
 * @brief Remove observers
 */
- (void)uninstallPlugin
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[sortedMorse release];
	[morse2latin release];
	[latin2morse release];
	[menuItem release];
	
	[super dealloc];
}

/*! 
 * @brief The menu item is always valid
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return YES;
}

/*!
 * @brief Ask the preferences dialog to display.
 */
- (IBAction)showPreferences:(id)sender
{
	[MorsidiumPreferences showWindow];
}

#pragma mark Chat handing
/*!
 * @brief Handles content before it's displayed
 */
- (void)willReceiveContent:(NSNotification *)notification
{
	if (!enableDecoding) {
		return;
	}
	
	AIContentObject *contentObject = [[notification userInfo] objectForKey:@"Object"];
	[contentObject setDisplayContent:YES];
	NSString *whitespacelessData = [[[contentObject message] string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	/* Will only attempt to decode Morse if more than half of the string contains dots or dashes. Ignores whitespace. */
	unichar *charBuffer = calloc([whitespacelessData length], sizeof(unichar));
	[whitespacelessData getCharacters:charBuffer];
	int morseChars = 0;
	int totalChars = [whitespacelessData length];
	for (int i = 0; i < totalChars; i++, charBuffer++) {
		if ((*charBuffer == '-') || (*charBuffer == '.')) {
			morseChars++;
		}
	}
	free(charBuffer);
	
	
	BOOL shouldDecode = (morseChars) > (totalChars / 2);
	
	if (shouldDecode) {
		NSMutableString *data = [[NSMutableString alloc] initWithString:[[contentObject message] string]];

		for (id morse in sortedMorse) {
			NSString *latin = [morse2latin objectForKey:morse];
			[data replaceOccurrencesOfString:morse
								  withString:latin
									 options:NSLiteralSearch
									   range:NSMakeRange(0, [data length])];
		}
		
		NSMutableAttributedString *newMessage = [[NSMutableAttributedString alloc] initWithAttributedString:[contentObject message]];
		NSString *additionString = [NSString stringWithFormat:@"&nbsp;<i>(Morse Decoding: %@)</i>", data];
		
		NSAttributedString *addition = [[NSAttributedString alloc] initWithHTML:[additionString dataUsingEncoding:NSASCIIStringEncoding] documentAttributes:NULL];
		[newMessage appendAttributedString:addition];
		[contentObject setMessage:newMessage];
		
		[addition release];
		[data release];
	}
}

#pragma mark Preferences handling
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime

{
	if (object) {
		return;
	}
	
	if([key isEqualToString:PREFERENCE_ENABLE_DECODING] || firstTime) {
		enableDecoding = [[prefDict objectForKey:PREFERENCE_ENABLE_DECODING] boolValue];
		
		if (enableDecoding) {
			[[adium notificationCenter] addObserver:self
										   selector:@selector(willReceiveContent:)
											   name:Content_WillReceiveContent
											 object:nil];	
			
		} else if(!firstTime) {
			[[adium notificationCenter] removeObserver:self];
		}
	}
}

@end
