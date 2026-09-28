
%close all
clear
clc
addpath(genpath('../src'));
scan = linear_scan(linspace(-0.018,0.018,256).', linspace(0.01,0.036+0.01,256).');
savefolder = 'meetingAug';
fitflag = 1;
c = 200;
version = '-linear'; 
nlevelLst = {'001', '003', '006'};  % 001, 003, 006
type = 'Deno';
sigma = '';

az = -8; el = 87;
DataAspectRatio = [1 1 1000];
cvrange = 80;
cmap = jet;
to = 100;
phanIdxLst = 5 : to;
P    = zeros(65536, length(phanIdxLst) * length(nlevelLst));
VAR  = zeros(65536, length(phanIdxLst) * length(nlevelLst));
VAR1  = zeros(65536, length(phanIdxLst) * length(nlevelLst));

count = 1;
for nlevel = nlevelLst
    nlevel = nlevel{1};
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
    
        p = p ./ max(abs(p(:)));
        
        a = cdfplot(xsvar);
        upt = min(a.XData(a.YData>=0.9997));%0.9997))
        xsvar1 = xsvar;
        xsvar1(xsvar1>upt) = upt;
        xsvar1 = xsvar1(:) ./ max(abs(xsvar1(:)));
    
        P(:,count)  = p(:);
        VAR(:,count)= xsvar(:);
        VAR1(:,count)= xsvar1(:);
    
        count = count + 1;
    end
end
P = P(:);
VAR = VAR(:);
VAR1 = VAR1(:);

P = P(1:5:end);
VAR = VAR(1:5:end);
VAR1 = VAR1(1:5:end);

%%
close all
if fitflag
    % -- fitted parameters (fx + sig)
    a = 0.5; % Asymptote maximum
    b = -5; % Logistic growth rate
    c = 0.5; % Midpoint
    d = -0.1; % Asymptote minimum
    f = 0.5;     
    ft = fittype('a + f * x + (d - a) ./ (1 + exp(-b * (x - c)))', 'independent', 'x', 'dependent', 'y');
    mdl_fxSig = fit(P,VAR1,ft, 'StartPoint', [a,b,c,d,f], 'Lower', [0.3, -10, 0.5, -0.5, 0.5], 'Upper',[0.8, 0, 0.5, 0.2, 0.5])
    save(['mdls/' type sigma version '/mdl' type sigma version '_fx+sig.mat'], 'mdl_fxSig')

    % -- fitted parameters (fx)
    f = 0.5;  
    ft = fittype('f * x', 'independent', 'x', 'dependent', 'y');
    mdl_fx = fit(P,VAR1,ft, 'StartPoint', [f], 'Lower', [0.3], 'Upper',[0.9])
    save(['mdls/' type sigma version '/mdl' type sigma version '_fx.mat'], 'mdl_fx')

else
    load(['mdls/' type sigma version '/mdl' type sigma version '_fx.mat'])
    load(['mdls/' type sigma version '/mdl' type sigma version '_fx+sig.mat'])
end

% -- 3D histogram before log (after thresholding the outliers)
taskname = 'cloud_T_wolog_fit';
figure;
downList = 0:0.01:0.99;
for down =  downList 
    up = down + downList(2);
    cc = cmap(round(size(cmap,1) .* (up + down)/2), :);
    VAR1selected = VAR1(P>down & P<up);
    histogram2((up + down)/2*ones(length(VAR1selected),1), ...
        VAR1selected, FaceColor=cc, BinWidth=[0.001,0.01], EdgeColor="none");
    hold on
end
hold off
xlabel("$\mathcal{N}(\mathbf{p})$", 'Interpreter','latex','FontSize',15)
ylabel("$\mathcal{N}(\mathcal{T}_{99.97\%}(\widehat{\mathbf{\mathbf{v}}_o}))$", 'Interpreter','latex','FontSize',15)
title([type sigma], 'FontSize',20)
xlim([0, 1]);
ylim([0, 1]);
view(-53, 74);

% -- plot the fitted curve
xa = -0.5: 0.1: 1.5;
% fx
ya = feval(mdl_fx, xa);
hold on ; scatter(xa, ya, 60, 'filled')
% fx + sig
ya = feval(mdl_fxSig, xa);
hold on ; scatter(xa, ya, 60, 'filled')
saveas(gcf, ['mdls/' type sigma version  '/' taskname '.png'], 'png')
savefig(gcf, ['mdls/' type sigma version  '/' taskname, '.fig'])


