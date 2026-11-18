function components = wg_face_components(gmtry,ids)
ids = ids(:);
n = numel(ids);
parent = 1:n;
for k = 1:n
    a = wg_root(parent,k);
    iv = gmtry.fcVx(ids(k),:);
    for j = k+1:n
        if any(gmtry.fcVx(ids(j),:) == iv(1)) || any(gmtry.fcVx(ids(j),:) == iv(2))
            b = wg_root(parent,j);
            if a ~= b
                parent(b) = a;
            end
        end
    end
end
roots = zeros(1,n);
for k = 1:n
    roots(k) = wg_root(parent,k);
end
[~,~,group] = unique(roots,'stable');
components = cell(1,max([0;group(:)]));
for k = 1:numel(components)
    components{k} = ids(group == k);
end
end

function root = wg_root(parent,k)
root = k;
while parent(root) ~= root
    root = parent(root);
end
end
