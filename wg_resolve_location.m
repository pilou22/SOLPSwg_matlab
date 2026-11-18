function location = wg_resolve_location(run,spec,raw)
if ~strcmp(spec.location,'auto')
    location = spec.location;
    return
end
switch spec.source
    case 'ft44'
        location = 'cell';
    case 'ft46'
        location = 'triangle';
    case {'b2fstate','b2fstati','b2fplasmf','b2fgmtry'}
        candidates = {'cell','face','vertex'};
        matches = {};
        for k = 1:numel(candidates)
            count = wg_location_count(run,candidates{k});
            if size(raw,1) == count
                matches{end+1} = candidates{k};
            end
        end
        if numel(matches) ~= 1
            error('WG:AmbiguousLocation','Cannot infer the spatial location of %s.%s with size %s. Set spec.location explicitly.',spec.source,spec.field,mat2str(size(raw)));
        end
        location = matches{1};
    otherwise
        error('WG:UnknownSource','Unknown source %s.',spec.source);
end
end
