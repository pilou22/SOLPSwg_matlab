%% Pull data from EFGW via SFTP
clearvars;
shot = 91207; % USER: Experimental shot number used for TS and LP data.
MDS = 1; % USER: Local solps_ssh directory containing the SOLPS outputs.
experimentalTime = 0.9; % USER: Initial time shown by both time sliders, in seconds.
maxLPTemperature = 100; % USER: Upper FourParamsFit electron-temperature cutoff in eV.
refreshFromEFGW = false; % USER: Set true to enable retrieval of the files listed below.
efgwDirectory = '/pfs/work/g2psint/solps-iter_wg_github/runs/TCV/TCVtblld/91207_D+C_t=1.4/noDRIFTS_033150'; % USER: Source run directory on viz06.
efgwHost = 'viz06-ext.efgw.cineca.it'; % USER: SFTP gateway host.
efgwUser = 'g2psint'; % USER: SFTP gateway account.
quantities = {'/../baserun/b2fgmtry','/b2fstate','/b2fstati','/b2fplasmf', ...
    '/fort.33','/fort.34','/fort.35','/fort.44','/fort.46'}; % USER: SFTP file paths/globs relative to efgwDirectory.

runConfig = wg_core('setup');
solpsDirectory = fullfile(runConfig.shotRoot,num2str(MDS));
if refreshFromEFGW
    if ~isfolder(solpsDirectory)
        mkdir(solpsDirectory);
    end
    keyFile = fullfile(getenv('HOME'),'.ssh','gw_key');
    for k = 1:numel(quantities)
        command = ['sftp -o BatchMode=yes -i ',keyFile,' ',efgwUser,'@', ...
            efgwHost,':',efgwDirectory,quantities{k},' ',solpsDirectory,'/'];
        [status,output] = system(command);
        if status ~= 0
            error('WG:SFTP','Failed to retrieve %s: %s',quantities{k},output);
        end
        fprintf('Retrieved %s\n',quantities{k});
    end
end

p = wg_core('defaults');
p.runDir = solpsDirectory;
p.targetX = 'drsep'; % USER: Abscissa used for target comparisons.
p.profileMode = {'inner','outer'}; % USER: Target regions to compare with LP.
p.profileMethod = 'native'; % USER: Sampling/interpolation style for SOLPS profiles.
p.profileX = 'Z'; % USER: Abscissa for the TS sightline comparison.
p.upstreamSide = 'outer'; % USER: Upstream drsep mapping convention.
p.innerTargetLabels = 1; % USER: fcLbl value(s) identifying the inner-target faces.
p.outerTargetLabels = 2; % USER: fcLbl value(s) identifying the outer-target faces.
p.saveFigures = false; % USER: Set true to save the displayed slider state as PNG figures.
p.exportData = false; % USER: Set true to export the initial comparison structures.
outputDirectory = fullfile(solpsDirectory,'WG_experimental');
if (p.saveFigures || p.exportData) && ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

LP = LP_MDSdld(shot);
if ~isfield(LP,'FourParamsFit')
    error('WG:Langmuir','FourParamsFit data are unavailable for shot %d.',shot);
end
timeVector = LP.time(:)';
if isempty(timeVector) || any(~isfinite(timeVector))
    error('WG:LangmuirTime','No valid LP sampling times are available.');
end
[~,initialLPIndex] = min(abs(timeVector-experimentalTime));

%% Compare Thomson scattering with SOLPS
solpsRun = wg_core('load_run',p);
[solpsRun,solpsState] = wg_core('load_source',solpsRun,'b2fstate');
if isfield(solpsState,'time') && ~isempty(solpsState.time) && isfinite(solpsState.time(1))
    b2StateTime = solpsState.time(1);
else
    b2StateTime = NaN;
end
analysisTime = experimentalTime;

experimentalTS = get_edge_data(shot,[timeVector(1) timeVector(end)],'',{'TS'});
if ~isfield(experimentalTS,'TS') || ~experimentalTS.TS.available
    error('WG:Thomson','No Thomson data available for shot %d.',shot);
end
TS = experimentalTS.TS;
if sum(isfinite(TS.ne(:))) < 2 || sum(isfinite(TS.te(:))) < 2
    error('WG:ThomsonData','No finite Thomson profiles are available in the LP time range.');
end
[~,initialTSIndex] = min(abs(TS.t(:)-timeVector(initialLPIndex)));
if isfield(TS,'R_time') && any(isfinite(TS.R_time(:)))
    sightlineRadius = median(TS.R_time(isfinite(TS.R_time)));
