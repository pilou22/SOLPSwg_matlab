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
