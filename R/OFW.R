#'Title OFW
#' @description performs analysis of the thermograms using Ozawa-Flynn and Wall method
#' @param mat matrix of the all the thermograms checked using the functiom mat.check
#' @param degree selected degrees of  cristallinity for performing the analysis
#' @return models "mod", datable "xy" for plot, "Ea" list of value, datatable "DT" built with the values of mat according to the specified degrees
#' @references 1. Flynn J, Wall L. Res natl bur standards. Phys Chem. 1966;70:487-492.
#' @export
#' @examples \donttest{
#' require(data.table)
#' require(MASS)
#' rates=c(0.5,1,2,5,10,20,50)
#' a<-lapply(rates, function(x) JMA(A=exp(35),Ea=120000,T0=0,T.end=300,q=x,npoints=5000,n=2))
#' a<-lapply(seq(1,length(a)), function(x) data.table(a[[x]]$time.s,a[[x]]$T.C,
#' a[[x]]$dadT, rates[[x]]))
#' lapply(seq(1,length(a)), function(x) setnames(a[[x]],
#' c("time.seconds","temperature.s","heat.flow","rates") ) )
#' ar<-testMat(a,toselect=c(0,1,2,0,0,0,3,4))
#' ofw<-OFW(ar)
#' }



OFW <- function(mat, degree=seq(0.2, 0.8, by = 0.05)) {
  time.minutes.check <- time.minutes<-time.minutes.zero <- id_cycle <- rit <- NULL

  mat.zero <- mat[mat$ri > 0][, time.minutes.check := (time.minutes.zero - min(time.minutes.zero)), by = id_cycle][]

  DT <- lapply(degree, function(x) mat.zero[, .SD[which.min(abs(ri - x))], by = list(id_cycle)])

  for (i in 1:length(degree))
  {
    DT[[i]]$rit <- degree[[i]]
  }

  DT <- rbindlist(DT)

  #-------------
  x <- (1 / DT$temperature.s.K) * 1000
  y <- log(abs((DT$rate)))
  #-------------

  xy <- data.table(x, y, DT$ri, DT$rate, DT$rit)
  setnames(xy, c("x", "y", "ri", "rate", "rit"))
  xy <- xy[is.finite(rowSums(xy)), ]
  formulas <- list(y ~ x)
  mod <- xy[, lapply(formulas, function(x) list(lm(x, data = .SD))), by = rit]
  Ea <- lapply(mod$V1, function(x) -x$coeff[[2]] * 8.314/1.052)
  my.list <- list("mod" = mod, "xy" = xy, "Ea" = Ea, "DT" = DT)
  print(summaryTableFri(my.list))
  return(my.list)
}