else
    sightlineRadius = median(TS.R(isfinite(TS.R)));
end
zRange = [min(TS.Z(isfinite(TS.Z))),max(TS.Z(isfinite(TS.Z)))];
solpsSightline = [sightlineRadius,zRange(1),sightlineRadius,zRange(2)];
p.lineEndpoints = solpsSightline;
p.lineSamples = max(300,5*numel(unique(TS.Z(isfinite(TS.Z)))));
[ solpsRun,solpsNeTS ] = wg_core('line_profile',solpsRun,wg_core('spec','b2fstate','ne'),p);
[ solpsRun,solpsTeTS ] = wg_core('line_profile',solpsRun,wg_core('spec','b2fstate','te'),p);
[solpsPsiSeparation,solpsMapping] = wg_core('map_drsep',solpsRun,p,solpsNeTS.R,solpsNeTS.Z,[]);
solpsSeparatrixZ = wg_experimental_crossings(solpsNeTS.Z,solpsPsiSeparation);
initialExperimentalSeparatrixZ = wg_experimental_crossings(TS.Z,TS.rho(initialTSIndex,:)-1);

tsFigure = figure('Name','Thomson scattering comparison','Color','w');
tsAxes = gobjects(2,1);
tsExperimentalLines = gobjects(2,1);
tsSolpsLines = gobjects(2,1);
experimentalSepColor = [0.85,0.33,0.1];
for k = 1:2
    ax = subplot(2,1,k,'Parent',tsFigure);
    tsAxes(k) = ax;
    hold(ax,'on');
    if k == 1
        yLabel = '$n_e$ [$10^{19}$ m$^{-3}$]';
    else
        yLabel = '$T_e$ [eV]';
    end
    tsExperimentalLines(k) = wg_experimental_ts_panel(ax,TS,initialTSIndex,k);
    [xSolps,order] = sort(solpsNeTS.Z);
    if k == 1
        ySolps = solpsNeTS.values(order)/1e19;
    else
        ySolps = solpsTeTS.values(order);
    end
    validSolps = isfinite(xSolps) & isfinite(ySolps);
    tsSolpsLines(k) = plot(ax,xSolps(validSolps),ySolps(validSolps),'r-', ...
        'LineWidth',1.5,'DisplayName','SOLPS');
    xlabel(ax,'$Z$ [m]','Interpreter','latex');
    ylabel(ax,yLabel,'Interpreter','latex');
    grid(ax,'on');
    box(ax,'on');
    wg_experimental_separatrix_lines(ax,solpsSeparatrixZ,[0.1,0.1,0.1],':', ...
        'SOLPS \rho=1');
    wg_experimental_separatrix_lines(ax,initialExperimentalSeparatrixZ, ...
        experimentalSepColor,'--','TS \rho=1');
    legend(ax,'show','Location','best');
end
tsTitle = sgtitle(sprintf('TS versus SOLPS: shot %d, MDS %d, R=%.4f m, t=%.4f s', ...
    shot,MDS,sightlineRadius,TS.t(initialTSIndex)));
[tsSlider,tsTimeLabel] = wg_experimental_time_slider(tsFigure,timeVector,initialLPIndex, ...
    sprintf('LP t=%.4f s, TS t=%.4f s',timeVector(initialLPIndex),TS.t(initialTSIndex)));
tsInterface = struct('TS',TS,'time',timeVector,'timeLabel',tsTimeLabel, ...
    'experimentalLines',tsExperimentalLines,'experimentalSepColor',experimentalSepColor, ...
    'title',tsTitle,'shot',shot,'MDS',MDS,'sightlineRadius',sightlineRadius);
set(tsFigure,'UserData',tsInterface);
set(tsSlider,'Callback',@wg_experimental_change_ts);

%% Compare FourParamsFit LP data with SOLPS at the targets
innerProbes = ~(LP.pos(:,1)>0.66 & LP.pos(:,2)<-0.4) & ...
    LP.pos(:,1)<0.7 & LP.pos(:,2)<0.7;
outerProbes = LP.pos(:,1)>0.66 & LP.pos(:,2)<-0.4;
initialValidFit = wg_experimental_lp_fit_mask(LP,initialLPIndex,maxLPTemperature);
experimentalRegions(1).name = 'Inner target';
experimentalRegions(1).location = 'inner';
experimentalRegions(1).probes = innerProbes & initialValidFit;
experimentalRegions(2).name = 'Outer target';
experimentalRegions(2).location = 'outer';
experimentalRegions(2).probes = outerProbes & initialValidFit;

