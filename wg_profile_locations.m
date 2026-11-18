function locations = wg_profile_locations(run,p)
requested = p.profileMode;
if ischar(requested) || isstring(requested)
    requested = cellstr(requested);
end
if ~iscellstr(requested) || isempty(requested)
    error('WG:ProfileMode','profileMode must be a mode name or a cell array of mode names.');
end
locations = cell(size(requested));
for k = 1:numel(requested)
    mode = lower(strtrim(requested{k}));
    location.name = mode;
    location.labels = [];
    location.target = [];
    switch mode
        case 'inner'
            location.labels = p.innerTargetLabels;
        case 'outer'
            location.labels = p.outerTargetLabels;
        case 'labels'
            location.labels = p.customTargetLabels;
        case 'line'
        otherwise
            error('WG:ProfileMode','Each profile mode must be inner, outer, labels, or line.');
    end
    if ~strcmp(mode,'line')
        location.target = wg_select_target(run,location.labels,p);
    end
    locations{k} = location;
end
end
