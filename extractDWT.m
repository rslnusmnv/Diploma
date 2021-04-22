 function [Wext] = extractDWT(I, quater)
I = rgb2ycbcr(I);
Y = I(:,:,1);
Y=int32(Y);
[LL,LH,HL,HH] = dwt2(Y, 'haar');
if quater == 'HL'
    HL = int32(HL);
    quadr = HL; 
end

if quater == 'LH'
    LH = int32(LH);
    quadr = LH;
end

if quater == 'LL'
    LL = int32(LL);
    quadr = LL; 
end

if quater == 'HH'
    HH = int32(HH);
    quadr = HH; 
end

Wext = uint8(zeros(size(quadr)));
for i = 1:4
    Wext = bitset(Wext,i,bitget(quadr,i));
end
Wext = (Wext)*16;
Wext = imresize(Wext, 2);

