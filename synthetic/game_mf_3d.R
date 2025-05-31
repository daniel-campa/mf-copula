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

csv <- "./HNTT/preprocessed/human/2021.01.25-12.12.54.csv"
mask <- "./HNTT/preprocessed/human/2021.01.25-12.12.54-mask.txt"
output_dir <- './synthetic/output/ntt-human-mf-ban10-chol2-150/2021.01.25-12.12.54'

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


ban <- 10
scale_res <- FALSE
use_offset <- FALSE
use_cholesky <- TRUE

# cholesky correlation modification
cor_delta <- 0.2
chol_scale <- 150

temp_x <- Xpath[,1]
temp_y <- Xpath[,2]
temp_z <- Xpath[,3]

scale_x <- runif(length(temp_x), min=0, max=1)
scale_y <- runif(length(temp_y), min=0, max=1)
scale_z <- runif(length(temp_z), min=0, max=1)

# number of time series realizations
nMC <- 5

# length of each series
num_gen <- 2000

# number of copulas to use
num_cop <- length(corners)+1

# residual scaling
scale_eps_min0 <- 1
scale_eps_max0 <- 10
reduced_dim_multiplier <- 1


bound <- function(x, lower = -1, upper = 1) {
  pmin(upper, pmax(lower, x))
}


