function v=gameToMatlab(clv)
% GAMETOMATLAB converts a TU-game w that is based on 
% a generic power set representation (like Mathematica) into
% the Matlab game convention v that is based on a unique
% integer representation. 
%
%  Usage: v=gameToMatlab(clw)
%  Example: 
%   Let be the order of coalitions given by
%   S=[1 2 3 4 12 13  14 23 24 34 123 124 134 234 1234]. 
%   A TU-game w represented by the following worth of coalitions
%   w=[0 0 0 0 1  1/2 1  1  0  1  5/4  1   1   1   2 ]  
%   will be converted to
%   v=[0 0 1  0  1/2  1  5/4  0  1   0   1   1   1   1   2]
%   based on the following binary order (full form)
%   S=[1 2 12 3  13   23 123  4  14  24 124  34 134 234 1234].
%   The same set of coalitions stated in terms of their unique 
%   integer representation is given by
%   S=[1 2  3 4   5    6  7   8   9  10  11  12  13  14   15].
% 
% Define variables:
%  output:
%  v        -- Tu-Game that reflects the Matlab convention of coalition order.
%
%  input:
%  clw      -- TuGame class object ('mama').
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

w=clv.tuvalues;
N=clv.tusize;
n=clv.tuplayers;
S=1:N;
mg=sortsets(S,n);
[~, ix]=sort(mg);
v=w(ix);
