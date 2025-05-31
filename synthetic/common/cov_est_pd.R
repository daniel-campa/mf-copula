# High-dimensional autocovariance matrices and optimal linear prediction
# McMurry and Politis

shrinkFactors <- function(x, l, kernel="Trap") {
	require(iosmooth)
	n <- length(x)

	gamma0 <- acf(x, lag.max=0, type="covariance", plot=F)$acf[1,1,1]
	xsdlen <- max(501, 50*l+1)
	yio <- iospecden(x, l, x.points=seq(-pi, pi, len=xsdlen), kernel=kernel)$y
	y2o <- sospecden(x, l, x.points=seq(-pi, pi, len=xsdlen), kernel=kernel)$y
	
	# Shrink To White Noise Factor
	thresh <- max(min(y2o/2), min(yio), (10*gamma0/n)/(2*pi))
	
	if( abs(gamma0/(2*pi) - thresh) < 1e-10) {
		sfwn <- 1
	} else {
		sfwn <- (gamma0/(2*pi) - thresh)/(gamma0/(2*pi) - min(yio))
    }
	
	# Shrink To 2o Factor
	min2o <- min(y2o)	
	minio <- min(yio)

	thresh <- (10*gamma0/n)/(2*pi) #was 10
	
	# sf*fio + (1-sf)*f2o
	sf2o <- min(ifelse(yio > thresh | yio >= y2o, 1, 
				pmax((thresh - y2o)/(yio - y2o), 0)))		

	list(sfwn = sfwn, sf2o = sf2o)
}

mf.predict <- function(x, l, kernel = c("Trap", "Rect"), posDef = c("ShrWN", "Shr2o")) {
	require(iosmooth)

	kernel <- match.arg(kernel, c("Trap", "Rect"))
	posDef <- match.arg(posDef, c("ShrWN", "Shr2o"))
	
	n <- length(x)
	xbar <- mean(x)
	x <- x - xbar
	
	x.acf <- as.vector(acf(x, type="covariance", plot=FALSE, lag.max=n)$acf)
	if(missing(l)) l <- bwadap.ts(x) #l is the bandwidth
	
	kappa <- switch(kernel, "Trap" = iosmooth:::kappaTrap, "Rect" = iosmooth:::kappaRect)
	diags <- kappa(0:(n-1), l) * x.acf
	
	if(posDef == "Shr2o") {
		M <- iosmooth:::bw2order(diags, n)
		diagsParzen <- (iosmooth:::kappaParzen((0:(n-1)),M))*x.acf
		sfs <- shrinkFactors(x, l)
		diagsShr <- sfs$sf2o*diags + (1 - sfs$sf2o)*diagsParzen
	} else if(posDef == "ShrWN") {
		sfs <- shrinkFactors(x, l)
		diagsShr <- diags * c(1, rep(sfs$sfwn, n-1))
	}

	Gamman <- toeplitz(diagsShr)
	Gammanp1 <- toeplitz(c(diagsShr,0))
	
	GammanChol <- chol(Gamman) # Gamman = t(GammanChol) %*% GammanChol
	Gammanp1Chol <- chol(Gammanp1)

	en <- forwardsolve(t(GammanChol), x)
	
	constPart <- en %*% t(Gammanp1Chol)[n+1, -(n+1)]
	avgPart <- mean(en)*Gammanp1Chol[n+1, n+1]
	
	as.vector(constPart + avgPart + xbar)
}

mf.predict_vector <- function(x, l, kernel = c("Trap", "Rect"), posDef = c("ShrWN", "Shr2o"), lmf=FALSE, nMC=0) {
	require(iosmooth)

	kernel <- match.arg(kernel, c("Trap", "Rect"))
	posDef <- match.arg(posDef, c("ShrWN", "Shr2o"))
	
	n <- length(x)
        if (n >1) {
	xbar <- mean(x)
	x <- x - xbar
	
	x.acf <- as.vector(acf(x, type="covariance", plot=FALSE, lag.max=n)$acf)
	if(missing(l)) l <- bwadap.ts(x) #l is the bandwidth
	
	kappa <- switch(kernel, "Trap" = iosmooth:::kappaTrap, "Rect" = iosmooth:::kappaRect)
	diags <- kappa(0:(n-1), l) * x.acf
	
	if(posDef == "Shr2o") {
		M <- iosmooth:::bw2order(diags, n)
		diagsParzen <- (iosmooth:::kappaParzen((0:(n-1)),M))*x.acf
		sfs <- shrinkFactors(x, l)
		diagsShr <- sfs$sf2o*diags + (1 - sfs$sf2o)*diagsParzen
	} else if(posDef == "ShrWN") {
		sfs <- shrinkFactors(x, l)
		diagsShr <- diags * c(1, rep(sfs$sfwn, n-1))
	}

	Gamman <- toeplitz(diagsShr)
	Gammanp1 <- toeplitz(c(diagsShr,0))
	
	GammanChol <- chol(Gamman) # Gamman = t(GammanChol) %*% GammanChol
	Gammanp1Chol <- chol(Gammanp1)

        if (lmf==FALSE) {
	  en <- forwardsolve(t(GammanChol), x)

	  constPart <- en %*% t(Gammanp1Chol)[n+1, -(n+1)]
	  varPart   <- en*Gammanp1Chol[n+1, n+1]

          en_out    <- en

        }
        else {
 	  en_actual <- forwardsolve(t(GammanChol), x)
          if (nMC==0) {
            en_ideal  <- rnorm(length(x))
          } else {
            en_ideal  <- rnorm(nMC)
          }

	  constPart <- en_actual %*% t(Gammanp1Chol)[n+1, -(n+1)]
	  varPart   <- en_ideal*Gammanp1Chol[n+1, n+1]

          en_out    <- en_actual

        }
	
	# avgPart <- mean(en)*Gammanp1Chol[n+1, n+1]
	
	pred <- as.vector(constPart + varPart + xbar)

        return(list(pred, en_out, diagsShr))
        } else {
        return(list(NA, NA, NA))
        }
        
}

mf_boot.gen_pseudo <- function(x, diagsShr, innov_boot) {
	
#	n <- length(x)
        xbar <- mean(x)

        # reconstruct covariance matrices from diagonal values
	Gamman <- toeplitz(diagsShr)
	GammanChol <- chol(Gamman) # Gamman = t(GammanChol) %*% GammanChol

	constPart <- t(GammanChol)%*%innov_boot
	
 	pseudo <- as.vector(constPart + xbar)
#	pseudo <- as.vector(constPart)

        return(pseudo)
}
