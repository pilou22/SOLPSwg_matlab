function wg_save_figure(fig,run,p,name)
if ~p.saveFigures
    return
end
directory = wg_output_dir(run,p);
file = fullfile(directory,[name,'.png']);
print(fig,file,'-dpng',sprintf('-r%d',p.dpi));
fprintf('Saved %s\n',file);
end
