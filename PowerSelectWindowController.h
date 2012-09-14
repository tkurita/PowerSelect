#import <Cocoa/Cocoa.h>


@interface PowerSelectWindowController : NSWindowController {
	NSString *searchText;
	NSString *searchLocation;
	NSArray *searchResult;
	BOOL isFound;
	unsigned int modeIndex;
	IBOutlet id progressIndicator;
	IBOutlet id candidateDrawer;
	IBOutlet id candidateTable;
	IBOutlet id candidateTableScrollView;
	IBOutlet id searchComboBox;
	IBOutlet id selectAllButton;
	IBOutlet id selectButton;
}

@property(retain) NSString *searchText;
@property(retain) NSString *searchLocation;
@property(assign) unsigned int modeIndex;

- (IBAction)performSearch:(id)sender;
- (IBAction)performSelect:(id)sender;
- (IBAction)performSelectAll:(id)sender;

@end
