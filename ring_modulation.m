%% AFX -- Ring modulation

% References
% http://www.mathworks.com/help/dsp/ref/dsp.variablefractionaldelay-class.html
% http://www.mathworks.com/help/dsp/ref/dsp.sinewave-class.html

% Begin with a clean workspace
clear, close all

%% User interface:

% Effect parameters with suggested initial value and typical range:
gain = 1;
LFO_freq_Hz = 250; % low-frequency oscillator rate (Hz) / 30Hz / 10Hz to 1kHz
alpha = 0.8; % low-frequency oscillator depth

% Source audio:
file_name = 'Mixing Audio Textbook Samples\22 Other Modulation Tools\22-015 Original Bass.wav';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\Samples';

%% Create the audio reader and player objects
audio_reader = dsp.AudioFileReader([audio_folder '\' file_name]);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate, ...
                                'ChannelMappingSource', 'Property', ...
                                'ChannelMapping', [1 2]);
audio_player.QueueDuration = 0;

%% Create the sinewave oscillators
LFO = dsp.SineWave(alpha, LFO_freq_Hz);
LFO.PhaseOffset = pi/2;
LFO.SampleRate = audio_reader.SampleRate;
LFO.SamplesPerFrame = audio_reader.SamplesPerFrame;

%% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    
    % Get the next low-frequency oscillator output frame
    m = 1 - alpha + step(LFO);
    
    % Generate the output
    y_left = (gain / 2) .* (m .* x(:, 1));
    y_right = (gain / 2) .* (m .* x(:, 2));
    y = [y_left y_right];
    
    % Listen to the results
    step(audio_player, y);
end


%% Clean up
release(audio_reader);
release(audio_player);

% All done!