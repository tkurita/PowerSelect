#import <Cocoa/Cocoa.h>

@interface FindInsertionLocation : NSObject
- (FindInsertionLocation *)makeLocator;
- (NSString *)insertionPath;
- (BOOL)selectInFinder:(NSArray *)array;
@end


@interface PowerSelectWindowController : NSWindowController {
	BOOL isFound;
	IBOutlet id progressIndicator;
	IBOutlet id candidateDrawer;
	IBOutlet id candidateTable;
	IBOutlet id candidateTableScrollView;
	IBOutlet id searchComboBox;
	IBOutlet id selectAllButton;
	IBOutlet id selectButton;
	IBOutlet id searchResultController;
    IBOutlet id findInsertionLocation;
}

@property(retain) NSString *searchText;
@property(retain) NSString *searchLocation;
@property(retain) FindInsertionLocation *locator;
@property(retain) NSThread *searchThread;
@property(retain) NSMutableArray *searchResult;
@property(assign) unsigned int modeIndex;

- (IBAction)performSearch:(id)sender;
- (IBAction)performSelect:(id)sender;
- (IBAction)performSelectAll:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
