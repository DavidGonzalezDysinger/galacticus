# Contains a Perl module which implements processing GnuPlot output through LaTeX.

package LaTeX;
use File::Copy;
use System::Redirect;

my $status = 1;
$status;

sub GnuPlot2PDF {
    # Get the name of the GnuPlot-generated EPS file.
    my $gnuplotEpsFile = shift;

    # Get the root name.
    (my $gnuplotRoot = $gnuplotEpsFile) =~ s/\.eps//;

    # Construct the name of the corresponding LaTeX files.
    my $gnuplotLatexFile = $gnuplotRoot.".tex";
    my $gnuplotAuxFile   = $gnuplotRoot.".aux";

    # Construct the name of the corresponding pdf file.
    my $gnuplotPdfFile = $gnuplotRoot.".pdf";

    # Create a wrapper file for the LaTeX.
    open(wHndl,">gnuplotWrapper.tex");
    print wHndl "\\documentclass[10pt]{article}\n\\usepackage{graphicx}\n\\usepackage{nopageno}\n\\usepackage{txfonts}\n\\usepackage[usenames]{color}\n\\begin{document}\n\\include{".$gnuplotRoot."}\n\\end{document}\n";
    close(wHndl);
    &SystemRedirect::tofile("epstopdf ".$gnuplotEpsFile."; pdflatex gnuplotWrapper; pdfcrop gnuplotWrapper.pdf","/dev/null");
    move("gnuplotWrapper-crop.pdf",$gnuplotPdfFile);
    unlink(
	   "gnuplotWrapper.pdf",
	   "gnuplotWrapper.tex",
	   "gnuplotWrapper.log",
	   "gnuplotWrapper.aux",
	   $gnuplotEpsFile,
	   $gnuplotLatexFile,
	   $gnuplotAuxFile
	   );
}

