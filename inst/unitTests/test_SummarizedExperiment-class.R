M1 <- matrix(1, 5, 3, dimnames=list(NULL, NULL))
M2 <- matrix(1, 3, 3, dimnames=list(NULL, NULL))
mList <- list(M1, M2)
assaysList <- list(M1=SimpleList(m=M1), M2=SimpleList(m=M2))
rowData1 <- DataFrame(id1=LETTERS[1:5])
rowData2 <- new("DataFrame", nrows=3L)
rowDataList <- list(rowData1, rowData2)
colData0 <- DataFrame(x=letters[1:3])

se0List <-
    list(SummarizedExperiment(
           assays=assaysList[["M1"]],
           rowData=rowData1,
           colData=colData0),
         SummarizedExperiment(
           assays=assaysList[["M2"]],
           colData=colData0))


test_SummarizedExperiment_construction <- function()
{
    ## empty-ish
    m1 <- matrix(0, 0, 0)
    checkTrue(validObject(new("SummarizedExperiment")))
    checkTrue(validObject(SummarizedExperiment()))
    checkTrue(validObject(
        SummarizedExperiment(assays=SimpleList(m1))))
    checkException(
        SummarizedExperiment(assays=SimpleList(matrix())),
        "assays dim mismatch", TRUE)
    checkException(
        SummarizedExperiment(assays=SimpleList(m1, matrix())),
        "assays dim mismatch", TRUE)
    checkException(
        SummarizedExperiment(assays=SimpleList(character())),
        "assays class", TRUE)

    ## substance
    for (i in seq_along(se0List)) {
        se0 <- se0List[[i]] 
        checkTrue(validObject(se0))
        checkIdentical(SimpleList(m=mList[[i]]), assays(se0))
        checkIdentical(rowDataList[[i]], rowData(se0))
        checkIdentical(colData0, colData(se0))
    }

    ## array in assays slot
    ss <- se0List[[1]]
    assays(ss) <- SimpleList(array(1:5, c(5,3,2)))
    checkTrue(validObject(ss))
    checkTrue(all(dim(assays(ss[1:3,1:2])[[1]]) == c(3, 2, 2)))

    ## matrix-of-list in assay slot
    m <- matrix(list(), 2, 3, dimnames=list(LETTERS[1:2], letters[1:3]))
    checkTrue(validObject(se <- SummarizedExperiment(m)))
    checkIdentical(m, assay(se))
    checkIdentical(m[,1:2], assay(se[,1:2]))

    ## DataFrame in assay slot
    df <- DataFrame(a=1:3, b=1:3, row.names=LETTERS[1:3])
    checkTrue(validObject(SummarizedExperiment(list(df))))
}

test_SummarizedExperiment_getters <- function()
{
    for (i in seq_along(se0List)) {
        se0 <- se0List[[i]] 

        ## dim, dimnames
        checkIdentical(c(nrow(mList[[i]]), nrow(colData0)), dim(se0))
        checkIdentical(list(NULL, NULL), dimnames(se0))

        ## col / metadata
        checkIdentical(rowDataList[[i]], rowData(se0))
        checkIdentical(colData0, colData(se0))
        checkIdentical(list(), metadata(se0))
    }

    ## assays
    m0 <- matrix(0L, 0, 0, dimnames=list(NULL, NULL))
    m1 <- matrix(0, 0, 0, dimnames=list(NULL, NULL))
    a <- SimpleList(a=m0, b=m1)
    checkIdentical(a, assays(SummarizedExperiment(assays=a)))
    ## assay
    checkException(
        assay(SummarizedExperiment()), "0-length assay", TRUE)
    checkIdentical(m0,
        assay(SummarizedExperiment(assays=a)), "default assay")
    checkIdentical(m1,
        assay(SummarizedExperiment(assays=a), 2),
        "assay, numeric index")
    checkException(
        assay(SummarizedExperiment(assays=a), 3),
        "invalid assay index", TRUE)
    checkIdentical(m1,
        assay(SummarizedExperiment(assays=a), "b"),
        "assay, character index")
    checkException(
        assay(SummarizedExperiment(assays=a), "c"),
        "invalid assay name", TRUE)
}

test_SummarizedExperiment_setters <- function()
{
    for (i in seq_along(se0List)) {
        se0 <- se0List[[i]] 

        ## row / col / metadata<-
        se1 <- se0

        rowData <- rowDataList[[i]]
        rowData <- rowData[rev(seq_len(nrow(rowData))),,drop=FALSE]
        rowData(se1) <- rowData
        checkIdentical(rowData, rowData(se1))
        checkException(rowData(se1) <- rowData(se0)[1:2,,drop=FALSE],
                       "incorrect row dimensions", TRUE)

        colData <- colData0[rev(seq_len(nrow(colData0))),,drop=FALSE]
        colData(se1) <- colData
        checkIdentical(colData, colData(se1))
        checkException(colData(se1) <- colData(se0)[1:2,,drop=FALSE],
                       "incorrect col dimensions", TRUE)

        lst <- list("foo", "bar")
        metadata(se1) <- lst
        checkIdentical(lst, metadata(se1))

        ## assay / assays
        se1 <- se0
        assay(se1) <- assay(se1)+1
        checkIdentical(assay(se0)+1, assay(se1))
        se1 <- se0
        assay(se1, 1) <- assay(se1, 1) + 1
        checkIdentical(assay(se0, "m") + 1, assay(se1, "m"))
        se1 <- se0
        assay(se1, "m") <- assay(se1, "m") + 1
        checkIdentical(assay(se0, "m")+1, assay(se1, "m"))

        ## dimnames<-
        se1 <- se0
        dimnames <- list(letters[seq_len(nrow(se1))],
                         LETTERS[seq_len(ncol(se1))])
        rownames(se1) <- dimnames[[1]]
        colnames(se1) <- dimnames[[2]]
        checkIdentical(dimnames, dimnames(se1))
        colData1 <- colData0
        row.names(colData1) <- dimnames[[2]]
        checkIdentical(colData1, colData(se1))
        se1 <- se0
        dimnames(se1) <- dimnames
        checkIdentical(dimnames, dimnames(se1))
        dimnames(se1) <- NULL
        checkIdentical(list(NULL, NULL), dimnames(se1))
    }
}

