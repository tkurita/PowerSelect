/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet id searchResult;
	IBOutlet id searchResultController;	
}

- (IBAction)makeDonation:(id)sender;
- (IBAction)newWindow:(id)sender;

@end

@interface NSString (PowerSelectExtra) 

- (NSNumber *)nameContain:(NSString *)containedText;
- (NSNumber *)nameNotContain:(NSString *)containedText; 
- (NSNumber *)nameHasPrefix:(NSString *)text;
- (NSNumber *)nameNotHasPrefix:(NSString *)text;
- (NSNumber *)nameHasSuffix:(NSString *)text;
- (NSNumber *)nameNotHasSuffix:(NSString *)text;

@end
