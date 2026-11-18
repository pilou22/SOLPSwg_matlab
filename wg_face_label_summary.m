function summary = wg_face_label_summary(gmtry)
labels = unique(gmtry.fcLbl(gmtry.fcLbl ~= 0));
summary = struct([]);
ivAll = gmtry.fcVx;
R = gmtry.vxX;
Z = gmtry.vxY;
for k = 1:numel(labels)
    ids = find(gmtry.fcLbl == labels(k));
    components = wg_face_components(gmtry,ids);
    iv = ivAll(ids,:);
    summary(k).label = labels(k);
    summary(k).faces = ids;
    summary(k).components = components;
    summary(k).extent = [min(R(iv(:))),max(R(iv(:))),min(Z(iv(:))),max(Z(iv(:)))];
end
end
