function [x, Lerr, smat, xarr]=ipopt_kernel(v,x)
% IPOPT_KERNEL computes from (v,x) a kernel element 
% using least squares method (ipoptmex 3.11.8).
% Source: Meinhardt, 2010.
%
% https://projects.coin-or.org/Ipopt
%
% Source:  A. Wächter and L. T. Biegler, On the Implementation of a Primal-Dual 
%          Interior Point Filter Line Search Algorithm for Large-Scale Nonlinear Programming, 
%          Mathematical Programming 106(1), pp. 25-57, 2006.
%
%
%
% Usage: [x Lerr smat xarr]=ipopt_kernel(v,x)
%
% Define variables:
%  output:
%  x        -- Pre-Kernel element (output)
%  Lerr     -- List of computed function values of hx and h. 
%  smat     -- Matrix of maximum surpluses.
%  xarr     -- History of computed solution at each iteration step.
%
%  input:
%  v        -- A Tu-Game v of length 2^n-1. 
%  x        -- payoff vector of size(1,n) (optional)


%  Author:        Holger I. Meinhardt (hme)
%  E-Mail:        Holger.Meinhardt@wiwi.uni-karlsruhe.de
%  Institution:   University of Karlsruhe (KIT)  
%
%  Record of revisions:
%   Date              Version         Programmer
%   ====================================================
%   12/28/2012        0.3             hme
%   04/04/2016        0.8             hme
%                

if nargin<1
    error('At least the game must be given!');
elseif nargin<2
    N=length(v);
    [~, n]=log2(N);
    if (2^n-1)~=N
      error('Game has not the correct size!');
    end
    k=1:n;
    vi=v(bitset(0,k));
    slb=sum(vi)>v(N);
    if slb==1
      error('Game is not essential!')
    end
    if N==1,
      Si=N;
     else
      Si=bitset(N,k,0);
    end
    mv=max(v);
    mnQ=mv>v(N);
    x=(mv-v(Si))/2;
    sx=sum(x);
     if sx>0
        if mnQ==1
           if n < 10
              x(n)=v(N);
           elseif n >= 11 && n <  15
              x=x*mv/sx;
           else
              x=ones(1,n);
           end
        else
           x=x*mv/sx;
        end
      elseif all(abs(x-0)<10^3*eps)==1
       x=(mv-v(bitset(0,k)))/2;
       sx=sum(x);
       mmq=min(x)~=max(x);
       if sx>0 && mmq
          x=select_starting_pt(v);
        else
         x=(v(N)/n)*ones(1,n);
       end
      else
       x=(v(N)/n)*ones(1,n);
     end
    smc=1;
else
    N=length(v);
    [~, n]=log2(N);
    k=1:n;
    vi=v(bitset(0,k));
    slb=sum(vi)>v(N);
    if slb==1
      error('Game is not essential!')
    end
    mv=max(v);
    mnQ=mv>v(N);
    if (2^n-1)~=N
       error('Game has not the correct size!');
    end
    smc=1;
end

[x, Lerr, smat, xarr]=computePrk(v,x,smc,0,mnQ);
smat=tril(smat,-1)+triu(smat,1);


% Main function to compute a
% pre-kernel element.
%-----------------------------
function [x, Lerr, smat, xarr]=computePrk(v,x,smc,slv,mnQ)
% 
%  output:  -- as above.
%
%  input:
%   v       -- as above.
%   x       -- as above.
%  smc      -- selecting from effc the smallest/largest cardinality (optional).
%              Value must be set to 0 (largest),1 (smallest) or 2 (reset).
%  slv      -- selecting a different linear solver (QR/SVD-decomposition). 
%              Value must be set to 0 or 1.

tol=10^8*eps;
n=length(x);
N=2^n-1;
x=x';
cnt=0;
if 15<=n 
 CNT=n+2;
else
 CNT=2*(n+1);
end
Lerr=-inf(CNT,2);
xarr=-inf(CNT,n);
m=1+n*(n-1)/2;
upe=true(n);

ofval=inf;
ra = reasonable_outcome(v)';
k=1:n;
vi=v(bitset(0,k))';
cvr=vi==ra;
if any(cvr)
   fi=find(cvr);
   ra(fi)=Inf;
end


