clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'new.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
% videoPlr = vision.VideoPlayer; % создание плеера
% videoFR.info() % Если раскомментить можно узнать инфу о видео
%% READING FRAMES AND AUDIOSAMPLES (HARD VERSION)
frameCounter = 1;
while ~isDone(videoFR)
    %frame = step(videoFR); %Чтение кадра без аудиосэмпла    
    [frame{frameCounter}, sample{frameCounter}] = videoFR(); %Чтение кадра с аудиосэмплом  
    lengthAudiosample = length(sample{frameCounter});
%     %% EXTRACT AUDIO (HARD VERSION)Раскомментируй 32 и закомментируй 31
%     z = 1;
%     for j = frameCounter*length(audiosample)+1:frameCounter*length(audiosample)+length(audiosample)
%         audioHV(j, 1) = audiosample(z, 1);
%         audioHV(j, 2) = audiosample(z, 2);
%         z = z +1;
%     end
%     %%
    %step(videoPlr, frame); %Воспроизведение кадров
    frameCounter = frameCounter + 1;
end
frameCounter = frameCounter - 1;
audioHV = cell2mat(sample);
audioHV = reshape(audioHV, [frameCounter * length(sample{frameCounter}),1]);

%% READING AUDIO (SIMPLE VERSION)
[audioSV, Fs] = audioread ( 'new.avi', 'double' );
figure; plot(audioHV); title('Аудио собранное по кадрам');
figure; plot(audioSV); title('Аудио из audioread');
% audioSV = audioSV(1:length(audioSV)); %Это чтобы оставить только одну дорожку аудио
% audioSV(length(audioSV)+1: length(audioSV)+1696) = 0;
%% EXTRACT PROCESS
% audio = audioSV;
audio = audioHV;
n = 5;
n1 = 3;
L = length(audio);
N = 8000;
P = L / N;
for i=1:P
    audiosample{i} = audio(1+(N*(i-1)):N*i);
end

%SCRAMBLING
load('scrambleVector.mat','xh');
for i = 1:P
    scrambledAudiosample{i} = audiosample{xh(i)};
end

%COMPUTE DCT
for i=1:P
    dctAudiosample{i} = dct(scrambledAudiosample{i});
end

%EXTRACT WATERMARKS
for i=1:P
    W{i} = dctAudiosample{i}(N-N/25 +1 :N);
end

for i =1:P
    for j = 1:N/25
        SC{i}(j) = nthroot(W{i}(j), n1);
    end
end
compressedAudio = cell2mat(SC);
compressedAudio = reshape(compressedAudio, [L/25 1]);
figure; plot(compressedAudio); title('Сжатый сигнал');

%% RECONSTRUCTION
load('MC.mat','MC');
for i = 1:P
    SC{i}(N/25+1:N) = 0;
    SC{i} = SC{i} * MC{i};
    reconstructionAudiosample{i} = idct(SC{i});
end
%% RECORDING R audio
reconstructionAudio = cell2mat(reconstructionAudiosample);
reconstructionAudio = reshape(reconstructionAudio, [length(audio),1]);
figure; plot(reconstructionAudio); title('Восстановленное аудио');
audiowrite('reconstructionAudio.wav',reconstructionAudio, Fs);