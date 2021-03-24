clc; clear; %close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'deleteFragmentVid.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
videoFR2 = vision.VideoFileReader('Filename', 'new.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
% videoPlr = vision.VideoPlayer; % создание плеера
% videoFR.info() % Если раскомментить можно узнать инфу о видео
%% READING FRAMES AND AUDIOSAMPLES (HARD VERSION)
frameCounter = 1;
while ~isDone(videoFR)
    %frame = step(videoFR); %Чтение кадра без аудиосэмпла    
    [frame{frameCounter}, sample{frameCounter}] = videoFR(); %Чтение кадра с аудиосэмплом  
    lengthAudiosample = length(sample{frameCounter});
    %step(videoPlr, frame); %Воспроизведение кадров
    frameCounter = frameCounter + 1;
end
% release(videoPlr);
release(videoFR);
frameCounter = frameCounter - 1;
audioHV = cell2mat(sample);
audioHV = reshape(audioHV, [frameCounter * length(sample{frameCounter}),1]);
% audioHV(length(audioHV)+1: length(audioHV)+40000) = 0;

frameCounter2 = 1;
while ~isDone(videoFR2) 
    [frame2{frameCounter2}, sample2{frameCounter2}] = videoFR2(); %Чтение кадра с аудиосэмплом  
    lengthAudiosample2 = length(sample2{frameCounter2});
    frameCounter2 = frameCounter2 + 1;
end
release(videoFR2);
frameCounter2 = frameCounter2 - 1;
audioHV2 = cell2mat(sample2);
audioHV2 = reshape(audioHV2, [frameCounter2 * length(sample2{frameCounter2}),1]);
figure; plot(audioHV2); title('Видео без удаления');
% audioHV(length(audioHV)+1: length(audioHV)+40000) = 0;
%% READING AUDIO (SIMPLE VERSION)
[audioSV, Fs] = audioread ( 'deleteFragmentVid.avi', 'double' );
figure; plot(audioHV); title('Аудио собранное по кадрам');
% figure; plot(audioSV); title('Аудио из audioread');
% audioSV = audioSV(1:length(audioSV)); %Это чтобы оставить только одну дорожку аудио
% audioSV(length(audioSV)+1: length(audioSV)+1696) = 0;
%% EXTRACT PROCESS
% audio = audioSV;
audio = audioHV;
originalLength = 744000;
n = 5;
n1 = 3;
L = length(audio);
N = 8000;
P = L / N;
m = 1;
countLeft = 0;
for i = 1:N:L
    audiosample = audio(i:i+N-1);
    dctAudiosample = dct(audiosample);
    F = dctAudiosample(1:n);
    F1 = 0;
    for j = 1:ceil(n/2)
       F1 = F1 + floor((100*F(j))+1/2)/(n/2);
    end
    F2 = 0;
    for j = floor(n/2)+1: n
        F2 = F2 + floor((100*F(j))+1/2)/(n/2);
    end
    if abs(F1 - F2)<=0.41
        fprintf('Кадр %d F1 = %f F2=%f |F1-F2|=%f\n', m, F1, F2, abs(F1-F2));
        countLeft = countLeft + 1;
        m = m +1;
    else
        fprintf('Плохо %d F1 = %f F2=%f |F1-F2|=%f\n\n\n', m, F1, F2, abs(F1-F2));
        break;
    end    
end
m = 1;
countRight = 0;
for i = L:-N:1
    audiosample = audio(i-N+1:i);
    dctAudiosample = dct(audiosample);
    F = dctAudiosample(1:n);
    F1 = 0;
    for j = 1:ceil(n/2)
       F1 = F1 + floor((100*F(j))+1/2)/(n/2);
    end
    F2 = 0;
    for j = floor(n/2)+1: n
        F2 = F2 + floor((100*F(j))+1/2)/(n/2);
    end
    if abs(F1 - F2)<=0.41
        fprintf('Кадр %d F1 = %f F2=%f |F1-F2|=%f\n', m, F1, F2, abs(F1-F2));
        countRight = countRight + 1;
        m = m +1;
    else
        fprintf('Плохо %d F1 = %f F2=%f |F1-F2|=%f\n', m, F1, F2, abs(F1-F2));
        break;
    end    
end
%adding zeros 
difference = originalLength - N*(countLeft+countRight);
augmentedAudio = audio(1:N*countLeft);
augmentedAudio(N*countLeft+1:N*countLeft+difference) = 0;
augmentedAudio(N*countLeft+difference+1:originalLength) = audio(L-N*countRight+1:L);
figure; plot(audio); title('Аудио с удаленным фрагментом');
figure; plot(augmentedAudio); title('Аудио с нулями');
%EXTRACT WATERMARKS
load('scrambleVector.mat','xh');
load('MC.mat','MC');
load('watermarks.mat','W');
for i=countLeft : countLeft+difference/N
    k = xh(i);
    audioframe = augmentedAudio(1+(N*(k-1)):N*k);
    dctFrame = dct(audioframe);
    W = dctFrame(N-N/25 +1 :N);
    for j = 1:N/25
        SC(j) = nthroot(W(j), n1);
    end
    SC(N/25+1:N) = 0;
    SC = SC * MC{i};
    reconstructionAudiosample = idct(SC);
    augmentedAudio(1+(N*(i-1)):N*i) = reconstructionAudiosample;
end
figure; plot(augmentedAudio); title('Восстановленное аудио');
%% RECORDING RECONSTRUCTION AUDIO
reconstructionAudio = augmentedAudio;
audiowrite('reconstructionAudio2.wav',reconstructionAudio, Fs);