function [run,mesh] = wg_mesh_geometry(run,location,includeGuards)
if nargin < 3
    includeGuards = false;
end
key = sprintf('%s_%d',location,includeGuards);
if isfield(run.cache,key)
    mesh = run.cache.(key);
    return
end
mesh.location = location;
switch location
    case 'cell'
        g = run.gmtry;
        requested = 1:g.nCv;
        if ~includeGuards
            requested = 1:g.nCi;
        end
        valid = [];
        polygons = {};
        for iCv = requested
            first = g.cvVxP(iCv,1);
            n = g.cvVxP(iCv,2);
            if n < 3 || first < 1 || first+n-1 > numel(g.cvVx)
                continue
            end
            vertexIds = g.cvVx(first:first+n-1);
            if any(vertexIds < 1 | vertexIds > g.nVx)
                continue
            end
            valid(end+1) = iCv;
            polygons{end+1} = vertexIds(:)';
        end
        nCells = numel(valid);
        if nCells == 0
            error('WG:EmptyMesh','No valid polygons found for the requested cell selection.');
        end
        nmax = max(cellfun(@numel,polygons))+1;
        mesh.Faces = ones(nmax,nCells);
        for k = 1:nCells
            v = polygons{k};
            mesh.Faces(1:numel(v),k) = v;
            mesh.Faces(numel(v)+1,k) = v(1);
            if size(mesh.Faces,1) > numel(v)+1
                mesh.Faces(numel(v)+2:end,k) = v(1);
            end
        end
        mesh.X = reshape(g.vxX(mesh.Faces),size(mesh.Faces));
        mesh.Y = reshape(g.vxY(mesh.Faces),size(mesh.Faces));
        mesh.ids = valid(:);
        mesh.vertices = [g.vxX(:),g.vxY(:)];
        mesh.R = g.cvX(valid);
        mesh.Z = g.cvY(valid);
    case 'triangle'
        run = wg_load_triangles(run);
        t = run.triangles;
        mesh.Faces = t.cells';
        mesh.ids = (1:run.nTriangles)';
        mesh.vertices = t.nodes;
        mesh.X = reshape(t.nodes(mesh.Faces,1),size(mesh.Faces));
        mesh.Y = reshape(t.nodes(mesh.Faces,2),size(mesh.Faces));
        mesh.R = mean(mesh.X,1);
        mesh.Z = mean(mesh.Y,1);
    case 'vertex'
        [run,mesh] = wg_mesh_geometry(run,'cell',includeGuards);
        mesh.location = 'vertex';
        return
    otherwise
        error('WG:MeshLocation','No polygon mesh for location %s.',location);
end
mesh.n = numel(mesh.ids);
mesh.lo = [min(mesh.X,[],1)',min(mesh.Y,[],1)'];
mesh.hi = [max(mesh.X,[],1)',max(mesh.Y,[],1)'];
mesh.extent = [min(mesh.vertices(:,1)),max(mesh.vertices(:,1)),min(mesh.vertices(:,2)),max(mesh.vertices(:,2))];
run.cache.(key) = mesh;
end
