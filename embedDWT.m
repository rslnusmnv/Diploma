function [Iw] = embedDWT(I,W, quater)
%% переход в YCbCr и квантование изображения ЦВЗ
I = rgb2ycbcr(I);
Y = I(:,:,1);
% Wq = uint8(fix(double(W)/16));
Wq = fix(double(W)/16);
Y = int32(Y);
[LL,LH,HL,HH] = dwt2(Y,'haar');

if quater == 'LH'
    LH = int32(LH);
    for i = 1:4
        LH = bitset(LH,i,bitget(Wq,i));
    end
end

if quater == 'HL'
    HL = int32(HL);
    for i = 1:4
        HL = bitset(HL,i,bitget(Wq,i));
    end
end

if quater == 'LL'
    LL = int32(LL);
    for i = 1:4
        LL = bitset(LL,i,bitget(Wq,i));
    end
end

if quater == 'HH'
    HH = int32(HH);
    for i = 1:4
        HH = bitset(HH,i,bitget(Wq,i));
    end
end
Yw = idwt2(LL,LH,HL,HH,'haar');
Yw = uint8(Yw);   
Iw = I;
Iw(:,:,1) = Yw;
Iw = ycbcr2rgb(Iw);
