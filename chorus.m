%% AFX -- Chorus effect
%
% References:
% http://www.mathworks.com/help/dsp/ref/dsp.variableintegerdelay-class.html
% http://www.mathworks.com/help/dsp/ref/dsp.variablefractionaldelay-class.html
% http://www.mathworks.com/help/dsp/ref/dsp.sinewave-class.html
% http://www.mathworks.com/help/dsp/systemobjectslist.html
%

% Begin with a clean workspace
clear, close all

%% User interface:

% Effect parameters with suggested initial value and typical range:
g_w = 0.5;
LFO_freq_Hz = 0.05; % low-frequency oscillator rate (Hz) / 1Hz / 0.1 to 10Hz
LFO_depth_samples = 1000; % low-frequency oscillator depth (samples) / 5000 / 65536
delay_max_ms = 20; % max delay line length (ms) / 0ms / 0 to 1000ms
                     % (the delay line max length is 65535 samples)

% Source audio:
file_name = 'Mixing Audio Textbook Samples\22 Other Modulation Tools\22-011 Chorus 1 (Guitar).wav';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\Samples';

%% Create the audio reader and player objects
audio_reader = dsp.AudioFileReader([audio_folder '\' file_name]);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate);
audio_player.QueueDuration = 0;

%% Convert the user interface values:
% delay in samples and linear gain
delay_max = (delay_max_ms/1000)*audio_reader.SampleRate;

%% Create the delay line object
audio_delayline = dsp.VariableFractionalDelay;
audio_delayline.MaximumDelay = delay_max;

%% Create the sinewave oscillators
LFO = dsp.SineWave(0.5,LFO_freq_Hz);
LFO.SampleRate = audio_reader.SampleRate;
LFO.SamplesPerFrame = audio_reader.SamplesPerFrame;

%% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    
    % Uncommment this line to use the 440-Hz test tone instead
    % x = step(test_tone);
    
    % Get the next low-frequency oscillator output frame
    lfo = (step(LFO)+0.5)*LFO_depth_samples;
    
    % Retrieve the next frame from the delay line;
    % insert a new frame, too;
    delayline_out = step(audio_delayline, x, lfo);
    
    % Generate the output
    y = g_w .* delayline_out + x;
    
    % Listen to the results
    step(audio_player, y);

end


%% Clean up
release(audio_reader);
release(audio_player);

% All done!
