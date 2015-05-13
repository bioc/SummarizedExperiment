\name{intra-range-methods}

\alias{intra-range-methods}

\alias{shift}
\alias{shift,RangedSummarizedExperiment-method}

\alias{narrow}
\alias{narrow,RangedSummarizedExperiment-method}

\alias{resize}
\alias{resize,RangedSummarizedExperiment-method}

\alias{flank}
\alias{flank,RangedSummarizedExperiment-method}

\alias{promoters}
\alias{promoters,RangedSummarizedExperiment-method}

\alias{restrict}
\alias{restrict,RangedSummarizedExperiment-method}

\alias{trim,RangedSummarizedExperiment-method}


\title{Intra range transformations of a RangedSummarizedExperiment object}

\description{
  This man page documents \emph{intra range transformations} of a
  \link{RangedSummarizedExperiment} object. These transformations
  operate on the \code{rowRanges} component of the object.

  See \code{?`\link[GenomicRanges]{intra-range-methods}`} in the
  \pkg{GenomicRanges} package for intra range transformations of a
  \link[GenomicRanges]{GenomicRanges} or \link[GenomicRanges]{GRangesList}
  object, which the transformations described below are based on.
}

\usage{
\S4method{shift}{RangedSummarizedExperiment}(x, shift=0L, use.names=TRUE)

\S4method{narrow}{RangedSummarizedExperiment}(x, start=NA, end=NA, width=NA, use.names=TRUE)

\S4method{resize}{RangedSummarizedExperiment}(x, width, fix="start", use.names=TRUE,
       ignore.strand=FALSE)

\S4method{flank}{RangedSummarizedExperiment}(x, width, start=TRUE, both=FALSE,
      use.names=TRUE, ignore.strand=FALSE)

\S4method{promoters}{RangedSummarizedExperiment}(x, upstream=2000, downstream=200)

\S4method{restrict}{RangedSummarizedExperiment}(x, start=NA, end=NA, keep.all.ranges=FALSE,
         use.names=TRUE)

\S4method{trim}{RangedSummarizedExperiment}(x, use.names=TRUE)
}

\arguments{
  \item{x}{
    A \link{RangedSummarizedExperiment} object.
  }
  \item{shift, use.names}{
    See \code{?`\link[GenomicRanges]{intra-range-methods}`} in the
    \pkg{GenomicRanges} package.
  }
  \item{start, end, width, fix}{
    See \code{?`\link[GenomicRanges]{intra-range-methods}`} in the
    \pkg{GenomicRanges} package.
  }
  \item{ignore.strand, both}{
    See \code{?`\link[GenomicRanges]{intra-range-methods}`} in the
    \pkg{GenomicRanges} package.
  }
  \item{upstream, downstream}{
    See \code{?`\link[GenomicRanges]{intra-range-methods}`} in the
    \pkg{GenomicRanges} package.
  }
  \item{keep.all.ranges}{
    See \code{?`\link[GenomicRanges]{intra-range-methods}`} in the
    \pkg{GenomicRanges} package.
  }
}

\details{
  Any of these functions performs the following transformation on
  \link{RangedSummarizedExperiment} object \code{x}:
\preformatted{rowRanges(x) <- f(rowRanges(x), ...)
}
  where \code{f} is the name of the function and \code{...} any additional
  arguments passed to the function.
}

\seealso{
  \itemize{
    \item \link{RangedSummarizedExperiment} objects.
    \item The \link[GenomicRanges]{intra-range-methods} man page in the
          \pkg{GenomicRanges} package.
  }
}

\examples{
nrows <- 20; ncols <- 6
counts <- matrix(runif(nrows * ncols, 1, 1e4), nrows)
rowRanges <- GRanges(rep(c("chr1", "chr2"), c(5, 15)),
                     IRanges(sample(1000L, 20), width=100),
                     strand=Rle(c("+", "-"), c(12, 8)))
colData <- DataFrame(Treatment=rep(c("ChIP", "Input"), 3),
                     row.names=LETTERS[1:6])
se0 <- SummarizedExperiment(assays=SimpleList(counts=counts),
                            rowRanges=rowRanges, colData=colData)

se1 <- shift(se0, 1)
stopifnot(identical(
  rowRanges(se1),
  shift(rowRanges(se0), 1)
))

se2 <- narrow(se0, start=10, end=-15)
stopifnot(identical(
  rowRanges(se2),
  narrow(rowRanges(se0), start=10, end=-15)
))

se3 <- resize(se0, width=75)
stopifnot(identical(
  rowRanges(se3),
  resize(rowRanges(se0), width=75)
))

se4 <- flank(se0, width=20)
stopifnot(identical(
  rowRanges(se4),
  flank(rowRanges(se0), width=20)
))

se5 <- restrict(se0, start=200, end=700, keep.all.ranges=TRUE)
stopifnot(identical(
  rowRanges(se5),
  restrict(rowRanges(se0), start=200, end=700, keep.all.ranges=TRUE)
))
}

\keyword{methods}
\keyword{utilities}