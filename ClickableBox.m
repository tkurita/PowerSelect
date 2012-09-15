#import "ClickableBox.h"


@implementation ClickableBox

- (void)mouseUp:(NSEvent *)theEvent
{
	if (delegate) {
		[delegate clickableBoxClicked:self];
	}
}

@end
