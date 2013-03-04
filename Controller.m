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

#import "Controller.h"

@implementation Controller

- (int)base
{
    return base;
}

- (int)numSize
{
    return numSize;
}

- (IBAction)clear:(id)sender
{
    [self zeroNum: &x];
    *xBuf = '\0';
    xBufEnd = xBuf;
    [self displayX];
}

- (IBAction)clearAll:(id)sender
{
    [self allClear];
}

- (void)zeroNum:(Num*)v
{
    v->d = 0.0;
    v->i = 0;
    v->err = nil;
}

- (void)allClear
{
    [self zeroNum: &x];
    [self zeroNum: &y];
    [self zeroNum: &m];
    *xBuf = '\0';
    xBufEnd = xBuf;
    freezeX = NO;
    yIsSet = NO;
    op = NULL;
    [self displayX];
    [self displayY];
    [self displayM];
}

- (IBAction)enterDigit:(id)sender
{
    if (freezeX) {
        y = x;
	[self zeroNum: &x];
	*xBuf = '\0';
	xBufEnd = xBuf;
        freezeX = NO;
        yIsSet = YES;
        [self displayY];
    }
    int	tag = [ [sender selectedCell] tag];
    
    if (![self addDigit: tag]) {
        NSBeep();
    }
}

- (BOOL)addDigit:(int)digit
{
    if (0 == numSize) {
	char	c;
	
	if (0 > digit) {
	    if (-1 == digit) {
		c = '.';
	    } else if (-2 == digit) {
		c = 'e';
	    } else {
		return NO;
	    }
	} else if (digit < 10) {
	    c = '0' + digit;
	} else {
	    return NO;
	}
	*xBufEnd++ = c;
	if (-2 == digit) {
	    *xBufEnd++ = '0';
	}
	*xBufEnd = '\0';

	if ('.' == *xBuf && xBufEnd - xBuf == 1) {
	    [self displayX];
	    return YES;
	}
	char	*end;
	double	d = strtod(xBuf, &end);

	if (end != xBufEnd) {
	    if (-2 == digit) {
		xBufEnd--;
	    }
	    xBufEnd--;
	    *xBufEnd = '\0';
	    return NO;
	} else {
	    if (-2 == digit) {
		xBufEnd--;
		*xBufEnd = '\0';
	    }
	    x.d = d;
	    [self displayX];
	    return YES;
	}
    } else {
	if (0 > digit) {
	    return NO;
	} else if (digit < base) {
            unsigned long long	max;
            unsigned long long	xt;
            
	    if (10 == base) {
		switch (numSize) {
		    case 64:	max = 0xFFFFFFFFFFFFFFFFULL;	break;
		    case 63:	max = 0x7FFFFFFFFFFFFFFFULL;	break;
		    case 32:	max = 0x00000000FFFFFFFFULL;	break;
		    case 31:	max = 0x000000007FFFFFFFULL;	break;
		    case 16:	max = 0x000000000000FFFFULL;	break;
		    case 15:	max = 0x0000000000007FFFULL;	break;
		    case 8:	max = 0x00000000000000FFULL;	break;
		    case 7:	max = 0x000000000000007FULL;	break;
		    default:	max = 0xFFFFFFFFFFFFFFFFULL;	break;
		}
	    } else {
		switch (numSize) {
		    case 64:
		    case 63:	max = 0xFFFFFFFFFFFFFFFFULL;	break;
		    case 32:
		    case 31:	max = 0x00000000FFFFFFFFULL;	break;
		    case 16:
		    case 15:	max = 0x000000000000FFFFULL;	break;
		    case 8:
		    case 7:	max = 0x00000000000000FFULL;	break;
		    default:	max = 0xFFFFFFFFFFFFFFFFULL;	break;
		}
	    }
	    /* Check high limit only as numbers can only be made negative
	     * after x has been frozen. */
	    xt = max / base;
	    if (xt < x.i ||
		(xt == x.i && (int)(max - xt * base) < digit)) {
		return NO;
	    }
            x.i = x.i * base + digit;
        }
        [self displayX];
        return YES;
    }
    return NO;
}

