
forward_trans <- function(y, ban, arma=FALSE, pred=TRUE, lmf=FALSE) {

  nsamples <- length(y)

  # uniformizing transform
  x <- c(1:nsamples)
  method <- 1

  # apply the uniformizing transformation
  u <- c(1:nsamples)
  for (k in 2:(nsamples-1)) {
    xx <- c(x[1:(k - 1)], x[(k + 1):nsamples])
    yy <- c(y[1:(k - 1)], y[(k + 1):nsamples])
    w <- calc.weights(xx, x[k], ban, lc=TRUE)
    u[k]<-  uniformize.kernel(yy, y[k],  inverse=FALSE, w=w)
  }

  u2 <- na.rm(u[2:(nsamples-1)])

  # normalizing transform
  normsamples <- na.rm(qnorm(u2))
  normsamples <- replace(normsamples, is.infinite(normsamples), NA)
  normsamples <- na.rm(normsamples)

  # whitening transform
  normsamples_pred_list <- mf.predict_vector(normsamples, posDef="Shr2o", lmf=lmf, nMC=nMC)
  normsamples_pred <- normsamples_pred_list[[1]]
  normsamples_innov <- normsamples_pred_list[[2]]
  cov_diags <- normsamples_pred_list[[3]]

  return(list(normsamples, normsamples_innov, cov_diags))

}

reverse_trans <- function(y, normsamples, epsilon, cov_diags, ban, arma=FALSE, pred=TRUE) {

  nsamples <- length(epsilon)
  x <- c(1:nsamples)

  y_star <- numeric(nsamples)

  # correlated normal samples
  normsamples_pred_star <- mf_boot.gen_pseudo(normsamples, cov_diags, epsilon[1:nsamples])

  # uniform samples
  unifsamples_star <- na.rm(pnorm(normsamples_pred_star))
  unifsamples_star <- c(NA, unifsamples_star, NA)

  adjust <- 0

  # pseudo data
  for (k in 2:(nsamples-1)) {
    xx <- c(x[1:(k - 1)], x[(k + 1):nsamples])
    yy <- c(y[1:(k - 1)], y[(k + 1):nsamples])
    w <- calc.weights(xx, x[k], ban, lc=TRUE)
    y_star[k]<-  uniformize.kernel(yy, unifsamples_star[k],  inverse=TRUE, w=w)
  }

  return(y_star[2:(nsamples-1)])

}
