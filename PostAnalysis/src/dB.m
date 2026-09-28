function [x2dB] = dB(x,plage)
	x2dB = 20*log10(abs(x ./ max(abs(x(:)))));
%     x2dB = x2dB(:);
	if nargin == 2
		x2dB(x2dB<-plage) = -plage;
	end
end