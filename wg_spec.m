function spec = wg_spec(source,field,indices)
if nargin < 3
    indices = [];
end
spec.source = lower(source);
spec.field = field;
spec.indices = indices;
spec.reduce = 'none';
spec.label = '';
spec.unit = '';
spec.scale = [];
spec.location = 'auto';
spec.colorScale = '';
spec.clim = [];
spec.transform = [];
end
