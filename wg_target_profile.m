function [run,profile] = wg_target_profile(run,target,spec,p)
[run,q] = wg_quantity(run,spec);
g = run.gmtry;
faces = target.faces;
cellIds = wg_target_cell_ids(g,faces,p.targetCellSide);
values = nan(size(faces));
switch q.location
    case 'cell'
        values = q.values(cellIds);
    case 'face'
        values = q.values(faces);
        if p.targetFaceAreaNormalize
            values = values./g.fcS(faces);
            q.unit = [q.unit,' m^{-2}'];
            q.label = [q.label,'/S'];
        end
    case 'vertex'
        values = mean(q.values(g.fcVx(faces,:)),2);
    case 'triangle'
        run = wg_load_triangles(run);
        for k = 1:numel(faces)
            triangles = find(run.triangles.plasma_cell == cellIds(k));
            if ~isempty(triangles)
                values(k) = mean(q.values(triangles));
            end
        end
    otherwise
        error('WG:TargetLocation','Unsupported target quantity location %s.',q.location);
end
switch lower(p.targetX)
    case 's'
        x = target.arc;
        xlabel = 's [m]';
    case 'r'
        x = target.R;
        xlabel = 'R [m]';
    case 'z'
        x = target.Z;
        xlabel = 'Z [m]';
    case 'psi'
        x = target.psi;
        xlabel = '\psi [Wb/rad]';
    case 'index'
        x = (1:numel(faces))';
        xlabel = 'face index in selection';
    case {'drsep','drsepupstream'}
        [x,profile.upstreamMapping] = wg_map_drsep(run,p,target.R,target.Z,target.psi);
        xlabel = '\Delta r_{sep}^{upstream} [m]';
    otherwise
        error('WG:TargetX','targetX must be s, R, Z, psi, index, or drsep.');
end
profile.quantity = q;
profile.target = target;
profile.cellIds = cellIds;
profile.xlabel = xlabel;
profile.isSparse = false;
parts = repmat(struct('x',[],'values',[],'R',[],'Z',[],'faces',[],'part',0),target.nParts,1);
for k = 1:target.nParts
    use = target.part == k;
    parts(k).x = x(use);
    parts(k).values = values(use);
    parts(k).R = target.R(use);
    parts(k).Z = target.Z(use);
    parts(k).faces = faces(use);
    parts(k).part = k;
end
profile.parts = parts;
profile.values = values;
profile.x = x;
end
