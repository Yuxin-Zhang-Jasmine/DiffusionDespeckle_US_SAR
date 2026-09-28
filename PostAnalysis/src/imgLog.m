function [] = imgLog(imgLog,scan, name)
% display an img which is already converted to be in dB unit

x_lim = [min(scan.x_matrix(:)) max(scan.x_matrix(:))]*1e3; 
z_lim = [min(scan.z_matrix(:)) max(scan.z_matrix(:))]*1e3;
figure;
imagesc((scan.x_axis)*1e3,(scan.z_axis)*1e3, imgLog); 
shading flat; colormap gray; caxis([0,1]);  hold on; 
axis equal manual;  set(gca,'YDir','reverse'); axis off
set(gca,'fontsize',10);  axis([x_lim z_lim]); title(name); 

end