locations = wg_core('profile_locations',solpsRun,p);
elementaryCharge = 1.602176634e-19;
charges = (solpsState.zamin+solpsState.zamax)/2;
comparison.LP = struct([]);
for k = 1:numel(experimentalRegions)
    location = locations{strcmp(cellfun(@(x) x.name,locations, ...
        'UniformOutput',false),experimentalRegions(k).location)};
    target = location.target;
    [ solpsRun,neProfile ] = wg_core('target_profile',solpsRun,target,wg_core('spec','b2fstate','ne'),p);
    [ solpsRun,teProfile ] = wg_core('target_profile',solpsRun,target,wg_core('spec','b2fstate','te'),p);
    [drsep,mapping] = wg_core('map_drsep',solpsRun,p,target.R,target.Z,target.psi);

    ionFluxDensity = zeros(numel(target.faces),numel(charges));
    for is = 1:numel(charges)
        ionFluxDensity(:,is) = boundary_flux_density(solpsRun.gmtry, ...
            target.faces,solpsState.fna(:,:,is));
    end
    solpsJsat = abs(elementaryCharge*(ionFluxDensity*charges(:)));

    comparison.LP(k).name = experimentalRegions(k).name;
    comparison.LP(k).experimental = wg_experimental_lp_profile(LP, ...
        experimentalRegions(k).probes,initialLPIndex);
    comparison.LP(k).experimental.probes = LP.probes(experimentalRegions(k).probes);
    comparison.LP(k).experimental.position = LP.pos(experimentalRegions(k).probes,:);
    comparison.LP(k).solps.drsep = drsep;
    comparison.LP(k).solps.ne = neProfile.values;
    comparison.LP(k).solps.Te = teProfile.values;
    comparison.LP(k).solps.Jsat = solpsJsat;
    comparison.LP(k).solps.R = target.R;
    comparison.LP(k).solps.Z = target.Z;
    comparison.LP(k).solps.faces = target.faces;
    comparison.LP(k).solps.mapping = mapping;
end

lpFigure = figure('Name','Langmuir probe comparison','Color','w');
quantityNames = {'ne','Te','Jsat'};
yLabels = {'$n_e$ [m$^{-3}$]','$T_e$ [eV]','$|j_{sat}|$ [A m$^{-2}$]'};
lpExperimentalLines = gobjects(3,2);
for k = 1:numel(comparison.LP)
    for j = 1:numel(quantityNames)
        ax = subplot(3,2,2*(j-1)+k,'Parent',lpFigure);
        lpExperimentalLines(j,k) = wg_experimental_panel(ax,comparison.LP(k),quantityNames{j});
        title(ax,comparison.LP(k).name,'Interpreter','none');
        xlabel(ax,{'$\Delta r_{\mathrm{sep}}$' '[m]'},'Interpreter','latex');
        ylabel(ax,yLabels{j},'Interpreter','latex');
        grid(ax,'on');
        box(ax,'on');
        if k == 1 && j == 1
            legend(ax,'show','Location','best');
        end
    end
end
lpTitle = sgtitle(sprintf('FourParamsFit versus SOLPS: shot %d, t=%gs',shot,timeVector(initialLPIndex)));
[lpSlider,lpTimeLabel] = wg_experimental_time_slider(lpFigure,timeVector,initialLPIndex, ...
    sprintf('LP t=%.4f s',timeVector(initialLPIndex)));
lpInterface = struct('LP',LP,'time',timeVector,'timeLabel',lpTimeLabel, ...
    'experimentalLines',lpExperimentalLines,'title',lpTitle,'shot',shot, ...
    'probeMasks',{{innerProbes,outerProbes}},'maxLPTemperature',maxLPTemperature);
set(lpFigure,'UserData',lpInterface);
set(lpSlider,'Callback',@wg_experimental_change_lp);

