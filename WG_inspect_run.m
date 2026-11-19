clearvars;
clc;
runConfig = wg_core('setup');

%% User parameters
p = wg_core('defaults');
% Run to inspect. On lac3, replace 186317 with another MDS number if needed.
% The original viz06 run example remains unchanged when that cluster is selected.
if strcmp(runConfig.cluster,'lac3')
    p.runDir = fullfile(runConfig.shotRoot,'186317');
else
    % p.runDir = '/pfs/work/g2psint/solps-iter_wg_github_svdk/runs/TCV/TCVtblld/91685/91685_DDN_3/run1';
    p.runDir = '/pfs/work/g2psint/solps-iter_wg_github/runs/TCV/TCVtblld/91207_D+C_t=1.4/noDRIFTS_033150';
end

% Sources to read and summarize; an absent formatted b2fplasmf is reported without stopping.
% Example: {'b2fstate','ft44','ft46'} avoids checking unavailable sources.
p.sources = {'b2fstate','b2fplasmf','ft44','ft46'};

%% Print source dimensions, species metadata, and face-label geometry
run = wg_core('load_run',p);
fprintf('\nRun: %s\n',run.runDir);
fprintf('Geometry: %s\n',run.files.geometry);
fprintf('nCi=%d, nCg=%d, nCv=%d, nFc=%d, nVx=%d\n',run.gmtry.nCi,run.gmtry.nCg,run.gmtry.nCv,run.gmtry.nFc,run.gmtry.nVx);
for k = 1:numel(p.sources)
    source = p.sources{k};
    try
        [run,data] = wg_core('load_source',run,source);
    catch exception
        fprintf('\n%s: %s\n',source,exception.message);
        continue
    end
    fprintf('\n%s fields:\n',source);
    names = fieldnames(data);
    for j = 1:numel(names)
        fprintf('  %-20s %s\n',names{j},mat2str(size(data.(names{j}))));
    end
    if isfield(data,'zamin')
        fprintf('B2 species: MATLAB index, zamin, zamax, zn, am\n');
        for j = 1:numel(data.zamin)
            fprintf('  %d  %g  %g  %g  %g\n',j,data.zamin(j),data.zamax(j),data.zn(j),data.am(j));
        end
    end
end
summary = wg_core('face_label_summary',run.gmtry);
fprintf('\nNonzero face labels:\n');
fprintf('  label      faces  components   Rmin      Rmax      Zmin      Zmax\n');
for k = 1:numel(summary)
    e = summary(k).extent;
    fprintf('  %6d  %8d  %10d   %+8.4f  %+8.4f  %+8.4f  %+8.4f\n',summary(k).label,numel(summary(k).faces),numel(summary(k).components),e);
end
fprintf('\nUse these extents to set innerTargetLabels, outerTargetLabels, targetRzBox, and targetComponent in WG_profiles.m.\n');
