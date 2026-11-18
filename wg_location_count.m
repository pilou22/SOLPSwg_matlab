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
