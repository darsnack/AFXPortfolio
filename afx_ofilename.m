function filename = afx_ofilename( effect_name, source_filename, ...
    audio_folder, file_type, parameter_list )
%AFX_OFILENAME Create a descriptive filename for an audio output file
%   Create a descriptive filename for an audio output file. Call the
%   function with these parameters:
%   1. effect name (string)
%   2. source audio file name (string)
%   3. folder name for the audio output file (string)
%   4. type of audio file ('wav', 'ogg', etc.) (string)
%   5. cell array containing any of the following:
%      a. parameter value (numeric or string)
%      b. parameter value and unit (string)
%      c. parameter name (string), value, and unit
%
%
% Example 1: include the name of the parameter:
% y_filename = afx_ofilename('pitchshifter','speech1','c:\audio','ogg',...
%    { {'fshift' 70 'Hz'} {'dir' 'up' ''} })
% produces the string 'c:\audio\pitchshifter_speech1_{fshift=70Hz}{dir=up}.ogg'
%
% Example 2: omit the parameter names:
% y_filename = afx_ofilename('pitchshifter','speech2','c:\audio','ogg',...
%    { {150 'Hz'} {'down' ''} })
% produces the string 'c:\audio\pitchshifter_speech2_{150Hz}{down}.ogg'
%
% Example 3: mix and match:
% y_filename = afx_ofilename('pitchshifter','speech3','c:\audio','ogg',...
%    { {200} {'keep'} {150 'Hz'} {'dir' 'down' ''} {'base' 1 'Hz'}  })
% produces c:\audio\pitchshifter_speech3_{200}{keep}{150Hz}{dir=down}{base=1Hz}.ogg
%

% Build the base name for the file
filename = [audio_folder '\' effect_name '_' source_filename '_'];

% Loop through the parameter list and append to the base name
for k = 1:size(parameter_list,2)
    switch length(parameter_list{k})
        case 1 % single parameter value, either numeric or string
            if isstr(parameter_list{k}{1})
                format_str = '{%s}';
            else
                format_str = '{%g}';
            end
            filename = [filename sprintf(format_str,parameter_list{k}{1})];
        case 2 % parameter value followed by unit (string)
            if isstr(parameter_list{k}{1})
                format_str = '{%s%s}';
            else
                format_str = '{%g%s}';
            end
            filename = [filename sprintf(format_str,parameter_list{k}{1},...
                parameter_list{k}{2})];
        case 3 % parameter name (string), value, and unit 
            if isstr(parameter_list{k}{2})
                format_str = '{%s=%s%s}';
            else
                format_str = '{%s=%g%s}';
            end
            filename = [filename sprintf(format_str,parameter_list{k}{1},...
                parameter_list{k}{2},parameter_list{k}{3})];
        otherwise % empty list or too many
            filename = [filename '{___}'];
    end
end

% Append the file type
filename = [filename '.' file_type];
end

