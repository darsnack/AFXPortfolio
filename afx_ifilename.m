function filename = afx_ifilename(source_filename,audio_folder,file_type)
%AFX_IFILENAME Create a full filename for an audio input file
%   Create a full filename for an audio input file. Call the
%   function with these parameters:
%   1. source audio file name (string)
%   2. folder name for the audio input file (string)
%   3. type of audio file ('wav', 'ogg', etc.) (string)
%
%
% Example:
% x_filename = afx_ifilename('speech1','c:\audio','wav')
% produces the string 'c:\audio\speech1.wav'
%

% Create the filename
filename = [audio_folder '\' source_filename '.' file_type];

end

