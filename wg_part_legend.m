function label = wg_part_legend(location,part,run,p)
if strcmp(location.name,'line')
    e = p.lineEndpoints;
    label = sprintf('line: (%.4g,%.4g)-(%.4g,%.4g)',e);
    return
end
labels = unique(run.gmtry.fcLbl(part.faces));
label = sprintf('%s: fcLbl %s',location.name,mat2str(labels'));
if numel(location.target.faces) > numel(part.faces)
    label = sprintf('%s, component %d',label,part.part);
end
end
