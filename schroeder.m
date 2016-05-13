%% AFX -- Schroeder reverb

% References
% http://www.mathworks.com/help/dsp/ref/dsp.sinewave-class.html

% Begin with a clean workspace
clear, close all

%% User Interface
% an array of loop times can be specified
% an appropriate number of comb and all pass filters will be used based on
%  on the array length
loop_times = [29.7 37.1 41.1 43.7]; % loop time (ms) / 30 <= loop_times <= 45 
RT60 = 5; % reverb time (s) / 5 / 1 <= RT60 <= 10

% Results parameters
write_output = false;

% Source audio:
file_name = '22-004 Original Guitar';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\InputAudio';
output_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\OutputAudio';

%% Set up audio file objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder, 'wav'));
ofile_name = afx_ofilename('schroeder', file_name, output_folder, 'wav', ...
                            {{'RT60' RT60 's'}});
audio_writer = dsp.AudioFileWriter(ofile_name, 'SampleRate', audio_reader.SampleRate);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate, ...
                                'ChannelMappingSource', 'Property', ...
                                'ChannelMapping', [1 2]);
audio_player.QueueDuration = 0;

%% Translate user interface parameters
num_filters = length(loop_times);
delay_samples = loop_times / 1000 * audio_reader.SampleRate;
g_comb = 10.^(-3*loop_times / RT60);

delay_ap = zeros(round(num_filters/2));
g_ap = zeros(round(num_filters/2));
for i = 0:round(num_filters/2)-1
    tau = 100e-3 / (3^i);
    reverb_time = 0.005 / (3^i);
    delay_ap(i + 1) = tau * audio_reader.SampleRate;
    g_ap(i + 1) = 10.^(-3 * tau / reverb_time);
end

%% Create the delay line object
delay_lines_c = {};
delay_lines_ap = {};
for i = 1:num_filters
    delay_lines_c{i} = dsp.VariableFractionalDelay;
end
for i = 1:round(num_filters/2)
    delay_lines_ap{i} = dsp.VariableFractionalDelay;
end

%% Read, process, and play the audio
y_comb = zeros(num_filters, audio_reader.SamplesPerFrame, 2);
y_ap = zeros(round(num_filters/2), audio_reader.SamplesPerFrame, 2);
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    
    % Process comb filters
    y = zeros(audio_reader.SamplesPerFrame, 2);
    for i = 1:num_filters
        tmp = reshape(y_comb(i, :, :), audio_reader.SamplesPerFrame, 2);
        delayline_in = x + g_comb(i) * tmp;
        fun = @(a) step(a, delayline_in, delay_samples(i));
        tmp = cell2mat(cellfun(fun, delay_lines_c(i), 'UniformOutput', false));
        y = y + tmp;
        y_comb(i, :, :) = reshape(tmp, 1, audio_reader.SamplesPerFrame, 2);
    end
    
    % Process all pass filters
    for i = 1:round(num_filters/2)
        tmp = reshape(y_ap(i, :, :), audio_reader.SamplesPerFrame, 2);
        delayline_in = y + g_ap(i) * tmp;
        fun = @(a) step(a, delayline_in, delay_ap(i));
        tmp = cell2mat(cellfun(fun, delay_lines_ap(i), 'UniformOutput', false));
        y = (1 - g_ap(i)^2) * tmp - g_ap(i) * x;
        y_ap(i, :, :) = reshape(tmp, 1, audio_reader.SamplesPerFrame, 2);
    end
    
    % Check for clipping
    if (max(abs(y(:))) > 0.02)
        y = y / max(abs(y(:)));
    end
    
    % Listen to the results
    step(audio_player, y);
    
    % Save the results to a file
    if write_output
        step(audio_writer, y);
    end
end

%% Clean up
release(audio_reader);
release(audio_player);
release(audio_writer);