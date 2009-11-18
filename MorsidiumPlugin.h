#import <Adium/AIPlugin.h>
#import <Adium/AIChatControllerProtocol.h>

#define	PREFERENCE_GROUP					@"Morsidium"
#define PREFERENCE_ENABLE_DECODING		    @"EnableDecoding"

@interface MorsidiumPlugin : AIPlugin {
	NSDictionary *morse2latin;
	NSDictionary *latin2morse;
	NSArray *sortedMorse;
	NSMenuItem *menuItem;
	BOOL enableDecoding;
}

@end
