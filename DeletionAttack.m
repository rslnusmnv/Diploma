clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'new.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
videoWR = vision.VideoFileWriter('Filename', 'deleteFragmentVid.avi', 'AudioInputPort', true);
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
startOfRange = 304;
endOfRange = 328;
for i = 1:frameCounter
    if i < startOfRange || i > endOfRange
        videoWR(frame{i}, sample{i});
        i
    end
end
release(videoWR);
% [audioSV, Fs] = audioread ( 'new.avi', 'double' );
% [audioHV, Fs] = audioread ( 'deleteFragmentVid.avi', 'double' );
% figure; plot(audioSV); title('Исходное аудио');
% figure; plot(audioHV); title('Аудио без фрагмента');