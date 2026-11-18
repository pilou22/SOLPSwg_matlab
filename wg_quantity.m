function [run,q] = wg_quantity(run,spec)
[run,data] = wg_load_source(run,spec.source);
[found,raw,location] = wg_derived_quantity(run,data,spec);
if found
    location = wg_location_override(spec,location);
else
    if ~isfield(data,spec.field)
        available = strjoin(fieldnames(data),', ');
        error('WG:MissingField','Field %s is not present in %s. Available fields: %s',spec.field,spec.source,available);
    end
    raw = data.(spec.field);
    if ~isnumeric(raw) || isempty(raw)
        error('WG:InvalidField','Field %s.%s is not a nonempty numeric array.',spec.source,spec.field);
    end
    location = wg_resolve_location(run,spec,raw);
    raw = wg_select_array(raw,spec.indices);
    if ~strcmp(spec.reduce,'none')
        reduced = reshape(raw,size(raw,1),[]);
        switch lower(spec.reduce)
            case 'sum'
                raw = sum(reduced,2);
            case 'mean'
                raw = mean(reduced,2);
            otherwise
                error('WG:Reduction','Unknown reduction %s.',spec.reduce);
        end
    end
end
raw = squeeze(raw);
expected = wg_location_count(run,location);
if numel(raw) ~= expected
    error('WG:UnresolvedDimensions','%s.%s leaves %d values, but %s data require %d. Supply indices or a reduction; selected size is %s.',spec.source,spec.field,numel(raw),location,expected,mat2str(size(raw)));
end
q.values = raw(:);
q.location = location;
q.source = spec.source;
q.field = spec.field;
q.name = sprintf('%s.%s',spec.source,spec.field);
[q.label,q.unit,defaultScale] = wg_quantity_metadata(spec);
if isempty(spec.scale)
    q.values = defaultScale*q.values;
else
    q.values = spec.scale*q.values;
end
if ~isempty(spec.transform)
    transformed = spec.transform(q.values);
    if ~isnumeric(transformed) || numel(transformed) ~= expected
        error('WG:Transform','The quantity transform must return %d numeric values.',expected);
    end
    q.values = transformed(:);
end
q.spec = spec;
end

function location = wg_location_override(spec,location)
if ~strcmp(spec.location,'auto')
    if ~strcmp(spec.location,location)
        error('WG:Location','Derived quantity %s is defined on %s data, not %s.',spec.field,location,spec.location);
    end
end
end
