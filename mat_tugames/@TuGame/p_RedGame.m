function [vS T]=p_RedGame(clv,x,S)
% P_REDGAME computes from (v,x,S) a Davis-Maschler reduced game vS on S at x for
% game v.
%
% Usage: [vS T]=p_RedGame(clv,x,S)
%
% Define variables:
%  output:
%  vS      -- The Davis-Maschler reduced game vS w.r.t. x.
%  T       -- The corresponding sub-coalitions of S which define 
%             the reduced game vS.
%  input:
%  clv      -- TuGame class object.
%  x        -- payoff vector of size(1,n).
%  S        -- A coalition/set identified by its unique integer representation.
%


%  Author:        Holger I. Meinhardt (hme)
%  E-Mail:        Holger.Meinhardt@wiwi.uni-karlsruhe.de
%  Institution:   University of Karlsruhe (KIT)  
%
%  Record of revisions:
%   Date              Version         Programmer
%   ====================================================
%   10/30/2012        0.3              hme
%                

v=clv.tuvalues;
n=clv.tuplayers;
J=1:n;
plS=bitget(S,J);
lmcS=plS==0;
plcS=J(lmcS);
cSpot=2.^(plcS-1);
cS=cSpot*ones(length(plcS),1);
T=SubSets(S,n);
lgt=length(T);
vS=zeros(1,lgt);
Q=SubSets(cS,n);

if isempty(Q)
  vS(T)=v(T);
else
 it=0:-1:1-n;
 plmQ=rem(floor(Q(:)*pow2(it)),2);
 PayQ=plmQ*x';
 parfor k=1:lgt-1;
   TorQk=bitor(T(k),Q);
   vS(k)=max(v(TorQk)-PayQ');
   vS(k)=max(v(T(k)),vS(k)); % Considering the empty set of Q.
 end
 vS(end)=x*plS';
end