- (BOOL)deleteDigit
{
    if (freezeX) {
        return NO;
    }
    if (0 == numSize) {
	if (xBuf == xBufEnd) {
	    return NO;
	}
	xBufEnd--;
	*xBufEnd = '\0';
    } else {
	if (0 == x.i) {
	    return NO;
	}
	x.i = x.i / base;
    }
    [self displayX];
    return YES;
}

- (IBAction)doOp:(id)sender
{
    NSButtonCell	*cell = [sender selectedCell];
    NSString		*method = [cell alternateTitle];
    int			tag = [cell tag];

    if (nil != x.err) {
	NSBeep();
	return;
    }
    if (0 == [method length]) {
        method = [[cell image] name];
    }
    /* '-' is a special case. When entering the exponent portion of a floating
     * point number '-' can be used to set the sign of the exponent. */
    if (2 < tag) { // - button
	if (0 == numSize && !freezeX && xBuf < xBufEnd && 'e' == *(xBufEnd - 1)) {
	    *xBufEnd++ = '-';
	    *xBufEnd = '\0';
	    [self displayX];
	    return;
	}
	tag = 2;
    }
    if (1 == tag) {		// unary operator
        freezeX = YES;
        [self performSelector: NSSelectorFromString(method)];
	[self limitNum: &x];
        [self displayX];
    } else if (2 == tag) {	// 2 variable operator
        if (yIsSet) {
            if (NULL != op) {
                [self performSelector: NSSelectorFromString(op)];
		[self limitNum: &x];
            }
            [self displayY];
            [self displayX];
        }
        op = method;
        freezeX = YES;
        [self displayX];
    } else if (0 == tag) {	// equals
        if (yIsSet) {
            if (NULL != op) {
                [self performSelector: NSSelectorFromString(op)];
		[self limitNum: &x];
            }
            yIsSet = NO;
            [self displayY];
        }
        freezeX = YES;
        op = NULL;
        [self displayX];
    }
}

- (void)limitNum:(Num*)v
{
    switch (numSize) {
    case 31:
	if (0 > (long long)v->i) {
	    v->i = 0xFFFFFFFF00000000ULL | v->i;
	} else {
	    v->i = v->i & 0x00000000FFFFFFFFULL;
	}
	break;
    case 32:
        v->i = v->i & 0x00000000FFFFFFFFULL;
        break;
    case 15:
	if (0 > (long long)v->i) {
	    v->i = 0xFFFFFFFFFFFF0000ULL | v->i;
	} else {
	    v->i = v->i & 0x000000000000FFFFULL;
	}
	break;
    case 16:
        v->i = v->i & 0x000000000000FFFFULL;
        break;
    case 7:
	if (0 > (long long)v->i) {
	    v->i = 0xFFFFFFFFFFFFFF00ULL | v->i;
	} else {
	    v->i = v->i & 0x00000000000000FFULL;
	}
	break;
    case 8:
        v->i = v->i & 0x00000000000000FFULL;
        break;
    case 64:
    case 63:
    case 0:
    default:
        break;
    }
}

// Arithmetic methods
- (void)multiply
{
    if (0 == numSize) {
	x.d = y.d * x.d;
    } else {
	x.i = y.i * x.i;
    }
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)divide
{
    if (0 == numSize) {
	x.d = y.d / x.d;
    } else {
	if (0 == x.i) {
	    x.err = @"Inf";
	} else {
	    x.i = y.i / x.i;
	}
    }
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)add
{
    if (0 == numSize) {
	x.d = y.d + x.d;
    } else {
	x.i = y.i + x.i;
    }
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)subtract
{
    if (0 == numSize) {
	x.d = y.d - x.d;
    } else {
	x.i = y.i - x.i;
    }
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)changeSign
{
    if (0 == numSize) {
	x.d = -x.d;
    } else {
	x.i = -x.i;
    }
}

