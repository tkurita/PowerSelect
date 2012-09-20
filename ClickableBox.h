#import <Cocoa/Cocoa.h>


@interface ClickableBox : NSBox {
	IBOutlet id delegate;
}

@end

@protocol ClickableBoxDelegateProtocol

- (void)clickableBoxClicked:(id)sender;

- (void)clickableBoxDoubleClicked:(id)sender;

@end
 