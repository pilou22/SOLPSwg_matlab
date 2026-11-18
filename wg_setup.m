function wg_setup()
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(here);
addpath(genpath(fullfile(root,'scripts','MatlabPostProcessing')));
end
