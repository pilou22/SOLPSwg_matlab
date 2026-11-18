function varargout = wg_core(action,varargin)
%WG_CORE Central dispatcher for the hidden wide-grid toolkit internals.
%   WG_CORE(ACTION,...) routes toolkit calls to the private local
%   implementations. The three user-facing scripts in the parent folder are
%   the only intended entry points.

if nargin < 1 || isempty(action)
    error('WG:Core','An action name is required.');
end
h = wg_handlers();
name = lower(char(action));
if ~isfield(h,name)
    name = ['wg_',name];
end
if ~isfield(h,name)
    error('WG:Core','Unknown toolkit action ''%s''.',char(action));
end
if nargout == 0
    h.(name)(varargin{:});
else
    varargout = cell(1,nargout);
    [varargout{:}] = h.(name)(varargin{:});
end
end

function h = wg_handlers()
h.wg_color_data = @wg_color_data;
h.wg_defaults = @wg_defaults;
h.wg_derived_quantity = @wg_derived_quantity;
h.wg_draw_face_ids = @wg_draw_face_ids;
h.wg_draw_faces = @wg_draw_faces;
h.wg_export_data = @wg_export_data;
h.wg_face_components = @wg_face_components;
h.wg_face_label_summary = @wg_face_label_summary;
h.wg_find_cells = @wg_find_cells;
h.wg_find_file = @wg_find_file;
h.wg_line_crossings = @wg_line_crossings;
h.wg_line_profile = @wg_line_profile;
h.wg_load_run = @wg_load_run;
h.wg_load_source = @wg_load_source;
h.wg_load_triangles = @wg_load_triangles;
h.wg_location_count = @wg_location_count;
h.wg_map_drsep = @wg_map_drsep;
h.wg_mesh_geometry = @wg_mesh_geometry;
h.wg_order_face_chain = @wg_order_face_chain;
h.wg_output_dir = @wg_output_dir;
h.wg_part_legend = @wg_part_legend;
h.wg_plot_location_map = @wg_plot_location_map;
h.wg_plot_map = @wg_plot_map;
h.wg_profile_locations = @wg_profile_locations;
h.wg_quantity = @wg_quantity;
h.wg_quantity_metadata = @wg_quantity_metadata;
h.wg_resolve_location = @wg_resolve_location;
h.wg_save_figure = @wg_save_figure;
h.wg_select_array = @wg_select_array;
h.wg_select_target = @wg_select_target;
h.wg_set_line_coordinate = @wg_set_line_coordinate;
h.wg_setup = @wg_setup;
h.wg_spec = @wg_spec;
h.wg_target_cell_ids = @wg_target_cell_ids;
h.wg_target_profile = @wg_target_profile;
h.wg_upstream_mapping = @wg_upstream_mapping;
end

%% wg_color_data
function [values,limits,scale] = wg_color_data(q,p)
values = q.values;
limits = q.spec.clim;
if isempty(limits)
    limits = p.colorLimits;
end
scale = q.spec.colorScale;
if isempty(scale)
    scale = p.colorScale;
end
finite = values(isfinite(values));
if isempty(finite)
    error('WG:NoFiniteData','%s contains no finite values.',q.name);
end
if strcmp(scale,'auto')
    positive = finite(finite > 0);
    scale = 'linear';
    if ~isempty(positive) && all(finite >= 0) && max(positive)/min(positive) >= 1e3
        scale = 'log';
    end
end
if strcmp(scale,'log')
    positive = values(isfinite(values) & values > 0);
    if isempty(positive)
        error('WG:LogData','%s has no positive data for a logarithmic color scale.',q.name);
    end
    hidden = sum(isfinite(values) & values <= 0);
    if hidden > 0
        warning('WG:LogMask','Masking %d nonpositive values of %s.',hidden,q.name);
    end
    values(values <= 0) = NaN;
    if isempty(limits)
        limits = [max(positive)/10^p.logDecades,max(positive)];
        limits(1) = max(limits(1),min(positive));
    end
else
    scale = 'linear';
    if isempty(limits)
        limits = [min(finite),max(finite)];
    end
end
if limits(1) == limits(2)
    delta = max(1,abs(limits(1)))*1e-12;
    limits = limits+[-delta,delta];
end
if limits(1) > limits(2)
    error('WG:ColorLimits','Lower color limit exceeds upper limit.');
end
end