test_SummarizedExperiment_subset <- function()
{
    for (i in seq_along(se0List)) {
        se0 <- se0List[[i]] 

        ## numeric
        se1 <- se0[2:3,]
        checkIdentical(c(2L, ncol(se0)), dim(se1))
        checkIdentical(rowData(se1), rowData(se0)[2:3,,drop=FALSE])
        checkIdentical(colData(se1), colData(se0))
        se1 <- se0[,2:3]
        checkIdentical(c(nrow(se0), 2L), dim(se1))
        checkIdentical(rowData(se1), rowData(se0))
        checkIdentical(colData(se1), colData(se0)[2:3,,drop=FALSE])
        se1 <- se0[2:3, 2:3]
        checkIdentical(c(2L, 2L), dim(se1))
        checkIdentical(colData(se1), colData(se0)[2:3,,drop=FALSE])

        ## character
        se1 <- se0
        dimnames(se1) <- list(LETTERS[seq_len(nrow(se1))],
                               letters[seq_len(ncol(se1))])
        ridx <- c("B", "C")
        checkException(se1[LETTERS,], "i-index out of bounds", TRUE)
        cidx <- c("b", "c")
        checkIdentical(colData(se1[,cidx]), colData(se1)[cidx,,drop=FALSE])
        checkIdentical(colData(se1[,"a"]), colData(se1)["a",,drop=FALSE])
        checkException(se1[,letters], "j-index out of bounds", TRUE)

        ## logical
        se1 <- se0
        dimnames(se1) <- list(LETTERS[seq_len(nrow(se1))],
                               letters[seq_len(ncol(se1))])
        checkEquals(se1, se1[TRUE,])
        checkIdentical(c(0L, ncol(se1)), dim(se1[FALSE,]))
        checkEquals(se1, se1[,TRUE])
        checkIdentical(c(nrow(se1), 0L), dim(se1[,FALSE]))
        idx <- c(TRUE, FALSE)               # recycling
        se2 <- se1[idx,]
        se2 <- se1[,idx]
        checkIdentical(colData(se1)[idx,,drop=FALSE], colData(se2))

        ## Rle
        se1 <- se0
        rle <- rep(c(TRUE, FALSE), each=3, length.out=nrow(se1))
        checkIdentical(assays(se1[rle]), assays(se1[Rle(rle)]))
    }

    ## 0 columns
    se <- SummarizedExperiment(matrix(integer(0), nrow=5))
    checkIdentical(dim(se[1:5, ]), c(5L, 0L)) 
    ## 0 rows 
    se <- SummarizedExperiment(colData=DataFrame(samples=1:10))
    checkIdentical(dim(se[ ,1:5]), c(0L, 5L)) 
}

test_SummarizedExperiment_subsetassign <- function()
{
    for (i in seq_along(se0List)) {
        se0 <- se0List[[i]] 
        dimnames(se0) <- list(LETTERS[seq_len(nrow(se0))],
                               letters[seq_len(ncol(se0))])
        ## rows
        se1 <- se0
        se1[1:2,] <- se1[2:1,]
        checkIdentical(colData(se0), colData(se1))
        checkIdentical(c(metadata(se0), metadata(se0)), metadata(se1))
        ## Rle
        se1rle <- se1Rle <- se0
        rle <- rep(c(TRUE, FALSE), each=3, length.out=nrow(se1))
        se1rle[rle,] <- se1rle[rle,]
        se1Rle[Rle(rle),] <- se1Rle[Rle(rle),]
        checkIdentical(assays(se1rle), assays(se1Rle))
        ## cols
        se1 <- se0
        se1[,1:2] <- se1[,2:1,drop=FALSE]
        checkIdentical(colData(se0)[2:1,,drop=FALSE],
                       colData(se1)[1:2,,drop=FALSE])
        checkIdentical(colData(se0)[-(1:2),,drop=FALSE],
                       colData(se1)[-(1:2),,drop=FALSE])
        checkIdentical(c(metadata(se0), metadata(se0)), metadata(se1))
    }

    ## full replacement
    se1 <- se2 <- se0List[[1]]
    se1[,] <- se2
    checkIdentical(se1, se2)
}

test_SummarizedExperiment_assays_4d <- function()
{
    ## [
    a <- array(0, c(3, 3, 3, 3), list(LETTERS[1:3], letters[1:3], NULL, NULL))
    assays <- SimpleList(a=a)
    se <- SummarizedExperiment(assays)
    checkIdentical(assays(se[1,])[[1]], a[1,,,,drop=FALSE])

    ## [<-
    a1 <- a; a1[1,,,] <- a[1,,,,drop=FALSE] + 1
    assays(se[1,])[[1]] <- 1 + assays(se[1,])[[1]]
    checkIdentical(assays(se)[[1]], a1)

    ## [, [<- don't support more than 4 dimensions
    a <- array(0, c(3, 3, 3, 3, 3),
               list(LETTERS[1:3], letters[1:3], NULL, NULL, NULL))
    assays <- SimpleList(a=a)
    se <- SummarizedExperiment(assays)
    checkException(se[1,], silent=TRUE)
}
