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
