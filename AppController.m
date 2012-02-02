#import "AppController.h"
#import "DonationReminder/DonationReminder.h"
#import "CocoaLib/StringExtra.h"

#define CMPARE_OPTIONS NSCaseInsensitiveSearch
@implementation NSString (PowerSelectExtra)

- (BOOL)nameContain:(NSString *)containedText
{
	return [self contain:containedText options:CMPARE_OPTIONS];
}

- (BOOL)nameNotContain:(NSString *)containedText
{
	return ![self contain:containedText options:CMPARE_OPTIONS];
}

- (BOOL)nameHasPrefix:(NSString *)text
{
	return [self hasPrefix:text options:CMPARE_OPTIONS];
}

- (BOOL)nameNotHasPrefix:(NSString *)text
{
	return ![self hasPrefix:text options:CMPARE_OPTIONS];
}

- (BOOL)nameHasSuffix:(NSString *)text
{
	return [self hasSuffix:text options:CMPARE_OPTIONS];
}

- (BOOL)nameNotHasSuffix:(NSString *)text
{
	return ![self hasSuffix:text options:CMPARE_OPTIONS];
}
@end

@implementation AppController

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif	
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

- (void)setSearchResult:(NSArray *)an_array
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

- (NSArray *)searchAtDirectory:(NSString*)path withString:(NSString*)subText withMethod:(NSString *)methodName
{
	NSFileManager *file_manager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enumerator = [file_manager enumeratorAtPath:path];
	NSString *item_name;
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:1];
	SEL selector = NSSelectorFromString(methodName);
	while (item_name = [enumerator nextObject]) {
		BOOL matched = (BOOL)[item_name performSelector:selector withObject:subText];
		if (matched) {
			[results addObject:[path stringByAppendingPathComponent:item_name]];
		}
		[enumerator skipDescendents];
	}
	
	return results;
}

@end
