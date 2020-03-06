#import "PowerSelectWindowController.h"
#import "PathExtra/PathExtra.h"
#import "AppController.h"

@implementation PowerSelectWindowController

- (IBAction) cancelAction:(id)sender
{
	if (_searchThread && [_searchThread isExecuting]) {
		[_searchThread cancel];
	} else {
		[self close];
	}
}

- (void)clickableBoxDoubleClicked:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:_searchLocation];
}

- (IBAction)performSelectWithoutClosing:(id)sender
{
	NSArray *array = [searchResultController valueForKeyPath:@"selectedObjects.path"];
    [_locator selectInFinder:array];
}

- (IBAction)performSelect:(id)sender
{
	NSArray *array = [searchResultController valueForKeyPath:@"selectedObjects.path"];
    if ([_locator selectInFinder:array]) {
        [self close];
    }
}

- (IBAction)performSelectAll:(id)sender
{
	NSArray *array = [searchResultController valueForKeyPath:@"arrangedObjects.path"];
    if ([_locator selectInFinder:array]) {
        [self close];
    }
}

typedef BOOL (^SearchHandler)(NSString *, NSString *);

- (SearchHandler)obtainSearchHandler
{
    switch (_modeIndex) {
        case 0:
            return ^BOOL (NSString *target, NSString *search_text){
                    return [[target nameContain:search_text] boolValue];};
        case 1:
            return ^BOOL (NSString *target, NSString *search_text){
                    return [[target nameNotContain:search_text] boolValue];};
        case 3:
            return ^BOOL (NSString *target, NSString *search_text){
                    return [[target nameHasPrefix:search_text] boolValue];};
        case 4:
            return ^BOOL (NSString *target, NSString *search_text){
                    return [[target nameNotHasPrefix:search_text] boolValue];};
        case 6:
            return ^BOOL (NSString *target, NSString *search_text){
                    return [[target nameHasSuffix:search_text] boolValue];};
        case 7:
            return ^BOOL (NSString *target, NSString *search_text){
                    return [[target nameNotHasSuffix:search_text] boolValue];};
        default:
            return ^BOOL (NSString *target, NSString *search_text){
                    return [[target nameNotContain:search_text] boolValue];};
    }
}

- (void)setupDrawer
{
	[candidateTableScrollView setNextKeyView:searchComboBox];
	CGFloat row_height = [candidateTable rowHeight];
	NSSize spacing = [candidateTable intercellSpacing];
    NSRect header_rect = [[candidateTable headerView] frame];
	CGFloat table_height = (row_height + spacing.height) * [_searchResult count] + spacing.height + header_rect.size.height;
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
	@autoreleasepool {
        SearchHandler search_handler = [self obtainSearchHandler];
		NSFileManager *file_manager = [NSFileManager new];
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSDirectoryEnumerator *enumerator = [file_manager enumeratorAtPath:_searchLocation];
		NSString *item_name;
		isFound = NO;
		while (item_name = [enumerator nextObject]) {
			if ([_searchThread isCancelled]) {
				goto bail;
			}
            BOOL matched = search_handler(item_name, _searchText);
            if (matched) {
				NSString *matched_item = [_searchLocation stringByAppendingPathComponent:item_name];
				if ([matched_item isVisible]) {
					NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:matched_item 
																				   forKey:@"path"];
					dict[@"icon"] = [workspace iconForFile:matched_item];
                NSError *err = nil;
					NSString *a_kind;
                [[NSURL fileURLWithPath:matched_item] getResourceValue:&a_kind
                                                                forKey:NSURLLocalizedTypeDescriptionKey
                                                                 error:&err];
                if (err) {
                    NSLog(@"%@" ,err);
                } else {
                    dict[@"kind"] = a_kind;
                }
					dict[@"name"] = [file_manager displayNameAtPath:matched_item];
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
	}
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
    self.locator = [findInsertionLocation makeLocator];
    if (!(self.searchLocation = [_locator insertionPath])) {
        goto error;
    }
	self.searchThread = [[NSThread alloc] initWithTarget:self selector:@selector(searchInThread:)
							  object:self];

	self.searchResult = [NSMutableArray arrayWithCapacity:1];
	[_searchThread start];
	
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


- (void)saveHistory
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *searchtext_history = [user_defaults objectForKey:@"SearchTextHistory"];
	
	NSInteger hist_max = [user_defaults integerForKey:@"HistoryMax"];
	
	if ((_searchText != nil) && (![_searchText isEqualToString:@""])) {
		if (![searchtext_history containsObject:_searchText]) {
			searchtext_history = [searchtext_history mutableCopy];
			[searchtext_history insertObject:_searchText atIndex:0];
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
	[user_defaults setObject:_searchText forKey:@"SearchText"];
	[user_defaults setInteger:_modeIndex	forKey:@"ModePopup"];
	[self saveHistory];
	[user_defaults synchronize];
}

- (void)awakeFromNib
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	self.searchText = [user_defaults stringForKey:@"SearchText"];
	self.modeIndex = [user_defaults integerForKey:@"ModePopup"];
	[candidateTable setDoubleAction:@selector(performSelectWithoutClosing:)];
}

@end
