
import com.itextpdf.kernel.geom.PageSize
import com.itextpdf.kernel.geom.Rectangle
import com.itextpdf.kernel.pdf.CompressionConstants
import com.itextpdf.kernel.pdf.PdfDocument
import com.itextpdf.kernel.pdf.PdfPage
import com.itextpdf.kernel.pdf.PdfReader
import com.itextpdf.kernel.pdf.PdfWriter
import com.itextpdf.kernel.pdf.WriterProperties
import com.itextpdf.kernel.pdf.canvas.PdfCanvas
import com.itextpdf.kernel.pdf.xobject.PdfFormXObject
import java.io.File
import java.io.IOException

class IncorrectExample {
    @Throws(IOException::class)
    protected fun manipulatePdf(dest: String?) {
        val srcDoc = PdfDocument(PdfReader(SOURCE))
        val pdfDoc = PdfDocument(PdfWriter(dest))
        for (i in 1..1) {
            val pageSize = getPageSize(srcDoc, i)
            pdfDoc.setDefaultPageSize(pageSize)
            val canvas = PdfCanvas(pdfDoc.addNewPage())
            val page: PdfFormXObject =
                srcDoc.getPage(i).copyAsFormXObject(pdfDoc)
                canvas.addXObjectAt(page, 0.0f, 0.04112599224328761f)
        }
        pdfDoc.close()
        srcDoc.close()
    }

    companion object {
        const val DEST = "out.pdf"
        const val SOURCE = "../../example/downloaded.pdf"
        @Throws(IOException::class)
        @JvmStatic
        fun main(args: Array<String>) {
            val file = File( File("").getAbsoluteFile(), DEST)
            file.parentFile.mkdirs()
            IncorrectExample().manipulatePdf(DEST)
        }

        private fun getPageSize(
            pdfDoc: PdfDocument,
            pageNumber: Int
        ): PageSize {
            val page: PdfPage = pdfDoc.getPage(pageNumber)
            val pageSize: Rectangle = page.getPageSize()

            // Returns a page size with the lowest value of the dimensions of the existing page as the width
            // and the highest value as the height. This way, the page will always be in portrait.
            return PageSize(
                pageSize.getWidth(),
                pageSize.getHeight()
            )
        }

    }
}