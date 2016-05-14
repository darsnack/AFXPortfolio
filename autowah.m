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
LFO_freq_Hz =10; %/10 % low-frequency oscillator rate (Hz) / 1Hz / 0.1 to 10Hz 
LFO2Freq=2;
LFO_depth_samples = 1000; % low-frequency oscillator depth (samples) / 5000 / 65536
delay_max_ms = 5; % max delay line length (ms) / 0ms / 0 to 1000ms
                     % (the delay line max length is 65535 samples)

% Source audio:
file_name = '22-004 Original Guitar';
audio_folder = 'C:\Users\Jacques\Documents\AFX\AFXPortfolio\InputAudio';
output_folder = 'C:\Users\Jacques\Documents\AFX\AFXPortfolio\OutputAudio';

% Create the audio reader and player objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder,'wav'),'SamplesPerFrame',2048);

ofile_name = afx_ofilename('WahWah', file_name, output_folder, 'wav', ...
                            {{'freq' LFO_freq_Hz 'Hz'} ...
                            {'delay_max' delay_max_ms 'ms'}...
                            {'LOfreq' LFO2Freq 'Hz'}});
audio_writer = dsp.AudioFileWriter(ofile_name,'SampleRate',audio_reader.SampleRate);

audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate,'ChannelMappingSource','Property','ChannelMapping',[1 2]);
audio_player.QueueDuration = 0;

% Convert the user interface values:
% delay in samples and linear gain

% Create the delay line object
% Create the sinewave oscillators
MaxF=4000; %high wah frequency
MinF=500;   %Low wah frequency
Maxuse=2*MaxF/audio_reader.SampleRate;
Minuse=2*MinF/audio_reader.SampleRate;

LFO = dsp.SineWave((Maxuse-Minuse)/2,LFO_freq_Hz);
LFO.SamplesPerFrame = 1;

LFO2 = dsp.SineWave(1,LFO2Freq);
LFO2.SamplesPerFrame = 1;

% Read, process, and play the audio
while ~isDone(audio_reader)
    % Retrieve the next audio frame from the file 
    
    
    x = step(audio_reader);
         
    
    xl=100*x(:,1);
    xr=100*x(:,2);
    
%     if max(abs(xl),[],1)<40
%     freq=-max(abs(xl),[],1)/40*(Maxuse-Minuse)/2;
%     else 
%     freq=(Maxuse-Minuse)/2;
%     end
   
    ch=step(LFO2)*step(LFO)+(Maxuse+Minuse)/2;
    
    [b,a] = butter(2,ch);
    yl=filter(b,a,xl);
    yr=filter(b,a,xr);
    
    % Listen to the results
    y=[yl/100 yr/100];
    step(audio_player, y);
    step(audio_writer, y);

end

% Clean up
release(audio_writer);
release(audio_reader);
release(audio_player);

% All done!