- (void)factorial
{
    long	n;

    if (0 == numSize) {
	if (0.0 > x.d) {
	    x.err = @"Undefined";
	} else if (172.0 <= x.d) {
	    x.err = @"Inf";
	} else if (0 == x.d) {
	    x.d = 1;
	} else {
	    double	f = 1.0;
	    
	    for (n = (long)x.d; 0 < n; n--) {
		f *= n;
	    }
	    x.d = f;
	}
    } else {
	if ((numSize & 1) && 0 > (long long)x.i) {
	    x.err = @"Undefined";
	} else {
	    if (20 < x.i) {
		x.err = @"Inf";
	    } else if (0 == x.i) {
		x.i = 1;
	    } else {
		unsigned long long	f = 1;

		for (n = (long)x.i; 0 < n; n--) {
		    f *= n;
		}
		x.i = f;
	    }
	}
    }
}

- (void)modulo
{
    if (0 == numSize) {
	x.d = fmod(y.d, x.d);
    } else {
	if (0 == x.i) {
	    x.err = @"NaN";
	} else {
	    x.i = y.i % x.i;
	}
    }
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)yRaisedToX
{
    if (0 == numSize) {
	x.d = pow(y.d, x.d);
    } else {
	x.i = (unsigned long long)pow((double)y.i, (double)x.i);
    }
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)addOne
{
    if (0 == numSize) {
	x.d += 1;
    } else {
	x.i++;
    }
}

- (void)subOne
{
    if (0 == numSize) {
	x.d -= 1;
    } else {
	x.i--;
    }
}

- (void)squared
{
    if (0 == numSize) {
	x.d = x.d * x.d;
    } else {
	x.i = x.i * x.i;
    }
}

- (void)sqrt
{ 
    if (0 == numSize) {
	x.d = sqrt(x.d);
    } else {
	x.i = (unsigned long long)sqrt((double)x.i);
    }
}

// math methods
- (void)sin
{
    if (0 == angleType) {	// degrees
	x.d = x.d / 180.0 * M_PI;
    }
    x.d = sin(x.d);
}

- (void)asin
{
    x.d = asin(x.d);
    if (0 == angleType) {	// degrees
	x.d = x.d / M_PI * 180.0;
    }
}

- (void)sinh
{
    if (0 == angleType) {	// degrees
	x.d = x.d / 180.0 * M_PI;
    }
    x.d = sinh(x.d);
}

- (void)asinh
{
    x.d = asinh(x.d);
    if (0 == angleType) {	// degrees
	x.d = x.d / M_PI * 180.0;
    }
}

- (void)cos
{
    if (0 == angleType) {	// degrees
	x.d = x.d / 180.0 * M_PI;
    }
    x.d = cos(x.d);
}

- (void)acos
{
    x.d = acos(x.d);
    if (0 == angleType) {	// degrees
	x.d = x.d / M_PI * 180.0;
    }
}

- (void)cosh
{
    if (0 == angleType) {	// degrees
	x.d = x.d / 180.0 * M_PI;
    }
    x.d = cosh(x.d);
}

- (void)acosh
{
    x.d = acosh(x.d);
    if (0 == angleType) {	// degrees
	x.d = x.d / M_PI * 180.0;
    }
}

- (void)tan
{
    if (0 == angleType) {	// degrees
	x.d = x.d / 180.0 * M_PI;
    }
    x.d = tan(x.d);
}

- (void)atan
{
    x.d = atan(x.d);
    if (0 == angleType) {	// degrees
	x.d = x.d / M_PI * 180.0;
    }
}

- (void)tanh
{
    if (0 == angleType) {	// degrees
	x.d = x.d / 180.0 * M_PI;
    }
    x.d = tanh(x.d);
}

- (void)atanh
{
    x.d = atanh(x.d);
    if (0 == angleType) {	// degrees
	x.d = x.d / M_PI * 180.0;
    }
}

- (void)floor
{
    x.d = floor(x.d);
}

- (void)ceil
{
    x.d = ceil(x.d);
}

- (void)round
{
    x.d = round(x.d);
}

- (void)trunc
{
    x.d = trunc(x.d);
}

- (void)log
{
    x.d = log10(x.d);
}

- (void)tenRaisedToX
{
    if (0 == numSize) {
	x.d = pow(10.0, x.d);
    } else {
	x.i = (unsigned long long)pow(10.0, (double)x.i);
    }
}

- (void)ln
{
    x.d = log(x.d);
}

