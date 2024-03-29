clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'new.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
% Два сжатия DV и MJPEG, нужное расскомментируй
% videoWR = vision.VideoFileWriter('Filename', 'compressedVidDV.avi', 'AudioInputPort', true, 'VideoCompressor', 'DV Video Encoder');
videoWR = vision.VideoFileWriter('Filename', 'compressedVidMJPEG.avi', 'AudioInputPort', true, 'VideoCompressor', 'MJPEG Compressor');
% в этом случае аудио не пишется
% videoWR = vision.VideoFileWriter('Filename', 'kek.mp4', 'FileFormat', 'MPEG4', 'AudioInputPort', true);
videoWR.VideoCompressor
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
%% WRITING
frameCounter = frameCounter - 1;
for i = 1:frameCounter
    videoWR(frame{i},sample{i});
end
release(videoWR);




