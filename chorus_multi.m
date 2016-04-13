%% AFX -- Chorus effect (multivoice)
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
g_w1 = 0.8;
g_w2 = 0.8;
g_w3 = 0.8;
g_w4 = 0.8;
g_d = 1;
LFO_freq_Hz = 0.08; % low-frequency oscillator rate (Hz) / 1Hz / 0.1 to 10Hz
LFO_depth_samples = 1000; % low-frequency oscillator depth (samples) / 5000 / 65536
delay_max_ms = 30; % max delay line length (ms) / 0ms / 0 to 1000ms
                     % (the delay line max length is 65535 samples)

% Source audio:
file_name = 'Mixing Audio Textbook Samples\22 Other Modulation Tools\22-004 Original Guitar.wav';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\Samples';

%% Create the audio reader and player objects
audio_reader = dsp.AudioFileReader([audio_folder '\' file_name]);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate, ...
                                'ChannelMappingSource', 'Property', ...
                                'ChannelMapping', [1 2]);
audio_player.QueueDuration = 0;

%% Convert the user interface values:
% delay in samples and linear gain
delay_max = (delay_max_ms/1000)*audio_reader.SampleRate;

%% Create the delay line object
audio_delayline1 = dsp.VariableFractionalDelay;
audio_delayline1.MaximumDelay = delay_max;

audio_delayline2 = dsp.VariableFractionalDelay;
audio_delayline2.MaximumDelay = delay_max;

audio_delayline3 = dsp.VariableFractionalDelay;
audio_delayline3.MaximumDelay = delay_max;

audio_delayline4 = dsp.VariableFractionalDelay;
audio_delayline4.MaximumDelay = delay_max;

%% Create the sinewave oscillators
LFO1 = dsp.SineWave(0.5, LFO_freq_Hz);
LFO1.SampleRate = audio_reader.SampleRate;
LFO1.SamplesPerFrame = audio_reader.SamplesPerFrame;

LFO2 = dsp.SineWave(0.5, LFO_freq_Hz);
LFO2.PhaseOffset = pi/4;
LFO2.SampleRate = audio_reader.SampleRate;
LFO2.SamplesPerFrame = audio_reader.SamplesPerFrame;

LFO3 = dsp.SineWave(0.5, LFO_freq_Hz);
LFO3.PhaseOffset = pi/2;
LFO3.SampleRate = audio_reader.SampleRate;
LFO3.SamplesPerFrame = audio_reader.SamplesPerFrame;

LFO4 = dsp.SineWave(0.5, LFO_freq_Hz);
LFO4.PhaseOffset = 3*pi/4;
LFO4.SampleRate = audio_reader.SampleRate;
LFO4.SamplesPerFrame = audio_reader.SamplesPerFrame;

%% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    x_left = x(:, 1);
    x_right = x(:, 2);
    
    % Get the next low-frequency oscillator output frame
    lfo1 = (step(LFO1) + 0.5) * LFO_depth_samples;
    lfo2 = (step(LFO2) + 0.5) * LFO_depth_samples;
    lfo3 = (step(LFO3) + 0.5) * LFO_depth_samples;
    lfo4 = (step(LFO4) + 0.5) * LFO_depth_samples;
    
    % Retrieve the next frame from the delay line;
    % insert a new frame, too;
    delayline_out1 = step(audio_delayline1, x_left, lfo1);
    delayline_out2 = step(audio_delayline2, x_left, lfo2);
    delayline_out3 = step(audio_delayline3, x_right, lfo3);
    delayline_out4 = step(audio_delayline4, x_right, lfo4);
    
    % Generate the output
    y_left = g_w1 .* delayline_out1 + ...
        g_w2 .* delayline_out2 + ...
        (g_d / 2) .* x_left;
    y_right = g_w3 .* delayline_out3 + ...
        g_w4 .* delayline_out4 + ...
        (g_d / 2) .* x_right;
    y = [y_left, y_right];
    
    % Listen to the results
    step(audio_player, y);

end


%% Clean up
release(audio_reader);
release(audio_player);

% All done!
