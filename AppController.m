#import "AppController.h"
#import "DonationReminder/DonationReminder.h"
#import "CocoaLib/StringExtra.h"
#import <OSAKit/OSAScript.h>
#import "PowerSelectWindowController.h"

#define CMPARE_OPTIONS NSCaseInsensitiveSearch
@implementation NSString (PowerSelectExtra)

- (NSNumber *)nameContain:(NSString *)containedText
{
	return [NSNumber numberWithBool:[self contain:containedText options:CMPARE_OPTIONS]];
}

- (NSNumber *)nameNotContain:(NSString *)containedText
{
	return [NSNumber numberWithBool:![self contain:containedText options:CMPARE_OPTIONS]];
}

- (NSNumber *)nameHasPrefix:(NSString *)text
{
	return [NSNumber numberWithBool:[self hasPrefix:text options:CMPARE_OPTIONS]];
}

- (NSNumber *)nameNotHasPrefix:(NSString *)text
{
	return [NSNumber numberWithBool:![self hasPrefix:text options:CMPARE_OPTIONS]];
}

- (NSNumber *)nameHasSuffix:(NSString *)text
{
	return [NSNumber numberWithBool:[self hasSuffix:text options:CMPARE_OPTIONS]];
}

- (NSNumber *)nameNotHasSuffix:(NSString *)text
{
	return [NSNumber numberWithBool:![self hasSuffix:text options:CMPARE_OPTIONS]];
}
@end

@implementation AppController

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


void showError(NSDictionary *err_info)
{
	NSLog(@"Error : %@", [err_info description]);
	NSLog(@"%@", err_info);
	[NSApp activateIgnoringOtherApps:YES];
	NSRunAlertPanel(nil, [err_info objectForKey:OSAScriptErrorMessage], 
					@"OK", nil, nil);	
}

OSAScript* loadScript(NSString *script_name)
{
	NSDictionary *err_info = nil;
	NSString *path = [[NSBundle mainBundle] pathForResource:script_name
													 ofType:@"scpt" inDirectory:@"Scripts"];
	
	OSAScript *scpt = [[OSAScript alloc] initWithContentsOfURL:
					   [NSURL fileURLWithPath:path] error:&err_info];
	
	if (err_info) {
		showError(err_info);
		if (scpt) {
			[scpt release];
			scpt = nil;
		}
	}
	
	return scpt;
}

BOOL checkGUIScripting()
{
	NSDictionary *err_info = nil;
	OSAScript *scpt = loadScript(@"CheckGUIScripting");
	if (!scpt) return NO;
	
	NSAppleEventDescriptor *result_desc = [scpt executeAndReturnError:&err_info];
	if (err_info) {
		showError(err_info);
		if (scpt) [scpt release];
	}
	DescType result_type = [result_desc descriptorType];
	
	return result_type == 'true';
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif	
	
	if (!checkGUIScripting()) {
		[NSApp terminate:self];
		return;
	}
		
		
	/* checking checking UI Elements Scripting ... */
	/*
	if (!AXAPIEnabled()) {
		[NSApp activateIgnoringOtherApps:YES];
		int ret = NSRunAlertPanel(NSLocalizedString(@"disableUIScripting", ""), @"", 
							NSLocalizedString(@"Launch System Preferences", ""),
							NSLocalizedString(@"Cancel",""), @"");
		switch (ret)
        {
            case NSAlertDefaultReturn:
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
                break;
			default:
                break;
        }
        
		[NSApp terminate:self];
		return;
    }
	*/
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary *defautlsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:defautlsDict];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	NSAppleEventDescriptor *ev = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
	AEEventID evid = [ev eventID];
	BOOL should_open_window = YES;
	NSAppleEventDescriptor *propData;
	switch (evid) {
		case kAEOpenDocuments:
			break;
		case kAEOpenApplication:
			propData = [ev paramDescriptorForKeyword: keyAEPropData];
			DescType type = propData ? [propData descriptorType] : typeNull;
			OSType value = 0;
			if(type == typeType) {
				value = [propData typeCodeValue];
				switch (value) {
					case keyAELaunchedAsLogInItem:
						break;
					case keyAELaunchedAsServiceItem:
						should_open_window = NO;
						break;
				}
			} else {
			}
			break;
	}
	
	if (should_open_window) {
		[[[PowerSelectWindowController alloc] initWithWindowNibName:@"PowerSelectWindow"] 
			showWindow:self];
	}
	
	[DonationReminder remindDonation];	
}

- (IBAction)newWindow:(id)sender
{
	[[[PowerSelectWindowController alloc] initWithWindowNibName:@"PowerSelectWindow"] 
	 showWindow:self];	
}
- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)awakeFromNib
{
	[NSApp setServicesProvider:self];
}

- (void)searchInFront:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	NSString *pboard_string;
    NSArray *types;
	
    types = [pboard types]; // ペーストボード内のデータ型
	
    if (![types containsObject:NSStringPboardType] // NSStringPboardTypeでない
        || !(pboard_string = [pboard stringForType:NSStringPboardType])) { 
        *error = NSLocalizedString(@"Error: Pasteboard doesn't contain a string.",
								   @"Pasteboard couldn't give string.");
        return;
    }

	PowerSelectWindowController *wc = [[PowerSelectWindowController alloc] initWithWindowNibName:@"PowerSelectWindow"];
	[wc showWindow:self];
	wc.searchText = pboard_string;
	[wc performSearch:self];
	return;
}

@end
