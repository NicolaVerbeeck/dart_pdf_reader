## 0.5.1

- Fix parsing PDFs where stream or startxref ends with extra whitespace (#50)

## 0.5.0

- Add support for web by using the archive package. (#48)
- **Breaking**: EOFException and ParseException now no longer implement dart:io's IOException, just base Exception. (#48)

## 0.4.3

- Add more tests
- Bump lints

## 0.4.2

- Export PDFNames

## 0.4.1

- Don't require endstream to be followed by a newline (#40)
- Use read word to read trailer header (#41)
- Cleanup usages of PDFName and group common names in PDFNames

## 0.4.0

- Add experimental support for extends on object streams (#29)
- Ensure compressed xrefs can be read without decode parameters (#33)
- Seek further backwards when searching for %%EOF (#34)

## 0.3.0

- Added `pageCount` to `PDFPages`
- Updated `PDFNumber` to use 10 fraction digits in `toString` instead of 5

## 0.2.6

- Add buffered stream implementation to enable for faster reading of files

## 0.2.5

- Make ObjectResolver exported as it is used in the public API of Page

## 0.2.4

- Add direct support for accessing page's art, bleed, crop and trim boxes
- Add direct support for accessing page's rotation flag

## 0.2.3

- Support malformed strings when decoding utf8

## 0.2.2

- Expose document, resolver and dictionary in catalog

## 0.2.1

- Expose resolver in pages

## 0.2.0

- Bugfix: Hex strings now consume their ending bracket
- Bugfix: Multiple content streams in a page are now supported
- Update: Support direct dictionaries in outlines
- Breaking: `destination` in `PDFOutlineGoToAction` has been updated to a generic object as per spec
- Deprecation: `page.contentStream` has been deprecated in favor of `page.contentStreams`

## 0.1.6

- Fixed bug in `ByteOutputStream` where writeAll would not update position
- Added tests for `ByteOutputStream` and `ByteInputStream`

## 0.1.5

- Fixed bug when using fastRead
- Added more uint list optimizations where possible

## 0.1.4

- Use Uint8List instead of List<int> for bytes
- Add fast path for copying bytes from ByteStream

## 0.1.3

- Add support for pdf bookmarks (outlines)

## 0.1.2

- Don't hold future in ByteStream to allow sending across isolates

## 0.1.1

- Add support for ascii85, asciihex, lzw and run length filters

## 0.1.0

- Breaking: require dart 3
- Experimental: support loading compressed xref streams and compressed object streams

## 0.0.8

- Bugfix: pdf streams with reference to length would crash the parser

## 0.0.7

- Bugfix: toString on literal strings would have double ()

## 0.0.6

- Add asPDFString to PDFStringLike that returns the string encoded for output in pdf

## 0.0.5

- Bugfix: support for \r only newlines

## 0.0.4

- Code cleanup
- Small parsing bug fixes

## 0.0.3

- Remove unused dependencies
- Add some clone methods
- Change visibility of some dictionary map

## 0.0.2

- Update dependencies

## 0.0.1

- Initial version.
