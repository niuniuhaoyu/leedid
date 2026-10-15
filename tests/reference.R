# Uses pinned author functions, plus independent fractional-mass DID trimming.
# Run from repository root: Rscript tests/reference.R /path/to/LeeDiD-reference
args <- commandArgs(TRUE)
ref <- if(length(args)) args[1] else 'work/LeeDiD-reference'
stopifnot(dir.exists(ref))
suppressPackageStartupMessages(library(dplyr))
for(f in c('selection.R','distributions.R','bounds.R','inference.R')) source(file.path(ref,'R',f))
# Stabilize mathematically integer inverse-ECDF ranks against floating cancellation.
# Preserve author's original functions unchanged; retain raw outputs separately.
qstable <- function(x, probs, type=1) {
 if(inherits(x,'ecdf')) x <- evalq(rep.int(x,diff(c(0,round(nobs*y)))),environment(x))
 x <- sort(x); z <- length(x)*pmax(0,pmin(1,probs))
 hit <- abs(z-round(z))<1e-12;z[hit] <- round(z[hit])
 x[pmax(1,pmin(length(x),ceiling(z)))]
}
cic_bounds_stable <- cic_bounds
body(cic_bounds_stable) <- parse(text=gsub('stats::quantile','qstable',paste(deparse(body(cic_bounds)),collapse='\n'),fixed=TRUE))[[1]]
dir.create('tests/generated', recursive=TRUE, showWarnings=FALSE)
set.seed(412)
n <- 300
w <- data.frame(id=1:n,g=rep(0:1,each=n/2),a=rnorm(n),b=NA,s10=1,s20=1,s11=1,s21=1)
w$b <- w$a + .5 + w$g*(.6 + .15*w$a) + rnorm(n,sd=.35)
for(g in 0:1) {
 ix <- which(w$g==g)
 w$s10[ix[1:10]] <- w$s11[ix[1:10]] <- 0
 w$s20[ix[11:18]] <- w$s21[ix[11:18]] <- 0
 n1 <- if(g==0) 25 else 6
 n2 <- if(g==0) 6 else 25
 w$s11[ix[19:(18+n1)]] <- 0
 w$s21[ix[(19+n1):(18+n1+n2)]] <- 0
}
w$a[w$s10*w$s20==0] <- NA
w$b[w$s11*w$s21==0] <- NA
long <- function(w) {
 rbind(data.frame(id=w$id,g=w$g,period=1,y=w$a,s1=w$s10,s2=w$s20),
       data.frame(id=w$id,g=w$g,period=2,y=w$b,s1=w$s11,s2=w$s21))
}
d <- long(w)
write.csv(d,'tests/generated/reference_data.csv',row.names=FALSE,na='')
probs <- c(.13,.37,.61,.89)
fractional <- function(x,p,top=FALSE) {
 x <- sort(x,decreasing=top); mass <- p*length(x)
 weights <- pmax(0,pmin(1,mass-(seq_along(x)-1)))
 sum(x*weights)/mass
}
reference <- function(w, stabilized=TRUE) {
 boundfun <- if(stabilized) cic_bounds_stable else cic_bounds
 d <- long(w)
 pi <- compute_ao_share(d,'id','period','g',c('s1','s2'),2,1)
 cc <- d[d$id %in% w$id[complete.cases(w[,c('a','b')])],]
 epc <- empirical_cdfs(cc,'y','period','g',2,1)
 qb <- boundfun(epc,probs,pi$pi_0,pi$pi_1)
 m <- sum(w$g==1 & complete.cases(w[,c('a','b')]))
 k <- 0:m/m
 breaks <- sort(unique(c(0,1,k/pi$pi_1,(k-1+pi$pi_1)/pi$pi_1)))
 breaks <- breaks[breaks>=0 & breaks<=1]
 mid <- (head(breaks,-1)+tail(breaks,-1))/2
 b <- boundfun(epc,mid,pi$pi_0,pi$pi_1)
 integ <- colSums(as.matrix(b[,c('lb','ub')])*diff(breaks))
 delta0 <- na.omit((w$b-w$a)[w$g==0]);delta1 <- na.omit((w$b-w$a)[w$g==1])
 did <- c(fractional(delta1,pi$pi_1)-fractional(delta0,pi$pi_0,TRUE),
          fractional(delta1,pi$pi_1,TRUE)-fractional(delta0,pi$pi_0))
 c(pi$pi_0,pi$pi_1,did,integ,qb$lb,qb$ub)
}
expected <- reference(w)
raw <- reference(w,FALSE)
write.csv(rbind(raw=raw,stabilized=expected),'tests/generated/raw_author_comparison.csv',row.names=TRUE)
set.seed(765)
idx <- replicate(29,sample.int(n,n,TRUE))
boots <- t(apply(idx,2,function(i) {z<-w[i,];z$id<-1:n;reference(z)}))
write.csv(idx,'tests/generated/shared_indices.csv',row.names=FALSE)
write.csv(rbind(expected,boots),'tests/generated/expected.csv',row.names=FALSE)
ci <- imbens_manski_ci(expected[3:6][c(1,3)],expected[3:6][c(2,4)],
                      apply(boots[,c(3,5)],2,sd),apply(boots[,c(4,6)],2,sd))
write.csv(ci,'tests/generated/expected_ci.csv',row.names=FALSE)
cat('Generated author-function reference: 1 original + 29 shared resamples,',length(expected),'statistics each.\n')
