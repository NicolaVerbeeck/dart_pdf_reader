import 'pdf_types.dart';
import 'package:meta/meta.dart';

/// Collection of names used in PDF files
@immutable
final class PDFNames {
  // coverage:ignore-start
  const PDFNames._();

  // coverage:ignore-end

  static const bm = PDFName('BM');

  // ignore: constant_identifier_names
  static const CA = PDFName('CA');
  static const pdf = PDFName('PDF');
  static const a = PDFName('A');
  static const alternate = PDFName('Alternate');
  static const annots = PDFName('Annots');
  static const artBox = PDFName('ArtBox');
  static const ascii85Decode = PDFName('ASCII85Decode');
  static const author = PDFName('Author');
  static const b = PDFName('B');
  static const bbox = PDFName('BBox');
  static const bitsPerComponent = PDFName('BitsPerComponent');
  static const bleedBox = PDFName('BleedBox');
  static const ca = PDFName('ca');
  static const catalog = PDFName('Catalog');
  static const colorSpace = PDFName('ColorSpace');
  static const colors = PDFName('Colors');
  static const columns = PDFName('Columns');
  static const contents = PDFName('Contents');
  static const count = PDFName('Count');
  static const creationDate = PDFName('CreationDate');
  static const creator = PDFName('Creator');
  static const cropBox = PDFName('CropBox');
  static const d = PDFName('D');
  static const dctDecode = PDFName('DCTDecode');
  static const decode = PDFName('Decode');
  static const decodeParms = PDFName('DecodeParms');
  static const dest = PDFName('Dest');
  static const deviceCMYK = PDFName('DeviceCMYK');
  static const deviceGray = PDFName('DeviceGray');
  static const deviceRGB = PDFName('DeviceRGB');
  static const encoding = PDFName('Encoding');
  static const extGState = PDFName('ExtGState');
  static const extend = PDFName('Extends');
  static const filter = PDFName('Filter');
  static const first = PDFName('First');
  static const flateDecode = PDFName('FlateDecode');
  static const font = PDFName('Font');
  static const form = PDFName('Form');
  static const group = PDFName('Group');
  static const height = PDFName('Height');
  static const iccBased = PDFName('ICCBased');
  static const id = PDFName('ID');
  static const image = PDFName('Image');
  static const imageB = PDFName('ImageB');
  static const imageC = PDFName('ImageC');
  static const index = PDFName('Index');
  static const indexed = PDFName('Indexed');
  static const info = PDFName('Info');
  static const intent = PDFName('Intent');
  static const keywords = PDFName('Keywords');
  static const kids = PDFName('Kids');
  static const lang = PDFName('Lang');
  static const length = PDFName('Length');
  static const matrix = PDFName('Matrix');
  static const mediaBox = PDFName('MediaBox');
  static const metadata = PDFName('Metadata');
  static const modDate = PDFName('ModDate');
  static const n = PDFName('N');
  static const name = PDFName('Name');
  static const next = PDFName('Next');
  static const objStm = PDFName('ObjStm');
  static const ocProperties = PDFName('OCProperties');
  static const ocg = PDFName('OCG');
  static const ocgs = PDFName('OCGs');
  static const off = PDFName('OFF');
  static const on = PDFName('ON');
  static const order = PDFName('Order');
  static const outlines = PDFName('Outlines');
  static const page = PDFName('Page');
  static const pages = PDFName('Pages');
  static const parent = PDFName('Parent');
  static const predictor = PDFName('Predictor');
  static const prev = PDFName('Prev');
  static const procSet = PDFName('ProcSet');
  static const producer = PDFName('Producer');
  static const properties = PDFName('Properties');
  static const resources = PDFName('Resources');
  static const root = PDFName('Root');
  static const rotate = PDFName('Rotate');
  static const s = PDFName('S');
  static const sMask = PDFName('SMask');
  static const size = PDFName('Size');
  static const structParents = PDFName('StructParents');
  static const subject = PDFName('Subject');
  static const subtype = PDFName('Subtype');
  static const text = PDFName('Text');
  static const title = PDFName('Title');
  static const transparency = PDFName('Transparency');
  static const trimBox = PDFName('TrimBox');
  static const type = PDFName('Type');
  static const usage = PDFName('Usage');
  static const version = PDFName('Version');
  static const w = PDFName('W');
  static const width = PDFName('Width');
  static const xObject = PDFName('XObject');
  static const xRef = PDFName('XRef');
  static const xml = PDFName('XML');
  static const embeddedFiles = PDFName('EmbeddedFiles');
  static const names = PDFName('Names');
  static const af = PDFName('AF');
  static const f = PDFName('F');
  static const ef = PDFName('EF');
  static const desc = PDFName('Desc');
}
