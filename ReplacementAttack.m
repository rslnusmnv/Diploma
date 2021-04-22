clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'new.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
videoWR = vision.VideoFileWriter('Filename', 'replaceFragmentVid.avi', 'AudioInputPort', true);
%% READING FRAMES AND AUDIOSAMPLES (HARD VERSION)
frameCounter = 1;
while ~isDone(videoFR) 
    [frame{frameCounter}, sample{frameCounter}] = videoFR(); %Чтение кадра с аудиосэмплом  
    lengthAudiosample = length(sample{frameCounter});
    frameCounter = frameCounter + 1;
end
release(videoFR);
frameCounter = frameCounter - 1;
audioHV = cell2mat(sample);
audioHV = reshape(audioHV, [frameCounter * length(sample{frameCounter}),1]);
% figure; plot(audioHV); title('Видео без замены');
%% REPLACEMENT AND WRITING
startOfRange = 318;
endOfRange = 343;
for i = 1:frameCounter    
    if i < startOfRange || i > endOfRange
        videoWR(frame{i}, sample{i});        
    else
        videoWR(frame{i+100}, sample{i+100});
    end
end
release(videoWR);
%% PLOT REPLACEMENT ATTACK
videoFR2 = vision.VideoFileReader('Filename', 'replaceFragmentVid.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
frameCounter2 = 1;
while ~isDone(videoFR2) 
    [frame2{frameCounter2}, sample2{frameCounter2}] = videoFR2(); %Чтение кадра с аудиосэмплом  
    frameCounter2 = frameCounter2 + 1;
end
release(videoFR2);
frameCounter2 = frameCounter2 - 1;
audioHV2 = cell2mat(sample2);
audioHV2 = reshape(audioHV2, [frameCounter2 * length(sample2{frameCounter2}),1]);
% figure; plot(audioHV2); title('Видео с заменой');