- (void)eRaisedToX
{
    if (0 == numSize) {
	x.d = pow(2.7182818284590452354, x.d);
    } else {
	x.i = (unsigned long long)pow(2.7182818284590452354, (double)x.i);
    }
}

- (void)abs
{
    if (0 == numSize) {
	if (0 > x.d) {
	    x.d = -x.d;
	}
    } else {
	if (0 > x.i) {
	    x.i = -x.i;
	}
    }
}

- (void)logXY
{
    x.d = log(x.d) / log(y.d);
}

- (void)invert
{
    if (0 == numSize) {
	x.d = 1 / x.d;
    } else {
	if (0 == x.i) {
	    x.err = @"Inf";
	} else {
	    x.i = 1 / x.i;
	}
	x.i = 1 / x.i;
    }
}

- (void)e
{
    y = x;
    *xBuf = '\0';
    xBufEnd = xBuf;
    freezeX = YES;
    yIsSet = YES;
    [self displayY];
    if (0 == numSize) {
	x.d = 2.7182818284590452354;
    } else {
	x.i = 2;
    }
}

- (void)pi
{
    y = x;
    *xBuf = '\0';
    xBufEnd = xBuf;
    freezeX = YES;
    yIsSet = YES;
    [self displayY];
    if (0 == numSize) {
	x.d = 3.14159265358979323846;
    } else {
	x.i = 3;
    }
}

// bit operation methods
- (void)and
{
    x.i = x.i & y.i;
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)or
{
    x.i = x.i | y.i;
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)xor
{
    x.i = x.i ^ y.i;
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)not
{
    x.i = ~x.i;
}

- (void)shiftLeft
{
    x.i = y.i << x.i;
    [self zeroNum: &y];
    yIsSet = NO;
}

- (void)shiftRight
{
    [self limitNum: &y];
    x.i = y.i >> x.i;
    [self zeroNum: &y];
    yIsSet = NO;
}

// register operator methods
- (void)memClear
{
    [self zeroNum: &m];
    [self displayM];
}

- (void)memAdd
{
    if (0 == numSize) {
	m.d += x.d;
    } else {
	m.i += x.i;
    }
    [self displayM];
}

- (void)memRecall
{
    if (freezeX) {
        y = x;
        yIsSet = YES;
        [self displayY];
    }
    freezeX = YES;
    x = m;
}

- (void)swapXY
{
    Num	tmp = y;

    y = x;
    x = tmp;
    yIsSet = YES;
    freezeX = YES;
    [self displayY];
}

- (void)swapXM
{
    Num	tmp = x;

    x = m;
    m = tmp;
    freezeX = YES;
    [self displayM];
}

- (void)swapYM
{
    Num	tmp = y;

    y = m;
    m = tmp;
    yIsSet = YES;
    [self displayY];
    [self displayM];
}

- (void)equals
{
}

- (IBAction)setBase:(id)sender
{
    [self setBaseValue: [ [sender selectedItem] tag]];
    [self displayX];
    [self displayY];
    [self displayM];
}

- (void)setBaseValue:(int)v
{
    if (10 != v && 0 == numSize) {
	[self setNumSizeValue: 64];
        [sizePopup selectItemAtIndex: 1];
    }
    NSFont	*f;
    NSString	*fontName = (257 == v) ? @"VT100" : @"Courier";
//    NSString	*fontName = (257 == v) ? @"VT100" : @"Lucida Grande";
    int		fontSize = (2 == v) ? 15 : (257 == v) ? 12 : 36;
    NSRect	r;

    if (2 == v && 2 != base) {
	r = [xOut frame];
	r.origin.y -= 12;
	[xOut setFrameOrigin: r.origin];
	r = [yOut frame];
	r.origin.y -= 2;
	[yOut setFrameOrigin: r.origin];
	r = [mOut frame];
	r.origin.y -= 2;
	[mOut setFrameOrigin: r.origin];
    } else if (2 == base && 2 != v) {
	r = [xOut frame];
	r.origin.y += 12;
	[xOut setFrameOrigin: r.origin];
	r = [yOut frame];
	r.origin.y += 2;
	[yOut setFrameOrigin: r.origin];
	r = [mOut frame];
	r.origin.y += 2;
	[mOut setFrameOrigin: r.origin];
    }
    base = v;
    f = [NSFont fontWithName: fontName size: fontSize];
    [xOut setFont: f];
    f = [NSFont fontWithName: fontName size: (2 == base) ? 7 : 11];
    [yOut setFont: f];
    [mOut setFont: f];
    [self setPadEnable];
}

