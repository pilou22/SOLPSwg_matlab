function directory = wg_output_dir(run,p)
directory = p.outputDir;
if isempty(directory)
    directory = fullfile(run.runDir,'WG_postprocessing');
end
if (p.saveFigures || p.exportData) && ~isfolder(directory)
    mkdir(directory);
end
end
