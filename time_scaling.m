%% AFX -- Phaser effect

% References
% http://www.mathworks.com/help/dsp/ref/dsp.sinewave-class.html

% Begin with a clean workspace
clear, close all

%% User Interface
% Phaser parameters:
scale_factor = 1.5;

% STFT parameters:
frame_size = 20; % Frame size (ms) / 20 / 1 <= frame_size <= 1000
hop_factor = 1/8; % hop factor or overlap amount / 1/2 / 1/1 <= hop_factor <= 1/16

% Source audio:
enable_noise = false;
file_name = '22-001 Original Vocal';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\InputAudio';
output_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\OutputAudio';

%% Set up audio file objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder, 'wav'));
ofile_name = afx_ofilename('time-scaling', file_name, output_folder, 'wav', ...
                            {{'scale_factor' scale_factor ''}});
audio_writer = dsp.AudioFileWriter(ofile_name, 'SampleRate', audio_reader.SampleRate);
audio_player = dsp.AudioPlayer('SampleRate', scale_factor * audio_reader.SampleRate, ...
                                'ChannelMappingSource', 'Property', ...
                                'ChannelMapping', [1 2]);
audio_player.QueueDuration = 0;

%% STFT Setup
% Force the frame size to be a power of two and ensure that hop size is an
% integer
frame_size_N = 2^nextpow2((frame_size/1000)*audio_reader.SampleRate);
h_a = round(frame_size_N * hop_factor);
h_s = scale_factor * h_a;
audio_reader.SamplesPerFrame = h_a;

% Create the buffer to read the source audio as overlapped frames
xbuffer = dsp.Buffer(frame_size_N,frame_size_N-h_a);

% Create the windowing object
xwin = dsp.Window('Hanning','Sampling','Periodic');
ywin = dsp.Window('Hanning','Sampling','Periodic');

% Obtain the window weights
xwin.WeightsOutputPort = true;
[xfw,w] = step(xwin,zeros(frame_size_N,audio_reader.info.NumChannels));

% Compute the COLA-criterion gain
cola_gain = (sum(w)/frame_size_N)/hop_factor;
reset(xwin)

% Obtain the window weights
ywin.WeightsOutputPort = true;
[yfw,w] = step(ywin,zeros(frame_size_N,audio_reader.info.NumChannels));
reset(ywin)

% Create the FFT and IFFT objects
xfft = dsp.FFT;
yifft = dsp.IFFT('ConjugateSymmetricInput',true,'Normalize',true);

ysink = dsp.SignalSink;

%% Set up filter
omega_ha = (2 * pi * h_a / frame_size_N) * (0:frame_size_N - 1)';
omega_ha(:, 2) = omega_ha;

%% Read, process, play, and write the audio
firstpass = true;
Xm0 = zeros(frame_size_N, 2);
Xp0 = zeros(frame_size_N, 2);
Yp = zeros(frame_size_N, 2);
while ~isDone(audio_reader)
    % Retrieve the next input audio frame
    x = step(audio_reader);
    
    % Insert audio frame into buffer, and read overlapped frame
    xf = step(xbuffer,x);
    
    % Apply the analysis window
    xfw = step(xwin,xf);
    
    % Compute the FFT of the windowed frame
    X = step(xfft,xfw);
    
    % Convert to polar form (magnitude and phase)
    Xm = abs(X);
    Xp = angle(X);
    
    % Apply effect
    Ym = Xm;
    Xdp = omega_ha + afx_princarg(Xp - Xp0 - omega_ha);
    Yp = afx_princarg(Yp + Xdp * scale_factor);
    Y = Ym .* exp(1i*Yp);
    Xp0 = Xp;
    
    % Compute the IFFT of the windowed result
    yfw = step(yifft, Y);
    y = step(ywin, yfw);
    
    % Accumulate the overlappping region into the overlap/add buffer;
    % initialize the output overlap/add buffer to zero on the first loop pass
    if firstpass
        yolabuffer = y/cola_gain;
    else
        yolabuffer = yolabuffer + (y/cola_gain);
    end
    
    % Store to sink
    step(ysink,yolabuffer(1:h_s,:));
    
    yolabuffer(1:frame_size_N-h_a,:) = yolabuffer(h_a+1:frame_size_N,:);
    yolabuffer(frame_size_N-h_a+1:frame_size_N,:) = 0;
    
    firstpass = false;
end

yc = ysink.Buffer;
ap = audioplayer(yc,scale_factor*audio_reader.SampleRate);
play(ap)
disp('Enter pause(ap), resume(ap), stop(ap), or play(ap)');