- (IBAction)setAngleType:(id)sender
{
    angleType = [ [sender selectedItem] tag];
    [self displayX];
    [self displayY];
    [self displayM];
}

- (IBAction)setNumSize:(id)sender
{
    int	tag = [[sender selectedItem] tag];

    if (tag == numSize) {
	return;
    }
    [self setNumSizeValue: tag];

    if (0 == numSize && 10 != base) {
	[self setBaseValue: 10];
	[basePopup selectItemAtIndex: 0];
    }
    [self setPadEnable];
    [self limitNum: &x];
    [self limitNum: &y];
    [self limitNum: &m];
    [self displayX];
    [self displayY];
    [self displayM];
}

- (void)setNumSizeValue:(int)size
{
    if (size == numSize) {
	return;
    }
    [self changeNumSize: &x oldSize: numSize newSize: size];
    [self changeNumSize: &y oldSize: numSize newSize: size];
    [self changeNumSize: &m oldSize: numSize newSize: size];
    numSize = size;
}

- (void)changeNumSize:(Num*)v oldSize:(int)oSize newSize:(int)nSize
{
    if (0 == nSize) {		// becoming float from int
	if (oSize & 1) {	// signed
	    v->d = (double)(long long)v->i;
	} else {
	    v->d = (double)v->i;
	}
    } else if (0 == oSize) {	// becoming int from float
	if (0.0 > v->d) {
	    if ((-0x7FFFFFFFFFFFFFFFLL - 1) > v->d) {
		v->err = @"-Inf";
	    } else {
		v->i = (unsigned long long)(long long)v->d;
	    }
	} else {
	    if (0xFFFFFFFFFFFFFFFFULL < v->d) {
		v->err = @"Inf";
	    } else {
		v->i = (unsigned long long)v->d;
	    }
	}
    } else if (nSize > oSize && oSize & 1) {	// signed and expanding size
	switch (oSize) {
	case 31:
	    if (0 > (long)v->i) {
		v->i = 0xFFFFFFFF00000000ULL | v->i;
	    }
	    break;
	case 15:
	    if (0 > (short)v->i) {
		v->i = 0xFFFFFFFFFFFF0000ULL | v->i;
	    }
	    break;
	case 7:
	    if (0 > (short)v->i) {
		v->i = 0xFFFFFFFFFFFFFF00ULL | v->i;
	    }
	    break;
	default:
	    break;
	}
    }
}

- (void)setPadEnable
{
    NSArray	*cells = [keyPad cells];
    id		c;
    int		i, tag;
    
    for (i = [cells count] - 1; 0 <= i; i--) {
        c = [cells objectAtIndex: i];
        tag = [c tag];
        [c setEnabled: ((tag < base && 0 <= tag) || (0 > tag && 10 == base && 0 == numSize))];
    }
    [mathPad setEnabled: (0 == numSize)];
    [bitPad setEnabled: (0 != numSize)];
}