%% wg_defaults
function p = wg_defaults()
p.runDir = '';
p.geometryFile = '';
p.files = struct();
p.quantities = {};
p.figureVisible = 'on';
p.figureSize = [1100,850];
p.colorScale = 'auto';
p.colorLimits = [];
p.colormap = 'turbo';
p.logDecades = 8;
p.includeGuardCells = false;
p.showMesh = false;
p.showTargets = false;
p.targetLabels = [];
p.zoom = [];
p.saveFigures = false;
p.exportData = false;
p.outputDir = '';
p.dpi = 250;
p.profileMode = 'inner';
p.innerTargetLabels = 1;
p.outerTargetLabels = 2;
p.customTargetLabels = [];
p.targetRzBox = [];
p.targetComponent = 0;
p.targetSeed = [];
p.targetCellSide = 'physical';
p.targetX = 's';
p.targetReverse = false;
p.lineEndpoints = [0.65,0.0,1.05,0.0];
p.lineSamples = 400;
p.profileMethod = 'native';
p.profileX = 'auto';
p.upstreamReferenceLine = [];
p.upstreamPsiSep = [];
p.upstreamRsep = [];
p.upstreamSide = 'outer';
p.upstreamSamples = 1000;
p.upstreamExtrapolate = true;
p.showProfileLegend = true;
p.targetFaceAreaNormalize = false;
p.profileYScale = 'linear';
p.profileYLim = [];
p.plotLocationMap = true;
p.plotColumns = 2;
p.sources = {'b2fstate','b2fplasmf','ft44','ft46'};
end


%% wg_derived_quantity
function [found,values,location] = wg_derived_quantity(~,data,spec)
found = true;
location = 'cell';
if strcmp(spec.source,'ft44')
    switch lower(spec.field)
        case 'total_d_density'
            values = data.dab2(:,1,1) + 2*data.dmb2(:,1,1);
            return
        case 'total_atom_density'
            values = sum(data.dab2,3);
            return
        case 'total_molecule_density'
            values = sum(data.dmb2,3);
            return
        case 'total_test_ion_density'
            values = sum(data.dib2,3);
            return
    end
end
found = false;
values = [];
location = '';
end


%% wg_draw_face_ids
function h = wg_draw_face_ids(run,ids,color,width)
g = run.gmtry;
ids = ids(:);
X = nan(3,numel(ids));
Y = nan(3,numel(ids));
for k = 1:numel(ids)
    iv = g.fcVx(ids(k),:);
    X(1:2,k) = g.vxX(iv);
    Y(1:2,k) = g.vxY(iv);
end
h = plot(gca,X,Y,'Color',color,'LineWidth',width);
end


%% wg_draw_faces
function h = wg_draw_faces(run,labels,color,width)
g = run.gmtry;
ids = find(ismember(g.fcLbl,labels));
X = nan(3,numel(ids));
Y = nan(3,numel(ids));
for k = 1:numel(ids)
    iv = g.fcVx(ids(k),:);
    X(1:2,k) = g.vxX(iv);
    Y(1:2,k) = g.vxY(iv);
end
h = plot(gca,X,Y,'Color',color,'LineWidth',width);
end


%% wg_export_data
function wg_export_data(run,p,name,data)
if ~p.exportData
    return
end
directory = wg_output_dir(run,p);
file = fullfile(directory,[name,'.mat']);
save(file,'data');
fprintf('Saved %s\n',file);
end


%% wg_face_components
function components = wg_face_components(gmtry,ids)
ids = ids(:);
n = numel(ids);
parent = 1:n;
for k = 1:n
    a = wg_root(parent,k);
    iv = gmtry.fcVx(ids(k),:);
    for j = k+1:n
        if any(gmtry.fcVx(ids(j),:) == iv(1)) || any(gmtry.fcVx(ids(j),:) == iv(2))
            b = wg_root(parent,j);
            if a ~= b
                parent(b) = a;
            end
        end
    end
end
roots = zeros(1,n);
for k = 1:n
    roots(k) = wg_root(parent,k);
end
[~,~,group] = unique(roots,'stable');
components = cell(1,max([0;group(:)]));
for k = 1:numel(components)
    components{k} = ids(group == k);
end
end

function root = wg_root(parent,k)
root = k;
while parent(root) ~= root
    root = parent(root);
end
end


%% wg_face_label_summary
function summary = wg_face_label_summary(gmtry)
labels = unique(gmtry.fcLbl(gmtry.fcLbl ~= 0));
summary = struct([]);
ivAll = gmtry.fcVx;
R = gmtry.vxX;
Z = gmtry.vxY;
for k = 1:numel(labels)
    ids = find(gmtry.fcLbl == labels(k));
    components = wg_face_components(gmtry,ids);
    iv = ivAll(ids,:);
    summary(k).label = labels(k);
    summary(k).faces = ids;
    summary(k).components = components;
    summary(k).extent = [min(R(iv(:))),max(R(iv(:))),min(Z(iv(:))),max(Z(iv(:)))];
