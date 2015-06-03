#' Run a Rasch model from R using Winsteps.
#'
#' This function uses the Winsteps software to batch analyze a given list of 
#'   dataframes/matrices. The results are read back into R without leaving the 
#'   R interface or interacting with the Winsteps GUI.
#'   
#' @param itmsL List of dataframes or matrices of item responses to be analyzed.
#' @param demsL List of dataframes or matrices of person identifiers/demographic 
#'   fields.
#' @param titleL Optional list of names for control and datafiles written to the
#'   working directory. Note that this argument is only neccessary if 
#'   \code{keep = TRUE}.
#' @param keep Should the external files used to conduct the analysis be stored 
#'   in the working directory? If TRUE, all Winsteps files will be retained, 
#'   including control, data, item, and person files in .txt format, as well as 
#'   the .bat file used to process the data. Defaults to FALSE, in which case 
#'   no files are retained. Alternatively, a character vector of the files to 
#'   retain can be supplied. Possible arguments are \code{c("iFile", "pFile",
#'   "cntrlFile", "dtaFile", "outFile", "bat")}. These correspond to, 
#'   respectively, item, person, control, data, output, and the .bat (batch 
#'   processing) files.
#' @param ... Additional arguments passed to \code{\link{batch_r2Winsteps}}.
#' @seealso \code{\link{batch_r2Winsteps}} \code{\link{batchWinsteps}} 
#'   \code{\link{batch.pfile}} \code{\link{batch.ifile}}
#' @export
#' @return List containing all item and person parameters from the given 
#'   analyses.

batchRunWinsteps <- function(itmsL, demsL, titleL = NULL, keep = FALSE, ...) {

#---------- Check for previously run analyses & remove i and p files -----------
#Create name vectors of all files
    if(!is.null(titleL)){
        pFileNameV <- rep(NA, length(itmsL))
        iFileNameV <- rep(NA, length(itmsL))
        cntrlFileV <- rep(NA, length(itmsL)) # To be used later for keep = FALSE
        dtaFileV <- rep(NA, length(itmsL))   #
        outFileV <- rep(NA, length(itmsL))   #
    
        for(i in 1:length(itmsL)){
            pFileNameV[i] <- paste(titleL[i], "Pfile.txt", sep = "")
            iFileNameV[i] <- paste(titleL[i], "Ifile.txt", sep = "")
            cntrlFileV[i] <- paste(titleL[i], "Cntrl.txt", sep = "") #
            dtaFileV[i] <- paste(titleL[i], "Dta.txt", sep = "")     #
            outFileV[i] <- paste(titleL[i], "Out.txt", sep = "")     #
        }
    }

    if(is.null(titleL)){
        pFileNameV <- rep(NA, length(itmsL))
        iFileNameV <- rep(NA, length(itmsL))
        cntrlFileV <- rep(NA, length(itmsL)) #
        dtaFileV <- rep(NA, length(itmsL))   #
        outFileV <- rep(NA, length(itmsL))   #
    
        for(i in 1:length(itmsL)){
            pFileNameV[i] <- paste("r2Winsteps", i, "Pfile.txt", sep = "")
            iFileNameV[i] <- paste("r2Winsteps", i, "Ifile.txt", sep = "")
            cntrlFileV[i] <- paste("r2Winsteps", i, "Cntrl.txt", sep = "") #
            dtaFileV[i]   <- paste("r2Winsteps", i, "Dta.txt", sep = "")   #
            outFileV[i]   <- paste("r2Winsteps", i, "Out.txt", sep = "")   #
        }
    }
    
    if(any(sapply(iFileNameV, file.exists))) {
        warning("Previously estimated item file(s) removed.")
    }
    
    for(i in 1:length(iFileNameV)){
        if (file.exists(iFileNameV[i]) == TRUE) {
            invisible(file.remove(iFileNameV[i]))
        }
    }

    if(any(sapply(pFileNameV, file.exists))) {
        warning("Previously estimated person file(s) removed.")
    }
    for(i in 1:length(pFileNameV)){
        if (file.exists(pFileNameV[i]) == TRUE) {
            invisible(file.remove(pFileNameV[i]))
        }
    }

#------------------------ Get files ready for analysis -------------------------
    if(is.null(titleL)){
        lastPfileName<-paste("r2Winsteps", length(itmsL), "Pfile.txt", sep = "")
        lastIfileName<-paste("r2Winsteps", length(itmsL), "Ifile.txt", sep = "")
    }
    else{
        lastPfileName<-paste(titleL[length(titleL)], "Pfile.txt", sep = "")
        lastIfileName<-paste(titleL[length(titleL)], "Ifile.txt", sep = "")   
    }

    demNamesL <- lapply(demsL, names)
 
 #-------------------------------- run analysis --------------------------------
    call<-batch_r2Winsteps(itmsL, demsL, titleL = titleL, ...)
    batName<-ifelse(is.null(as.list(call)$batName), "r2WinstepsBatch", 
        as.list(call)$batName)
    batFile <- paste(batName, ".bat", sep = "")
    
    system(paste("open", batFile))
    
    repeat {
        Sys.sleep(0.1)
        
        if (file.exists(lastPfileName) == TRUE & 
            file.exists(lastIfileName) == TRUE) 
            
        break
    }

#------------------------------- Import results --------------------------------
    p <- batch.pfile(demNameL = demNamesL, 
            files = paste(titleL, "Pfile", sep = ""))
    i <- batch.ifile(files = paste(titleL, "Ifile", sep = ""))
    
    pars<-list("ItemParameters" = i, "PersonParameters" = p)

#------------------------- Remove files, if requested --------------------------    
    if (keep == FALSE) {
        file.remove(c(iFileNameV, pFileNameV, batFile, cntrlFileV, dtaFileV, 
            outFileV))
    if (keep == TRUE) {
        return(pars)
    }
    } else {
        keepL <- list("iFile" = iFileNameV, "pFile" = pFileNameV, 
                      "cntrlFile" = cntrlFileV, "dtaFile" = dtaFileV, 
                      "outFile" = outFileV, "bat" = batFile)
        
        m <- names(keepL) %in% keep

        keepL <- keepL[!m]

        invisible(sapply(keepL, file.remove))
    }

return(pars)
} 