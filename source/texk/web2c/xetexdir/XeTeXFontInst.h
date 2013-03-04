/****************************************************************************\
 Part of the XeTeX typesetting system
 Copyright (c) 1994-2008 by SIL International
 Copyright (c) 2009, 2011 by Jonathan Kew

 SIL Author(s): Jonathan Kew

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of the copyright holders
shall not be used in advertising or otherwise to promote the sale,
use or other dealings in this Software without prior written
authorization from the copyright holders.
\****************************************************************************/

/*
 *   file name:  XeTeXFontInst.h
 *
 *   created on: 2005-10-22
 *   created by: Jonathan Kew
 *	
 *	originally based on PortableFontInstance.h from ICU
 */


#ifndef __XeTeXFontInst_H
#define __XeTeXFontInst_H

#include <stdio.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TRUETYPE_TABLES_H

#include "XeTeXFontMgr.h"
#include "XeTeX_ext.h"

#define MATH_TAG HB_TAG('M','A','T','H')

// create specific subclasses for each supported platform

class XeTeXFontInst
{
protected:
    float    fPointSize;

    unsigned short fUnitsPerEM;
    float fAscent;
    float fDescent;

    float fDeviceScaleX;
    float fDeviceScaleY;

	float fItalicAngle;

    uint16_t fNumGlyphs;
	bool fNumGlyphsInited;
	
	bool fVertical; // false = horizontal, true = vertical

	char *fFilename; // actually holds [filename:index], as used in xetex

    void getMetrics();

	FT_Face ftFace;
	hb_font_t* hbFont;
	const char *fMath;

public:
    XeTeXFontInst(float pointSize, int &status);
	XeTeXFontInst(const char* filename, int index, float pointSize, int &status);

    virtual ~XeTeXFontInst();

	virtual void initialize(const char* pathname, int index, int &status);

    virtual const void *getFontTable(OTTag tableTag) const;
    virtual const void *getFontTable(FT_Sfnt_Tag tableTag) const;
    virtual const char *getMathTable();

	virtual const char *getFilename() const
	{
		return fFilename;
	}

	virtual hb_font_t *getHbFont() const
	{
		return hbFont;
	}

	virtual void setLayoutDirVertical(bool vertical);

	virtual bool getLayoutDirVertical() const
	{
		return fVertical;
	};

    virtual float getAscent() const
    {
        return fAscent;
    }

    virtual float getDescent() const
    {
        return fDescent;
    }

    virtual GlyphID mapCharToGlyph(UChar32 ch) const;
    virtual GlyphID mapGlyphToIndex(const char* glyphName) const;

	virtual uint16_t getNumGlyphs() const;

    virtual void getGlyphAdvance(GlyphID glyph, realpoint &advance) const;

	virtual void getGlyphBounds(GlyphID glyph, GlyphBBox* bbox);

	float getGlyphWidth(GlyphID glyph);
	void getGlyphHeightDepth(GlyphID glyph, float *ht, float* dp);
	void getGlyphSidebearings(GlyphID glyph, float* lsb, float* rsb);
	float getGlyphItalCorr(GlyphID glyph);

	virtual const char* getGlyphName(GlyphID gid, int& nameLen);
	
	virtual UChar32 getFirstCharCode();
	virtual UChar32 getLastCharCode();

    float getPointSize() const
    {
        return fPointSize;
    };

	float unitsToPoints(float units) const
	{
		return (units * fPointSize) / (float) fUnitsPerEM;
	}

	float pointsToUnits(float points) const
	{
		return (points * (float) fUnitsPerEM) / fPointSize;
	}

    float getItalicAngle() const
    {
        return fItalicAngle;
    }
};

#endif
