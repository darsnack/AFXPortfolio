%% AFX -- Day 5-2 - Short-time Fourier transform
%
% Apply the short-time Fourier transform in both the forward and
% inverse directions. Look for the "begin-end processing" zone to
% create various effects by modifying the magnitude and/or phase.
%

% Begin with a clean workspace
clear

% Name of this effect
effect_name = 'FreqBinShift';
write_audio = true;

%% User interface:

% Effect parameters with suggested initial value and typical range:
frame_size_ms = 20; % frame size in ms / 20ms / 1ms to 1000ms or higher
hop_factor = 1/4; % hop factor (overlap amount) / 1/2 / 1/1 to 1/16 or more

% Options:
use_test_tone = false;
test_tone_freq_bin = 4.00;
plot_complete_output = false;
listen_to_complete_output = false;
plot_cola_error = false;

shiftfactor=-5;

% Audio files -- x = input, y = output:
x_name = '22-001 Original Vocal';
x_type = 'wav';
y_type = 'wav';
audio_folder = 'C:\Users\Jacques\Documents\AFX\AFXPortfolio\InputAudio';
audio_folder_out = 'C:\Users\Jacques\Documents\AFX\AFXPortfolio\OutputAudio';


%% Create the input/output file names
x_filename = afx_ifilename(x_name,audio_folder,x_type);
if write_audio
    y_filename = afx_ofilename(effect_name,x_name,audio_folder_out,y_type,{...
        {'N' frame_size_ms 'ms'} ...
        {'h' hop_factor ''}...
        {'s' shiftfactor ''} ...
        });
end

%% Create the audio reader, player, and writer objects
audio_reader = dsp.AudioFileReader(x_filename);

% Force the frame size to be a power of two and ensure that hop size is an
% integer
frame_size_N = 2^nextpow2((frame_size_ms/1000)*audio_reader.SampleRate);
hop_size = round(frame_size_N * hop_factor);

audio_reader.SamplesPerFrame = hop_size;
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate);
audio_player.QueueDuration = 0; % 0 useful for short clips; 1 is default
if write_audio
    audio_writer = dsp.AudioFileWriter(y_filename);
    audio_writer.SampleRate = audio_reader.SampleRate;
    audio_writer.FileFormat = y_type;
end

%% Create a test tone generator
if use_test_tone
    test_tone = dsp.SineWave;
    test_tone.PhaseOffset = pi/2;
    test_tone.Frequency = (test_tone_freq_bin/frame_size_N)*audio_reader.SampleRate;
    test_tone.SampleRate = audio_reader.SampleRate;
    test_tone.SamplesPerFrame = audio_reader.SamplesPerFrame;
end

%% Create the buffer to read the source audio as overlapped frames
xbuffer = dsp.Buffer(frame_size_N,frame_size_N-hop_size);

%% Create the windowing object
xwin = dsp.Window('Hanning','Sampling','Periodic');

% Obtain the window weights
xwin.WeightsOutputPort = true;
[xfw,w] = step(xwin,zeros(frame_size_N,audio_reader.info.NumChannels));

% Compute the COLA-criterion gain
cola_gain = (sum(w)/frame_size_N)/hop_factor;
reset(xwin)

%% Create the FFT and IFFT objects
xfft = dsp.FFT;
yifft = dsp.IFFT('ConjugateSymmetricInput',true,'Normalize',true);

%% Create sinks for the input and output
ysink = dsp.SignalSink;
if plot_cola_error xsink = dsp.SignalSink; end

%% Initialize variables before the main loop
firstpass = true;



%% Read, process, play, and write the audio
while ~isDone(audio_reader)
    
    % Retrieve the next input audio frame
    x = step(audio_reader);
    if use_test_tone
        x = step(test_tone);
    end
    
    % Save the input signal to the sink array, if requested
    if plot_cola_error, step(xsink,x), end
    
    % Insert audio frame into buffer, and read overlapped frame
    xf = step(xbuffer,x);
    
    % Apply the analysis window
    xfw = step(xwin,xf);
    arraysize=size(xfw,1);    
    % Compute the FFT of the windowed frame
    X = step(xfft,xfw);
    
    % Convert to polar form (magnitude and phase)
    Xm = fftshift(abs(X));
    Xp = fftshift(angle(X));   
    
    % ----- Begin processing:
    % ---
       
    % -
    Xm1=Xm(1:(arraysize/2),:);
    Xm2=Xm((arraysize/2+1):arraysize,:);
    Xp1=Xp(1:(arraysize/2),:);
    Xp2=Xp((arraysize/2+1):arraysize,:);
    
    % transparent pass-through; useful for COLA check
    Ym = [circshift(Xm1,-shiftfactor);circshift(Xm2,shiftfactor)];
    Yp = [circshift(Xp1,-shiftfactor);circshift(Xp2,shiftfactor)];
    
    % -
    % ---
    % ----- end processing.
    
    % Reassemble the output magnitude/phase as a complex value
    Y = fftshift(Ym) .* exp(j*fftshift(Yp));
   
    % Compute the IFFT of the processed frame
    y = step(yifft,Y);
    
    % Optional: study the time-domain and/or frequency-domain signals
    %range = 1:8;
    % range = 251:256;
    %[Xm(range) Xp(range)]
    %plot(x), stem(Xm)
    
    % Accumulate the overlappping region into the overlap/add buffer;
    % initialize the output overlap/add buffer to zero on the first loop pass
    if firstpass
        yolabuffer = y/cola_gain;
      else
        yolabuffer = yolabuffer + (y/cola_gain);
    end
    
    % Save the completed portion of overlap/add buffer; listen, too,
    % and optionally write to the file
    step(ysink,yolabuffer(1:hop_size,:));
    step(audio_player,yolabuffer(1:hop_size,:));
    if write_audio step(audio_writer,yolabuffer(1:hop_size,:)); end
    
    % Left-shift the overlap/add buffer, filling right side with zeros
    yolabuffer(1:frame_size_N-hop_size,:) = ...
        yolabuffer(hop_size+1:frame_size_N,:);
    yolabuffer(frame_size_N-hop_size+1:frame_size_N,:) = 0;
    
    % Accumulate the overlappping region into the overlap/add buffer
    %yolabuffer = yolabuffer + (y/cola_gain);
    
    % No longer the first pass through the loop
    firstpass = false;
   
    
end

%% Look at the complete output signal
if plot_complete_output
    yc = ysink.Buffer;
    plot(yc), title('complete output signal')
end

%% Listen to finished result
if listen_to_complete_output
    yc = ysink.Buffer;
    ap = audioplayer(yc,audio_reader.SampleRate);
    play(ap)
    disp('Enter pause(ap), resume(ap), stop(ap), or play(ap)');
end

%% Plot the difference between the output and the input;
% NOTE: The circular shift on the input array accounts for the
% one-hop delay caused by the dsp.Buffer element
if plot_cola_error
    xc = xsink.Buffer;
    yc = ysink.Buffer;
    plot(yc-circshift(xc,hop_size)), title('difference between output and input')
    %plot(circshift(xc,hop_size)), hold on, plot(yc), hold off
end

%% Clean up
release(audio_reader);
release(audio_player);
if write_audio release(audio_writer); end

% All done!
