clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'new.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double', 'VideoOutputDataType', 'uint8');
videoWR = vision.VideoFileWriter('Filename', 'new2.avi', 'AudioInputPort', true);
% videoPlr = vision.VideoPlayer; % создание плеера
% videoFR.info() % Если раскомментить можно узнать инфу о видео
%% READING FRAMES AND AUDIOSAMPLES (HARD VERSION)
frameCounter = 1;
while ~isDone(videoFR)    
    [frame{frameCounter}, sample{frameCounter}] = videoFR(); %Чтение кадра с аудиосэмплом  
    watermark{frameCounter} = imresize(frame{frameCounter}, 0.5);
    watermark{frameCounter} = [watermark{frameCounter} watermark{frameCounter}; watermark{frameCounter} watermark{frameCounter}];
    watermark{frameCounter} = imresize(watermark{frameCounter}, 0.5);
    watermark{frameCounter} = rgb2gray(watermark{frameCounter});
    %step(videoPlr, frame); %Воспроизведение кадров
    lengthAudiosample = length(sample{frameCounter});
    frameCounter = frameCounter + 1;
    close all;
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
        newFrame = embedDWT(frame{(i-1)*N/lengthAudiosample+j},watermark{(xh(i)-1)*N/lengthAudiosample+j},'HL');
        filename = ['D:\Учеба\10 семестр\Разработка\embed\' num2str((i-1)*N/lengthAudiosample+j) '-' num2str((xh(i)-1)*N/lengthAudiosample+j) '.tiff'];
        imwrite(watermark{(xh(i)-1)*N/lengthAudiosample+j}, filename);
        videoWR(newFrame, sample{(i-1)*N/lengthAudiosample+j});
    end
end
release(videoWR);
