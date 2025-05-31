suppressPackageStartupMessages({
  require(copula)
})

copula_gaussian <- function(x, nsamples=10000) {

ncolumns <- ncol(as.matrix(x))

cor_mat <- cor(x)
corr_val <- cor_mat[upper.tri(cor_mat)]

copula_samples <- rCopula(nsamples, copula=normalCopula(param=corr_val, dim = ncolumns, dispstr = "un"))
copula_samples_final <- toEmpMargins(copula_samples, x=x)

return(copula_samples_final)

}
