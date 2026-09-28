function [alpha] = alphaResolution(img)
% a resolution metric, the lower the better

autoCorr_result = xcorr2(img);
threshold = 0.75 * max(autoCorr_result(:));
exceedingPixels = autoCorr_result > threshold;
alpha = (sum(exceedingPixels(:)) / numel(autoCorr_result)) * 100;

end

