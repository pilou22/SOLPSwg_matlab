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
