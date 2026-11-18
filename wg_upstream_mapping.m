function mapping = wg_upstream_mapping(run,p)
g = run.gmtry;
if ~isempty(p.upstreamPsiSep) && (~isscalar(p.upstreamPsiSep) || ~isfinite(p.upstreamPsiSep))
    error('WG:UpstreamPsi','upstreamPsiSep must be empty or a finite scalar.');
end
if ~isempty(p.upstreamRsep) && (~isscalar(p.upstreamRsep) || ~isfinite(p.upstreamRsep))
    error('WG:UpstreamPsi','upstreamRsep must be empty or a finite scalar.');
end
if isempty(p.upstreamReferenceLine)
    pad = 0.02*(max(g.vxX)-min(g.vxX));
    line = [min(g.vxX)-pad,0,max(g.vxX)+pad,0];
else
    line = p.upstreamReferenceLine;
end
if numel(line) ~= 4 || hypot(line(3)-line(1),line(4)-line(2)) == 0
    error('WG:UpstreamLine','upstreamReferenceLine must contain distinct [R1,Z1,R2,Z2] endpoints.');
end
t = linspace(0,1,p.upstreamSamples)';
R = line(1)+(line(3)-line(1))*t;
Z = line(2)+(line(4)-line(2))*t;
psi = griddata(g.vxX,g.vxY,g.vxFpsi,R,Z,'linear');
valid = isfinite(R) & isfinite(Z) & isfinite(psi);
R = R(valid);
Z = Z(valid);
psi = psi(valid);
if numel(psi) < 2
    error('WG:UpstreamLine','Too few valid magnetic-flux samples lie on the upstream reference line.');
end
if isempty(p.upstreamPsiSep)
    [~,index] = min(abs(g.fsPsi));
    psiSep = g.fsPsi(index);
else
    psiSep = p.upstreamPsiSep;
end
[~,axisIndex] = max(psi);
Raxis = median(R(psi == psi(axisIndex)));
switch lower(p.upstreamSide)
    case 'outer'
        branch = R >= Raxis;
    case 'inner'
        branch = R <= Raxis;
    otherwise
        error('WG:UpstreamSide','upstreamSide must be outer or inner.');
end
R = R(branch);
Z = Z(branch);
psi = psi(branch);
[psi,order] = sort(psi);
R = R(order);
Z = Z(order);
[psiUnique,~,groups] = unique(psi);
Runique = accumarray(groups,R,[],@mean);
Zunique = accumarray(groups,Z,[],@mean);
if numel(psiUnique) < 2
    error('WG:UpstreamFlux','The requested upstream branch does not contain a usable flux interval.');
end
method = 'linear';
if p.upstreamExtrapolate
    extrapolation = 'extrap';
else
    extrapolation = NaN;
end
if isempty(p.upstreamRsep)
    Rsep = interp1(psiUnique,Runique,psiSep,method,extrapolation);
else
    Rsep = p.upstreamRsep;
end
if ~isfinite(Rsep)
    error('WG:UpstreamSeparatrix','Cannot map psiSep=%g to an upstream R. Use upstreamRsep or enable extrapolation.',psiSep);
end
mapping.psi = psiUnique;
mapping.R = Runique;
mapping.Z = Zunique;
mapping.psiSep = psiSep;
mapping.Rsep = Rsep;
mapping.Raxis = Raxis;
mapping.side = lower(p.upstreamSide);
mapping.referenceLine = line;
mapping.extrapolate = p.upstreamExtrapolate;
end
