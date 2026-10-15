*! leedid numerical routines 0.1.0 15oct2026
version 16.0
mata:
real scalar _ld_version() return(1)
real scalar _ld_q(real colvector x, real scalar p)
{
    real scalar k, v
    p=max((0,min((1,p))))
    v=rows(x)*p
    if (abs(v-round(v))<1e-12) v=round(v)
    k=max((1,ceil(v)))
    return(x[min((rows(x),k))])
}
real scalar _ld_cdf(real colvector x, real scalar y)
{
    real scalar lo, hi, mid
    lo=0; hi=rows(x)
    while (lo<hi) {
        mid=floor((lo+hi+1)/2)
        if (x[mid]<=y) lo=mid
        else hi=mid-1
    }
    return(lo/rows(x))
}
real scalar _ld_trim(real colvector x, real scalar p, real scalar upper)
{
    real scalar m, k, z
    real colvector ordered
    ordered=x
    if (upper) ordered=x[rows(x)::1]
    m=rows(x)*p; k=floor(m); z=0
    if (k>0) z=sum(ordered[1::k])
    if (k<rows(x)) z=z+(m-k)*ordered[k+1]
    return(z/m)
}
real rowvector _ld_qbounds(real colvector a, real colvector b,
    real colvector c, real colvector d, real scalar p0, real scalar p1,
    real scalar q)
{
    real scalar low, high
    low=_ld_q(b,q*p1)-_ld_q(d,_ld_cdf(c,_ld_q(a,q*p1+1-p1))+1-p0)
    high=_ld_q(b,q*p1+1-p1)-_ld_q(d,_ld_cdf(c,_ld_q(a,q*p1))-1+p0)
    return((low,high))
}
real matrix _ld_details(real matrix X, real rowvector signs)
{
    real scalar j, g, Jn
    real matrix D, Z
    Jn=cols(signs); D=J(Jn*2,5,.)
    for (j=1;j<=Jn;j++) for (g=0;g<=1;g++) {
        Z=select(X,X[,1]:==g)
        D[2*j-1+g,]=(j,g,mean(Z[,3+j]),mean(Z[,3+Jn+j]),.)
    }
    for (j=1;j<=Jn;j++) {
        D[2*j-1,5]=D[2*j-1,3]*D[2*j,4]/D[2*j,3]
        D[2*j,5]=D[2*j,3]*D[2*j-1,4]/D[2*j-1,3]
    }
    return(D)
}
real rowvector _ld_fit(real matrix X, real rowvector signs, real rowvector probs)
{
    real scalar Jn, g, j, n, q, p0, p1, clipped, cccic, ccdid, keep, raw
    real matrix D, Z, Qb
    real colvector ok, sel, a,b,c,d,dt,dc,knots,u
    real rowvector pi, nn, out, integ
    Jn=cols(signs); n=cols(probs)
    out=J(1,11+2*n,.)
    if (sum(X[,1]:==0)==0 | sum(X[,1]:==1)==0) return(out)
    D=_ld_details(X,signs)
    if (min(D[,3])<=0 | hasmissing(D)) return(out)
    pi=J(1,2,.); nn=pi; clipped=0
    sel=J(rows(X),1,1)
    for (j=1;j<=Jn;j++) sel=sel:*X[,3+Jn+j]
    for (g=0;g<=1;g++) {
        keep=1
        for (j=1;j<=Jn;j++) {
            if ((g==0 & signs[j]==1) | (g==1 & signs[j]==-1)) raw=D[2*j-1+g,4]
            else raw=D[2*j-1+g,5]
            keep=keep-(1-raw)
        }
        raw=mean(select(sel,X[,1]:==g))
        if (raw<=0) return(out)
        pi[g+1]=keep/raw
        if (pi[g+1]<=0 | missing(pi[g+1])) return(out)
        if (pi[g+1]>1+1e-12) clipped=clipped+1
        pi[g+1]=min((1,pi[g+1]))
    }
    p0=pi[1];p1=pi[2]
    Z=select(X,(X[,1]:==1):&(sel:==1))
    if (rows(Z)==0 | hasmissing(Z[,2..3])) return(out)
    a=sort(Z[,2],1); b=sort(Z[,3],1);dt=sort(Z[,3]-Z[,2],1)
    Z=select(X,(X[,1]:==0):&(sel:==1))
    if (rows(Z)==0 | hasmissing(Z[,2..3])) return(out)
    c=sort(Z[,2],1);d=sort(Z[,3],1);dc=sort(Z[,3]-Z[,2],1)
    nn=(rows(c),rows(a))
    ccdid=mean(dt)-mean(dc)
    u=J(rows(a),1,.)
    for (j=1;j<=rows(a);j++) u[j]=_ld_q(d,_ld_cdf(c,a[j]))
    cccic=mean(b)-mean(u)
    // Every bound is constant between consecutive treated quantile breakpoints.
    u=(0::rows(a)):/rows(a)
    knots=uniqrows(sort((0\1\u:/p1\(u:-(1-p1)):/p1),1))
    knots=select(knots,(knots:>=0):&(knots:<=1))
    integ=(0,0)
    for (j=2;j<=rows(knots);j++) {
        q=(knots[j]+knots[j-1])/2
        integ=integ+(knots[j]-knots[j-1])*_ld_qbounds(a,b,c,d,p0,p1,q)
    }
    Qb=J(n,2,.)
    for (j=1;j<=n;j++) Qb[j,]=_ld_qbounds(a,b,c,d,p0,p1,probs[j])
    return((pi,nn,clipped,ccdid,cccic,
        _ld_trim(dt,p1,0)-_ld_trim(dc,p0,1),
        _ld_trim(dt,p1,1)-_ld_trim(dc,p0,0),integ,Qb[,1]',Qb[,2]'))
}