% Cycling may occur, so that we need an artificial halt
while cnt<CNT  
    cnt=cnt+1;
    [A, smat]=effCoalitions(v,x,smc,cnt);
    upe=tril(upe,-1);
    etr12=A';
    ec12=etr12(upe)';
    ec21=A(upe)';
    it=0:-1:1-n;
    e12=rem(floor(ec12(:)*pow2(it)),2);
    e21=rem(floor(ec21(:)*pow2(it)),2);
    E=e21-e12;
    E(m,:)=ones(1,n);
    a=(v(ec21)-v(ec12))';
    a(m)=v(N);
    if n==2, a=a'; end;
    err=norm(E*x-a)^2; if err<eps, break; end
    Q=E'*E;
    b=E'*a;

    ir=(x-vi)';
    irQ=all(ir>-tol);
    if irQ
      smat=tril(smat,-1)+triu(smat,1);
      krm=smat-smat';
      irm=repmat(ir,n,1);
      kriQ=all((krm.*irm)<=tol);
      effQ=abs(v(end)-sum(x))<tol;
      krQ=all(kriQ) && effQ;
    else
      krQ=0;
    end
    if krQ == 1; x=x'; break; end


%
% Calling solver ordinary least squares.
    [s1 s2] = size(E);
  % The starting point.
  x0 = { zeros(s2,1)
         ones(s2,1) };
%  x0 = zeros(s2,1);
  % The constraint functions are bounded from below by zero.
%  options.cl = v(end);
%  options.cu = v(end);
  options.lb = repmat(vi,2,1);
  options.ub = repmat(ra,2,1);


  % Set up the auxiliary data.
  lambda = 0;
  options.auxdata = { s1 s2 E a lambda };

  % Set the IPOPT options.
  options.ipopt.jac_d_constant   = 'yes';
  options.ipopt.hessian_constant = 'yes';
  options.ipopt.mu_strategy      = 'adaptive';
  options.ipopt.max_iter         = 100;
  options.ipopt.tol              = 1e-10;

  % The callback functions.
  funcs.objective         = @objective;
  funcs.constraints       = @constraints;
  funcs.gradient          = @gradient;
  funcs.jacobian          = @jacobian;
  funcs.jacobianstructure = @jacobianstructure;
  funcs.hessian           = @hessian;
  funcs.hessianstructure  = @hessianstructure;
 
    [w info] = ipopt_auxdata(x0,funcs,options);
    x        = w{1};
%    lambda = 0;
%    x = lasso(E,a,lambda);


% Due to a badly conditioned matrix, we might get an overflow/underflow.
% In this case, we restart with a new starting point.
    z1=any(isinf(x));
    z2=any(isnan(x));
    if z1==1 || z2==1 
       x=eye(n,1); 
    else 
    end
    Lerr(cnt,:)=[err, norm(E*x-a)^2]; % checking purpose
    xarr(cnt,:)=x'; % intermediate results
end