end
end


%% wg_find_cells
function ids = wg_find_cells(mesh,R,Z)
R = R(:);
Z = Z(:);
ids = zeros(size(R));
for k = 1:numel(R)
    candidates = find(mesh.lo(:,1) <= R(k) & mesh.hi(:,1) >= R(k) & ...
        mesh.lo(:,2) <= Z(k) & mesh.hi(:,2) >= Z(k));
    for j = 1:numel(candidates)
        c = candidates(j);
        if inpolygon(R(k),Z(k),mesh.X(:,c),mesh.Y(:,c))
            ids(k) = mesh.ids(c);
            break
        end
    end
end
end


%% wg_find_file
function file = wg_find_file(candidates)
file = '';
for k = 1:numel(candidates)
    candidate = candidates{k};
    if ~isempty(candidate) && isfile(candidate)
        file = candidate;
        return
    end
end
end


%% wg_line_crossings
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


%% wg_line_profile
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


%% wg_load_run
function run = wg_load_run(p)
wg_setup();
run.parameters = p;
run.sources = struct();
run.cache = struct();
run.files = struct();
runDir = p.runDir;
if isempty(runDir) || ~isfolder(runDir)
    error('WG:RunDirectory','Invalid run directory: %s',runDir);
end
runDir = char(java.io.File(runDir).getCanonicalPath());
run.runDir = runDir;
dirs = {runDir,fullfile(runDir,'b2mn.exe.dir'),fullfile(runDir,'..','baserun'),fullfile(runDir,'baserun')};
names = {'geometry','b2fstate','b2fstati','b2fplasmf','fort44','fort46','fort33','fort34','fort35'};
base = {'b2fgmtry','b2fstate','b2fstati','b2fplasmf','fort.44','fort.46','fort.33','fort.34','fort.35'};
for k = 1:numel(names)
    key = names{k};
    if isfield(p.files,key) && ~isempty(p.files.(key))
        run.files.(key) = p.files.(key);
        continue
    end
    if strcmp(key,'geometry') && ~isempty(p.geometryFile)
        run.files.(key) = p.geometryFile;
        continue
    end
    candidates = cell(size(dirs));
    for j = 1:numel(dirs)
        candidates{j} = fullfile(dirs{j},base{k});
    end
    if strcmp(key,'b2fplasmf')
        extra = cell(size(dirs));
        for j = 1:numel(dirs)
            extra{j} = fullfile(dirs{j},'b2fplasmf_us');
        end
        candidates = [candidates,extra];
    end
    run.files.(key) = wg_find_file(candidates);
end
if isempty(run.files.geometry)
    error('WG:MissingGeometry','No b2fgmtry found for %s',runDir);
end
run.gmtry = read_b2fgmtry_us(run.files.geometry);
if run.gmtry.isClassicalGrid ~= 0
    warning('WG:ClassicalGeometry','This toolkit is intended for unstructured wide-grid geometries.');
end
run.nCells = run.gmtry.nCv;
run.nFaces = run.gmtry.nFc;
end


%% wg_load_source
function [run,data] = wg_load_source(run,source)
source = lower(source);
if isfield(run.sources,source)
    data = run.sources.(source);
    return
end
switch source
    case 'b2fgmtry'
        data = run.gmtry;
    case {'b2fstate','b2fstati'}
        key = source;
        if strcmp(source,'b2fstate') && isempty(run.files.b2fstate) && ~isempty(run.files.b2fstati)
            key = 'b2fstati';
        end
        if ~isfield(run.files,key) || isempty(run.files.(key))
            error('WG:MissingSource','No %s file found.',key);
        end
        data = read_b2fstate_us(run.files.(key));
        run.sources.used_b2state_file = run.files.(key);
    case 'b2fplasmf'
        if isempty(run.files.b2fplasmf)
            error('WG:MissingSource','No formatted b2fplasmf file found.');
        end
        data = read_b2fplasmf_us(run.files.b2fplasmf);
    case 'ft44'
        if isempty(run.files.fort44)
            error('WG:MissingSource','No fort.44 file found.');
        end
        [data,~] = read_ft44_us(run.files.fort44,run.gmtry.nCv);
    case 'ft46'
        required = {'fort46','fort33','fort34','fort35'};
        for k = 1:numel(required)
            if isempty(run.files.(required{k}))
                error('WG:MissingSource','Missing %s required for fort.46.',required{k});
            end
        end
        run = wg_load_triangles(run);
        data = read_ft46_us(run.files.fort46,run.gmtry.nCi,run.triangles);
    otherwise
        error('WG:UnknownSource','Unknown source %s.',source);