real scalar _ld_critical(real scalar width, real scalar se, real scalar coverage)
{
    real scalar lo, hi, mid, j
    if (se==0) return(0)
    lo=0;hi=invnormal((1+coverage)/2)
    for(j=1;j<=80;j++) {
        mid=(lo+hi)/2
        if (normal(mid+max((0,width))/se)-normal(-mid)<coverage) lo=mid
        else hi=mid
    }
    return((lo+hi)/2)
}
void _ld_run(string scalar vars, string scalar directions, string scalar probabilities,
    string scalar outname, string scalar qname, string scalar metaname,
    string scalar bname, string scalar detailname, string scalar clustername,
    real scalar reps, real scalar coverage, string scalar vname,
    string scalar bootname, string scalar bootqname)
{
    real matrix L,X,B,Q,boot,V,P,Z,C
    real rowvector signs, probs, fit, f, se
    real colvector cl, ord, draw, idx
    real scalar n,j,k,m,h,failed,projected,crit,outside
    L=st_data(.,tokens(vars));n=rows(L)/2
    X=(L[(1::n):*2:-1,1],L[(1::n):*2:-1,2],L[(1::n):*2,2],
       L[(1::n):*2:-1,3..cols(L)],L[(1::n):*2,3..cols(L)])
    cl=st_data(.,clustername); cl=cl[(1::n):*2:-1]
    signs=strtoreal(tokens(directions));probs=strtoreal(tokens(probabilities))
    fit=_ld_fit(X,signs,probs)
    if (hasmissing(fit)) {
        errprintf("AO shares are undefined or nonpositive; check selection rates and assumptions.\n")
        _error(498)
    }
    B=J(2,7,.)
    B[1,1..3]=fit[(6,8,9)]; B[2,1..3]=fit[(7,10,11)]
    Q=(probs',fit[(12..(11+cols(probs)))]',fit[((12+cols(probs))..cols(fit))]',J(cols(probs),4,.))
    ord=order(cl,1);C=(cl[ord],X[ord,]);P=panelsetup(C,1);m=rows(P)
    failed=0;projected=0
    if (reps>0) {
        boot=J(reps,cols(fit),.)
        for(j=1;j<=reps;j++) {
            if (m==n) Z=X[runiformint(n,1,1,n),]
            else {
                draw=runiformint(m,1,1,m);Z=J(0,cols(X),.)
                for(k=1;k<=m;k++) Z=Z\C[P[draw[k],1]::P[draw[k],2],2..cols(C)]
            }
            f=_ld_fit(Z,signs,probs);boot[j,]=f
            if (hasmissing(f)) failed=failed+1
            else projected=projected+(f[5]>0)
        }
        st_matrix(bootname,boot[,8..11]);st_matrix(bootqname,boot[,12..cols(fit)])
        if (failed==0) {
            V=variance(boot);se=sqrt(diagonal(V))'
            st_matrix(vname,V[8..11,8..11])
            for(j=1;j<=2;j++) {
                k=6+2*j
                B[j,4..5]=se[k..(k+1)]
                crit=_ld_critical(B[j,3]-B[j,2],max(B[j,4..5]),coverage)
                B[j,6..7]=(B[j,2]-crit*B[j,4],B[j,3]+crit*B[j,5])
            }
            for(j=1;j<=rows(Q);j++) {
                Q[j,4..5]=(se[11+j],se[11+cols(probs)+j])
                crit=_ld_critical(Q[j,3]-Q[j,2],max(Q[j,4..5]),coverage)
                Q[j,6..7]=(Q[j,2]-crit*Q[j,4],Q[j,3]+crit*Q[j,5])
            }
        }
    }
    st_matrix(outname,B);st_matrix(qname,Q)
    st_matrix(metaname,(fit[1..5],m,reps-failed,failed,projected));st_matrix(bname,fit[8..11])
    st_matrix(detailname,_ld_details(X,signs))
}
end
