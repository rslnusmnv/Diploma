clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'deleteFragmentVid.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double', 'VideoOutputDataType', 'uint8');
videoFR2 = vision.VideoFileReader('Filename', 'new2.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
videoWR = vision.VideoFileWriter('Filename', 'reconstructionVideo.avi', 'AudioInputPort', true);
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
% figure; plot(audioHV2); title('Видео без удаления');
% audioHV(length(audioHV)+1: length(audioHV)+40000) = 0;
%% READING AUDIO (SIMPLE VERSION)
[audioSV, Fs] = audioread ( 'deleteFragmentVid.avi', 'double' );
% figure; plot(audioHV); title('Аудио собранное по кадрам');
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
m = 1;
countLeft = 0;
for i = 1:N:L
    audiosample = audio(i:i+N-1);
    dctAudiosample = dct(audiosample);
    F = dctAudiosample(1:n);
%     F1 = 0;
%     for j = 1:ceil(n/2)
%        F1 = F1 + floor((100*F(j))+1/2)/(n/2);
%     end
%     F2 = 0;
%     for j = floor(n/2)+1: n
%         F2 = F2 + floor((100*F(j))+1/2)/(n/2);
%     end
    F1 = F(2) + F(3);
    F2 = F(4) + F(5);
    if  abs(F1-F2)<=0.001   %abs(F1 - F2)<=0.41
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
%     F1 = 0;
%     for j = 1:ceil(n/2)
%        F1 = F1 + floor((100*F(j))+1/2)/(n/2);
%     end
%     F2 = 0;
%     for j = floor(n/2)+1: n
%         F2 = F2 + floor((100*F(j))+1/2)/(n/2);
%     end
    F1 = F(2) + F(3);
    F2 = F(4) + F(5);
    if  abs(F1-F2)<=0.001 %abs(F1 - F2)<=0.41
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
P = originalLength / N;
[height, width, intense] = (size(frame{1}));
missingVideoFrame = uint8(zeros(height, width, intense));
missingAudiosample = double(zeros(lengthAudiosample, 1));
reconstructionVideoFrame = frame;
for i = 1:(P - (countLeft+1)-countRight)*8000/1600
    reconstructionVideoFrame = [reconstructionVideoFrame(1:countLeft*8000/1600+1+i) missingVideoFrame reconstructionVideoFrame(countLeft*8000/1600+2+i:end)];
end
% figure; plot(audio); title('Аудио с удаленным фрагментом');
% figure; plot(augmentedAudio); title('Аудио с нулями');
%EXTRACT WATERMARKS 
load('scrambleVector.mat','xh');
load('MC.mat','MC');
load('watermarks.mat','W');
NumberFramesInSample = N/lengthAudiosample;
reconstructFlag =[];
for i=countLeft : countLeft+difference/N
    k = find(xh==i);
    audioframe = augmentedAudio(1+(N*(k-1)):N*k);
    dctFrame = dct(audioframe);
    W = dctFrame(N-N/25 +1 :N);
    for z = 1:N/25
        SC(z) = nthroot(W(z), n1);
    end
    SC(N/25+1:N) = 0;
    SC = SC * MC{i};
    reconstructAudiosample = idct(SC);
    augmentedAudio(1+(N*(i-1)):N*i) = reconstructAudiosample;
    for j = 1:NumberFramesInSample
        Wext = extractDWT(reconstructionVideoFrame{(k-1)*N/lengthAudiosample+j},'HL'); 
        filename = ['D:\Учеба\10 семестр\Разработка\extr\' num2str((i-1)*N/lengthAudiosample+j) '.tiff'];
        imwrite(Wext, filename);
        image = double(Wext);
        [height, width] = (size(image));
        image = medfilt2(image,[5,5]);
        image1 = image(1:height/2,1:width/2);
        image2 = image(1:height/2,width/2+1:width);
        image3= image(height/2+1:height,1:width/2);
        image4 = image(height/2+1:height,width/2+1:width);
        res = (image1+image2+image3+image4)/4;
        res = uint8(imresize(res, 2));
        filename = ['D:\Учеба\10 семестр\Разработка\extrmean\' num2str((i-1)*N/lengthAudiosample+j) '.tiff'];
        imwrite(res,filename);
        reconstructionVideoFrame{(i-1)*N/lengthAudiosample+j} = res;
        reconstructFlag = [reconstructFlag; (i-1)*N/lengthAudiosample+j];
    end
end
% figure; subplot (3,1,1); plot(audioHV2); title('Исходное аудио');
% subplot (3,1,2); plot(audio); title('Аудио с удаленным фрагментом');
% subplot (3,1,3); plot(augmentedAudio); title('Восстановленное аудио');
%% RECORDING RECONSTRUCTION AUDIO
reconstructionAudio = augmentedAudio;
audiowrite('reconstructionAudio2.wav',reconstructionAudio, Fs);
%% DIVISION INTO SAMPLES 
for m = 1:originalLength/lengthAudiosample
    reconstructionAudiosample{m} = reconstructionAudio(1+(lengthAudiosample*(m-1)):lengthAudiosample*m);
    reconstructionAudiosample{m} = reshape(reconstructionAudiosample{m},[lengthAudiosample,1]);
end
%% RECODING RECONSTRUCTION VIDEO
for i = 1:originalLength/lengthAudiosample
    if i < reconstructFlag(1) || i > reconstructFlag(end) 
        reconstructionVideoFrame{i}=rgb2gray(reconstructionVideoFrame{i});
        videoWR(reconstructionVideoFrame{i}, reconstructionAudiosample{i});
    else
        videoWR(reconstructionVideoFrame{i}, reconstructionAudiosample{i});
    end
end
release(videoWR);

%% QUALITY CONTROL
evaluate_audio_metrics(audioHV2, reconstructionAudio);
evaluate_video_metrics(reconstructionVideoFrame, frame2);