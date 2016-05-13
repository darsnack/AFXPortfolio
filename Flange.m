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
LFO_freq_Hz = 1; % low-frequency oscillator rate (Hz) / 1Hz / 0.1 to 10Hz
LFO_depth_samples = 100; % low-frequency oscillator depth (samples) / 5000 / 65536
delay_max_ms = 4; % max delay line length (ms) / 0ms / 0 to 1000ms
                  % (the delay line max length is 65535 samples)

% Source audio:
file_name = '22-004 Original Guitar';
audio_folder = 'C:\Users\Jacques\Documents\AFX\AFXPortfolio\InputAudio';
output_folder = 'C:\Users\Jacques\Documents\AFX\AFXPortfolio\OutputAudio';

% Create the audio reader and player objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder,'wav'));

ofile_name = afx_ofilename('flange', file_name, output_folder, 'wav', ...
                            {{'freq' LFO_freq_Hz 'Hz'} ...
                            {'delay_max' delay_max_ms 'ms'}});
audio_writer = dsp.AudioFileWriter(ofile_name,'SampleRate',audio_reader.SampleRate);

audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate,'ChannelMappingSource','Property','ChannelMapping',[1 2]);
audio_player.QueueDuration = 0;

% Convert the user interface values:
% delay in samples and linear gain
delay_max = round((delay_max_ms/1000)*audio_reader.SampleRate);

% Create the delay line object
audio_delayline = dsp.VariableIntegerDelay;
audio_delayline = dsp.VariableFractionalDelay;
audio_delayline.MaximumDelay = delay_max;

audio_delayline2 = dsp.VariableIntegerDelay;
audio_delayline2 = dsp.VariableFractionalDelay;
audio_delayline2.MaximumDelay = delay_max;

% Create the sinewave oscillators

LFO = dsp.SineWave(0.5,LFO_freq_Hz);
LFO.SampleRate = audio_reader.SampleRate;
LFO.SamplesPerFrame = audio_reader.SamplesPerFrame;

LFO2 = dsp.SineWave(0.5,LFO_freq_Hz);
LFO2.PhaseOffset=0;
LFO2.SampleRate = audio_reader.SampleRate;
LFO2.SamplesPerFrame = audio_reader.SamplesPerFrame;

GainW=0.8;
GainD=1;


% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file
    x = step(audio_reader);
    xl=x(:,1);
    xr=x(:,2);
    
    % Get the next low-frequency oscillator output frame
    lfo = (step(LFO)+0.5)*LFO_depth_samples;
    lfo2 = (step(LFO2)+0.5)*LFO_depth_samples;
    
    
    % Retrieve the next frame from the delay line;
    % insert a new frame, too;
    delayline_out = step(audio_delayline, xl, lfo);
    delayline_out2 = step(audio_delayline2, xr, lfo2);
    
    % Generate the output
    yl = (delayline_out*GainW+xl*GainD)*0.6;
    yr = (delayline_out2*GainW+xr*GainD)*0.6;
    
    % Listen to the results
    y=[yl yr];
    step(audio_player, y);
   step(audio_writer, y);

end

% Clean up
release(audio_writer);
release(audio_reader);
release(audio_player);

% All done!
