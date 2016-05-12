function pv_of_phi = afx_princarg( phi )
%princArg Principal argument
%   Detailed explanation goes here

pv_of_phi = phi - round(phi/(2*pi))*2*pi; % dspPhaseVododer.m
%pv_of_phi = mod(phi+pi,-2*pi)+pi; % DAFX p. 241

end