- (NSString*)formValueString:(Num)v
{
    NSString	*s;

    if (nil != v.err) {
	return v.err;
    }
    if (0 == numSize) {	// float
	s = [NSString stringWithFormat:@"%.15g", v.d];
    } else {
	switch (base) {
        case 2:
            s = [self formatAsBinaryString: v.i];
            break;
        case 8:
            s = [self formatAsOctalString: v.i];
	    break;
        case 10:
            switch (numSize) {
            case 63:
                s = [NSString stringWithFormat:@"%qi", v.i];
                break;
            case 31:
                s = [NSString stringWithFormat:@"%ld", (long)v.i];
                break;
            case 15:
                s = [NSString stringWithFormat:@"%hi", (short)v.i];
                break;
            case 7:
                s = [NSString stringWithFormat:@"%ld", (long)(char)v.i];
                break;
            case 64:
            case 32:
            case 16:
            case 8:
                s = [NSString stringWithFormat:@"%qu", v.i];
                break;
            default:
                s = @"Error";
                break;
            }
            break;
        case 16:
            switch (numSize) {
            case 63:
            case 64:
                s = [NSString stringWithFormat:@"%016qX", v.i];
                break;
            case 31:
            case 32:
                 s = [NSString stringWithFormat:@"%08X", (unsigned long)(0x00000000FFFFFFFFULL & v.i)];
                break;
            case 15:
            case 16:
                 s = [NSString stringWithFormat:@"%04X", (unsigned short)(0x000000000000FFFFULL & v.i)];
                break;
            case 7:
            case 8:
                 s = [NSString stringWithFormat:@"%02X", (unsigned char)(0x00000000000000FFULL & v.i)];
                break;
            default:
                s = @"Error";
                break;
            }
            break;
        case 256:
            s = [self formatAsAsciiString: v.i];
            break;
        default:
            s = @"Error";
            break;
        }
    }
    return s;
}

- (NSString*)formatAsBinaryString:(unsigned long long)v
{
    char	*c, buf[65];
    int		i;
    
    for (i = numSize - 1, c = buf; 0 <= i; i--, c++) {
        *c = ((v >> i) & 0x0000000000000001ULL) ? '1' : '0';
    }
    *c = '\0';
    
    return [NSString stringWithCString: buf encoding: NSASCIIStringEncoding];
}

- (NSString*)formatAsOctalString:(unsigned long long)v
{
    char	*c, buf[65];
    int		i, first = numSize / 3 * 3;
    
    for (i = first, c = buf; 0 <= i; i -= 3, c++) {
        *c = ((v >> i) & 0x0000000000000007ULL) + '0';
    }
    *c = '\0';
    
    return [NSString stringWithCString: buf encoding: NSASCIIStringEncoding];
}

- (NSString*)formatAsAsciiString:(unsigned long long)v
{
    char	*c, buf[9];
    int		charCnt = numSize / 8;
    int		i;
    
    for (i = charCnt - 1, c = buf; 0 <= i; i--, c++) {
        *c = (v >> (i * 8)) & 0x00000000000000FF;
    }
    *c = '\0';
    
    return [NSString stringWithCString: buf encoding: NSASCIIStringEncoding];
}

- (void)displayX
{
    if (0 == numSize && !freezeX) {
	if (xBuf == xBufEnd) {
	    [xOut setStringValue: @"0"];
	} else {
            [xOut setStringValue: [NSString stringWithCString: xBuf encoding: NSASCIIStringEncoding]];
	}
    } else {
	[xOut setStringValue: [self formValueString: x]];
    }
}

- (void)displayY
{
    [yOut setStringValue: [self formValueString: y]];
}

- (void)displayM
{
    [mOut setStringValue: [self formValueString: m]];
}

- (IBAction)showAsciiTable:(id)sender
{
    if (nil == asciiTable) {
        if (![NSBundle loadNibNamed:@"AsciiTable.nib" owner:self]) {
            NSLog(@"Failed to load AsciiTable");
            return;
        }
    }
    unsigned int	i, j;
    char		cstr[2];
    //NSFont		*vt100 = [NSFont fontWithName: @"VT100" size: 9];
    
    cstr[1] = '\0';
    for (i = 0; i < 16; i++) {
        for (j = 0; j < 16; j++) {
            *cstr = (char)((i << 4) | j);
            if (2 > i) {
                //[ [asciiTableMatrix cellAtRow: i column: j] setFont: vt100];
            }
            [ [asciiTableMatrix cellAtRow: i column: j] setTitle: [NSString stringWithCString: cstr encoding: NSASCIIStringEncoding]];
        }
    }
    [asciiTable makeKeyAndOrderFront: nil];
}

- (IBAction)evalExpr:(id)sender
{
}

@end

@implementation Controller(ApplicationNotifications)

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [self setBaseValue: [[basePopup selectedItem] tag]];
    numSize = [[sizePopup selectedItem] tag];
    [self clearAll: self];
 }

@end

@implementation Controller(WindowNotifications)

- (void)windowWillClose:(NSNotification*)aNotification
{
    [NSApp terminate: self];
}

@end
