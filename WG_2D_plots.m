clearvars;
clc;
wg_core('setup');

%% User parameters
p = wg_core('defaults');
% Run containing SOLPS output. Example: replace this path with '.../run2'.
p.runDir = '/pfs/work/g2psint/solps-iter_wg_github_svdk/runs/TCV/TCVtblld/91685/91685_DDN_3/run1';
% Empty searches runDir, b2mn.exe.dir, ../baserun, and baserun for b2fgmtry.
% Example: fullfile(p.runDir,'../baserun/b2fgmtry') selects the geometry explicitly.
p.geometryFile = '';
% One quantity produces one figure. Sources are b2fstate, b2fstati, b2fplasmf, ft44, and ft46.
% Example: wg_core('spec','b2fstate','na',2) selects B2 species 2 (one-based indexing).
% Example: wg_core('spec','b2fstate','fhi',{':',1}) selects face-flux component 1.
p.quantities = {
    wg_core('spec','ft44','D_neutral_density'), 
    wg_core('spec','b2fstati', 'te')
};
% 'auto' selects log for suitable positive fields; use 'linear' or 'log' to force a scale.
% Example: 'linear' is appropriate for signed fluxes and potentials.
p.colorScale = 'linear';
% Empty computes limits from the data. Example: [1e15,1e20] fixes the color range.
% For per-quantity limits, set spec.clim after creating that spec instead.
p.colorLimits = [0 50];
% Automatic log scale spans at most this many decades from the maximum.
% Example: 5 displays values from max(data)/1e5 to max(data).
p.logDecades = 8;
% Any MATLAB colormap available by name. Example: 'parula', 'jet', or 'hot'.
p.colormap = 'turbo';
% Empty displays the full domain. Example: [0.58,1.14,-0.765,0.33] sets R and Z limits.
p.zoom = [];
% false plots physical B2 cells 1:nCi only; true also includes valid guard polygons.
% Example: true is useful for inspecting boundary-condition data, not physical cell geometry.
p.includeGuardCells = false;
% true overlays cell edges. Example: true helps inspect the unstructured wide-grid mesh.
p.showMesh = false;
% true overlays the faces selected by targetLabels. Example: true highlights target surfaces.
p.showTargets = false;
% fcLbl values used by showTargets. Example: [1,2,3,4] overlays all four DDN targets.
p.targetLabels = [1,2];
% 'on' displays figures interactively; 'off' is useful for headless MATLAB batch jobs.
% Example: 'off'.
p.figureVisible = 'on';
% true saves a PNG per quantity. Example: true writes WG_postprocessing/2D_*.png.
p.saveFigures = false;
% true saves values, native element IDs, metadata, and source-file paths in MAT files.
% Example: true writes WG_postprocessing/2D_*.mat.
p.exportData = false;
% Empty uses <runDir>/WG_postprocessing only when saving/exporting is enabled.
% Example: '/tmp/my_WG_figures' chooses another output directory.
p.outputDir = '';
% PNG raster resolution in dots per inch. Example: 300 gives publication-resolution images.
p.dpi = 250;

%% Generate figures
run = wg_core('load_run',p);
figures = cell(size(p.quantities));
for k = 1:numel(p.quantities)
    [run,figures{k}] = wg_core('plot_map',run,p.quantities{k},p);
end
