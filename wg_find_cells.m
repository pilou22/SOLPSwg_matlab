function ids = wg_find_cells(mesh,R,Z)
R = R(:);
Z = Z(:);
ids = zeros(size(R));
for k = 1:numel(R)
    candidates = find(mesh.lo(:,1) <= R(k) & mesh.hi(:,1) >= R(k) & ...
        mesh.lo(:,2) <= Z(k) & mesh.hi(:,2) >= Z(k));
    for j = 1:numel(candidates)
        c = candidates(j);
        if inpolygon(R(k),Z(k),mesh.X(:,c),mesh.Y(:,c))
            ids(k) = mesh.ids(c);
            break
        end
    end
end
end
