function [RGP RGPC]=ISRG_propertyQ(v,x,str,tol)
% ISRG_PROPERTYQ checks whether an imputation x satisfies the
% imputation saving reduced game property (consistency).
%
% Usage: [RGP RGPC]=ISRG_propertyQ(v,x,str,tol)
% Define variables:
%  output: Fields
%  rgpQ     -- Returns 1 (true) whenever the ISRGP is satisfied, 
%              otherwise 0 (false).
%  rgpq     -- Gives a precise list of imutation saving reduced games for which the 
%              restriction of x on S is a solution of the imputation saving reduced game vS. 
%              It returns a list of zeros and ones.
%  vS       -- All Davis-Maschler or Hart-MasColell imputation saving reduced games on S at x.
%  impVec   -- Returns a vector of restrictions of x on all S.
%  input:
%  v        -- A Tu-Game v of length 2^n-1. 
%  x        -- payoff vector of size(1,n). Must be efficient.
%  str      -- A string that defines different Methods. 
%              Permissible methods are: 
%              'PRN' that is, the Davis-Maschler imputation saving reduced game 
%               in accordance with the nucleolus.
%              'PRK' that is, the Davis-Maschler imputation saving reduced game 
%               in accordance with pre-kernel solution.
%              'SHAP' that is, Hart-MasColell imputation saving reduced game 
%               in accordance with the Shapley Value.
%              'HMS_PK' that is, Hart-MasColell imputation saving reduced game 
%               in accordance with the pre-kernel solution.
%              'HMS_PN' that is, Hart-MasColell imputation saving reduced game 
%               in accordance with the nucleous.
%              Default is 'PRK'.
%  tol      -- Tolerance value. By default, it is set to 10^6*eps.
%              (optional) 
%              

%  Author:        Holger I. Meinhardt (hme)
%  E-Mail:        Holger.Meinhardt@wiwi.uni-karlsruhe.de
%  Institution:   University of Karlsruhe (KIT)  
%
%  Record of revisions:
%   Date              Version         Programmer
%   ====================================================
%   10/14/2015        0.7             hme
%                



if nargin<2
  x=PreKernel(v);
  n=length(x);
  tol=10^6*eps;
  str='PRK';
elseif nargin<3
  n=length(x);
  tol=10^6*eps;
  str='PRK';
elseif nargin<4
  n=length(x);
  tol=10^6*eps;
else
  n=length(x);
end

N=length(v);
S=1:N;
rgpq=false(1,N);
it=0:-1:1-n;
PlyMat=rem(floor(S(:)*pow2(it)),2)==1;
impVec=cell(1,N);
rgpq_sol=cell(1,N);
sol=cell(1,N);

%vS=cell(2,N);
if strcmp(str,'SHAP')
  vS=HMS_ImputSavingReducedGame(v,x,'SHAP');
elseif strcmp(str,'HMS_PK')
  vS=HMS_ImputSavingReducedGame(v,x,'PRK');
elseif strcmp(str,'HMS_PN')
  vS=HMS_ImputSavingReducedGame(v,x,'PRN');
else
  vS=ImputSavingReducedGame(v,x);
end


for k=1:N-1
 impVec{1,k}=x(PlyMat(k,:)); 
  if strcmp(str,'SHAP')
% Checks whether a solution x restricted to S is a solution of the 
% reduced game vS.
   sol{1,k}=ShapleyValue(vS{1,k});
   rgpq_sol{1,k}=abs(sol{1,k}-impVec{1,k})<tol;
   rgpq(k)=all(rgpq_sol{1,k});
  elseif strcmp(str,'PRK')
% Checks whether a solution x restricted to S is a solution of the 
% reduced game vS. To speed up computation, we use this code below for both, 
% the pre-nucleolus and and the pre-kernel. 
   rgpq(k)=PrekernelQ(vS{1,k},impVec{1,k});
  elseif strcmp(str,'PRN')
   if length(vS{1,k})==1
     rgpq(k)=PrekernelQ(vS{1,k},impVec{1,k});
   else
     try
       sol{1,k}=cplex_nucl2(vS{1,k},impVec{1,k}); % using cplex.
     catch
       sol{1,k}=nucl2(vS{1,k},impVec{1,k}); % use a third party solver instead!
     end
     rgpq_sol{1,k}=abs(sol{1,k}-impVec{1,k})<tol;
     rgpq(k)=all(rgpq_sol{1,k});
   end
  elseif strcmp(str,'HMS_PK')
   rgpq(k)=PrekernelQ(vS{1,k},impVec{1,k});
  elseif strcmp(str,'HMS_PN')
   if length(vS{1,k})==1
     rgpq(k)=PrekernelQ(vS{1,k},impVec{1,k});
   else
     try
       sol{1,k}=cplex_nucl2(vS{1,k},impVec{1,k});
     catch
       sol{1,k}=nucl2(vS{1,k},impVec{1,k}); % use a third party solver instead!
     end
     rgpq_sol{1,k}=abs(sol{1,k}-impVec{1,k})<tol;
     rgpq(k)=all(rgpq_sol{1,k});
   end   
  end
end

if strcmp(str,'SHAP')
   sol{N}=ShapleyValue(v);
   rgpq_sol{N}=abs(sol{N}-x)<tol;
   rgpq(N)=all(rgpq_sol{N});
elseif strcmp(str,'PRK')
  rgpq(N)=PrekernelQ(v,x);
elseif strcmp(str,'PRN')
   try
     sol{N}=cplex_nucl2(v,x);
   catch
     sol{N}=nucl2(v,x); % use a third party solver instead!
   end
   rgpq_sol{N}=abs(sol{N}-x)<tol;
   rgpq(N)=all(rgpq_sol{N});
elseif strcmp(str,'HMS_PK')
  rgpq(N)=PrekernelQ(v,x);
elseif strcmp(str,'HMS_PN')
   try
     sol{N}=cplex_nucl2(v,x);
   catch
     sol{N}=nucl2(v,x); % use a third party solver instead!
   end
   rgpq_sol{N}=abs(sol{N}-x)<tol;
   rgpq(N)=all(rgpq_sol{N});
end
rgpQ=all(rgpq);
%Formatting Output
if nargout>1
 RGP=struct('rgpQ',rgpQ,'rgpq',rgpq);
 RGPC={'vS',vS,'impVec',impVec};
else
  RGP=struct('rgpQ',rgpQ,'rgpq',rgpq);
end
