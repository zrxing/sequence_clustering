normalize=function(x){
  #if(sum(abs(x))!=0){
    return(x/sum(x))
  #}else{
  #  return(rep(0,length(x)))
  #}
}

smooth.lambda = function(lambda){
  return(t(apply(lambda,1,ashsmooth.pois,cxx = FALSE)))
}

###mixed membership
EMupd.mix=function(y,smooth,pi,phi,n,K,B){
  #gamma is nB*K, pi is n*K, phi is K*B, y is n*B
  gamma=pi[rep(1:n,each=B),]*t(phi)[rep(1:B,n),]
  gamma=t(apply(gamma,1,normalize))
  gamma[is.na(gamma)]=1/K
  gammab=(as.vector(t(y))%o%rep(1,K))*gamma
  pi.num=(diag(1,n)[,rep(1:n,each=B)])%*%gammab
  pi=pi.num/(rowSums(y)%o%rep(1,K))
  ybt=(diag(1,B)[,rep(1:B,n)])%*%gammab
  #ybw=(diag(1,B)[,rep(1:B,n)])%*%gamma
  phi=t(ybt/(rep(1,B)%o%colSums(gammab)))
  #phi[phi==0]=pseudocounts
  #phi=t(apply(phi,1,normalize))
  #ykb=ybt/ybw
  #ykb[is.na(ykb)]=0
  #ykt=colSums(ykb)
  lscale=((colSums(ybt)/colSums(pi))%o%rep(1,B))
  lambda=phi*lscale
  #save(lambda,file="D:/Grad School/projects/sequence_clustering/results/analysis_k562ctcf/debug_lambda.Robj")
  phi.unsmoothed=NULL
  if(smooth==TRUE){
    phi.unsmoothed=phi
    lambda=smooth.lambda(lambda)
    phi=lambda/lscale
  }

  return(list(pi=pi,phi=phi,phi.unsmoothed=phi.unsmoothed,lambda=lambda,gamma=gamma))
}


negloglik.mix=function(y,pi,phi,n,K,B){
  loglik.ini=log(pi%*%phi)
  yloglik=y*loglik.ini
  yloglik[is.na(yloglik)]=0
  loglik.tot=-sum(yloglik)
  return(loglik.tot)
}



EMproc.mix=function(y,smooth,pi,phi,n,K,B,tol,maxit){
  loglik.old=Inf
  loglik=negloglik.mix(y,pi,phi,n,K,B)
  cyc=0
  while(abs(loglik-loglik.old)>tol&cyc<maxit){
    loglik.old=loglik
    res=EMupd.mix(y,smooth,pi,phi,n,K,B)
    pi=res$pi
    phi=res$phi
    phi.unsmoothed=res$phi.unsmoothed
    gamma=res$gamma
    lambda=res$lambda
    if(smooth==TRUE){
      loglik=negloglik.mix(y,pi,phi.unsmoothed,n,K,B)
    }else{
      loglik=negloglik.mix(y,pi,phi,n,K,B)    
    }
    cyc=cyc+1
#print(cyc)
#print(pi)
print(loglik)
  }
  return(list(pi=pi,phi=phi,phi.unsmoothed,lambda=lambda,gamma=gamma,loglik=loglik))
}

cluster.mix=function(y,smooth=TRUE,pi0=NULL,phi0=NULL,K,tol,maxit){
  n=dim(y)[1]
  B=dim(y)[2]
  #if(is.null(pseudocounts)) pseudocounts=10^(round(log10(1/B/100000)))
  
  if(is.null(pi0)|is.null(phi0)){
    kmeans.init=kmeans(y,K,nstart=5)
  }

  if(is.null(pi0)) pi0=rep(1,n)%o%normalize(as.vector(table(kmeans.init$cluster)))

  if(is.null(phi0)){
    phi0=t(apply(kmeans.init$centers,1,normalize))
    #phi0[phi0==0]=pseudocounts
    #phi0=t(apply(phi0,1,normalize))
    row.names(phi0)=NULL
  }

  out=EMproc.mix(y,smooth,pi0,phi0,n,K,B,tol,maxit)
  return(list(pi=out$pi,phi=out$phi,lambda=out$lambda,lambda=out$lambda,gamma=out$gamma,loglik=out$loglik))
}
