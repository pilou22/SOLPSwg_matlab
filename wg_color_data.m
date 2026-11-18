function [values,limits,scale] = wg_color_data(q,p)
values = q.values;
limits = q.spec.clim;
if isempty(limits)
    limits = p.colorLimits;
end
scale = q.spec.colorScale;
if isempty(scale)
    scale = p.colorScale;
end
finite = values(isfinite(values));
if isempty(finite)
    error('WG:NoFiniteData','%s contains no finite values.',q.name);
end
if strcmp(scale,'auto')
    positive = finite(finite > 0);
    scale = 'linear';
    if ~isempty(positive) && all(finite >= 0) && max(positive)/min(positive) >= 1e3
        scale = 'log';
    end
end
if strcmp(scale,'log')
    positive = values(isfinite(values) & values > 0);
    if isempty(positive)
        error('WG:LogData','%s has no positive data for a logarithmic color scale.',q.name);
    end
    hidden = sum(isfinite(values) & values <= 0);
    if hidden > 0
        warning('WG:LogMask','Masking %d nonpositive values of %s.',hidden,q.name);
    end
    values(values <= 0) = NaN;
    if isempty(limits)
        limits = [max(positive)/10^p.logDecades,max(positive)];
        limits(1) = max(limits(1),min(positive));
    end
else
    scale = 'linear';
    if isempty(limits)
        limits = [min(finite),max(finite)];
    end
end
if limits(1) == limits(2)
    delta = max(1,abs(limits(1)))*1e-12;
    limits = limits+[-delta,delta];
end
if limits(1) > limits(2)
    error('WG:ColorLimits','Lower color limit exceeds upper limit.');
end
end
