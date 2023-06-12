## Features

'Simple' PDF reader package. Does not do a lot of interpretation of the data
that is being read, but it does provide a way to read the data from a PDF file

## Getting started

1) Create `RandomAccessStream` from either bytes `ByteStream` or file `FileStream`
2) Create `PDFParser` using the stream from step 1
3) Read the PDF file using the `PDFParser` from step 2 `await parser.parse()`
