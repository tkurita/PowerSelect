#import "AppController.h"
#import "DonationReminder/DonationReminder.h"
#import "CocoaLib/StringExtra.h"
#import "CocoaLib/PathExtra.h" // will be removed
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
	[[[PowerSelectWindowController alloc] initWithWindowNibName:@"PowerSelectWindow"] 
		showWindow:self];
	
	[DonationReminder remindDonation];	
}

- (int)countResultRows
{
	return [searchResult count];
}

- (void)clearSearchResult
{
	[searchResult release];
	searchResult = nil;
}

- (void)setSearchResult:(NSArray *)an_array // obsolute
{
	NSMutableArray *result_array = [NSMutableArray array];
	
	if ([an_array count] < 1) {
		NSString *message = NSLocalizedString(@"NoItemsFound",@"");
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:message forKey:@"name"];
		[result_array addObject:dict];
		goto bail;
	}
	
	NSEnumerator *enumerator = [an_array objectEnumerator];
	NSString *a_path;
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	while (a_path = [enumerator nextObject]) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:a_path forKey:@"path"];
		[dict setObject:[workspace iconForFile:a_path] forKey:@"icon"];
		NSString *a_kind;
		LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:a_path], (CFStringRef *)&a_kind);
		[dict setObject:a_kind forKey:@"kind"];
		[dict setObject:[file_manager displayNameAtPath:a_path] forKey:@"name"];
		[result_array addObject:dict];
	}
bail:
	[searchResult release];
	searchResult = [result_array retain];
}

- (NSArray *)tableSelection
{
	return [searchResultController valueForKeyPath:@"selectedObjects.path"];
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

#pragma mark search directory
// will be removed
- (NSArray *)searchAtDirectory:(NSString*)path withString:(NSString*)subText withMethod:(NSString *)methodName
{
	NSFileManager *file_manager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enumerator = [file_manager enumeratorAtPath:path];
	NSString *item_name;
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:1];
	SEL selector = NSSelectorFromString(methodName);
	while (item_name = [enumerator nextObject]) {
		BOOL matched = [(NSNumber *)[item_name performSelector:selector withObject:subText] boolValue];
		if (matched) {
			NSString *matched_item = [path stringByAppendingPathComponent:item_name];
			if ([matched_item isVisible]) [results addObject:matched_item];
		}
		[enumerator skipDescendents];
	}
	
	return results;
}

@end
