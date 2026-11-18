function [run,profile] = wg_set_line_coordinate(run,profile,p)
switch lower(p.profileX)
    case 'r'
        profile.x = profile.R;
        profile.xlabel = 'R [m]';
    case 'z'
        profile.x = profile.Z;
        profile.xlabel = 'Z [m]';
    case 's'
        profile.x = profile.s;
        profile.xlabel = 's from (R_1,Z_1) [m]';
    case {'drsep','drsepupstream'}
        [profile.x,profile.upstreamMapping] = wg_map_drsep(run,p,profile.R,profile.Z,[]);
        profile.xlabel = '\Delta r_{sep}^{upstream} [m]';
    case 'auto'
        e = profile.endpoints;
        profile.x = profile.s;
        profile.xlabel = 's from (R_1,Z_1) [m]';
        if abs(e(4)-e(2)) < 10*eps(max(1,abs(e([2,4]))))
            profile.x = profile.R;
            profile.xlabel = 'R [m]';
        elseif abs(e(3)-e(1)) < 10*eps(max(1,abs(e([1,3]))))
            profile.x = profile.Z;
            profile.xlabel = 'Z [m]';
        end
    otherwise
        error('WG:ProfileX','profileX must be auto, s, R, Z, or drsep for a line profile.');
end
for k = 1:numel(profile.parts)
    profile.parts(k).x = profile.x;
end
end