end
run.sources.(source) = data;
end


%% wg_load_triangles
function run = wg_load_triangles(run)
if isfield(run,'triangles')
    return
end
required = {'fort33','fort34','fort35'};
for k = 1:numel(required)
    if isempty(run.files.(required{k}))
        error('WG:MissingSource','Missing %s required for triangle data.',required{k});
    end
end
run.triangles = read_triangle_mesh_us(run.files.fort33,run.files.fort34,run.files.fort35);
run.nTriangles = size(run.triangles.cells,1);
end


%% wg_location_count
function count = wg_location_count(run,location)
switch location
    case 'cell'
        count = run.gmtry.nCv;
    case 'face'
        count = run.gmtry.nFc;
    case 'vertex'
        count = run.gmtry.nVx;
    case 'triangle'
        run = wg_load_triangles(run);
        count = run.nTriangles;
    otherwise
        error('WG:Location','Unsupported spatial location %s.',location);
end
end


%% wg_map_drsep
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


%% wg_mesh_geometry
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


%% wg_order_face_chain
function ordered = wg_order_face_chain(gmtry,ids)
ids = ids(:);
if numel(ids) <= 1
    ordered = ids;
    return
end
ordered = ids(1);
remaining = ids(2:end);
ends = gmtry.fcVx(ids(1),:);
while ~isempty(remaining)
    found = 0;
    atEnd = true;
    for k = 1:numel(remaining)
        iv = gmtry.fcVx(remaining(k),:);
        if any(iv == ends(2))
            found = k;
            atEnd = true;
            break
        elseif any(iv == ends(1))
            found = k;
            atEnd = false;
            break
        end
    end
    if found == 0
        error('WG:BranchedTarget','The selected connected component is branched or cannot be ordered as one polyline.');
    end
    id = remaining(found);
    remaining(found) = [];
    iv = gmtry.fcVx(id,:);
    if atEnd
        ordered(end+1,1) = id;
        if ends(2) == iv(1)
            ends(2) = iv(2);
        else
            ends(2) = iv(1);
        end
    else
        ordered = [id;ordered];
        if ends(1) == iv(1)
            ends(1) = iv(2);
        else
            ends(1) = iv(1);
        end
    end
end
end


%% wg_output_dir
function directory = wg_output_dir(run,p)
directory = p.outputDir;
if isempty(directory)
    directory = fullfile(run.runDir,'WG_postprocessing');
end
if (p.saveFigures || p.exportData) && ~isfolder(directory)
    mkdir(directory);
end
end


%% wg_part_legend
function label = wg_part_legend(location,part,run,p)
if strcmp(location.name,'line')
    e = p.lineEndpoints;
    label = sprintf('line: (%.4g,%.4g)-(%.4g,%.4g)',e);
    return