if cnt==CNT, % should trigger errors ....
  if slv==0 && smc==1
       msg01='No Kernel Element found. Changing Cardinality.';
       warning('Kr:ChangCard',msg01);
       if mnQ==1 && n < 15;x=4*x;end
       [x, Lerr, smat, xarr]=computePrk(v,x',0,slv,mnQ);
  else
       if irQ
          smat=tril(smat,-1)+triu(smat,1);
          krm=smat-smat';
          irm=repmat(ir,n,1);
          kriQ=all((krm.*irm)<=tol);
          krQ=all(kriQ);
       else
          krQ=0;
       end
       x=x';
       if krQ==0
          msg02='No Kernel Element found. Change payoff vector and restart!';
          warning('Kr:NotFound',msg02);
      end
  end
else
%  warning('ker:NoC','Probably no kernel point found!');
x=x';
end


% ------------------------------------------------------------------
function f = objective (x, auxdata)
  [n m A y lambda] = deal(auxdata{:});
  [w u] = deal(x{:});
  f     = norm(y - A*w)^2/2 + lambda*sum(u);

% ------------------------------------------------------------------
function c = constraints (x, auxdata)
  [w u] = deal(x{:});
  c     = [ w + u; u - w;];
%   c = ones(1,n);
% ------------------------------------------------------------------
function g = gradient (x, auxdata)
  [n m A y lambda] = deal(auxdata{:});
  w = x{1};
  g = { -A'*(y - A*w)
        repmat(lambda,m,1) };

% ------------------------------------------------------------------
function J = jacobianstructure (auxdata)
  m = auxdata{2};
  I = speye(m);
  J = [ I I
        I I ];

% ------------------------------------------------------------------
function J = jacobian (x, auxdata)
  m = auxdata{2};
  I = speye(m);
  J = [  I  I
        -I  I ];

% ------------------------------------------------------------------
function H = hessianstructure (auxdata)
  m = auxdata{2};
  H = [ tril(ones(m))  zeros(m)
          zeros(m)     zeros(m) ];
  H = sparse(H);

% ------------------------------------------------------------------
function H = hessian (x, sigma, lambda, auxdata)
  [n m A y lambda] = deal(auxdata{:});
  H = [ tril(A'*A)  zeros(m)
         zeros(m)   zeros(m) ];
  H = sparse(sigma * H);






%--------------
function [A, smat]=effCoalitions(v,x,smc,cnt)
% Computes the set of most effective coalitions
% of smallest/largest cardinality.
%
% Define variables:
% output:
% A     -- matrix of most effective coalitions of smallest/largest cardinality.
% smat  -- as above.
% cnt   -- loop counter.
%
% input:
% cnt   -- loop counter.
%       -- otherwise, as above.
%
n=length(x);
% The set of effective coalitions might be too
% large or too small due to floating point arithmetic.
% Adjusting the tolerance value might help to find the
% correct choice. In case that the set of most effective
% coalitions is not selected correctly, pathological
% cycles may appear.

if cnt<6
 tol=eps;
elseif cnt > 10
 tol=1500*eps;
else
 tol=100*eps;
end

% Borrowed from J. Derks
Xm=x(1); for ii=2:n, Xm=[Xm x(ii) Xm+x(ii)]; end
% Computing the excess vector w.r.t. x.
e=v-Xm;
clear v Xm;
% Truncate data arrays.
[e, sC]=sort(e,'descend');
B=eye(n);
smat=-inf(n);
q0=n^2-n;
q=0;
k=1;
pl=1:n;
while q~=q0
  kS=sC(k);
  ai=bitget(kS,pl)==1;
  bj=ai==0;
  pli=pl(ai);
  plj=pl(bj);
  if isempty(plj)==0
    for i=1:numel(pli)
      for j=1:numel(plj)
        if B(pli(i),plj(j))==0 
           B(pli(i),plj(j))=k;
           smat(pli(i),plj(j))=e(k); % max surplus of i against j.
           q=q+1;
        end
      end
    end
  end
  k=k+1;
end
m=max(B(:));
e1=e(m)-tol;
le=e>=e1;
tS=sC(le);
lcl=length(tS);
te=e(le);
clear e sC;

% Computing the set of most effective coalitions.
A=eye(n);
a=false(lcl,n);
c=cell(n);
slcCell=cell(n);
binCell=cell(n);
abest=cell(n);

% Constructing the set of coalitions containing player i
% without player j.
for i=1:n
   a(:,i)=bitget(tS,i)==1;
end
b=a==0;

% Selecting the set of most effective coalitions
% having smallest/largest cardinality.
for i=1:n-1
   for j=i+1:n
       lij=a(:,i) & b(:,j);
       lji=a(:,j) & b(:,i);
       c{i,j}=tS(lij);
       c{j,i}=tS(lji);
       ex_ij=te(lij);
       ex_ji=te(lji);
       abest{i,j}=abs(smat(i,j)-ex_ij)<tol;
       abest{j,i}=abs(smat(j,i)-ex_ji)<tol;
       slcCell{i,j}=c{i,j}(abest{i,j});
       slcCell{j,i}=c{j,i}(abest{j,i});
   end
end

% Assigning the set of selected coalitions to 
% matrix A.
for i=1:n-1
  for j=i+1:n
      lCi=length(slcCell{i,j});
      lCj=length(slcCell{j,i});
     if lCi==1
        A(i,j)=slcCell{i,j}; 
     else
         binCell{i,j}=SortSets(slcCell{i,j},n,lCi,smc);
      if smc==1
           A(i,j)=binCell{i,j}(1);  % Selecting smallest cardinality.
      elseif smc==0
           A(i,j)=binCell{i,j}(end); % Selecting largest cardinality.
      else
           A(i,j)=binCell{i,j}(end);   % Selecting largest cardinality.
      end
     end
     if lCj==1
        A(j,i)=slcCell{j,i};
     else
        binCell{j,i}=SortSets(slcCell{j,i},n,lCj,smc);
       if smc==1
           A(j,i)=binCell{j,i}(1);  % Selecting smallest cardinality.
       elseif smc==0
           A(j,i)=binCell{j,i}(end); % Selecting largest cardinality.
       else
           A(j,i)=binCell{j,i}(end);   % Selecting largest cardinality.
       end
     end
  end
end


%-------------------------------
function Seff=SortSets(effij,n,bd,smc)
% Sorting the set of most effective
% coalitions with respect to their
% cardinality. Ascent ordering.
% Smallest coalitions are coming first.
  Pm=zeros(bd,n);
  for k=1:n, Pm(:,k) = bitget(effij,k);end
  ov=ones(n,1);
  clsize=Pm*ov;
  if smc==1
     mcl=min(clsize);
  else
     mcl=max(clsize);
  end
  eqm=find(clsize==mcl);
  lc=length(eqm);
  if lc~=bd
     effij=effij(eqm);
     Pm=Pm(eqm,:);
     clsize=clsize(eqm);
  end
  pwcl=clsize.^3;
  J=1:n;
  J=J(ones(lc,1),:);
  M=Pm.*J;
  M=M.^(1/2);
  clix=M*ov;
  clnb=clix.*pwcl;
  [~, ix]=sort(clnb);
  Seff=effij(ix);
