
%close all
clear
clc
addpath(genpath('../src'));
scan = linear_scan(linspace(-0.018,0.018,256).', linspace(0.01,0.036+0.01,256).');
savefolder = 'meetingAug';
fitflag = 1;
c = 200;
version = '-exp4x'; 
nlevel = '001';  % 001, 003, 006
type = 'Deconv';
sigma = '12';  % 08, 12

az = -8; el = 87;
DataAspectRatio = [1 1 1000];
cvrange = 80;
cmap = jet;
to = 100;
phanIdxLst = 5 : to;
P    = zeros(65536, length(phanIdxLst));
VAR  = zeros(65536, length(phanIdxLst));
VAR1  = zeros(65536, length(phanIdxLst));
LOGP = zeros(65536, length(phanIdxLst));
LOGVAR = zeros(65536, length(phanIdxLst));
LOGVAR1 = zeros(65536, length(phanIdxLst));

count = 1;
for phanIdx = phanIdxLst
    GTpath = ['../9_empiricalModelAnalysis/varyPhans' version '/phan' num2str(phanIdx)  '/GT/'];
    load([GTpath, 'p.mat'])

    respath = ['../9_empiricalModelAnalysis/' nlevel type sigma version '/phan' num2str(phanIdx) '/'];
    xs = zeros(c, 256,256);
    for i = 1 : c
        load([respath, num2str(i) '_-1.mat'])
        xs(i,:,:) = x;
    end
    xsvar = var(xs); 
    xsvar = xsvar ./ max(abs(xsvar(:)));
    logvar = dB(xsvar(:),cvrange) ./ 20;

    p = p ./ max(abs(p(:)));
    logp = dB(p(:),cvrange) ./ 20;
    
    a = cdfplot(xsvar);
    upt = min(a.XData(a.YData>=0.9997));%0.9997))
    xsvar1 = xsvar;
    xsvar1(xsvar1>upt) = upt;
    xsvar1 = xsvar1(:) ./ max(abs(xsvar1(:)));
    logvar1 = dB(xsvar1(:),cvrange) ./ 20;   

    P(:,count)  = p(:);
    VAR(:,count)= xsvar(:);
    VAR1(:,count)= xsvar1(:);
    LOGP(:,count)  = logp(:);
    LOGVAR(:,count)=logvar(:);
    LOGVAR1(:,count)=logvar1(:);

    count = count + 1;
end
P = P(:);
VAR = VAR(:);
VAR1 = VAR1(:);
LOGP = LOGP(:);
LOGP1 = (LOGP - min(LOGP(:))); LOGP1 = LOGP1 ./ max(LOGP1(:));

LOGVAR = LOGVAR(:);
LOGVAR1 = LOGVAR1(:);

close all
if fitflag
    % -- fitted parameters (fx)
    f = 1;  
    ft = fittype('f * x', 'independent', 'x', 'dependent', 'y');
    mdl_fx = fit(LOGP,LOGVAR1,ft, 'StartPoint', [f], 'Lower', [0.5], 'Upper',[3])
    save(['mdls/' type sigma version '/mdl' nlevel type sigma version '_fx.mat'], 'mdl_fx')

else
    load(['mdls/' type sigma version '/mdl003' type sigma version '_fx.mat'])
end


% 3D histogram after log (after thresholding the outliers)
taskname = 'cloud_T_log_fit';
rangelogp = abs(min(LOGP(:)));
figure(Position=[1138 34 309 420]);
downList = 0:0.01:0.99;
for down =  downList 
    up = down + downList(2);
    cc = cmap(round(size(cmap,1) .* (up + down)/2), :);
    LOGVAR1selected = LOGVAR1(LOGP1>down & LOGP1<up);
    histogram2(rangelogp * (up + down)/2*ones(length(LOGVAR1selected),1) - rangelogp, ...
        LOGVAR1selected, FaceColor=cc, BinWidth=[0.001,0.01], EdgeColor="none");
    hold on
end
hold off
xlabel("$log_{10}(\mathcal{N}(\mathbf{p}))$", 'Interpreter','latex','FontSize',15)
ylabel("$log_{10}(\mathcal{N}(\mathcal{T}_{99.97\%}(\widehat{\mathbf{\mathbf{v}}_o})))$", 'Interpreter','latex','FontSize',15)
title([type sigma], 'FontSize',20)
xlim([-cvrange / 40, 0]);
ylim([-cvrange / 20, 0]);
set(gca,'DataAspectRatio', DataAspectRatio)
view(az, el);

% -- plot the fitted curve
xa = -4: 0.1: 0.5;
% fx
ya = feval(mdl_fx, xa);
hold on ; scatter(xa, ya, 60, 'filled')

% saveas(gcf, [savefolder '/' nlevel type sigma version '/' taskname '.png'], 'png')
% savefig(gcf, [savefolder '/' nlevel type sigma version '/' taskname, '.fig'])


