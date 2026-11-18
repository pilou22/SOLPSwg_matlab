function [found,values,location] = wg_derived_quantity(~,data,spec)
found = true;
location = 'cell';
if strcmp(spec.source,'ft44')
    switch lower(spec.field)
        case 'd_neutral_density'
            values = data.dab2(:,1,1) + data.dmb2(:,1,1);
            return
        case 'total_atom_density'
            values = sum(data.dab2,3);
            return
        case 'total_molecule_density'
            values = sum(data.dmb2,3);
            return
        case 'total_test_ion_density'
            values = sum(data.dib2,3);
            return
    end
end
found = false;
values = [];
location = '';
end
