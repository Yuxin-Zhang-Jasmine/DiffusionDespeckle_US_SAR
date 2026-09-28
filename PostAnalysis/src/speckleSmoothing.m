function [ssi, smpi] = speckleSmoothing(noisyImg,filteredImg)
% speckle smoothing metrics for the log-compressed images.
% NOTE: coding according to "Ultrasound Image Despeckling Using Stochastic 
% Distance-Based BM3D", Cid A. N. Santos et al. IEEE TIP 2017
% --SSI (speckle suppression index): when the filter suppresses speckle,
% SSI<1, and the lower the SSI is, the stronger the suppression abilities
% the filter has.
% --SMPI (speckle suppression and mean preservation index): lower values of
% the SMPI indicate better filter performance regarding mean preservation
% and speckle removal.
[r, c] = size(filteredImg);
windowsize = 7; 
alp = (windowsize-1)/2;
imgn = padarray(noisyImg, [alp alp], 'symmetric');
imgf = padarray(filteredImg, [alp alp], 'symmetric');

SIglobal = var(imgn(:)) ./ mean(imgn(:));
SIlocals = zeros(r,c);
SSIs = zeros(r,c);
SMPIs = zeros(r,c);
meanPatchfs = zeros(r, c);
for i = 1: r
    for j = 1: c
        patchn = imgn(i: i+windowsize-1, j: j+windowsize-1);
        patchn = patchn(:);
        patchf = imgf(i: i+windowsize-1, j: j+windowsize-1);
        patchf = patchf(:);
        SIlocals(i,j)  = var(patchn) ./ mean(patchn);
        SSIs(i,j) = var(patchf) ./ mean(patchf) ./ SIlocals(i,j);
        meanPatchfs(i,j) = mean(patchf);
    end
end
posHomo = [SIlocals <= 0.9 * SIglobal];
count = sum(posHomo(:));
ssi = sum(sum(SSIs .* posHomo)) ./ count;
meanPatchfs = meanPatchfs .* posHomo;

posHomoIdices = find(posHomo==1);
meanPatchfs = meanPatchfs(posHomoIdices);
for i = 1: r
    for j = 1: c
        patchn = imgn(i: i+windowsize-1, j: j+windowsize-1);
        patchn = patchn(:);
        patchf = imgf(i: i+windowsize-1, j: j+windowsize-1);
        patchf = patchf(:);
        R = (max(meanPatchfs) - min(meanPatchfs)) ./ mean(patchn);
        SMPIs(i,j)= (R + abs(mean(patchn)-mean(patchf))) .* (var(patchf)./var(patchn));
    end
end
smpi = sum(sum(SMPIs .* posHomo)) ./ count;


