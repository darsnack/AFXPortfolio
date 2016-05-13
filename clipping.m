%% AFX -- Soft-clipping effect
%
% References:
% http://www.mathworks.com/help/dsp/systemobjectslist.html
%

% Begin with a clean workspace
clear, close all

%% User interface:

% Effect parameters with suggested initial value and typical range:
pre_gain = 30; % gain applied before nonlinear effects (dB) / 30 / 0 < g
soft_clipping = false; % choose between soft or hard clipping / true / true || false

% Results parameters
plot_output = false;
write_output = true;

% Source audio:
file_name = '22-001 Original Vocal';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\InputAudio';
output_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\OutputAudio';

%% Create the audio reader, writer, and player objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder, 'wav'));
ofile_name = afx_ofilename('clipping', file_name, output_folder, 'wav', ...
                            {{'pre-gain' pre_gain ''}, ...
                            {'soft-clipping' soft_clipping ''}});
audio_writer = dsp.AudioFileWriter(ofile_name, 'SampleRate', audio_reader.SampleRate);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate);
audio_player.QueueDuration = 0;

%% Convert user parameters
g = 10^(pre_gain / 20);

%% Read, process, and play the audio
t = 0:audio_reader.SamplesPerFrame-1;
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    
    % Generate the output
    if soft_clipping
        y = sign(x) .* (1 - exp(-abs(g*x)));
    else
        G = g*x;
        idx = find(G <= -1);
        G(idx) = -1;
        idx = find(G >= 1);
        G(idx) = 1;
        
        y = G;
    end
    
    % Listen to the results
    step(audio_player, y);
    
    % Plot the results
    if plot_output
        plot(t, y(:, 1), 'r', t, x(:, 1), 'b'); drawnow;
    end
    
    % Save the results to a file
    if write_output
        step(audio_writer, y);
    end
end


%% Clean up
release(audio_reader);
release(audio_player);
release(audio_writer);

% All done!
