na.rm<-function(x)
{       x[!is.na(x)]
}

calc.weights <- function(x,t,ban,lc=TRUE,negw=FALSE) {

  xt <- x-t

  if (lc==TRUE) {
    w  <- dnorm(xt, mean = 0, sd = (1.00*ban))
    w   <- w/sum(w)
  }
  else {
    w1   <-  dnorm(xt, mean = 0, sd = (1.00*ban))
    if (sum(xt[1:length(xt)])==0) {
     beta <- 0
    } else {
     beta <- as.numeric((t(xt)%*%w1)/(t(xt^2)%*%w1))
    }
    if (negw==FALSE) {
      w    <- w1*(rep(1,length(xt))-(xt*beta))*((xt*beta)<(rep(1,length(xt))))
    }
    else {
      w    <- w1*(rep(1,length(xt))-(xt*beta))
    }
    w    <- w/sum(w)
  }

return(w)
}

uniformize.kernel <- function(x, x0, inverse=FALSE, w, forcem=FALSE) {
n <- length(x)
if (n <= 1) return(NA) # ("sample size too small!")
if(missing(w)) {
w <- c(1:n)*0+1/n }
if(any(w < 0)) warning("Negative weight encountered.")
if(sum(w) != 1) {
w <- w/sum(w)
warning("Weights do not sum to 1.  Renormalizing.")
}
if ( is.na(sum(x)) ) {
w<- w[!is.na(x)]
w <- w/sum(w)
x<- x[!is.na(x)]
warning("missing values in x") }
# first compute the smoothed edf, i.e., the inverse=FALSE case 
if (forcem == TRUE) {
  body(density.default)[[15]][[4]][[4]][[3]] = substitute(print(paste("Negative weight encountered.")))
}

# ppdf<- density(x, weights = w ) # default uses gaussian kernel
ppdf<- density(x, weights = w, warnWbw = FALSE ) # default uses gaussian kernel
npdf<- length(ppdf$x)
delta<- ppdf$x[2]-ppdf$x[1]
pcdf<- cumsum(ppdf$y)*delta

if (forcem == TRUE) {
  pcdf  <- pcdf/max(pcdf)
}

if(inverse) {
FFinv <- approxfun(pcdf, ppdf$x)
return(FFinv(x0))
#In the inverse case x0 denotes the vector of y values to which FFinv is applied 
}
else {
FF <- approxfun(ppdf$x, pcdf)
return(FF(x0))
#Here x0 denotes the vector of x values to which FF is applied 
}}
