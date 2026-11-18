function ids = wg_target_cell_ids(gmtry,faces,side)
neighbors = gmtry.fcCv(faces,:);
ids = neighbors(:,1);
switch lower(side)
    case {'physical','interior','auto'}
        for k = 1:numel(faces)
            internal = neighbors(k,:) <= gmtry.nCi;
            if any(internal)
                ids(k) = neighbors(k,find(internal,1));
            end
        end
    case 'guard'
        for k = 1:numel(faces)
            guard = neighbors(k,:) > gmtry.nCi;
            if any(guard)
                ids(k) = neighbors(k,find(guard,1));
            end
        end
    case 'first'
    case 'second'
        ids = neighbors(:,2);
    otherwise
        error('WG:TargetSide','targetCellSide must be physical, guard, first, or second.');
end
end
