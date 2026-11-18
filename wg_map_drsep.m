function [drsep,mapping] = wg_map_drsep(run,p,R,Z,psi)
mapping = wg_upstream_mapping(run,p);
if nargin < 5 || isempty(psi)
    psi = griddata(run.gmtry.vxX,run.gmtry.vxY,run.gmtry.vxFpsi,R,Z,'linear');
end
if mapping.extrapolate
    extrapolation = 'extrap';
else
    extrapolation = NaN;
end
drsep = interp1(mapping.psi,mapping.R,psi,'linear',extrapolation)-mapping.Rsep;
drsep = drsep(:);
end