comparison.shot = shot;
comparison.MDS = MDS;
comparison.analysisTime = analysisTime;
comparison.b2StateTime = b2StateTime;
comparison.LPtime = timeVector(initialLPIndex);
comparison.LPfit = 'FourParamsFit';
comparison.maxLPTemperature = maxLPTemperature;
comparison.TS = TS;
comparison.TSsolps.time = analysisTime;
comparison.TSsolps.sightline = solpsSightline;
comparison.TSsolps.Z = solpsNeTS.Z;
comparison.TSsolps.ne = solpsNeTS.values;
comparison.TSsolps.Te = solpsTeTS.values;
comparison.TSsolps.separatrixZ = solpsSeparatrixZ;
comparison.TSsolps.mapping = solpsMapping;
comparison.TSexperimental.initialSeparatrixZ = initialExperimentalSeparatrixZ;
comparison.TSexperimental.rho = TS.rho(initialTSIndex,:);
comparison.TSexperimental.time = TS.t(initialTSIndex);
comparison.SourceFiles = solpsRun.files;
comparison.CurrentDefinition = ['abs(e * sum_s[za_s * boundary_flux_density(fna_s)]), ' ...
    'with za_s=(zamin_s+zamax_s)/2'];
if p.saveFigures
    wg_experimental_print_figure(tsFigure,fullfile(outputDirectory,'Thomson_comparison.png'));
    wg_experimental_print_figure(lpFigure,fullfile(outputDirectory,'Langmuir_comparison.png'));
end
if p.exportData
    save(fullfile(outputDirectory,'experimental_comparison.mat'),'comparison');
end

function handle = wg_experimental_ts_panel(ax,TS,index,quantity)
z = TS.Z(:);
if quantity == 1
    y = TS.ne(index,:)/1e19;
    yError = TS.dne(index,:)/1e19;
else
    y = TS.te(index,:);
    yError = TS.dte(index,:);
end
valid = isfinite(z) & isfinite(y(:)) & isfinite(yError(:));
handle = errorbar(ax,z(valid),y(valid),yError(valid),'.k','DisplayName','Thomson');
end

function experimental = wg_experimental_lp_profile(LP,mask,index)
experimental.dsep_mid = LP.dsep_mid(mask,index);
experimental.ne = LP.FourParamsFit.dens(mask,index);
experimental.Te = LP.FourParamsFit.Te(mask,index);
experimental.Jsat = abs(LP.FourParamsFit.Jsat(mask,index)).*sind(abs(LP.ang(mask,index))); %Convert from parallel to poloidal Jsat to match SOLPS
end

function mask = wg_experimental_lp_fit_mask(LP,index,maxLPTemperature)
temperature = LP.FourParamsFit.Te(:,index);
mask = temperature >= 0 & temperature <= maxLPTemperature & ...
    LP.FourParamsFit.dens(:,index) >= 0;
mask = mask(:);
end

function [handle,solpsHandle] = wg_experimental_panel(ax,profile,quantity)
hold(ax,'on');
x = profile.experimental.dsep_mid;
y = profile.experimental.(quantity);
valid = isfinite(x) & isfinite(y);
handle = plot(ax,x(valid),y(valid),'o','LineStyle','none', ...
    'Color','k','MarkerSize',3,'DisplayName','LP');
x = profile.solps.drsep;
y = profile.solps.(quantity);
valid = isfinite(x) & isfinite(y);
solpsHandle = plot(ax,nan,nan,'r-','LineWidth',1.4,'DisplayName','SOLPS');
if any(valid)
    [x,order] = sort(x(valid));
    y = y(valid);
    set(solpsHandle,'XData',x,'YData',y(order));
end
end

function [slider,timeLabel] = wg_experimental_time_slider(parent,timeVector,index,text)
count = numel(timeVector);
slider = uicontrol(parent,'Style','slider','Units','normalized', ...
    'Position',[0.06,0.015,0.60,0.028],'Min',1,'Max',count,'Value',index);
if count > 1
    step = 1/(count-1);
    set(slider,'SliderStep',[step,min(0.25,10*step)]);
end
timeLabel = uicontrol(parent,'Style','text','Units','normalized', ...
    'Position',[0.69,0.012,0.28,0.032],'String',text,'HorizontalAlignment','left');
end

function wg_experimental_change_ts(slider,~)
fig = slider.Parent;
ui = fig.UserData;
index = min(max(round(get(slider,'Value')),1),numel(ui.time));
set(slider,'Value',index);
[~,tsIndex] = min(abs(ui.TS.t(:)-ui.time(index)));
z = ui.TS.Z(:);
for k = 1:2
    if k == 1
        y = ui.TS.ne(tsIndex,:)/1e19;
        yError = ui.TS.dne(tsIndex,:)/1e19;
    else
        y = ui.TS.te(tsIndex,:);
        yError = ui.TS.dte(tsIndex,:);
    end
    valid = isfinite(z) & isfinite(y(:)) & isfinite(yError(:));
    set(ui.experimentalLines(k),'XData',z(valid),'YData',y(valid), ...
        'LData',yError(valid),'UData',yError(valid));
