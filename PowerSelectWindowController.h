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

@property(strong) NSString *searchText;
@property(strong) NSString *searchLocation;
@property(strong) FindInsertionLocation *locator;
@property(strong) NSThread *searchThread;
@property(strong) NSMutableArray *searchResult;
@property(assign) NSInteger modeIndex;

- (IBAction)performSearch:(id)sender;
- (IBAction)performSelect:(id)sender;
- (IBAction)performSelectAll:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
