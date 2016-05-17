%% AFX -- Phaser effect

% References
% http://www.mathworks.com/help/dsp/ref/dsp.sinewave-class.html

% Begin with a clean workspace
clear, close all

%% User Interface
% Phaser parameters:
depth = 1; % Adjust mix-in level of audio effect (0 for original audio
           % 1 for equal gain split) / 1 / 0 <= depth <= 1
fc_min = 200; % Minimum center frequency (Hz) / 1000 / 500 <= fc_min <= 4000
fc_max = 4000; % Maximum center frequency (Hz) / 3000 / 1000 <= fc_max <= 5000
g_fb = 0.5; % Feedback gain / 0.5 / 0 <= g_fb < 1
f_LFO = 0.2; % LFO frequency or effect rate / 1 / 0.01 <= f_LFO <= 10

% STFT parameters:
frame_size = 20; % Frame size (ms) / 20 / 1 <= frame_size <= 1000
hop_factor = 1/4; % hop factor or overlap amount / 1/2 / 1/1 <= hop_factor <= 1/16

% Results parameters
write_output = true;

% Source audio:
enable_noise = false;
file_name = '11-014 Guitar Src';
audio_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\InputAudio';
output_folder = 'D:\Users\Kyle\Documents\Courses\AFX\AFXPortfolio\OutputAudio';

%% Set up audio file objects
audio_reader = dsp.AudioFileReader(afx_ifilename(file_name, audio_folder, 'wav'));
ofile_name = afx_ofilename('phaser', file_name, output_folder, 'wav', ...
                            {{'depth' depth ''} ...
                            {'fc_min' fc_min 'Hz'} ...
                            {'fc_max' fc_max 'Hz'} ...
                            {'f_LFO' f_LFO 'Hz'}});
audio_writer = dsp.AudioFileWriter(ofile_name, 'SampleRate', audio_reader.SampleRate);
audio_player = dsp.AudioPlayer('SampleRate', audio_reader.SampleRate, ...
                                'ChannelMappingSource', 'Property', ...
                                'ChannelMapping', [1 2]);
audio_player.QueueDuration = 0;

%% LFO Setup
% Create a triangle wave
% f_LFO = f_LFO / audio_reader.SampleRate;
T_LFO = 1 / f_LFO; % Get period
dt = 1/audio_reader.SampleRate;
t_period = (0:dt:T_LFO-dt)';
triangle = 0.5 * sawtooth(2*pi*f_LFO*t_period) + 0.5;
triangle = [triangle; flip(triangle)];
LFO = fc_min .* (fc_max/fc_min).^triangle;
t_period = (0:dt:2*T_LFO-dt)';
plot(t_period, LFO);
LFO_Source = dsp.SignalSource(LFO, 'SignalEndAction', 'Cyclic repetition');

%% STFT Setup
% Force the frame size to be a power of two and ensure that hop size is an
% integer
frame_size_N = 2^nextpow2((frame_size/1000)*audio_reader.SampleRate);
hop_size = round(frame_size_N * hop_factor);
audio_reader.SamplesPerFrame = hop_size;
LFO_Source.SamplesPerFrame = frame_size_N;

% Create the buffer to read the source audio as overlapped frames
xbuffer = dsp.Buffer(frame_size_N,frame_size_N-hop_size);

% Create the windowing object
xwin = dsp.Window('Hanning','Sampling','Periodic');

% Obtain the window weights
xwin.WeightsOutputPort = true;
[xfw,w] = step(xwin,zeros(frame_size_N,audio_reader.info.NumChannels));

% Compute the COLA-criterion gain
cola_gain = (sum(w)/frame_size_N)/hop_factor;
reset(xwin)

% Create the FFT and IFFT objects
xfft = dsp.FFT;
yifft = dsp.IFFT('ConjugateSymmetricInput',true,'Normalize',true);

%% Set up filter
half_size = frame_size_N / 2;
omega = ((0:half_size-1)*(2*pi/half_size))';
Q = 1;

%% Set up spectrum analyzer
spec = dsp.SpectrumAnalyzer('SampleRate', audio_reader.SampleRate, ...
    'PlotAsTwoSidedSpectrum', false, ...
    'FrequencyScale', 'log');
%     'YLimits', [-40 40]);
noise = dsp.ColoredNoise(0, audio_reader.SamplesPerFrame, audio_reader.info.NumChannels);

%% Read, process, play, and write the audio
firstpass = true;
previousFilterOut = zeros(frame_size_N, audio_reader.info.NumChannels);
while ~isDone(audio_reader)
    % Retrieve the next input audio frame
    x = step(audio_reader);
    if enable_noise
        x = step(noise);
    end
    
    % Insert audio frame into buffer, and read overlapped frame
    xf = step(xbuffer,x);
    
    % Apply the analysis window
    xfw = step(xwin,xf);
    x = xfw;
    xfw = xfw + g_fb * previousFilterOut;
    
    % Compute the FFT of the windowed frame
    X = step(xfft,xfw);
    
    % Convert to polar form (magnitude and phase)
    Xm = abs(X);
    Xp = angle(X);
    
    % Advance LFO
    omega_c = step(LFO_Source);
    
    % Apply effect
    omega_c = 2*pi*omega_c(1)/(audio_reader.SampleRate);
    B = omega_c / Q;
    tan_B = tan(B / 2);
    tan_C = tan(omega_c / 2);
    H_num = exp(1i*omega)*(tan_C - 1) + tan_C + 1;
%     H_num = (1 - tan_B)*exp(2i*omega) + 2*exp(1i*omega)*cos(omega_c) + 1 + tan_B;
    H_den = exp(1i*omega)*(tan_C + 1) + tan_C - 1;
%     H_den = (1 + tan_B)*exp(2i*omega) + 2*exp(1i*omega)*cos(omega_c) + 1 - tan_B;
    H = depth * (H_num ./ H_den);
    H = [H; H];
    H(:, 2) = H;
    Hp = angle(H);
    Hp(:, :) = Hp(:, :) - max(Hp(:, 1));
%     hz = audio_reader.SampleRate * omega / (2 * pi);
%     hz = [-flipud(hz); hz];
%     plot(hz, 16*(180*Hp/pi)); drawnow;
    Ym = Xm;
    Yp = 8*Hp + Xp;
    Y = Ym .* exp(1i*Yp);
    
    % Compute the IFFT of the windowed result
    yfw = step(yifft, Y);
    previousFilterOut = yfw;
    
    y = yfw + (1 - depth/2) * x;
    
    % Accumulate the overlappping region into the overlap/add buffer;
    % initialize the output overlap/add buffer to zero on the first loop pass
    if firstpass
        yolabuffer = y/cola_gain;
    else
        yolabuffer = yolabuffer + (y/cola_gain);
    end
    
    % Play audio
    step(audio_player, yolabuffer(1:hop_size,:));
    
    % Spectrum analyzer
    step(spec, yolabuffer(1:hop_size,:));

    % Write audio
    if write_output
        step(audio_writer, yolabuffer(1:hop_size));
    end
    
    yolabuffer(1:frame_size_N-hop_size,:) = yolabuffer(hop_size+1:frame_size_N,:);
    yolabuffer(frame_size_N-hop_size+1:frame_size_N,:) = 0;
    
    firstpass = false;
end

release(audio_player);
release(audio_reader);
release(audio_writer);