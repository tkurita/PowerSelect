/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet id searchResult;
	IBOutlet id searchResultController;

}

- (IBAction)makeDonation:(id)sender;

@end

@interface NSString (PowerSelectExtra) 

- (BOOL)nameContain:(NSString *)containedText;
- (BOOL)nameNotContain:(NSString *)containedText; 
- (BOOL)nameHasPrefix:(NSString *)text;
- (BOOL)nameNotHasPrefix:(NSString *)text;
- (BOOL)nameHasSuffix:(NSString *)text;
- (BOOL)nameNotHasSuffix:(NSString *)text;

@end
