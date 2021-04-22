clc; clear; close all;
%% CREATING SYSTEM OBJECTS
videoFR = vision.VideoFileReader('Filename', 'vid.avi', 'AudioOutputPort', true, 'AudioOutputDataType', 'double');
videoWR = vision.VideoFileWriter('Filename', 'new.avi', 'AudioInputPort', true);
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
% audioHV = audioHV(1:150000);
%% READING AUDIO (SIMPLE VERSION)
[audioSV, Fs] = audioread ( 'vid.avi', 'double' );
figure; plot(audioHV); title('Аудио собранное по кадрам');
% figure; plot(audioSV); title('Аудио из audioread');
%% SPEECH COMPRESSION (PREPROCESSING)
% audio = audioSV;
audio = audioHV;
n = 5;
n1 = 3;
L = length(audio);
N = 8000;
P = L / N;
for i=1:P
    audiosample{i} = audio(1+(N*(i-1)):N*i);
    dctAudiosample{i} = dct(audiosample{i});
    dct4Audiosample{i} = dctAudiosample{i}(1:N/25);
    MC{i} = max(abs(dct4Audiosample{i}));
    compressedSignal{i} = dct4Audiosample{i}/MC{i};
end
signal = cell2mat(compressedSignal);
signal = reshape(signal, [L*0.04, 1]);
figure; plot(signal); title('Сжатый сигнал');
save('MC.mat','MC');
%% GENERATE PSEUDORANDOM DISTRIBUTION 
%Тут нужно подумать. Скорее всего нужно эту последовательность нужно брать
%какой-то постоянной. Например циклично сдвигать какую-то
%последовательность на какую-то определенную цифру. А ключ уже можно
%рандомить
xh = randperm(P); 
%Следующие две строчки реализуют идею про циклический сдвиг
% xh = (1:1:P); %
% xh = circshift(xh,20);
save('scrambleVector.mat','xh');
%% CREATING WATERMARK (Fi U Wi)
for i = 1:P
    SC{i} = compressedSignal{xh(i)};
end
for i = 1 : P
    F(i) = (xh(i)/(10)^n1);
end
for i = 1:P
    W{i} = (SC{i}).^abs(n1);
end
save('watermarks.mat','W');
%% EMBEDDING PROCESS
%SCRAMBLING
for i=1:P
    scrambleAudiosample{i} = audiosample{i};
end
%COMPUTE DCT
for i=1:P
    dctScrambleAudioSample{i} = dct(scrambleAudiosample{i});
end
%EMBEDD
for i=1:P
    dctScrambleAudioSample{i}(1:n) = F(i);
    dctScrambleAudioSample{i}(N-(3*N/25) +1 :N) = [W{i},W{i},W{i}];
    % Дальше закомменченная попытка встраивания в сэмплы в коэффициенты
    % меньше 0,1
%     for j = N/2:N
%         if abs(dctNewFrames{i}(j)) < 0.1
%             dctNewFrames{i}(j:n+1) = F(i);
%             dctNewFrames{i}(j+n+2:j+(N/25)+n+1) = W{i};
%             break;
%         end
%     end
end
%COMPUTE IDCT
for i = 1:P
    idctScrambleAudioSample{i} = idct(dctScrambleAudioSample{i});
end
%ANTISCRAMBLING
for i=1:P
    newAudiosample{i} = idctScrambleAudioSample{i};
end
%UNION CEIL
newAudio = cell2mat(newAudiosample);
newAudio = reshape(newAudio, [length(audio),1]);
%DRAWING GRAPHICS
figure; subplot (2,1,2); plot(signal); title('Сжатое аудио');
subplot (2,1,1); plot(audio); title('Исходное аудио');

figure; subplot (2,1,1); plot(audio); title('Исходное аудио');
subplot (2,1,2); plot(newAudio); title('Аудио с встроенным ЦВЗ');
audiowrite('newAudio.wav',newAudio, Fs);
save('NewAudioMat.mat','newAudio');
%% WRITING FRAMES AND AUDIOSAMPLES
for m = 1:L/lengthAudiosample
    newSample{m} = newAudio(1+(lengthAudiosample*(m-1)):lengthAudiosample*m);
    newSample{m} = reshape(newSample{m},[lengthAudiosample,1]);
end
for i = 1:frameCounter
    videoWR(frame{i}, newSample{i});
end
release(videoWR);
clear audioSV Fs;