end
delete(findall(fig,'Tag','TSExperimentalSeparatrix'));
separatrixZ = wg_experimental_crossings(ui.TS.Z,ui.TS.rho(tsIndex,:)-1);
for k = 1:numel(ui.experimentalLines)
    wg_experimental_separatrix_lines(ui.experimentalLines(k).Parent, ...
        separatrixZ,ui.experimentalSepColor,'--','TS equilibrium, \rho=1');
end
set(ui.title,'String',sprintf('TS versus SOLPS: shot %d, MDS %d, R=%.4f m, t=%.4f s', ...
    ui.shot,ui.MDS,ui.sightlineRadius,ui.TS.t(tsIndex)));
set(ui.timeLabel,'String',sprintf('LP t=%.4f s, TS t=%.4f s',ui.time(index),ui.TS.t(tsIndex)));
end

function wg_experimental_change_lp(slider,~)
fig = slider.Parent;
ui = fig.UserData;
index = min(max(round(get(slider,'Value')),1),numel(ui.time));
set(slider,'Value',index);
temperature = ui.LP.FourParamsFit.Te(:,index);
validFit = temperature >= 0 & temperature <= ui.maxLPTemperature & ...
    ui.LP.FourParamsFit.dens(:,index) >= 0;
validFit = validFit(:);
quantityNames = {'ne','Te','Jsat'};
for k = 1:2
    mask = ui.probeMasks{k} & validFit;
    experimental.dsep_mid = ui.LP.dsep_mid(mask,index);
    experimental.ne = ui.LP.FourParamsFit.dens(mask,index);
    experimental.Te = ui.LP.FourParamsFit.Te(mask,index);
    experimental.Jsat = abs(ui.LP.FourParamsFit.Jsat(mask,index)).*sind(abs(ui.LP.ang(mask,index))); %Convert from parallel to poloidal Jsat to match SOLPS
    for j = 1:3
        x = experimental.dsep_mid;
        y = experimental.(quantityNames{j});
        valid = isfinite(x) & isfinite(y);
        set(ui.experimentalLines(j,k),'XData',x(valid),'YData',y(valid));
    end
end
set(ui.timeLabel,'String',sprintf('LP t=%.4f s',ui.time(index)));
set(ui.title,'String',sprintf('FourParamsFit versus SOLPS: shot %d, t=%gs',ui.shot,ui.time(index)));
end

function wg_experimental_separatrix_lines(ax,positions,color,style,label)
for k = 1:numel(positions)
    handle = xline(ax,positions(k),style,'Color',color,'LineWidth',1.4);
    if isequal(color,[0.85,0.33,0.1])
        set(handle,'Tag','TSExperimentalSeparatrix');
    else
        set(handle,'Tag','SOLPSSeparatrix');
    end
    if k == 1
        set(handle,'DisplayName',label);
    else
        set(handle,'HandleVisibility','off');
    end
end
end

function positions = wg_experimental_crossings(z,coordinate)
z = z(:);
coordinate = coordinate(:);
valid = isfinite(z) & isfinite(coordinate);
z = z(valid);
coordinate = coordinate(valid);
if numel(z) < 2
    positions = [];
    return
end
positions = zeros(numel(z)-1,1);
nPositions = 0;
for k = 1:numel(z)-1
    a = coordinate(k);
    b = coordinate(k+1);
    if a == 0 && b == 0
        continue
    elseif a == 0
        position = z(k);
    elseif b == 0
        position = z(k+1);
    elseif a*b > 0
        continue
    else
        position = z(k)-a*(z(k+1)-z(k))/(b-a);
    end
    nPositions = nPositions+1;
    positions(nPositions) = position;
end
positions = sort(positions(1:nPositions));
positions = positions([true;diff(positions)>1e-6]);
if numel(positions) > 2
    positions = positions([1,end]);
end
end

function wg_experimental_print_figure(fig,filename)
controls = findall(fig,'Type','uicontrol');
if isempty(controls)
    print(fig,filename,'-dpng','-r200');
    return
end
visibility = get(controls,{'Visible'});
restore = onCleanup(@() set(controls,{'Visible'},visibility));
set(controls,'Visible','off');
print(fig,filename,'-dpng','-r200');
clear restore;
end
