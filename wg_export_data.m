function wg_export_data(run,p,name,data)
if ~p.exportData
    return
end
directory = wg_output_dir(run,p);
file = fullfile(directory,[name,'.mat']);
save(file,'data');
fprintf('Saved %s\n',file);
end
