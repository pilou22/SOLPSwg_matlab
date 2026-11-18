function [run,profile] = wg_line_profile(run,spec,p)
[run,q] = wg_quantity(run,spec);
e = p.lineEndpoints;
t = linspace(0,1,p.lineSamples)';
R = e(1)+(e(3)-e(1))*t;
Z = e(2)+(e(4)-e(2))*t;
L = hypot(e(3)-e(1),e(4)-e(2));
if L == 0
    error('WG:Line','Line endpoints must be distinct.');
end
s = t*L;
[run,crossings] = wg_line_crossings(run,e);
profile.quantity = q;
profile.endpoints = e;
profile.crossings = crossings;
profile.R = R;
profile.Z = Z;
profile.s = s;
profile.t = t;
profile.isSparse = false;
if strcmp(q.location,'face') && strcmpi(p.profileMethod,'native')
    profile.isSparse = true;
    ids = crossings.faceIndex;
    parts.x = crossings.s;
    parts.values = q.values(ids);
    parts.R = crossings.R;
    parts.Z = crossings.Z;
    parts.faces = ids;
    parts.part = 1;
    profile.parts = parts;
    profile.R = parts.R;
    profile.Z = parts.Z;
    profile.s = parts.x;
    profile.t = crossings.t;
    profile.x = crossings.s;
    profile.values = parts.values;
    profile.xlabel = 's from (R_1,Z_1) [m]';
    [run,profile] = wg_set_line_coordinate(run,profile,p);
    return
end
if strcmp(q.location,'triangle')
    [run,mesh] = wg_mesh_geometry(run,'triangle',false);
else
    [run,mesh] = wg_mesh_geometry(run,'cell',false);
end
ids = wg_find_cells(mesh,R,Z);
inside = ids > 0;
native = nan(size(ids));
if ~strcmp(q.location,'vertex')
    native(inside) = q.values(ids(inside));
end
switch lower(p.profileMethod)
    case 'native'
        values = native;
        if strcmp(q.location,'vertex')
            values = griddata(run.gmtry.vxX,run.gmtry.vxY,q.values,R,Z,'linear');
        end
    case {'linear','nearest'}
        method = lower(p.profileMethod);
        switch q.location
            case 'vertex'
                values = griddata(run.gmtry.vxX,run.gmtry.vxY,q.values,R,Z,method);
            case 'face'
                g = run.gmtry;
                iv = g.fcVx;
                Rf = mean(g.vxX(iv),2);
                Zf = mean(g.vxY(iv),2);
                values = griddata(Rf,Zf,q.values,R,Z,method);
            otherwise
                values = griddata(mesh.R(:),mesh.Z(:),q.values(mesh.ids),R,Z,method);
        end
        if ~ismember(q.location,{'vertex','face'})
            fallback = inside & ~isfinite(values);
            values(fallback) = native(fallback);
        end
    otherwise
        error('WG:ProfileMethod','profileMethod must be native, linear, or nearest.');
end
values(~inside) = NaN;
profile.parts.x = s;
profile.parts.values = values;
profile.parts.R = R;
profile.parts.Z = Z;
profile.parts.faces = [];
profile.parts.part = 1;
profile.values = values;
profile.x = s;
profile.cellIds = ids;
profile.xlabel = 's from (R_1,Z_1) [m]';
[run,profile] = wg_set_line_coordinate(run,profile,p);
end
