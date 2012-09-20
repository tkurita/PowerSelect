#import "ClickableBox.h"


@implementation ClickableBox

- (void)mouseUp:(NSEvent *)theEvent
{
	if (delegate) {
		if ([theEvent clickCount] > 1) {
			[delegate clickableBoxDoubleClicked:self];
		}
	}
}

@end
