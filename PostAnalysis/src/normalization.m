function [Nresult0_1] = normalization(image)
% Normalizaing image array to range [0,1]
image = image - min(image(:));
Nresult0_1 = image ./ max(image(:));