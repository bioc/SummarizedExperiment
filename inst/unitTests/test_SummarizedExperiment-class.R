m <- matrix(1, 5, 3, dimnames=list(NULL, NULL))
mlst <- matrix(1, 3, 3, dimnames=list(NULL, NULL))
mList <- list(m, mlst)
assaysList <- list(gr=SimpleList(m=m), grl=SimpleList(m=mlst))
rowRangesList <- 
    list(gr=GRanges("chr1", IRanges(1:5, 10)), 
         grl=split(GRanges("chr1", IRanges(1:5, 10)), c(1,1,2,2,3)))
names(rowRangesList[["grl"]]) <- NULL
colData <- DataFrame(x=letters[1:3])

## a list of one SE with GRanges and one with GRangesList
ssetList <- 
    list(SummarizedExperiment(
           assays=assaysList[["gr"]], 
           rowRanges=rowRangesList[["gr"]], 
           colData=colData),
         SummarizedExperiment(
           assays=assaysList[["grl"]], 
           rowRanges=rowRangesList[["grl"]], 
           colData=colData))


test_RangedSummarizedExperiment_construction <- function()
{
    ## empty-ish
    m1 <- matrix(0, 0, 0)
    checkTrue(validObject(new("RangedSummarizedExperiment")))
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
    for (i in length(ssetList)) {
        sset <- ssetList[[i]] 
        checkTrue(validObject(sset))
        checkIdentical(SimpleList(m=mList[[i]]), assays(sset))
        checkIdentical(rowRangesList[[i]], rowRanges(sset))
        checkIdentical(DataFrame(x=letters[1:3]), colData(sset))
    }

    ## array in assays slot
    ss <- ssetList[[1]]
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

test_RangedSummarizedExperiment_getters <- function()
{
    for (i in length(ssetList)) {
        sset <- ssetList[[i]] 
        rowRanges <- rowRangesList[[i]] 
        ## dim, dimnames
        checkIdentical(c(length(rowRanges), nrow(colData)), dim(sset))
        checkIdentical(list(NULL, NULL), dimnames(sset))

        ## row / col / metadata
        checkIdentical(rowRanges, rowRanges(sset))
        checkIdentical(colData, colData(sset))
        checkIdentical(list(), metadata(sset))
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

test_RangedSummarizedExperiment_setters <- function()
{
    for (i in length(ssetList)) {
        sset <- ssetList[[i]] 
        rowRanges <- rowRangesList[[i]] 
        ## row / col / metadata<-
        ss1 <- sset
        revData <- rowRanges[rev(seq_len(length(rowRanges))),,drop=FALSE]
        rowRanges(ss1) <- revData
        checkIdentical(revData, rowRanges(ss1))
        checkException(rowRanges(ss1) <- rowRanges(sset)[1:2,,drop=FALSE],
                       "incorrect row dimensions", TRUE)
        revData <- colData[rev(seq_len(nrow(colData))),,drop=FALSE]
        colData(ss1) <- revData
        checkIdentical(revData, colData(ss1))
        checkException(colData(ss1) <- colData(sset)[1:2,,drop=FALSE],
                       "incorrect col dimensions", TRUE)
        lst <- list("foo", "bar")
        metadata(ss1) <- lst
        checkIdentical(lst, metadata(ss1))

        ## assay / assays
        ss1 <- sset
        assay(ss1) <- assay(ss1)+1
        checkIdentical(assay(sset)+1, assay(ss1))
        ss1 <- sset
        assay(ss1, 1) <- assay(ss1, 1) + 1
        checkIdentical(assay(sset, "m") + 1, assay(ss1, "m"))
        ss1 <- sset
        assay(ss1, "m") <- assay(ss1, "m") + 1
        checkIdentical(assay(sset, "m")+1, assay(ss1, "m"))

        ## dimnames<-
        ss1 <- sset
        dimnames <- list(letters[seq_len(nrow(ss1))],
                         LETTERS[seq_len(ncol(ss1))])
        rownames(ss1) <- dimnames[[1]]
        colnames(ss1) <- dimnames[[2]]
        checkIdentical(dimnames, dimnames(ss1))
        rowRanges1 <- rowRanges
        names(rowRanges1) <- dimnames[[1]]
        checkIdentical(rowRanges1, rowRanges(ss1))
        colData1 <- colData
        row.names(colData1) <- dimnames[[2]]
        checkIdentical(colData1, colData(ss1))
        ss1 <- sset
        dimnames(ss1) <- dimnames
        checkIdentical(dimnames, dimnames(ss1))
        dimnames(ss1) <- NULL
        checkIdentical(list(NULL, NULL), dimnames(ss1))
    }
}

test_RangedSummarizedExperiment_subset <- function()
{
    for (i in length(ssetList)) {
        sset <- ssetList[[i]] 
        rowRanges <- rowRangesList[[i]] 
        ## numeric
        ss1 <- sset[2:3,]
        checkIdentical(c(2L, ncol(sset)), dim(ss1))
        checkIdentical(rowRanges(ss1), rowRanges(sset)[2:3,])
        checkIdentical(colData(ss1), colData(sset))
        ss1 <- sset[,2:3]
        checkIdentical(c(nrow(sset), 2L), dim(ss1))
        checkIdentical(rowRanges(ss1), rowRanges(sset))
        checkIdentical(colData(ss1), colData(sset)[2:3,,drop=FALSE])
        ss1 <- sset[2:3, 2:3]
        checkIdentical(c(2L, 2L), dim(ss1))
        checkIdentical(rowRanges(ss1), rowRanges(sset)[2:3,,drop=FALSE])
        checkIdentical(colData(ss1), colData(sset)[2:3,,drop=FALSE])

        ## character
        ss1 <- sset
        dimnames(ss1) <- list(LETTERS[seq_len(nrow(ss1))],
                               letters[seq_len(ncol(ss1))])
        ridx <- c("B", "C")
        checkIdentical(rowRanges(ss1[ridx,]), rowRanges(ss1)[ridx,])
        checkIdentical(rowRanges(ss1["C",]), rowRanges(ss1)["C",,drop=FALSE])
        checkException(ss1[LETTERS,], "i-index out of bounds", TRUE)
        cidx <- c("b", "c")
        checkIdentical(colData(ss1[,cidx]), colData(ss1)[cidx,,drop=FALSE])
        checkIdentical(colData(ss1[,"a"]), colData(ss1)["a",,drop=FALSE])
        checkException(ss1[,letters], "j-index out of bounds", TRUE)

        ## logical
        ss1 <- sset
        dimnames(ss1) <- list(LETTERS[seq_len(nrow(ss1))],
                               letters[seq_len(ncol(ss1))])
        checkEquals(ss1, ss1[TRUE,])
        checkIdentical(c(0L, ncol(ss1)), dim(ss1[FALSE,]))
        checkEquals(ss1, ss1[,TRUE])
        checkIdentical(c(nrow(ss1), 0L), dim(ss1[,FALSE]))
        idx <- c(TRUE, FALSE)               # recycling
        ss2 <- ss1[idx,]
        checkIdentical(rowRanges(ss1)[idx,,drop=FALSE], rowRanges(ss2))
        ss2 <- ss1[,idx]
        checkIdentical(colData(ss1)[idx,,drop=FALSE], colData(ss2))

        ## Rle
        ss1 <- sset
        rle <- rep(c(TRUE, FALSE), each=3, length.out=nrow(ss1))
        checkIdentical(rowRanges(ss1[rle]), rowRanges(ss1[Rle(rle)]))
        checkIdentical(assays(ss1[rle]), assays(ss1[Rle(rle)]))
    }

    ## 0 columns
    se <- SummarizedExperiment(rowRanges=GRanges("chr1", IRanges(1:10, width=1)))
    checkIdentical(dim(se[1:5, ]), c(5L, 0L)) 
    ## 0 rows 
    se <- SummarizedExperiment(colData=DataFrame(samples=1:10))
    checkIdentical(dim(se[ ,1:5]), c(0L, 5L)) 
}

test_RangedSummarizedExperiment_subsetassign <- function()
{
    for (i in length(ssetList)) {
        sset <- ssetList[[i]] 
        dimnames(sset) <- list(LETTERS[seq_len(nrow(sset))],
                               letters[seq_len(ncol(sset))])
        ## rows
        ss1 <- sset
        ss1[1:2,] <- ss1[2:1,]
        checkIdentical(rowRanges(sset)[2:1,], rowRanges(ss1)[1:2,])
        checkIdentical(rowRanges(sset[-(1:2),]), rowRanges(ss1)[-(1:2),])
        checkIdentical(colData(sset), colData(ss1))
        checkIdentical(c(metadata(sset), metadata(sset)), metadata(ss1))
        ## Rle
        ss1rle <- ss1Rle <- sset
        rle <- rep(c(TRUE, FALSE), each=3, length.out=nrow(ss1))
        ss1rle[rle,] <- ss1rle[rle,]
        ss1Rle[Rle(rle),] <- ss1Rle[Rle(rle),]
        checkIdentical(rowRanges(ss1rle), rowRanges(ss1Rle))
        checkIdentical(assays(ss1rle), assays(ss1Rle))
        ## cols
        ss1 <- sset
        ss1[,1:2] <- ss1[,2:1,drop=FALSE]
        checkIdentical(colData(sset)[2:1,,drop=FALSE],
                       colData(ss1)[1:2,,drop=FALSE])
        checkIdentical(colData(sset)[-(1:2),,drop=FALSE],
                       colData(ss1)[-(1:2),,drop=FALSE])
        checkIdentical(rowRanges(sset), rowRanges(ss1))
        checkIdentical(c(metadata(sset), metadata(sset)), metadata(ss1))
    }
    ## full replacement
    ss1 <- ss2 <- ssetList[[1]]
    rowRanges(ss2) <- rev(rowRanges(ss2))
    ss1[,] <- ss2
    checkIdentical(ss1, ss2)
}

quiet <- suppressWarnings
test_RangedSummarizedExperiment_cbind <- function()
## requires matching ranges
{
    ## empty
    se <- SummarizedExperiment()
    empty <- cbind(se, se)
    checkTrue(all.equal(se, empty))

    ## different ranges 
    se1 <- ssetList[[1]]
    se2 <- se1[2:4]
    rownames(se2) <- month.name[seq_len(nrow(se2))]
    checkException(quiet(cbind(se1, se2)), silent=TRUE)

    ## same ranges 
    se1 <- ssetList[[1]]
    se2 <- se1[,1:2]
    colnames(se2) <- month.name[seq_len(ncol(se2))]
    res <- cbind(se1, se2)
    checkTrue(nrow(res) == 5)
    checkTrue(ncol(res) == 5)
    ## rowRanges
    mcols(se1) <- DataFrame("one"=1:5)
    mcols(se2) <- DataFrame("two"=6:10)
    res <- quiet(cbind(se1, se2))
    checkIdentical(names(mcols(rowRanges(res))), c("one", "two"))
    mcols(se2) <- DataFrame("one"=6:10, "two"=6:10)
    checkException(cbind(se1, se2), silent=TRUE)
    ## colData
    checkTrue(nrow(colData(res)) == 5)
    ## assays 
    se1 <- ssetList[[1]]
    se2 <- se1[,1:2]
    assays(se1) <- SimpleList("m"=matrix(rep("m", 15), nrow=5),
                              "a"=array(rep("a", 30), c(5,3,2)))
    assays(se2) <- SimpleList("m"=matrix(LETTERS[1:10], nrow=5),
                              "a"=array(LETTERS[1:20], c(5,2,2)))
    res <- cbind(se1, se2) ## same variables
    checkTrue(nrow(res) == 5)
    checkTrue(ncol(res) == 5)
    checkTrue(all.equal(dim(assays(res)$m), c(5L, 5L)))
    checkTrue(all.equal(dim(assays(res)$a), c(5L, 5L, 2L)))
    names(assays(se1)) <- c("mm", "aa")
    checkException(cbind(se1, se2), silent=TRUE) ## different variables
}

test_RangedSummarizedExperiment_rbind <- function()
## requires matching samples 
{
    ## empty
    se <- SummarizedExperiment()
    empty <- rbind(se, se)
    checkTrue(all.equal(se, empty))

    ## different samples 
    se1 <- ssetList[[1]]
    se2 <- se1[,1]
    checkException(quiet(rbind(se1, se2)), silent=TRUE)

    ## same samples 
    se1 <- ssetList[[1]]
    se2 <- se1
    rownames(se2) <- LETTERS[seq_len(nrow(se2))]
    res <- rbind(se1, se2)
    checkTrue(nrow(res) == 10)
    checkTrue(ncol(res) == 3)
    ## rowRanges
    mcols(se1) <- DataFrame("one"=1:5)
    mcols(se2) <- DataFrame("two"=6:10)
    checkException(rbind(se1, se2), silent=TRUE)
    ## colDat
    se1 <- ssetList[[1]]
    se2 <- se1
    colData(se2) <- DataFrame("one"=1:3, "two"=4:6)    
    res <- quiet(rbind(se1, se2))
    checkTrue(ncol(colData(res)) == 3)
    ## assays 
    se1 <- ssetList[[1]]
    se2 <- se1
    assays(se1) <- SimpleList("m"=matrix(rep("m", 15), nrow=5),
                              "a"=array(rep("a", 30), c(5,3,2)))
    assays(se2) <- SimpleList("m"=matrix(LETTERS[1:15], nrow=5),
                              "a"=array(LETTERS[1:30], c(5,3,2)))
    res <- rbind(se1, se2) ## same variables
    checkTrue(nrow(res) == 10)
    checkTrue(ncol(res) == 3)
    checkTrue(all.equal(dim(assays(res)$m), c(10L, 3L)))
    checkTrue(all.equal(dim(assays(res)$a), c(10L, 3L, 2L)))
    names(assays(se1)) <- c("mm", "aa")
    checkException(rbind(se1, se2), silent=TRUE) ## different variables
}

test_RangedSummarizedExperiment_assays_4d <- function()
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
