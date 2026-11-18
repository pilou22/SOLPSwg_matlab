clearvars;
clc;
wg_core('setup');

%% User parameters
p = wg_core('defaults');
% Run containing the SOLPS output files. Example: replace this with '.../run2'.
p.runDir = '/pfs/work/g2psint/solps-iter_wg_github_svdk/runs/TCV/TCVtblld/91685/91685_DDN_3/run1';
% One quantity becomes one panel. Example species selection: wg_core('spec','b2fstate','na',2).
% Sources are b2fstate, b2fstati, b2fplasmf, ft44, and ft46; indices are one-based.
p.quantities = {
    wg_core('spec','b2fstati','ne')
    wg_core('spec','b2fstati','te')
};
% Modes are 'inner', 'outer', 'labels', and 'line'.
% Use a cell array for overlays. Example: {'inner','outer'} or {'inner','outer','line'}.
% When including 'line', targetX and profileX must select the same type of x-coordinate.
p.profileMode = {'line'};
% fcLbl values associated with each named target. Example: [1,2] combines DDN inner targets.
p.innerTargetLabels = [1];
% Example: [3,4] combines DDN outer targets; run WG_inspect_run to check new geometry.
p.outerTargetLabels = [4];
% Used for profileMode='labels'. Example: [5,6] selects those wall/boundary labels.
p.customTargetLabels = [];
% Optional target restriction [Rmin,Rmax,Zmin,Zmax]. Example: [0.7,0.9,-0.75,-0.70].
p.targetRzBox = [];
% 0 selects all components; an integer selects one; 'nearest' selects nearest to targetSeed.
% Example: p.targetComponent='nearest'; with targetSeed below.
p.targetComponent = 0;
% [R,Z] reference for targetComponent='nearest'. Example: [0.78,-0.73].
p.targetSeed = [];
% Cell-side data convention: 'physical', 'guard', 'first', or 'second'.
% Example: 'guard' examines boundary-condition values instead of the adjacent plasma cell.
p.targetCellSide = 'physical';
% true divides face quantities by fcS. Example: true converts face-integrated W to W/m^2.
p.targetFaceAreaNormalize = false;
% Target x-axis: 's' (geometric face-centre arc length in m), 'R', 'Z', 'psi', 'index', or 'drsep'.
% Example: 'drsep' maps to upstream radial distance from the separatrix.
p.targetX = 'Z';
% Reverse each ordered target component. Example: true reverses the arc-length orientation.
p.targetReverse = false;
% Arbitrary profile segment [R1,Z1,R2,Z2], used by profileMode='line'.
% Example: [0.65,0,1.05,0] is a horizontal cut through Z=0.
p.lineEndpoints = [0.8,-0.2,0.8,-0.75];
% Number of evenly spaced sample positions. Example: 1000 produces a finer profile.
p.lineSamples = 400;
% 'native' preserves native cells/triangles or direct face crossings; 'linear' and 'nearest'
% interpolate onto the requested line. Example: 'linear' gives smoother cell-field profiles.
p.profileMethod = 'native';
% Line x-axis: 'auto' (R or Z for horizontal/vertical cuts), 's', 'R', 'Z', or 'drsep'.
% 's' is distance from (R1,Z1). Example: 'R' forces major radius on the x-axis.
p.profileX = 'Z';
% Reference cut for drsep: [R1,Z1,R2,Z2]. Empty chooses a horizontal Z=0 cut across the mesh.
% Example: [0.90,0,1.14,0] samples only the outer-midplane side.
p.upstreamReferenceLine = [];
% Separatrix poloidal flux psi, in geometry-file units. Empty chooses the fsPsi nearest zero.
% Example: set p.upstreamPsiSep=-1.75e-5 instead of relying on automatic identification.
p.upstreamPsiSep = [];
% Optional explicit separatrix radius at the reference cut, in m. Empty computes R(psiSep).
% Example: p.upstreamRsep=1.107 overrides the interpolation result.
p.upstreamRsep = [];
% Upstream side used for R(psi): 'outer' or 'inner'. Example: 'outer' means outer midplane.
p.upstreamSide = 'outer';
% Samples of vxFpsi along the upstream reference line. Example: 2000 increases table resolution.
p.upstreamSamples = 1000;
% true permits linear extrapolation beyond the sampled R(psi) range; false returns NaN outside.
% Example: false discards distant PFR flux surfaces not intersecting the reference cut.
p.upstreamExtrapolate = true;
% true shows one legend entry per target component or line. Example: false hides all legends.
p.showProfileLegend = true;
% Shared y-axis scale for all panels: 'linear' or 'log'. Example: 'log' for broad density ranges.
p.profileYScale = 'linear';
% Empty uses automatic limits. Example: [0,1e20] applies that range to every panel.
p.profileYLim = [];
% true adds an R,Z figure showing all selected targets and lines. Example: false disables it.
p.plotLocationMap = true;
% Maximum number of quantity panels per row. Example: 1 puts quantities in a vertical column.
p.plotColumns = 2;
% Empty shows all geometry; otherwise [Rmin,Rmax,Zmin,Zmax]. Example: [0.6,0.9,-0.75,-0.3].
p.zoom = [];
% 'on' displays figures interactively; 'off' is useful for batch jobs. Example: 'off'.
p.figureVisible = 'on';
% true saves PNG figure files. Example: true writes them to outputDir.
p.saveFigures = false;
% true saves profile structures and all settings in MAT files. Example: true.
p.exportData = false;
% Empty uses <runDir>/WG_postprocessing only when output is enabled.
% Example: '/tmp/my_profiles' chooses another destination.
p.outputDir = '';
% PNG raster resolution. Example: 300 gives publication-resolution output.
p.dpi = 250;

