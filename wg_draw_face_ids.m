function h = wg_draw_face_ids(run,ids,color,width)
g = run.gmtry;
ids = ids(:);
X = nan(3,numel(ids));
Y = nan(3,numel(ids));
for k = 1:numel(ids)
    iv = g.fcVx(ids(k),:);
    X(1:2,k) = g.vxX(iv);
    Y(1:2,k) = g.vxY(iv);
end
h = plot(gca,X,Y,'Color',color,'LineWidth',width);
end
