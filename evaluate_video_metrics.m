function [] = evaluate_video_metrics(frame,frame2)
MSE = 0;
MAE = 0;
SNR = 0;
PSNR = 0;
cross_core = 0;
if length(frame)>= length(frame2)
    frameCounter=length(frame);
else
    frameCounter=length(frame2);
end
for i = 1:frameCounter   
%     frame{i} = rgb2gray(double(frame{i}));
    frame{i} = double(frame{i});
    frame2{i} = rgb2gray(double(frame2{i}));
    MSE = MSE + mse(frame{i}, frame2{i});
    MAE = MAE + mae(frame{i}, frame2{i});
    SNR = SNR + snr(frame{i}, frame2{i});
    PSNR = PSNR + psnr(frame{i}, frame2{i});
    cc = corrcoef(frame{i}, frame2{i});
    cross_core = cross_core + cc(1,2);
end
MSE = MSE/frameCounter
MAE = MAE/frameCounter
SNR = SNR/frameCounter
PSNR = PSNR/frameCounter
cross_core = cross_core/frameCounter
