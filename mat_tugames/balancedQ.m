function [bcQ, cmat, rk, cf]=balancedQ(cS,n,tol)
% BALANCEDQ verifies whether the collection of coalitions is balanced. 
% Requires Matlab's Optimization toolbox (default), otherwise CPLEX.
% Uses now Dual-Simplex (Matlab R2015a).
%
% Usage: [bcQ, cmat, rk]=balancedQ(cS,n,tol)
%
% 1. Example:
% Choose a collection of coalitions:
%
% cB={[2],[1 3],[1 4],[2 3 4]}
% uB=clToMatlab(cB)                   
% 
%  uB =
%
%     2     5     9    14
%
% [bcQ, ~, ~,cf]=balancedQ(uB,4)
%
% bcQ =
%
%     1
%
% cf =
%
%    0.5000
%    0.5000
%    0.5000
%    0.5000
%
%
% 2. Example:
% A collection of sets given by their unique integer representation:
%
% cS=[1   254   253     2    16   239   252     3   127   191   223   247   251     4];
% n=8;
% bSQ=balancedQ(cS,n) 
% 
% bSQ =
%
%     1
% 
% Define variables:
%  output:
%  bcQ      -- Returns 1 (true) or 0 (false).
%  cmat     -- Incidence matrix of players. 
%  rk       -- Rank of matrix cmat.
%  cf       -- Balanced weights.
%
%
%  input:
%  cS        -- Collection of coalitions.
%  n         -- Number of players involved.
%  tol       -- Tolerance value. Its default value is set to 10^4*eps.
%

%  Author:        Holger I. Meinhardt (hme)
%  E-Mail:        Holger.Meinhardt@wiwi.uni-karlsruhe.de
%  Institution:   University of Karlsruhe (KIT)  
%
%  Record of revisions:
%   Date              Version         Programmer
%   ====================================================
%   01/02/2015        0.6             hme
%   03/28/2015        0.7             hme
%   02/24/2018        0.9             hme
%                

    
if nargin < 2 
   tol=10^4*eps;
elseif nargin < 3
   tol=10^4*eps;
end

bcQ=false;

N=2^n-1;

zv=zeros(n,1);

warning('off','all');
if nargout < 4
  [cmat,xS,ef]=CheckBal(n,cS,tol);
elseif nargout == 4
% Trying to find positive weights.
  [cmat,xS,ef,cf]=CheckBal(n,cS,tol); 
else
  [cmat,xS,ef]=CheckBal(n,cS,tol);
end
warning('on','all');
if ef~=1
   %bcQ=false;
else
   bcQ=all(abs(zv-xS)<tol);
end
rk=rank(cmat);

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cmat,sol,ef,cf]=CheckBal(n,iS,tol)
% CHECKBAL checks balancedness of the collection iS.
%
%
% Define variables:
%  output:
%  cmat      -- Incidence matrix of players.
%  sol       -- Solution vector (zeros). 
%  ef        -- Exitflag of the linear problem.
%  cf        -- Balanced weights.
%
%  input:
%  n         -- Number of players involved.
%  iS        -- Collection of coalitions.
%  tol       -- Tolerance value. Its default value is set to 10^4*eps.
%

int=0:-1:1-n;
ov=ones(n,1);
N=2^n-1;
liS=length(iS);
cmat=(rem(floor(iS(:)*pow2(int)),2)==1)';
cmat=double(cmat);
[c1,c2]=size(cmat);
A=-cmat';
ovn=ones(c2,1);
b=zeros(c2,1);
zf=A'*ovn;
f=zf';
Aeq=ov';
beq=0;
mtv=verLessThan('matlab','9.1.0');
    try
      if mtv==1
         options = cplexoptimset('MaxIter',128,'Dual-Simplex','on','Display','off');
      else
         options = cplexoptimset('MaxIter',128,'Algorithm','primal','Display','off');
      end
      options.barrier.convergetol=1e-12;
      options.simplex.tolerances.feasibility=1e-9;
      options.simplex.tolerances.optimality=1e-9;
      options.emphasis.numerical=1;
      options.barrier.display=0;
      options.feasopt.tolerance=1e-12;
      options.Param.lpmethod=2;
      [sol,fval,ef,~,lambda] = cplexlp(f,A,b,Aeq,beq,[],[],[],options);
    catch
      opts.Display='off';
      opts.Simplex='on';
      opts.LargeScale='on';
      opts.Algorithm='dual-simplex';
      opts.TolFun=1e-10;
      opts.TolX=1e-10;
      opts.TolRLPFun=1e-10;
      %% for dual-simplex
      opts.MaxTime=9000;
      opts.Preprocess='none';
      opts.TolCon=1e-6;
      opts.MaxIter=10*(N+n);
      [sol,fval,ef] = linprog(f,A,b,Aeq,beq,[],[],[],opts);
    end
%
% Trying to find positive weights.
%
tol1=1000*tol;
if nargout == 4
  if ef==1
     B=[cmat,ov];
     [sb1,sb2]=size(B);
     dlb=zeros(sb2,1); %+tol1
%     dlb(sb2)=tol1;
     dub=ones(sb2,1);
     db=ones(n,1);
     dzf=[-ovn;beq];

     try
        %options = cplexoptimset('MaxIter',128,'Simplex','off','Display','off');
        %options.Param.lpmethod=3;
%        [cf,dfval,def] = cplexlp(dzf,B,db,[],[],dlb,dub,[],options);
        [cf,dfval,def] = cplexlp(dzf,[],[],B,db,dlb,dub,[],options);
     catch
        [cf,dfval,def] = linprog(dzf,[],[],B,db,dlb,dub,[],opts);
     end
     cf(end)=[];
     zQ=any(cf<tol*100);
     if zQ==1
       nv=null(cmat);
       if isempty(nv);
          cf=cmat\ov;
       else
          nv2=size(nv,2);
          if nv2==1 
             cf=pinv(cmat)*ov;
%             cf=cf+nv
          else
            cf1=nv*ones(nv2,1)/nv2;
            ncf1=pinv(cmat)*ov;
            cf=cf1+ncf1;
          end
       end
     end
  else
    cf=[];
  end
end
