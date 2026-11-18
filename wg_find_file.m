function file = wg_find_file(candidates)
file = '';
for k = 1:numel(candidates)
    candidate = candidates{k};
    if ~isempty(candidate) && isfile(candidate)
        file = candidate;
        return
    end
end
end
