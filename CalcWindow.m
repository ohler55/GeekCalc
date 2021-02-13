/* Copyright (C) 2004, 2005 Peter Ohler
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc., 59
 * Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "CalcWindow.h"
#import "Controller.h"

@implementation CalcWindow

- (id)initWithContentRect:(NSRect)contentRect
    styleMask:(unsigned int)aStyle
    backing:(NSBackingStoreType)bufferingType
    defer:(BOOL)flag
{
    [self setInitialFirstResponder: (id)self];

    return [super initWithContentRect: contentRect
        styleMask: aStyle
        backing: bufferingType
        defer: flag];
}

- (void)sendEvent:(NSEvent*)event
{
    /* The key down events need to be captured here and not in the keyDown
     * method since the first responder is not always the view we want and
     * controlling the first responder to be only the expression field or the
     * main view does not seem to be possible. */
    if (NSEventTypeKeyDown == [event type]) {
        [self keyDown: event];
    } else {
        [super sendEvent: event];
    }
}

- (void)keyDown:(NSEvent*)event
{
    //NSLog([event description]);
    int	key = [[event characters] characterAtIndex: 0];
    int code = [event keyCode];

    if (NSClearLineFunctionKey == key) {
	[controller clear: self];
    } else if (8 == key || 127 == key) {
        if (![controller deleteDigit]) {
            [super keyDown: event];
        }
    } else if (256 == [controller base]) {
        if (![controller addDigit: key]) {
            [super keyDown: event];
        }
    } else {
        id	button = [self findButton: key keyCode: code];
        
        if (nil != button) {
            [button performClick: self];
        } else {
            [super keyDown: event];
        }
    }
}

- (id)findButton:(int)key keyCode:(int)code
{
    if (27 == key) {
        return clearKey;
    } else if ('/' == key) {
        return divideKey;
    } else if ('*' == key) {
        return multiplyKey;
    } else if (',' == key) {
        return [self findViewButton: [self contentView] buttonTitle: '.'];
    } else if ([controller numSize] == 0 && ('e' == key || 'E' == key)) {
        return eeKey;
    } else {
        return [self findViewButton: [self contentView] buttonTitle: key];
    }
}

- (id)findViewButton:(NSView*)view buttonTitle:(char)key
 {
    NSString	*viewTitle;
    char	upKey = toupper(key);
    
    if ([view isKindOfClass: [NSButton class]]) {
        NSButton	*button = (NSButton*)view;
        
        if (![button isEnabled]) {
            return nil;
        }
        viewTitle = [button title];
        if (1 == [viewTitle length] && upKey == toupper(*[viewTitle cString])) {
            return button;
        }
    } else if ([view isKindOfClass: [NSMatrix class]]) {
        NSArray	*cells = [(NSMatrix*)view cells];
        id		c;
        int		i;
    
        for (i = (int)[cells count] - 1; 0 <= i; i--) {
            c = [cells objectAtIndex: i];
            if (![c isEnabled]) {
                continue;
            }
            viewTitle = [c title];
            if (1 == [viewTitle length] && upKey == toupper(*[viewTitle cString])) {
                return c;
            }
        }
    } else {
        NSEnumerator	*e = [[view subviews] objectEnumerator];
        id		button;
        
        while (nil != (view = [e nextObject])) {
            if (nil != (button = [self findViewButton: view buttonTitle: key]) && clearKey != button) {
                return button;
            }
        }
    }
    return nil;
 }
 
@end
