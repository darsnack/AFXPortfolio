%% AFX -- Panoramic effect

% References
% http://www.mathworks.com/help/dsp/ref/dsp.sinewave-class.html

% Begin with a clean workspace
clear, close all

%% User Interface
f_LFO = 0.1; % LFO frequency for panning (Hz) / 1 / 0.1 <= f_LFO <= 10

% Results parameters
write_output = false;

% Source audio:
file_name = '22-004 Original Guitar';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\InputAudio';
output_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\OutputAudio';

%% Set up audio file objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder, 'wav'));
ofile_name = afx_ofilename('panorama', file_name, output_folder, 'wav', ...
                            {{'f_LFO' f_LFO 'Hz'}});
audio_writer = dsp.AudioFileWriter(ofile_name, 'SampleRate', audio_reader.SampleRate);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate, ...
                                'ChannelMappingSource', 'Property', ...
                                'ChannelMapping', [1 2]);
audio_player.QueueDuration = 0;

%% Create the sinewave oscillators
LFO = dsp.SineWave(45, f_LFO);
LFO.SampleRate = audio_reader.SampleRate;
LFO.SamplesPerFrame = audio_reader.SamplesPerFrame;

%% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    
    % Get the next low-frequency oscillator output frame
    phi = step(LFO);
    phi = phi(1);
    phi = phi * pi / 180;
    
    % Generate gains
    g_L = cos(phi + pi/4);
    g_R = cos(phi - pi/4);
    
    % Generate the output
    y(:, 1) = g_L * x(:, 1);
    y(:, 2) = g_R * x(:, 2);
    
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