function selected = wg_select_array(raw,indices)
if isempty(indices)
    selected = raw;
    return
end
if isnumeric(indices)
    if ~isscalar(indices) || indices < 1 || indices ~= floor(indices)
        error('WG:Index','A numeric index must be a positive scalar integer.');
    end
    subs = repmat({':'},1,ndims(raw));
    subs{end} = indices;
elseif iscell(indices)
    subs = indices;
    if numel(subs) > ndims(raw)
        error('WG:Index','%d subscripts supplied for an array of dimension %d.',numel(subs),ndims(raw));
    end
    subs(end+1:ndims(raw)) = {':'};
else
    error('WG:Index','Indices must be a positive integer or a cell array of subscripts.');
end
s.type = '()';
s.subs = subs;
selected = subsref(raw,s);
end
