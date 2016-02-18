#import "PowerSelectWindowController.h"
#import "PathExtra.h"

extern OSAScript* loadScript(NSString *script_name);
extern void showError(NSDictionary *err_info);

@implementation PowerSelectWindowController

@synthesize searchText;
@synthesize searchLocation;
@synthesize locator;
@synthesize modeIndex;
@synthesize searchThread;
@synthesize searchResult;


- (IBAction) cancelAction:(id)sender
{
	if (searchThread && [searchThread isExecuting]) {
		[searchThread cancel];
	} else {
		[self close];
	}
}

- (void)clickableBoxDoubleClicked:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:searchLocation];
}

- (IBAction)performSelectWithoutClosing:(id)sender
{
	NSArray *array = [searchResultController valueForKeyPath:@"selectedObjects.path"];
	NSDictionary *error_info = nil;
	NSArray *args = [NSArray arrayWithObject:array];
	[locator executeHandlerWithName:@"select_in_finder" arguments:args error:&error_info];
	if (error_info) {
		showError(error_info);
	}		
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


- (SEL)searchMethod
{
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
	return search_method;
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

- (void)searchThreadDidEnd:(NSNotification *)notification
{
	if ([candidateDrawer state] ==  NSDrawerClosedState) {
		[candidateDrawer open];
		[self setupDrawer];
	} else {
		[self setupDrawer];
	}
	
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];
}

- (void)searchInThread:(id)sender
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	SEL selector = [self searchMethod];
	NSFileManager *file_manager = [NSFileManager new];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSDirectoryEnumerator *enumerator = [file_manager enumeratorAtPath:searchLocation];
	NSString *item_name;
	isFound = NO;
	while (item_name = [enumerator nextObject]) {
		if ([searchThread isCancelled]) {
			goto bail;
		}
		BOOL matched = [(NSNumber *)[item_name performSelector:selector withObject:searchText] boolValue];
		if (matched) {
			NSString *matched_item = [searchLocation stringByAppendingPathComponent:item_name];
			if ([matched_item isVisible]) {
				NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:matched_item 
																			   forKey:@"path"];
				[dict setObject:[workspace iconForFile:matched_item] forKey:@"icon"];
				NSString *a_kind;
				LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:matched_item], 
									   (CFStringRef *)&a_kind);
				[dict setObject:a_kind forKey:@"kind"];
				[dict setObject:[file_manager displayNameAtPath:matched_item] forKey:@"name"];
				[searchResultController performSelectorOnMainThread:@selector(addObject:)
														 withObject:dict waitUntilDone:NO];
				isFound = YES;
			}
		}
		[enumerator skipDescendents];
	}
	
	if (!isFound) {
		NSString *message = NSLocalizedString(@"NoItemsFound",@"");
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:message forKey:@"name"];
		[searchResultController addObject:dict];		
	}
bail:
	[self performSelectorOnMainThread:@selector(searchThreadDidEnd:)
						   withObject:nil waitUntilDone:NO];
	[file_manager release];
	[pool release];
}

/*
- (void)drawerDidOpen:(NSNotification *)notification
{
	[self setupDrawer];
}
*/
 
- (IBAction)performSearch:(id)sender
{
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	
	static OSAScript *insertionLocatorScript = nil;
	if (!insertionLocatorScript) {
		insertionLocatorScript = loadScript(@"InsertionLocator");
		if (!insertionLocatorScript) goto error;
	}
	
	NSDictionary *error_info = nil;
	NSAppleEventDescriptor *result_desc = [insertionLocatorScript executeAndReturnError:&error_info];
	if (error_info) {
		showError(error_info);
		goto error;
	}
	OSAScript *locator_script = [[OSAScript alloc] initWithCompiledData:[result_desc data] 
																  error:&error_info];
	if (error_info) {
		showError(error_info);
		goto error;
	}	
	self.locator = locator_script;
	result_desc = [locator executeHandlerWithName:@"insertion_path" arguments:nil
											error:&error_info];
	DescType desc_type = [result_desc descriptorType];
	if (desc_type == 'type') {
		if ([result_desc typeCodeValue] == 'msng') {
			goto error;
		}
	}
	
	NSString *path = [result_desc stringValue];

	self.searchLocation = path;
	self.searchThread = [[[NSThread alloc] initWithTarget:self selector:@selector(searchInThread:)
							  object:self] autorelease];

	self.searchResult = [NSMutableArray arrayWithCapacity:1];
	[searchThread start];
	
	if ([candidateDrawer state] ==  NSDrawerClosedState) {
		[candidateDrawer open];
	}
	
	goto bail;

error:	
	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];
bail:
	return;
}

- (void)dealloc
{
	[searchText release];
	[searchLocation release];
	[searchResult release];
	[locator release];
	[searchThread release];
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
	[candidateTable setDoubleAction:@selector(performSelectWithoutClosing:)];
}

@end