end
labels = unique(run.gmtry.fcLbl(part.faces));
label = sprintf('%s: fcLbl %s',location.name,mat2str(labels'));
if numel(location.target.faces) > numel(part.faces)
    label = sprintf('%s, component %d',label,part.part);
end
end


%% wg_plot_location_map
function [run,fig] = wg_plot_location_map(run,p,locations)
[run,mesh] = wg_mesh_geometry(run,'cell',false);
fig = figure('Visible',p.figureVisible,'Color','w','Position',[100,100,p.figureSize]);
ax = axes(fig);
hold(ax,'on');
patch(ax,'Vertices',mesh.vertices,'Faces',mesh.Faces','FaceColor',[0.93,0.93,0.93],'EdgeColor','none');
axis(ax,'equal');
for k = 1:numel(locations)
    location = locations{k};
    if strcmp(location.name,'line')
        e = p.lineEndpoints;
        plot(ax,e([1,3]),e([2,4]),'m-','LineWidth',2);
        plot(ax,e([1,3]),e([2,4]),'ko','MarkerFaceColor','y','MarkerSize',6);
    else
        target = location.target;
        switch location.name
            case 'inner'
                color = [0.85,0.1,0.1];
            case 'outer'
                color = [0.1,0.3,0.9];
            otherwise
                color = [0.1,0.65,0.25];
        end
        wg_draw_face_ids(run,target.faces,color,2.4);
    end
end
if isempty(p.zoom)
    xlim(ax,mesh.extent(1:2));
    ylim(ax,mesh.extent(3:4));
else
    xlim(ax,p.zoom(1:2));
    ylim(ax,p.zoom(3:4));
end
xlabel(ax,'$R$ [m]','Interpreter','latex');
ylabel(ax,'$Z$ [m]','Interpreter','latex');
title(ax,'Selected profile locations','Interpreter','latex');
grid(ax,'on');
box(ax,'on');
names = cellfun(@(x) x.name,locations,'UniformOutput',false);
wg_save_figure(fig,run,p,['location_',strjoin(names,'_')]);
end


%% wg_plot_map
function [run,fig,q,mesh] = wg_plot_map(run,spec,p)
[run,q] = wg_quantity(run,spec);
[values,limits,scale] = wg_color_data(q,p);
fig = figure('Visible',p.figureVisible,'Color','w','Position',[100,100,p.figureSize]);
ax = axes(fig);
hold(ax,'on');
mesh = [];
switch q.location
    case {'cell','triangle','vertex'}
        [run,mesh] = wg_mesh_geometry(run,q.location,p.includeGuardCells);
        if strcmp(q.location,'vertex')
            color = values;
            faceColor = 'interp';
        else
            color = values(mesh.ids);
            faceColor = 'flat';
        end
        patch(ax,'Vertices',mesh.vertices,'Faces',mesh.Faces', ...
            'FaceVertexCData',color,'FaceColor',faceColor,'EdgeColor','none');
        if p.showMesh
            patch(ax,'Vertices',mesh.vertices,'Faces',mesh.Faces', ...
                'FaceColor','none','EdgeColor',[0.75,0.75,0.75],'LineWidth',0.2);
        end
    case 'face'
        g = run.gmtry;
        mesh.location = 'face';
        mesh.ids = (1:g.nFc)';
        mesh.extent = [min(g.vxX),max(g.vxX),min(g.vxY),max(g.vxY)];
        iv = g.fcVx;
        X = [g.vxX(iv(:,1)),g.vxX(iv(:,2))]';
        Y = [g.vxY(iv(:,1)),g.vxY(iv(:,2))]';
        patch(ax,'Vertices',[X(:),Y(:)],'Faces',reshape(1:2*g.nFc,2,[])', ...
            'FaceVertexCData',repelem(values(:),2,1), ...
            'FaceColor','none','EdgeColor','flat','LineWidth',1.6);
    otherwise
        error('WG:PlotLocation','Cannot plot %s data.',q.location);
end
set(ax,'ColorScale',scale,'FontSize',12,'TickLabelInterpreter','latex');
clim(ax,limits);
colormap(fig,p.colormap);
c = colorbar(ax);
c.Label.String = ['$',q.label,'$ $[',q.unit,']$'];
c.Label.Interpreter = 'latex';
axis(ax,'equal');
if isempty(p.zoom)
    xlim(ax,mesh.extent(1:2));
    ylim(ax,mesh.extent(3:4));
else
    xlim(ax,p.zoom(1:2));
    ylim(ax,p.zoom(3:4));
end
xlabel(ax,'$R$ [m]','Interpreter','latex');
ylabel(ax,'$Z$ [m]','Interpreter','latex');
title(ax,q.name,'Interpreter','none');
grid(ax,'on');
box(ax,'on');
if p.showTargets
    labels = p.targetLabels;
    if isempty(labels)
        labels = [p.innerTargetLabels(:);p.outerTargetLabels(:)];
    end
    wg_draw_faces(run,labels,[1,0,0],2.2);
end
q.plottedValues = values;
q.colorLimits = limits;
q.colorScale = scale;
data = struct('quantity',q,'ids',mesh.ids,'sourceFiles',run.files);
safe = matlab.lang.makeValidName([q.source,'_',q.field]);
wg_save_figure(fig,run,p,['2D_',safe]);
wg_export_data(run,p,['2D_',safe],data);
end


%% wg_profile_locations
function locations = wg_profile_locations(run,p)
requested = p.profileMode;
if ischar(requested) || isstring(requested)
    requested = cellstr(requested);
end
if ~iscellstr(requested) || isempty(requested)
    error('WG:ProfileMode','profileMode must be a mode name or a cell array of mode names.');
end
locations = cell(size(requested));
for k = 1:numel(requested)
    mode = lower(strtrim(requested{k}));
    location.name = mode;
    location.labels = [];
    location.target = [];
    switch mode
        case 'inner'
            location.labels = p.innerTargetLabels;
        case 'outer'
            location.labels = p.outerTargetLabels;
        case 'labels'
            location.labels = p.customTargetLabels;
        case 'line'
        otherwise
            error('WG:ProfileMode','Each profile mode must be inner, outer, labels, or line.');
    end
    if ~strcmp(mode,'line')
        location.target = wg_select_target(run,location.labels,p);
    end
    locations{k} = location;
end
end


%% wg_quantity
function [run,q] = wg_quantity(run,spec)
[run,data] = wg_load_source(run,spec.source);
[found,raw,location] = wg_derived_quantity(run,data,spec);
if found
    location = wg_location_override(spec,location);
else
    if ~isfield(data,spec.field)
        available = strjoin(fieldnames(data),', ');
        error('WG:MissingField','Field %s is not present in %s. Available fields: %s',spec.field,spec.source,available);
    end
    raw = data.(spec.field);
    if ~isnumeric(raw) || isempty(raw)
        error('WG:InvalidField','Field %s.%s is not a nonempty numeric array.',spec.source,spec.field);
    end
    location = wg_resolve_location(run,spec,raw);
    raw = wg_select_array(raw,spec.indices);
    if ~strcmp(spec.reduce,'none')
        reduced = reshape(raw,size(raw,1),[]);
        switch lower(spec.reduce)
            case 'sum'
                raw = sum(reduced,2);
            case 'mean'
                raw = mean(reduced,2);
            otherwise
                error('WG:Reduction','Unknown reduction %s.',spec.reduce);
        end
    end
end
raw = squeeze(raw);
expected = wg_location_count(run,location);
if numel(raw) ~= expected
    error('WG:UnresolvedDimensions','%s.%s leaves %d values, but %s data require %d. Supply indices or a reduction; selected size is %s.',spec.source,spec.field,numel(raw),location,expected,mat2str(size(raw)));
end
q.values = raw(:);
q.location = location;
q.source = spec.source;
q.field = spec.field;
q.name = sprintf('%s.%s',spec.source,spec.field);
[q.label,q.unit,defaultScale] = wg_quantity_metadata(spec);
if isempty(spec.scale)
    q.values = defaultScale*q.values;
else
    q.values = spec.scale*q.values;
end
if ~isempty(spec.transform)
    transformed = spec.transform(q.values);
    if ~isnumeric(transformed) || numel(transformed) ~= expected
        error('WG:Transform','The quantity transform must return %d numeric values.',expected);
    end
    q.values = transformed(:);
end
q.spec = spec;
end

function location = wg_location_override(spec,location)
if ~strcmp(spec.location,'auto')
    if ~strcmp(spec.location,location)
        error('WG:Location','Derived quantity %s is defined on %s data, not %s.',spec.field,location,spec.location);
    end
end
end


%% wg_quantity_metadata
function [label,unit,scale] = wg_quantity_metadata(spec)
label = strrep(spec.field,'_','\_');
unit = 'file units';
scale = 1;
ev = 1.602176634e-19;
switch lower(spec.field)
    case {'ne','na','dab2','dmb2','dib2','pdena','pdenm','pdeni','total_d_density','total_atom_density','total_molecule_density','total_test_ion_density'}
        unit = 'm^{-3}';
    case 'te'
        label = 'T_e';
        unit = 'eV';
        scale = 1/ev;
    case 'ti'
        label = 'T_i';
        unit = 'eV';
        scale = 1/ev;
    case 'tn'
        label = 'T_n';
        unit = 'eV';
        scale = 1/ev;
    case {'tab2','tmb2','tib2'}
        unit = 'eV';
        scale = 1/ev;
    case {'ua','uadia','vadia','wadia','vaecrb','veecrb','vedia'}
        unit = 'm s^{-1}';
    case {'po','sig0'}
        unit = 'V';
    case {'edena','edenm','edeni'}
        unit = 'J m^{-3}';
    case {'vxdena','vxdenm','vxdeni','vydena','vydenm','vydeni','vzdena','vzdenm','vzdeni'}
        unit = 'kg s^{-1} m^{-2}';
    case {'rfluxa','rfluxm','pfluxa','pfluxm'}
        unit = 'm^{-2} s^{-1}';
    case 'fna'
        unit = 's^{-1}';
    case {'fhe','fhi','fhn','fhp','fht','fhj','fhe_mdf','fhi_mdf','fhe_eir','fhi_eir','fhepsch','fhipsch'}
        unit = 'W';
    case {'fch','fch_32','fch_52','fch_p'}
        unit = 'A';
    case 'cvvol'
        unit = 'm^{3}';
    case 'fcs'
        unit = 'm^{2}';
end
switch lower(spec.field)
    case {'fna','na','ua','kinrgy'}
        if isnumeric(spec.indices) && isscalar(spec.indices)
            label = sprintf('%s (B2 species %d)',label,spec.indices);
        end
    case {'dab2','tab2','dmb2','tmb2','dib2','tib2','pdena','pdenm','pdeni','edena','edenm','edeni'}
        if isnumeric(spec.indices) && isscalar(spec.indices)
            label = sprintf('%s (EIRENE index %d)',label,spec.indices);
        end
end
if ~isempty(spec.label)
    label = spec.label;
end
if ~isempty(spec.unit)
    unit = spec.unit;
end
end


%% wg_resolve_location
function location = wg_resolve_location(run,spec,raw)
if ~strcmp(spec.location,'auto')
    location = spec.location;
    return
end
switch spec.source
    case 'ft44'
        location = 'cell';
    case 'ft46'
        location = 'triangle';
    case {'b2fstate','b2fstati','b2fplasmf','b2fgmtry'}
        candidates = {'cell','face','vertex'};
        matches = {};
        for k = 1:numel(candidates)
            count = wg_location_count(run,candidates{k});
            if size(raw,1) == count
                matches{end+1} = candidates{k};
            end
        end
        if numel(matches) ~= 1
            error('WG:AmbiguousLocation','Cannot infer the spatial location of %s.%s with size %s. Set spec.location explicitly.',spec.source,spec.field,mat2str(size(raw)));
        end
        location = matches{1};
    otherwise
        error('WG:UnknownSource','Unknown source %s.',spec.source);
end
end


%% wg_save_figure
function wg_save_figure(fig,run,p,name)
if ~p.saveFigures
    return
end
directory = wg_output_dir(run,p);
file = fullfile(directory,[name,'.png']);
print(fig,file,'-dpng',sprintf('-r%d',p.dpi));
fprintf('Saved %s\n',file);
end


%% wg_select_array
function selected = wg_select_array(raw,indices)
if isempty(indices)
    selected = raw;
    return
end
if isnumeric(indices)
    if ~isscalar(indices) || indices < 1 || indices ~= floor(indices)
        error('WG:Index','A numeric index must be a positive scalar integer.');
    end
    subs = repmat({':'},1,ndims(raw));
    subs{end} = indices;
elseif iscell(indices)
    subs = indices;
    if numel(subs) > ndims(raw)
        error('WG:Index','%d subscripts supplied for an array of dimension %d.',numel(subs),ndims(raw));
    end
    subs(end+1:ndims(raw)) = {':'};
else
    error('WG:Index','Indices must be a positive integer or a cell array of subscripts.');
end
s.type = '()';
s.subs = subs;
selected = subsref(raw,s);
end


%% wg_select_target
function target = wg_select_target(run,labels,p)
g = run.gmtry;
if isempty(labels)
    error('WG:TargetLabels','At least one face label is required.');
end
ids = find(ismember(g.fcLbl,labels));
if isempty(ids)
    error('WG:TargetLabels','No faces found for labels %s.',mat2str(labels));
end
iv = g.fcVx(ids,:);
Rf = mean(g.vxX(iv),2);
Zf = mean(g.vxY(iv),2);
if ~isempty(p.targetRzBox)
    b = p.targetRzBox;
    keep = Rf >= b(1) & Rf <= b(2) & Zf >= b(3) & Zf <= b(4);
    ids = ids(keep);
    if isempty(ids)
        error('WG:TargetBox','No selected target faces lie inside the requested R/Z box.');
    end
end
components = wg_face_components(g,ids);
if strcmpi(p.targetComponent,'nearest')
    if isempty(p.targetSeed)
        error('WG:TargetComponent','targetSeed is required when targetComponent is nearest.');
    end
    iv = g.fcVx;
    Rf = mean(g.vxX(iv),2);
    Zf = mean(g.vxY(iv),2);
    distance = inf(size(components));
    for k = 1:numel(components)
        distance(k) = min(hypot(Rf(components{k})-p.targetSeed(1),Zf(components{k})-p.targetSeed(2)));
    end
    [~,selected] = min(distance);
    components = components(selected);
elseif isnumeric(p.targetComponent) && ~isequal(p.targetComponent,0)
    selected = p.targetComponent;
    if ~isscalar(selected) || selected < 1 || selected > numel(components) || selected ~= floor(selected)
        error('WG:TargetComponent','targetComponent must be 0, nearest, or an integer from 1 to %d.',numel(components));
    end
    components = components(selected);
end
target.labels = labels;
target.faces = [];
target.part = [];
target.arc = [];
target.R = [];
target.Z = [];
target.psi = [];
for k = 1:numel(components)
    ordered = wg_order_face_chain(g,components{k});
    iv = g.fcVx(ordered,:);
    R = mean(g.vxX(iv),2);
    Z = mean(g.vxY(iv),2);
    psi = mean(g.vxFpsi(iv),2);
    switch lower(p.targetX)
        case 'r'
            [~,order] = sort(R);
            ordered = ordered(order);
        case 'z'
            [~,order] = sort(Z);
            ordered = ordered(order);
        case 'psi'
            [~,order] = sort(psi);
            ordered = ordered(order);
        case {'s','index','drsep','drsepupstream'}
        otherwise
            error('WG:TargetX','targetX must be s, R, Z, psi, or index.');
    end
    if p.targetReverse
        ordered = ordered(end:-1:1);
    end
    iv = g.fcVx(ordered,:);
    Rout = mean(g.vxX(iv),2);
    Zout = mean(g.vxY(iv),2);
    psiout = mean(g.vxFpsi(iv),2);
    lengths = hypot(diff(g.vxX(iv),1,2),diff(g.vxY(iv),1,2));
    arc = cumsum(lengths)-lengths/2;
    n = numel(ordered);
    target.faces = [target.faces;ordered(:)];
    target.part = [target.part;repmat(k,n,1)];
    target.arc = [target.arc;arc(:)];
    target.R = [target.R;Rout(:)];
    target.Z = [target.Z;Zout(:)];
    target.psi = [target.psi;psiout(:)];
end
target.nParts = numel(components);
end


%% wg_set_line_coordinate
function [run,profile] = wg_set_line_coordinate(run,profile,p)
switch lower(p.profileX)
    case 'r'
        profile.x = profile.R;
        profile.xlabel = 'R [m]';
    case 'z'
        profile.x = profile.Z;
        profile.xlabel = 'Z [m]';
    case 's'
        profile.x = profile.s;
        profile.xlabel = 's from (R_1,Z_1) [m]';
    case {'drsep','drsepupstream'}
        [profile.x,profile.upstreamMapping] = wg_map_drsep(run,p,profile.R,profile.Z,[]);
        profile.xlabel = '\Delta r_{sep}^{upstream} [m]';
    case 'auto'
        e = profile.endpoints;
        profile.x = profile.s;
        profile.xlabel = 's from (R_1,Z_1) [m]';
        if abs(e(4)-e(2)) < 10*eps(max(1,abs(e([2,4]))))
            profile.x = profile.R;
            profile.xlabel = 'R [m]';
        elseif abs(e(3)-e(1)) < 10*eps(max(1,abs(e([1,3]))))
            profile.x = profile.Z;
            profile.xlabel = 'Z [m]';
        end
    otherwise
        error('WG:ProfileX','profileX must be auto, s, R, Z, or drsep for a line profile.');
end
for k = 1:numel(profile.parts)
    profile.parts(k).x = profile.x;
end
end


%% wg_setup
function wg_setup()
coreFile = mfilename('fullpath');
toolkitRoot = fileparts(fileparts(coreFile));
repoRoot = fileparts(fileparts(toolkitRoot));
addpath(toolkitRoot);
addpath(genpath(fullfile(repoRoot,'scripts','MatlabPostProcessing')));
end


%% wg_spec
function spec = wg_spec(source,field,indices)
if nargin < 3
    indices = [];
end
spec.source = lower(source);
spec.field = field;
spec.indices = indices;
spec.reduce = 'none';
spec.label = '';
spec.unit = '';
spec.scale = [];
spec.location = 'auto';
spec.colorScale = '';
spec.clim = [];
spec.transform = [];
end


%% wg_target_cell_ids
function ids = wg_target_cell_ids(gmtry,faces,side)
neighbors = gmtry.fcCv(faces,:);
ids = neighbors(:,1);
switch lower(side)
    case {'physical','interior','auto'}
        for k = 1:numel(faces)
            internal = neighbors(k,:) <= gmtry.nCi;
            if any(internal)
                ids(k) = neighbors(k,find(internal,1));
            end
        end
    case 'guard'
        for k = 1:numel(faces)
            guard = neighbors(k,:) > gmtry.nCi;
            if any(guard)
                ids(k) = neighbors(k,find(guard,1));
            end
        end
    case 'first'
    case 'second'
        ids = neighbors(:,2);
    otherwise
        error('WG:TargetSide','targetCellSide must be physical, guard, first, or second.');
end
end


%% wg_target_profile
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


%% wg_upstream_mapping
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

