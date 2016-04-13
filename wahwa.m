% AFX -- Figure 2.5 - Modulated delay line length
%
% Use either the variable integer delay or the variable fractional delay.
% When using an integer-delay delay line can clearly hear the "zipper noise"
% mentioned on p.26 of the AFX textbook.
%
% References:
% http://www.mathworks.com/help/dsp/ref/dsp.variableintegerdelay-class.html
% http://www.mathworks.com/help/dsp/ref/dsp.variablefractionaldelay-class.html
% http://www.mathworks.com/help/dsp/ref/dsp.sinewave-class.html
% http://www.mathworks.com/help/dsp/systemobjectslist.html
%

% Begin with a clean workspace
clear, close all

% User interface:

% Effect parameters with suggested initial value and typical range:
LFO_freq_Hz =0.3; % low-frequency oscillator rate (Hz) / 1Hz / 0.1 to 10Hz
LFO_depth_samples = 1000; % low-frequency oscillator depth (samples) / 5000 / 65536
delay_max_ms = 4; % max delay line length (ms) / 0ms / 0 to 1000ms
                     % (the delay line max length is 65535 samples)

% Source audio:
file_name = '22-004 Original Guitar.wav';
audio_folder = 'C:\Users\Jacques\Documents\AFX\Mixing Audio Textbook Samples\22 Other modulation tools';

% Create the audio reader and player objects
audio_reader = dsp.AudioFileReader([audio_folder '\' file_name],'SamplesPerFrame',1024);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate,'ChannelMappingSource','Property','ChannelMapping',[1 2]);
audio_player.QueueDuration = 0;

% Convert the user interface values:
% delay in samples and linear gain

% Create the delay line object
% Create the sinewave oscillators

LFO = dsp.SineWave(0.02,10);

% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    xl=x(:,1);
    xr=x(:,2);
    
    ch=step(LFO)+0.05;
    
    [b,a] = butter(6,ch);
    yl=filter(b,a,xl);
    yr=filter(b,a,xr);
    
    % Listen to the results
    y=[yl yr];
    step(audio_player, y);

end

% Clean up
release(audio_reader);
release(audio_player);

% All done!
