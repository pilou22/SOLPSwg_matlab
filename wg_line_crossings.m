function [run,crossings] = wg_line_crossings(run,endpoints)
key = sprintf('cross_%.16g_%.16g_%.16g_%.16g',endpoints);
key = regexprep(key,'[^a-zA-Z0-9_]','_');
if isfield(run.cache,key)
    crossings = run.cache.(key);
    return
end
A = endpoints(1:2);
d = endpoints(3:4)-A;
L = hypot(d(1),d(2));
if L == 0
    error('WG:Line','Line endpoints must be distinct.');
end
g = run.gmtry;
iv = g.fcVx;
B = [g.vxX(iv(:,1)),g.vxY(iv(:,1))];
e = [g.vxX(iv(:,2))-B(:,1),g.vxY(iv(:,2))-B(:,2)];
denom = d(1)*e(:,2)-d(2)*e(:,1);
w = B-A;
scale = max([1;abs(A(:));abs(d(:));abs(B(:));abs(e(:))]);
t = nan(run.nFaces,1);
u = nan(run.nFaces,1);
valid = abs(denom) > eps(scale)*max(1,norm(d));
t(valid) = (w(valid,1).*e(valid,2)-w(valid,2).*e(valid,1))./denom(valid);
u(valid) = (w(valid,1)*d(2)-w(valid,2)*d(1))./denom(valid);
tol = 1e-10;
valid = valid & t >= -tol & t <= 1+tol & u >= -tol & u <= 1+tol;
ids = find(valid);
t = min(1,max(0,t(ids)));
s = t*L;
order = sortrows([s,ids],[1,2]);
s = order(:,1);
ids = order(:,2);
t = s/L;
crossings.faceIndex = ids;
crossings.t = t;
crossings.s = s;
crossings.R = A(1)+t*d(1);
crossings.Z = A(2)+t*d(2);
crossings.L = L;
if ~isempty(s)
    keep = [true;diff(s) > tol*L];
    crossings.uniqueS = s(keep);
else
    crossings.uniqueS = [];
end
run.cache.(key) = crossings;
end