%% Build locations, compute profiles, and plot
run = wg_core('load_run',p);
locations = wg_core('profile_locations',run,p);
modeNames = cellfun(@(x) x.name,locations,'UniformOutput',false);
if any(strcmp(modeNames,'line')) && any(~strcmp(modeNames,'line'))
    lineAxis = lower(p.profileX);
    if strcmp(lineAxis,'auto')
        lineAxis = 's';
        if abs(p.lineEndpoints(4)-p.lineEndpoints(2)) < 10*eps(max(1,abs(p.lineEndpoints([2,4]))))
            lineAxis = 'r';
        elseif abs(p.lineEndpoints(3)-p.lineEndpoints(1)) < 10*eps(max(1,abs(p.lineEndpoints([1,3]))))
            lineAxis = 'z';
        end
    end
    targetAxis = lower(strrep(p.targetX,'upstream',''));
    lineAxis = strrep(lineAxis,'upstream','');
    if ~strcmp(targetAxis,lineAxis)
        error('WG:MixedCoordinates','Combining target and line profiles requires compatible targetX and profileX; use drsep, R, Z, or s for both.');
    end
end
nQuantities = numel(p.quantities);
nColumns = min(p.plotColumns,nQuantities);
nRows = ceil(nQuantities/nColumns);
fig = figure('Visible',p.figureVisible,'Color','w','Position',[80,80,650*nColumns,370*nRows]);
layout = tiledlayout(fig,nRows,nColumns,'TileSpacing','compact','Padding','compact');
profiles = cell(size(p.quantities));
for k = 1:nQuantities
    for m = 1:numel(locations)
        location = locations{m};
        if strcmp(location.name,'line')
            [run,newProfile] = wg_core('line_profile',run,p.quantities{k},p);
        else
            [run,newProfile] = wg_core('target_profile',run,location.target,p.quantities{k},p);
        end
        for j = 1:numel(newProfile.parts)
            newProfile.parts(j).legend = wg_core('part_legend',location,newProfile.parts(j),run,p);
            newProfile.parts(j).mode = location.name;
            newProfile.parts(j).isSparse = newProfile.isSparse;
        end
        if m == 1
            profiles{k} = newProfile;
            profiles{k}.runs = {newProfile};
        else
            profiles{k}.parts = [profiles{k}.parts;newProfile.parts];
            profiles{k}.runs{end+1} = newProfile;
        end
    end
    profile = profiles{k};
    ax = nexttile(layout,k);
    hold(ax,'on');
    handles = gobjects(0);
    labels = {};
    for j = 1:numel(profile.parts)
        part = profile.parts(j);
        if part.isSparse
            h = plot(ax,part.x,part.values,'o-','LineWidth',1.1,'MarkerSize',3);
        else
            h = plot(ax,part.x,part.values,'-','LineWidth',1.5);
        end
        handles(end+1) = h;
        labels{end+1} = part.legend;
    end
    set(ax,'YScale',p.profileYScale,'FontSize',11,'TickLabelInterpreter','latex');
    if ~isempty(p.profileYLim)
        ylim(ax,p.profileYLim);
    end
    xlabel(ax,['$',profile.xlabel,'$'],'Interpreter','latex');
    ylabel(ax,['$',profile.quantity.label,'$ $[',profile.quantity.unit,']$'],'Interpreter','latex');
    title(ax,profile.quantity.name,'Interpreter','none');
    if p.showProfileLegend && ~isempty(handles)
        legend(ax,handles,labels,'Location','best','Interpreter','none');
    end
    grid(ax,'on');
    box(ax,'on');
end
if p.plotLocationMap
    [run,locationFigure] = wg_core('plot_location_map',run,p,locations);
end
name = strjoin(modeNames,'_');
if any(strcmp(modeNames,'labels'))
    name = sprintf('%s_fcLbl_%s',name,strjoin(arrayfun(@num2str,p.customTargetLabels,'UniformOutput',false),'_'));
end
wg_core('save_figure',fig,run,p,['profiles_',name]);
data = struct('profiles',{profiles},'parameters',p,'sourceFiles',run.files,'locations',{locations});
wg_core('export_data',run,p,['profiles_',name],data);
