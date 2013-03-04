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

#import <Cocoa/Cocoa.h>

typedef struct _Num {
    double		d;
    unsigned long long	i;
    NSString		*err;
} Num;

@interface Controller : NSObject
{
    IBOutlet id xOut;
    IBOutlet id yOut;
    IBOutlet id mOut;
    IBOutlet id	basePopup;
    IBOutlet id	sizePopup;
    IBOutlet id keyPad;
    IBOutlet id mathPad;
    IBOutlet id bitPad;
    IBOutlet id	asciiTable;
    IBOutlet id	asciiTableMatrix;
    NSString	*op;
    BOOL	freezeX;
    BOOL	yIsSet;
    int		base;
    int		angleType;
    int		numSize;
    char	xBuf[128];
    char	*xBufEnd;
    Num		x;
    Num		y;
    Num		m;
}

- (int)base;
- (int)numSize;
- (void)zeroNum:(Num*)v;

- (IBAction)enterDigit:(id)sender;
- (BOOL)addDigit:(int)digit;
- (BOOL)deleteDigit;
- (IBAction)doOp:(id)sender;
- (void)limitNum:(Num*)v;

// arithmetic methods
- (void)multiply;
- (void)divide;
- (void)add;
- (void)subtract;
- (void)changeSign;
- (void)factorial;
- (void)modulo;
- (void)yRaisedToX;
- (void)addOne;
- (void)subOne;
- (void)squared;
- (void)sqrt;

// math methods
- (void)sin;
- (void)asin;
- (void)sinh;
- (void)asinh;
- (void)cos;
- (void)acos;
- (void)cosh;
- (void)acosh;
- (void)tan;
- (void)atan;
- (void)tanh;
- (void)atanh;
- (void)floor;
- (void)ceil;
- (void)round;
- (void)trunc;
- (void)log;
- (void)tenRaisedToX;
- (void)ln;
- (void)eRaisedToX;
- (void)abs;
- (void)logXY;
- (void)invert;
- (void)e;
- (void)pi;

// bit operation methods
- (void)and;
- (void)or;
- (void)xor;
- (void)not;
- (void)shiftLeft;
- (void)shiftRight;

// register operator methods
- (void)memClear;
- (void)memAdd;
- (void)memRecall;
- (void)swapXY;
- (void)swapXM;
- (void)swapYM;

- (IBAction)clear:(id)sender;
- (IBAction)clearAll:(id)sender;
- (void)allClear;
- (void)equals;

- (IBAction)setBase:(id)sender;
- (void)setBaseValue:(int)v;
- (IBAction)setAngleType:(id)sender;
- (IBAction)setNumSize:(id)sender;
- (void)setNumSizeValue:(int)size;
- (void)changeNumSize:(Num*)v oldSize:(int)oSize newSize:(int)nSize;
- (void)setPadEnable;

- (NSString*)formValueString:(Num)v;
- (NSString*)formatAsBinaryString:(unsigned long long)v;
- (NSString*)formatAsOctalString:(unsigned long long)v;
- (NSString*)formatAsAsciiString:(unsigned long long)v;
- (void)displayX;
- (void)displayY;
- (void)displayM;

- (IBAction)showAsciiTable:(id)sender;

@end

@interface Controller(ApplicationNotifications)

- (void)applicationDidFinishLaunching:(NSNotification*)notification;

 @end
 
@interface Controller(WindowNotifications)

- (void)windowWillClose:(NSNotification*)aNotification;

@end
