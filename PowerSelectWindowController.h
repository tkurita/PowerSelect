#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

@interface PowerSelectWindowController : NSWindowController {
	NSString *searchText;
	NSString *searchLocation;
	NSMutableArray *searchResult;
	OSAScript *locator;
	NSThread *searchThread;
	BOOL isFound;
	unsigned int modeIndex;
	IBOutlet id progressIndicator;
	IBOutlet id candidateDrawer;
	IBOutlet id candidateTable;
	IBOutlet id candidateTableScrollView;
	IBOutlet id searchComboBox;
	IBOutlet id selectAllButton;
	IBOutlet id selectButton;
	IBOutlet id searchResultController;
}

@property(retain) NSString *searchText;
@property(retain) NSString *searchLocation;
@property(retain) OSAScript *locator;
@property(retain) NSThread *searchThread;
@property(retain) NSMutableArray *searchResult;
@property(assign) unsigned int modeIndex;

- (IBAction)performSearch:(id)sender;
- (IBAction)performSelect:(id)sender;
- (IBAction)performSelectAll:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
