function varargout = lumicolor(xl,xc)
	
	%% Scaling
	minl = min(xl(:));
	xl = xl - minl;
	maxl = max(xl(:));
	xl = xl .* (255 ./ maxl);
	
	minc = min(xc(:));
	xc = xc - minc;
	maxc = max(xc(:));
	xc = xc .* (255 ./ maxc);
	
	%% Color projection
% 	cm = colormap('parula');
% 	cm = colormap('winter');
% 	cm = colormap('hsv');
  	cm = colormap('jet');
	xc = ind2rgb(uint8(xc),cm);

	%% Lumi-Color combination
	x = uint8(xc.*xl);
	
	%% Output
	if nargout == 0
		imshow(x)
		colorbar
	else
		varargout{1} = x;
	end
end
