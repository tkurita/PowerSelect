#import "PowerSelectWindowController.h"
#import "CocoaLib/PathExtra.h"

extern OSAScript* loadScript(NSString *script_name);
extern void showError(NSDictionary *err_info);

@implementation PowerSelectWindowController

@synthesize searchText;
@synthesize searchLocation;
@synthesize locator;
@synthesize modeIndex;

- (void)clickableBoxDoubleClicked:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:searchLocation];
}

- (IBAction)performSelect:(id)sender
{
	NSArray *array = [searchResultController valueForKeyPath:@"selectedObjects.path"];
	NSDictionary *error_info = nil;
	NSArray *args = [NSArray arrayWithObject:array];
	[locator executeHandlerWithName:@"select_in_finder" arguments:args error:&error_info];
	if (error_info) {
		showError(error_info);
	} else {
		[self close];
	}
}

- (IBAction)performSelectAll:(id)sender
{
	NSArray *array = [searchResultController valueForKeyPath:@"arrangedObjects.path"];
	NSDictionary *error_info = nil;
	NSArray *args = [NSArray arrayWithObject:array];
	[locator executeHandlerWithName:@"select_in_finder" arguments:args error:&error_info];
	if (error_info) {
		showError(error_info);
	} else {
		[self close];
	}
}

- (void)setSearchResult:(NSArray *)an_array
{
	NSMutableArray *result_array;
	if (an_array) {
		result_array = [NSMutableArray array];
	} else {
		result_array = [NSMutableArray arrayWithCapacity:1];
	}

	
	if (!an_array) {
		NSString *message = NSLocalizedString(@"NoItemsFound",@"");
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:message forKey:@"name"];
		[result_array addObject:dict];
		isFound = NO;
		goto bail;
	}
	isFound = YES;
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

- (NSArray *)searchAtDirectory:(NSString*)path withMethod:(SEL)selector
{
	self.searchLocation = path;
	NSFileManager *file_manager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enumerator = [file_manager enumeratorAtPath:path];
	NSString *item_name;
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:1];
	BOOL is_found = NO;
	while (item_name = [enumerator nextObject]) {
		BOOL matched = [(NSNumber *)[item_name performSelector:selector withObject:searchText] boolValue];
		if (matched) {
			NSString *matched_item = [path stringByAppendingPathComponent:item_name];
			if ([matched_item isVisible]) {
				[results addObject:matched_item];
				is_found = YES;
			}
		}
		[enumerator skipDescendents];
	}
	
	if (is_found) {
		return results;
	} else {
		return nil;
	}

}

- (void)setupDrawer
{
	[candidateTableScrollView setNextKeyView:searchComboBox];
	CGFloat row_height = [candidateTable rowHeight];
	NSSize spacing = [candidateTable intercellSpacing];
	CGFloat table_height = (row_height + spacing.height) * ([searchResult count] +1);
	NSRect view_rect = [candidateTableScrollView visibleRect];
	CGFloat scroll_view_height = view_rect.size.height;
	CGFloat height_diff = table_height - scroll_view_height;
	NSSize drawer_size = [candidateDrawer contentSize];
	CGFloat drawer_height= drawer_size.height + height_diff;
	
	NSSize drawer_max_size = [candidateDrawer maxContentSize];
	
	if (drawer_height > drawer_max_size.height) {
		drawer_size.height = drawer_max_size.height;
	} else {
		drawer_size.height = drawer_height;
	}
	
	[candidateDrawer setContentSize:drawer_size];
	
	if (isFound) {
		[selectAllButton setEnabled:YES];
	} else {
		[selectAllButton setEnabled:NO];
	}
	[selectButton setEnabled:NO];
}

- (void)drawerDidOpen:(NSNotification *)notification
{
	[self setupDrawer];
}

- (IBAction)performSearch:(id)sender
{
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	static OSAScript *insertionLocatorScript = nil;
	if (!insertionLocatorScript) {
		insertionLocatorScript = loadScript(@"InsertionLocator");
		if (!insertionLocatorScript) goto bail;
	}
	
	NSDictionary *error_info = nil;
	NSAppleEventDescriptor *result_desc = [insertionLocatorScript executeAndReturnError:&error_info];
	if (error_info) {
		showError(error_info);
		goto bail;
	}
	OSAScript *locator_script = [[OSAScript alloc] initWithCompiledData:[result_desc data] 
																  error:&error_info];
	if (error_info) {
		showError(error_info);
		goto bail;
	}	
	self.locator = locator_script;
	result_desc = [locator executeHandlerWithName:@"insertion_path" arguments:nil
											error:&error_info];
	DescType desc_type = [result_desc descriptorType];
	if (desc_type == 'type') {
		if ([result_desc typeCodeValue] == 'msng') {
			goto bail;
		}
	}
	
	NSString *path = [result_desc stringValue];
	
	SEL search_method;
	switch (modeIndex) {
		case 0:
			search_method = @selector(nameContain:);
			break;
		case 1:
			search_method = @selector(nameNotContain:);
			break;
		case 3:
			search_method = @selector(nameHasPrefix:);
			break;
		case 4:
			search_method = @selector(nameNotHasPrefix:);
			break;
		case 6:
			search_method = @selector(nameHasSuffix:);
			break;
		case 7:
			search_method = @selector(nameNotHasSuffix:);
			break;
		default:
			search_method = @selector(nameNotContain:);
			break;
	}
	
	NSArray *search_resut = [self searchAtDirectory:path withMethod:search_method];

	[self setSearchResult:search_resut];
	
	if ([candidateDrawer state] ==  NSDrawerClosedState) {
		[candidateDrawer open];
	} else {
		[self setupDrawer];
	}
bail:
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];

	return;
}

- (void)dealloc
{
	[searchText release];
	[searchLocation release];
	[searchResult release];
	[locator release];
	[super dealloc];
}

- (void)saveHistory
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *searchtext_history = [user_defaults objectForKey:@"SearchTextHistory"];
	
	unsigned int hist_max = [user_defaults integerForKey:@"HistoryMax"];
	
	if ((searchText != nil) && (![searchText isEqualToString:@""])) {
		if (![searchtext_history containsObject:searchText]) {
			searchtext_history = [searchtext_history mutableCopy];
			[searchtext_history insertObject:searchText atIndex:0];
			if ([searchtext_history count] > hist_max) {
				[searchtext_history removeLastObject];
			}
			[user_defaults setObject:searchtext_history forKey:@"SearchTextHistory"];
		}
	}
}

- (void)windowWillClose:(NSNotification*)notification
{	
	//[super windowWillClose:notification];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:searchText forKey:@"SearchText"];
	[user_defaults setInteger:modeIndex	forKey:@"ModePopup"];
	[self saveHistory];
	[user_defaults synchronize];
	[self autorelease];
}

- (void)awakeFromNib
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	self.searchText = [user_defaults stringForKey:@"SearchText"];
	self.modeIndex = [user_defaults integerForKey:@"ModePopup"];
	[candidateTable setDoubleAction:@selector(performSelect:)];
}

@end
