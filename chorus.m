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
g_w = 0.8;
g_d = 1;
LFO_freq_Hz = 0.08; % low-frequency oscillator rate (Hz) / 1Hz / 0.1 to 10Hz
LFO_depth_samples = 1000; % low-frequency oscillator depth (samples) / 5000 / 65536
delay_max_ms = 30; % max delay line length (ms) / 0ms / 0 to 1000ms
                     % (the delay line max length is 65535 samples)

% Source audio:
file_name = '22-004 Original Guitar';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\InputAudio';
output_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\OutputAudio';

%% Create the audio reader, writer, and player objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder, 'wav'));
ofile_name = afx_ofilename('chorus', file_name, output_folder, 'wav', ...
                            {{'freq' LFO_freq_Hz 'Hz'} ...
                            {'delay_max' delay_max_ms 'ms'}});
audio_writer = dsp.AudioFileWriter(ofile_name, 'SampleRate', audio_reader.SampleRate);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate);
audio_player.QueueDuration = 0;

%% Convert the user interface values:
% delay in samples and linear gain
delay_max = (delay_max_ms/1000)*audio_reader.SampleRate;

%% Create the delay line object
audio_delayline = dsp.VariableFractionalDelay;
audio_delayline.MaximumDelay = delay_max;

%% Create the sinewave oscillators
LFO = dsp.SineWave(0.5, LFO_freq_Hz);
LFO.SampleRate = audio_reader.SampleRate;
LFO.SamplesPerFrame = audio_reader.SamplesPerFrame;

%% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    
    % Get the next low-frequency oscillator output frame
    lfo = (step(LFO)+0.5)*LFO_depth_samples;
    
    % Retrieve the next frame from the delay line;
    % insert a new frame, too;
    delayline_out = step(audio_delayline, x, lfo);
    
    % Generate the output
    y = g_w .* delayline_out + g_d .* x;
    
    % Listen to the results
    step(audio_player, y);
    
    % Save the results to a file
    step(audio_writer, y);
end


%% Clean up
release(audio_reader);
release(audio_player);

% All done!
