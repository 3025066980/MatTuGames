function [saq subgC]=super_additiveQ(clv)
% SUPER_ADDITIVEQ returns 1 whenever the game v is super additive. 
% For n>14 this function needs some time to complete.
%
% Usage: [saq subgC]=super_additiveQ(clv)
%
% Define variables:
%  output:
%  saq      -- Returns 1 (true) or 0 (false).
%  subgC    -- Returns the list of sub-games which are super additive (1) 
%              or not (0).
%              This vector has length 2^n-1.
%
%  input:
%  clv        -- TuGame class object.
%

%  Author:        Holger I. Meinhardt (hme)
%  E-Mail:        Holger.Meinhardt@wiwi.uni-karlsruhe.de
%  Institution:   University of Karlsruhe (KIT)  
%
%  Record of revisions:
%   Date              Version         Programmer
%   ====================================================
%   10/29/2012        0.3             hme
%                

v=clv.tuvalues;
N=clv.tusize;
n=clv.tuplayers;

sS=cell(1,N);
subgC=cell(1,N);
sdv=cell(1,N);
lvq=cell(1,N);
saq1=false(1,N);

for k=1:N-1;
 sS{k}=subsets(k,n);
 subgC{k}=v(sS{k});
 sdv{k}=subdual(v,subgC{k},sS{k});
 lvq{k}=subgC{k}<=sdv{k};
 saq1(k)=all(lvq{k});
end

sdv{N}=dual_game(clv);
lvq{N}=v<=sdv{N};
saq1(N)=all(lvq{N});
saq=all(saq1);

%--------------------------------------
function [sS]=subsets(S,n)

it=0:-1:1-n;
vecS=rem(floor(S(:)*pow2(it)),2)==1;

J=1:n;
slcP=vecS==0;
sP=J(slcP);

S1=1:S; 

if (2^n-1)==S
  sS=S1;
else 
 lsP=length(sP);
 Tni=cell(lsP);
 for k=1:lsP
  Tni{k}=bitget(S1,sP(k))==0;
 end

 cls=size(Tni);
 ls1=length(S1);
 R=true(1,ls1);
 for k=1:cls(:,2)
  R=Tni{k} & R;
 end
 sS=S1(R);
end

%----------------------------------
function sdv=subdual(v,sv,sS)

bd=length(sS);
if bd>2
k=1:bd-1;
 CN=sS(bd)-sS(k);
 cv=v(CN);
 cv(bd)=0;
 sdv=(sv(bd)-cv);
 else
   cv=0;
   sdv=sv-cv;
end
