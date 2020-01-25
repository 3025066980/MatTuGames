function [v_sp, mat_hd, MatW, MatV, A, mat_vz]=game_space(v,x,slc,smc)
% GAME_SPACE computes the game space which replicates x as a pre-kernel element.
%
%
% Usage: [v_sp mat_hd MatW MatV A mat_vz]=game_space(v,x,slc,smc)
% Define variables:
% output:
%  v_spc             -- Game space spanned by the basis of the null space
%                       MatW.
%  mat_hd            -- basis of the null space MatW.
%  MatW              -- Matrix given by equation 2 on page 48 Meinhardt
%                       2010.
%  MatV              -- Matrix obtained by the unity games that
%                       constitutes balancedness of the maximal surpluses.
%  cA                -- Indicates the set of equivalence class/most
%                       effective coalitions w.r.t. the pre-kernel
%                       element x.
%
%
%  input:
%  v      -- A Tu-Game v of length 2^n-1. 
%  x      -- pre-kernel payoff of length(1,n)
%  scl    -- scaling factor
%  smc    -- selecting from effc the smallest/largest 
%            cardinality (optional). Value 1 or 0.

%  Author:        Holger I. Meinhardt (hme)
%  E-Mail:        Holger.Meinhardt@wiwi.uni-karlsruhe.de
%  Institution:   University of Karlsruhe (KIT)  
%
%  Record of revisions:
%   Date              Version         Programmer
%   ====================================================
%   02/02/2011        0.1 beta        hme
%                



N=length(v); n=length(x);
S=1:N;
onm=ones(n);
drij=zeros(1,n);
drji=zeros(1,n);
upe=logical(tril(onm,-1));
[~, A,~]=BestCoalitions(v,x,smc);
trA=A';
drij=trA(upe)';
drji=A(upe)';
uG=eye(N); % unity games

MatV=uG(:,drji)-uG(:,drij);
MatV(:,end+1)=uG(:,N);
MatV=sparse(MatV);
alpvec=MatV'*v';
[uc, gb]=unanimity_games(v);
MatW=MatV'*gb;
MatW=full(MatW);
nlW=null(MatW);
sW=size(nlW);
hd=uc';
HDm=repmat(hd,1,sW(2));
mat_hz=slc*nlW;
mat_vz=gb*mat_hz;
mat_vz=mat_vz';
mat_hd=HDm+mat_hz;
w_sp=gb*mat_hd;
v_sp=w_sp';


