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
