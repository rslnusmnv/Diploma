clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'new2.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double', 'VideoOutputDataType', 'uint8');
videoWR = vision.VideoFileWriter('Filename', 'fullReconstructionVideo.avi', 'AudioInputPort', true);
% videoPlr = vision.VideoPlayer; % создание плеера
% videoFR.info() % Если раскомментить можно узнать инфу о видео
%% READING FRAMES AND AUDIOSAMPLES (HARD VERSION)
frameCounter = 1;
while ~isDone(videoFR)    
    [frame{frameCounter}, sample{frameCounter}] = videoFR(); %Чтение кадра с аудиосэмплом
    lengthAudiosample = length(sample{frameCounter});
    frameCounter = frameCounter + 1;
end
% release(videoPlr);
release(videoFR);
frameCounter = frameCounter - 1;
L = 744000;
N = 8000;
P = L / N;
NumberFramesInSample = N/lengthAudiosample;
load('scrambleVector.mat','xh');
for i = 1:P    
    for j = 1:NumberFramesInSample
        Wext = extractDWT(frame{(i-1)*N/lengthAudiosample+j},'HL'); 
        filename = ['D:\Учеба\10 семестр\Разработка\extr\' num2str((xh(i)-1)*N/lengthAudiosample+j) '-' num2str((i-1)*N/lengthAudiosample+j) '.tiff'];
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
        filename = ['D:\Учеба\10 семестр\Разработка\extrmean\' num2str((xh(i)-1)*N/lengthAudiosample+j) '-' num2str((i-1)*N/lengthAudiosample+j) '.tiff'];
        imwrite(res,filename);
        reconstructionVideoFrame{(xh(i)-1)*N/lengthAudiosample+j} = res;
    end
end

audioHV = cell2mat(sample);
audioHV = reshape(audioHV, [frameCounter * length(sample{frameCounter}),1]);
%% READING AUDIO (SIMPLE VERSION)
[audioSV, Fs] = audioread ( 'new.avi', 'double' );
figure; plot(audioHV); title('Аудио собранное по кадрам');
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
    scrambledAudiosample{xh(i)} = audiosample{i};
end
%COMPUTE DCT
for i=1:P
    dctAudiosample{i} = dct(scrambledAudiosample{i});
end
%EXTRACT WATERMARKS
for i=1:P
    W{i} = dctAudiosample{i}(N-N/25 +1 :N);
%     SC{i} = W{i};
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
    reconstructAudiosample{i} = idct(SC{i});
end
%% RECORDING RECONSTRUCTION AUDIO
reconstructionAudio = cell2mat(reconstructAudiosample);
reconstructionAudio = reshape(reconstructionAudio, [length(audio),1]);
figure; subplot (3,1,1); plot(audio); title('Аудио с ЦВЗ');
subplot (3,1,2); plot(compressedAudio); title('Сжатый сигнал');
subplot (3,1,3); plot(reconstructionAudio); title('Восстановленое аудио');
audiowrite('reconstructionAudio.wav',reconstructionAudio, Fs);
%% DIVISION INTO SAMPLES 
for m = 1:frameCounter
    reconstructionAudiosample{m} = reconstructionAudio(1+(lengthAudiosample*(m-1)):lengthAudiosample*m);
    reconstructionAudiosample{m} = reshape(reconstructionAudiosample{m},[lengthAudiosample,1]);
end

%% RECODING RECONSTRUCTION VIDEO
for i = 1:frameCounter
    videoWR(reconstructionVideoFrame{i}, reconstructionAudiosample{i});
end
release(videoWR);
