function ordered = wg_order_face_chain(gmtry,ids)
ids = ids(:);
if numel(ids) <= 1
    ordered = ids;
    return
end
ordered = ids(1);
remaining = ids(2:end);
ends = gmtry.fcVx(ids(1),:);
while ~isempty(remaining)
    found = 0;
    atEnd = true;
    for k = 1:numel(remaining)
        iv = gmtry.fcVx(remaining(k),:);
        if any(iv == ends(2))
            found = k;
            atEnd = true;
            break
        elseif any(iv == ends(1))
            found = k;
            atEnd = false;
            break
        end
    end
    if found == 0
        error('WG:BranchedTarget','The selected connected component is branched or cannot be ordered as one polyline.');
    end
    id = remaining(found);
    remaining(found) = [];
    iv = gmtry.fcVx(id,:);
    if atEnd
        ordered(end+1,1) = id;
        if ends(2) == iv(1)
            ends(2) = iv(2);
        else
            ends(2) = iv(1);
        end
    else
        ordered = [id;ordered];
        if ends(1) == iv(1)
            ends(1) = iv(2);
        else
            ends(1) = iv(1);
        end
    end
end
end
