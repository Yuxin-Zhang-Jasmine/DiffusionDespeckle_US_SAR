function [] = ROIplot_contrast(scan,phantom)
    padding = 1.1;
    x = scan.x_matrix;
    z = scan.z_matrix;  
    for k=1:length(phantom.occlusionDiameter)
        r = phantom.occlusionDiameter(k) / 2;
        rin = r - padding * phantom.lateralResolution;
        rout1 = r + padding * phantom.lateralResolution;
        rout2 = 1.2*sqrt(rin^2+rout1^2);
        xc = phantom.occlusionCenterX(k);
        zc = phantom.occlusionCenterZ(k);
        maskOcclusion = ( ((x-xc).^2 + (z-zc).^2) <= r^2);
        maskInside = ( ((x-xc).^2 + (z-zc).^2) <= rin^2);
        maskOutside = ( (((x-xc).^2 + (z-zc).^2) >= rout1^2) & ...
                     (((x-xc).^2 + (z-zc).^2) <= rout2^2) );                
        %hold on; contour(scan.x_axis*1e3,scan.z_axis*1e3,maskOcclusion,[1 1],'b-','linewidth',2);
        hold on; contour(scan.x_axis*1e3,scan.z_axis*1e3,maskInside,[1 1],'LineColor', [60, 179, 113] / 255 ,'lineStyle', '-','linewidth',4);
%         hold on; contour(scan.x_axis*1e3,scan.z_axis*1e3,maskOutside,[1 1],'g-','linewidth',2);
        hold on; contour(scan.x_axis*1e3,scan.z_axis*1e3,maskOutside,[1 1],'LineColor','#007CC3', 'LineStyle', '-','LineWidth',4);

    end
    
end