for (k1 in 1:nMC) {

  print(k1)
  
  df <- data.frame(X=numeric(), Y=numeric(), Z=numeric())
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
      offset_z <- 0
    } else if (m == num_cop-1) {
      indices <- corners[m]:length(temp_x)
      if (use_offset) {
        offset_x <- tail(df[,'X'], 1) - as.numeric(temp_x[indices[1]])
        offset_y <- tail(df[,'Y'], 1) - as.numeric(temp_y[indices[1]])
        offset_z <- tail(df[,'Z'], 1) - as.numeric(temp_z[indices[1]])        
      }
    } else {
      indices <- corners[m]:corners[m+1]
      if (use_offset) {
        offset_x <- tail(df[,'X'], 1) - as.numeric(temp_x[indices[1]])
        offset_y <- tail(df[,'Y'], 1) - as.numeric(temp_y[indices[1]])
        offset_z <- tail(df[,'Z'], 1) - as.numeric(temp_z[indices[1]])        
      }
    }
    
    # not enough points for model
    if (length(indices) <= ban * 2) {
      dim_dfs[[1]] <- data.frame(X = temp_x[indices])
      dim_dfs[[2]] <- data.frame(Y = temp_y[indices])
      dim_dfs[[3]] <- data.frame(Z = temp_z[indices])
      
      new_df <- cbind(dim_dfs[[1]] + offset_x, dim_dfs[[2]] + offset_y, dim_dfs[[3]] + offset_z)
      
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
    
    if (var(temp_z[indices]) == 0) {
      res_z <- rep(0, length(indices) - ban)
    } else {
      z_for <- forward_trans(temp_z[indices], ban)
      normsamples_z <- z_for[[1]]
      res_z <- z_for[[2]]
      cov_diags_z <- z_for[[3]]
    }
    
    eps <- as.matrix(cbind(res_x, res_y, res_z))
    
    # checking for uncorrelated dimension in sub-series
    if (sum(is.na(cor(eps))) == 0) {
      eps_synth <- copula_gaussian(eps, nsamples=length(indices))
      dims <- 1:3
      scale_eps_min <- scale_eps_min0
      scale_eps_max <- scale_eps_max0
    } else if ((var(eps[,3]) == 0) && (var(eps[,2]) > 0) && (var(eps[,1]) > 0)) {
      print(sprintf('%d-%d: using original Z', indices[1], indices[length(indices)]))
      eps_synth <- copula_gaussian(eps[,1:2], nsamples=length(indices))
      eps_synth <- cbind(eps_synth, 0)
      dim_dfs[[3]] = data.frame(Z = temp_z[indices[1]:indices[length(indices)-2]])
      dims <- 1:2
      scale_eps_min <- scale_eps_min0 * reduced_dim_multiplier
      scale_eps_max <- scale_eps_max0 * reduced_dim_multiplier
    } else if ((var(eps[,2]) == 0) && (var(eps[,1]) > 0) && (var(eps[,3]) > 0)) {
      print(sprintf('%d-%d: using original Y', indices[1], indices[length(indices)]))
      eps_synth <- copula_gaussian(eps[,c(1,3)], nsamples=length(indices))
      eps_synth <- cbind(eps_synth[,1], 0, eps_synth[,2])
      dim_dfs[[2]] = data.frame(Y = temp_y[indices])
      dims <- c(1,3)
      scale_eps_min <- scale_eps_min0 * reduced_dim_multiplier
      scale_eps_max <- scale_eps_max0 * reduced_dim_multiplier
    } else if ((var(eps[,1]) == 0) && (var(eps[,2]) > 0) && (var(eps[,3]) > 0)) {
      print(sprintf('%d-%d: using original X', indices[1], indices[length(indices)]))
      eps_synth <- copula_gaussian(eps[,2:3], nsamples=length(indices))
      eps_synth <- cbind(0, eps_synth)
      dim_dfs[[1]] = data.frame(X = temp_x[indices])
      dims <- 2:3
      scale_eps_min <- scale_eps_min0 * reduced_dim_multiplier
      scale_eps_max <- scale_eps_max0 * reduced_dim_multiplier
    } else {
      print(sprintf('%d-%d: using means', indices[1], indices[length(indices)]))
      
      temp_x_s <- rep(mean(temp_x[indices]), length(indices))
      temp_y_s <- rep(mean(temp_y[indices]), length(indices))
      temp_z_s <- rep(mean(temp_z[indices]), length(indices))
      
      dim_dfs[[1]] <- data.frame(X = temp_x_s)
      dim_dfs[[2]] <- data.frame(Y = temp_y_s)
      dim_dfs[[3]] <- data.frame(Z = temp_z_s)
      
      dims <- c()
    }

    if (use_cholesky == TRUE) {
      i <- 0
      while (i < 1000) {
        sigma <- cor(eps_synth)
        cor_deltas <- runif(3, min=-cor_delta, max=cor_delta)
        # X-Y
        sigma[1,2] <- bound(sigma[1,2] + cor_deltas[1])
        sigma[2,1] <- sigma[1,2]
        # X-Z
        sigma[1,3] <- bound(sigma[1,3] + cor_deltas[2])
        sigma[3,1] <- sigma[1,3]
        #Y-Z
        sigma[2,3] <- bound(sigma[2,3] + cor_deltas[3])
        sigma[3,2] <- sigma[2,3]

        res <- tryCatch({
          modify_correlation_cholesky_3d(eps_synth, sigma)
        }, error = function(e) {
          NULL
        })

        if (!is.null(res)) {
          eps_synth <- res
          break  # break out of the loop when transformation is successful
        }
        i <- i + 1
      }

      eps_synth <- eps_synth * chol_scale
    }
    
    for (dim in dims) {
      # extract the synthetic residual values produced by the copula
      res_s <- as.vector(eps_synth[,dim])
      
      if (scale_res == TRUE) {
        scale_eps <- runif(length(res_s), min=scale_eps_min, max=scale_eps_max)
        res_s <- res_s * scale_eps
      }
      
      orig <- list(temp_x, temp_y, temp_z)[[dim]]
      normsamples <- list(normsamples_x, normsamples_y, normsamples_z)[[dim]]
      cov_diags <- list(cov_diags_x, cov_diags_y, cov_diags_z)[[dim]]
      scale <- list(scale_x, scale_y, scale_z)[[dim]][indices[1]:(length(indices)-ban)]
      
      temp_s <- reverse_trans(
        orig[indices],
        scale*normsamples[1:(length(indices)-ban)],
        res_s[1:(length(indices)-ban)],
        cov_diags[1:(length(indices)-ban)],
        ban
      )
      temp_s <- c(as.vector(orig[indices[1:ban]]), temp_s)
      temp_s <- na.locf(na.approx(temp_s, na.rm = FALSE))
      
      dim_df <- data.frame(temp_s)
      colnames(dim_df) <- c('X','Y','Z')[dim]
      
      dim_dfs[[dim]] <- dim_df
    }
    new_df <- cbind(dim_dfs[[1]] + offset_x, dim_dfs[[2]] + offset_y, dim_dfs[[3]] + offset_z)
    
    df <- rbind(df,new_df)
  }
  
  write.csv(df, sprintf("%s/path%d.csv", output_dir, k1))
  
}
print(output_dir)
