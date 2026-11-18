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
