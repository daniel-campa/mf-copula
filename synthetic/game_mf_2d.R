suppressPackageStartupMessages({
  library(rugarch)
  library(qrmtools)
  library(xts)
  library(copula)
  library(npcp)
  library(forecast)
  library(ggplot2)
  library(iosmooth)
})

setwd('~/git/mf-copula/')

source("./synthetic/common/copula_gaussian.R")
source("./synthetic/common/fb.R")
source("./synthetic/common/utils.R")
source("./synthetic/common/cov_est_pd.R")
source("./synthetic/common/chol.R")

csv <- "./schola/sets/set6/agent3/scen1.csv"
mask <- "./schola/sets/set6/agent3/scen1-mask.txt"
output_dir <- 'synthetic/output/set6/scen1-mf-ban2-chol2-15-offset/agent3'

path <- read.csv(csv)
if (file.exists((mask))) {
  corners <- read.csv(mask)$X0
} else {
  corners <- length(path)
}

if (dir.exists(output_dir)) {
  stop(sprintf('%s already exists', output_dir))
} else {
  dir.create(output_dir, recursive = TRUE)
}
print(output_dir)
write.csv(path, sprintf("%s/original.csv", output_dir), row.names = FALSE)

Xpath <- .xts(path, index = 1:nrow(path))


ban <- 2
scale_res <- FALSE
use_offset <- TRUE
use_cholesky <- TRUE

# cholesky correlation modification
cor_delta <- 0.2
chol_scale <- 15

temp_x <- Xpath[,1]
temp_y <- Xpath[,2]

scale_x <- runif(length(temp_x), min=0, max=1)
scale_y <- runif(length(temp_y), min=0, max=1)

# number of time series realizations
nMC <- 50

# length of each series
num_gen <- 2000

# number of copulas to use
num_cop <- length(corners)+1

# residual scaling
scale_eps_min0 <- 10
scale_eps_max0 <- 20
reduced_dim_multiplier <- 100




for (k1 in 1:nMC) {

  print(k1)

  df <- data.frame(X=numeric(), Y=numeric())
  dim_dfs <- list()


  for (m in 0:(num_cop-1)) {
    if (sum(is.na(df))!=0) {
      print('NA values in df')
      stop()
    }

    # indices for sub-series
    if (m == 0) {
      indices <- 1:corners[1]
      offset_x <- 0
      offset_y <- 0
    } else if (m == num_cop-1) {
      indices <- corners[m]:length(temp_x)
      if (use_offset == TRUE) {
        offset_x <- tail(df[,'x'], 1) - as.numeric(temp_x[indices[1]])
        offset_y <- tail(df[,'y'], 1) - as.numeric(temp_y[indices[1]])
      }
    } else {
      indices <- corners[m]:corners[m+1]
      if (use_offset == TRUE) {
        offset_x <- tail(df[,'x'], 1) - as.numeric(temp_x[indices[1]])
        offset_y <- tail(df[,'y'], 1) - as.numeric(temp_y[indices[1]])
      }
    }

    # not enough points for model
    if (length(indices) <= ban * 2) {
      dim_dfs[[1]] <- data.frame(x = temp_x[indices])
      dim_dfs[[2]] <- data.frame(y = temp_y[indices])

      new_df <- cbind(dim_dfs[[1]] + offset_x, dim_dfs[[2]] + offset_y)

      df <- rbind(df,new_df)

      next
    }

    # model free transforms
    if (var(temp_x[indices]) == 0) {
      res_x <- rep(0, length(indices) - ban)
    } else {
      x_for <- forward_trans(temp_x[indices], ban)
      normsamples_x <- x_for[[1]]
      res_x <- x_for[[2]]
      cov_diags_x <- x_for[[3]]
    }

    if (var(temp_y[indices]) == 0) {
      res_y <- rep(0, length(indices) - ban)
    } else {
      y_for <- forward_trans(temp_y[indices], ban)
      normsamples_y <- y_for[[1]]
      res_y <- y_for[[2]]
      cov_diags_y <- y_for[[3]]
    }


    eps <- as.matrix(cbind(res_x, res_y))

    # checking for uncorrelated dimension in sub-series
    if (sum(is.na(cor(eps))) == 0) {
      eps_synth <- copula_gaussian(
        eps, nsamples = length(indices)
      )
      dims <- 1:2
      scale_eps_min <- scale_eps_min0
      scale_eps_max <- scale_eps_max0
    } else {
      print(sprintf('%d-%d: using means', indices[1], indices[length(indices)]))

      temp_x_s <- rep(mean(temp_x[indices]), length(indices))
      temp_y_s <- rep(mean(temp_y[indices]), length(indices))

      dim_dfs[[1]] <- data.frame(x = temp_x_s)
      dim_dfs[[2]] <- data.frame(y = temp_y_s)

      dims <- c()
    }

    if (use_cholesky == TRUE) {
      cor_orig <- cor(eps_synth)[2]
      min_cor <- max(-1, cor_orig-cor_delta)
      max_cor <- min(1, cor_orig+cor_delta)
      target_rho <- runif(1, min=min_cor, max=max_cor)

      eps_synth <- modify_correlation_cholesky(eps_synth, target_rho) * chol_scale
    }

    for (dim in dims) {
      # extract the synthetic residual values produced by the copula
      res_s <- as.vector(eps_synth[,dim])

      if (scale_res == TRUE) {
        scale_eps <- runif(length(res_s), min=scale_eps_min, max=scale_eps_max)
        res_s <- res_s * scale_eps
      }

      orig <- list(temp_x, temp_y)[[dim]]
      normsamples <- list(normsamples_x, normsamples_y)[[dim]]
      cov_diags <- list(cov_diags_x, cov_diags_y)[[dim]]
      scale <- list(scale_x, scale_y)[[dim]][indices[1]:(length(indices)-ban)]

      temp_s <- reverse_trans(
        orig[indices],
        scale * normsamples[1:(length(indices) - ban)],
        res_s[1:(length(indices) - ban)],
        cov_diags[1:(length(indices) - ban)],
        ban
      )
      temp_s <- c(as.vector(orig[indices[1:ban]]), temp_s)
      temp_s <- na.locf(na.approx(temp_s, na.rm = FALSE))

      dim_df <- data.frame(temp_s)
      colnames(dim_df) <- c('x','y')[dim]

      dim_dfs[[dim]] <- dim_df
    }
    new_df <- cbind(dim_dfs[[1]] + offset_x, dim_dfs[[2]] + offset_y)

    df <- rbind(df,new_df)
  }
  
  write.csv(df, sprintf("%s/path%d.csv", output_dir, k1), row.names = FALSE)

}
print(output_dir)
