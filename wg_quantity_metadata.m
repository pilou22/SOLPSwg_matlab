function [label,unit,scale] = wg_quantity_metadata(spec)
label = strrep(spec.field,'_','\_');
unit = 'file units';
scale = 1;
ev = 1.602176634e-19;
switch lower(spec.field)
    case {'ne','na','dab2','dmb2','dib2','pdena','pdenm','pdeni','d_neutral_density','total_atom_density','total_molecule_density','total_test_ion_density'}
        unit = 'm^{-3}';
    case 'te'
        label = 'T_e';
        unit = 'eV';
        scale = 1/ev;
    case 'ti'
        label = 'T_i';
        unit = 'eV';
        scale = 1/ev;
    case 'tn'
        label = 'T_n';
        unit = 'eV';
        scale = 1/ev;
    case {'tab2','tmb2','tib2'}
        unit = 'eV';
        scale = 1/ev;
    case {'ua','uadia','vadia','wadia','vaecrb','veecrb','vedia'}
        unit = 'm s^{-1}';
    case {'po','sig0'}
        unit = 'V';
    case {'edena','edenm','edeni'}
        unit = 'J m^{-3}';
    case {'vxdena','vxdenm','vxdeni','vydena','vydenm','vydeni','vzdena','vzdenm','vzdeni'}
        unit = 'kg s^{-1} m^{-2}';
    case {'rfluxa','rfluxm','pfluxa','pfluxm'}
        unit = 'm^{-2} s^{-1}';
    case 'fna'
        unit = 's^{-1}';
    case {'fhe','fhi','fhn','fhp','fht','fhj','fhe_mdf','fhi_mdf','fhe_eir','fhi_eir','fhepsch','fhipsch'}
        unit = 'W';
    case {'fch','fch_32','fch_52','fch_p'}
        unit = 'A';
    case 'cvvol'
        unit = 'm^{3}';
    case 'fcs'
        unit = 'm^{2}';
end
switch lower(spec.field)
    case {'fna','na','ua','kinrgy'}
        if isnumeric(spec.indices) && isscalar(spec.indices)
            label = sprintf('%s (B2 species %d)',label,spec.indices);
        end
    case {'dab2','tab2','dmb2','tmb2','dib2','tib2','pdena','pdenm','pdeni','edena','edenm','edeni'}
        if isnumeric(spec.indices) && isscalar(spec.indices)
            label = sprintf('%s (EIRENE index %d)',label,spec.indices);
        end
end
if ~isempty(spec.label)
    label = spec.label;
end
if ~isempty(spec.unit)
    unit = spec.unit;
end
end
