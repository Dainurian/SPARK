########################################
# Edited by Shiquan Sun
# Date: 2018-12-29 07:48:59
# Modified: 2019-4-28 11:53:55;2020-2-8 00:56:23
##########################################

#' Compute Gaussian kernel matrix
#' @param data1 The data set
#' @param data2 The second data set
#' @param gamma The parameter for Guassian kernel
#' @export
# the suggested gamma is taking 0.01, 0.05, 0.1, 0.2, 0.5
ComputeGaussianL <- function(data1, data2=NULL, gamma=0.1){
	data1 <- as.matrix(data1)
	num_cell <- nrow(data1)
	if(is.null(data2)){
		data2 <- data1
	}# end fi
	
	dist_mat <- matrix(0, ncol = num_cell, nrow = num_cell)
	kernel_para <- rep(0, nrow(data1))
	for(k in 1:nrow( data1)){ #
		# dist_mat[k,]  <-  rowSums( (data2 -  kronecker(matrix(rep(1,nrow(data2)),ncol=1), matrix(data1[k,],nrow = 1), FUN = "*")  )^2 )
		dist_mat[k,] <- rowSums( abs(data2 - kronecker(matrix(rep(1,nrow(data2)),ncol=1), matrix(data1[k,],nrow = 1), FUN = "*")  ) )
		PP <- -dist_mat[k,]/log(gamma)
		#kernel_para[k] <- min( PP[which(abs(PP)>0)] )
		kernel_para[k] <- mean( PP[which(abs(PP)>0)] )
	}# end for
	
	# return cell length parameter
	return(mean(kernel_para))
}# end func


#' Filtering out the genes that are lowly expressed acorss cells or the cells that are a few number of genes expressed
#' @param counts Raw gene expression counts, p x n matrix
#' @param prectage_cell The prectage of cells that are expressed
#' @param min_total_counts Minimum counts for each cell
#' @export
FilteringGenesCells <- function(counts, prectage_cell=0.1, min_total_counts=10){
  idx <- which( apply(counts ,1 ,function(x){sum(x!=0)})>=(floor(prectage_cell*ncol(counts))) )
  # filtering out genes
  counts <- counts[idx,]
  # filtering out cells
  counts <- counts[ ,which(apply(counts,2,sum)>min_total_counts)]
  return(counts)
}# end func




#' Calculate Gaussian Parameter L based on Eculidean Distance
#' @param X Cell corrdinates matrix n x 2 or kernel matrix computed already
#' @param compute_distance Compute the distance matrix using generic function dist, default=TRUE
#' @export
ComputeGaussianPL <- function(X, compute_distance=TRUE){
  if(compute_distance){
    if(ncol(X)<2){stop("X has to be a coordinate matrix with number of column greater than 1")}
    D <- dist(X)
  }else{
    D <- X
  }# end fi
  
  #Dval <- unique(as.vector(D))
  Dval <- D
  Dval.nz <- Dval[Dval>1e-8]
  lmin <- min(Dval.nz)/2
  lmax <- max(Dval.nz)*2
  lrang <- 10^(seq(log10(lmin),log10(lmax),length.out=10))
  return(lrang)
}# end func



#' Summarized the multiple p-values via Cauchy combination rule
#' @param pvalues Pvalues from multiple kernels, a px10 matrix
#' @param weights The weights for combining the pvalues from multiple kernels, a px10 matrix or NULL
#' @export
CombinePValues <- function(pvalues, weights=NULL){
	if(!is.matrix(pvalues)){pvalues <- as.matrix(pvalues)}
	## to avoid extremely values
	pvalues[which(pvalues==0)] <- 5.55e-17
	pvalues[which((1-pvalues)<1e-3)] <- 0.99
	
	num_pval <- ncol(pvalues)
	num_gene <- nrow(pvalues)
	if(is.null(weights)){
		weights <- matrix(rep(1.0/num_pval, num_pval*num_gene), ncol=num_pval )
	}# end fi
	if( (nrow(weights) != num_gene) || (ncol(weights) != num_pval)){
		stop("the dimensions of weights does not match that of combined pvalues")
	}# end fi
	
	Cstat <- tan((0.5 - pvalues)*pi)

	wCstat <- weights*Cstat
	Cbar <- apply(wCstat, 1, sum)
	#combined_pval <- 1.0/2.0 - atan(Cbar)/pi
	combined_pval <- 1.0 - pcauchy(Cbar)	
	combined_pval[which(combined_pval <= 0)] <- 5.55e-17
	return(combined_pval)
}# end func


#' Anscombe variance stabilizing transformation: NB
#' @param counts gene expression count matrix
#' @param sv normalization parameter
#' @export
NormalizeVST <- function(counts, sv = 1) {
    varx = apply(counts, 1, var)
    meanx = apply(counts, 1, mean)
    phi = coef(nls(varx ~ meanx + phi * meanx^2, start = list(phi = sv)))
	
	## regress out log total counts
	norm_counts <- log(counts + 1/(2 * phi))
	total_counts <- apply(counts, 2, sum)
	res_norm_counts <- t(apply(norm_counts, 1, function(x){resid(lm(x ~ log(total_counts)))} ))
	
    return(res_norm_counts)
}# end func











