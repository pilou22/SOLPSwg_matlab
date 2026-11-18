function target = wg_select_target(run,labels,p)
g = run.gmtry;
if isempty(labels)
    error('WG:TargetLabels','At least one face label is required.');
end
ids = find(ismember(g.fcLbl,labels));
if isempty(ids)
    error('WG:TargetLabels','No faces found for labels %s.',mat2str(labels));
end
iv = g.fcVx(ids,:);
Rf = mean(g.vxX(iv),2);
Zf = mean(g.vxY(iv),2);
if ~isempty(p.targetRzBox)
    b = p.targetRzBox;
    keep = Rf >= b(1) & Rf <= b(2) & Zf >= b(3) & Zf <= b(4);
    ids = ids(keep);
    if isempty(ids)
        error('WG:TargetBox','No selected target faces lie inside the requested R/Z box.');
    end
end
components = wg_face_components(g,ids);
if strcmpi(p.targetComponent,'nearest')
    if isempty(p.targetSeed)
        error('WG:TargetComponent','targetSeed is required when targetComponent is nearest.');
    end
    iv = g.fcVx;
    Rf = mean(g.vxX(iv),2);
    Zf = mean(g.vxY(iv),2);
    distance = inf(size(components));
    for k = 1:numel(components)
        distance(k) = min(hypot(Rf(components{k})-p.targetSeed(1),Zf(components{k})-p.targetSeed(2)));
    end
    [~,selected] = min(distance);
    components = components(selected);
elseif isnumeric(p.targetComponent) && ~isequal(p.targetComponent,0)
    selected = p.targetComponent;
    if ~isscalar(selected) || selected < 1 || selected > numel(components) || selected ~= floor(selected)
        error('WG:TargetComponent','targetComponent must be 0, nearest, or an integer from 1 to %d.',numel(components));
    end
    components = components(selected);
end
target.labels = labels;
target.faces = [];
target.part = [];
target.arc = [];
target.R = [];
target.Z = [];
target.psi = [];
for k = 1:numel(components)
    ordered = wg_order_face_chain(g,components{k});
    iv = g.fcVx(ordered,:);
    R = mean(g.vxX(iv),2);
    Z = mean(g.vxY(iv),2);
    psi = mean(g.vxFpsi(iv),2);
    switch lower(p.targetX)
        case 'r'
            [~,order] = sort(R);
            ordered = ordered(order);
        case 'z'
            [~,order] = sort(Z);
            ordered = ordered(order);
        case 'psi'
            [~,order] = sort(psi);
            ordered = ordered(order);
        case {'s','index','drsep','drsepupstream'}
        otherwise
            error('WG:TargetX','targetX must be s, R, Z, psi, or index.');
    end
    if p.targetReverse
        ordered = ordered(end:-1:1);
    end
    iv = g.fcVx(ordered,:);
    Rout = mean(g.vxX(iv),2);
    Zout = mean(g.vxY(iv),2);
    psiout = mean(g.vxFpsi(iv),2);
    lengths = hypot(diff(g.vxX(iv),1,2),diff(g.vxY(iv),1,2));
    arc = cumsum(lengths)-lengths/2;
    n = numel(ordered);
    target.faces = [target.faces;ordered(:)];
    target.part = [target.part;repmat(k,n,1)];
    target.arc = [target.arc;arc(:)];
    target.R = [target.R;Rout(:)];
    target.Z = [target.Z;Zout(:)];
    target.psi = [target.psi;psiout(:)];
end
target.nParts = numel(components);
end
