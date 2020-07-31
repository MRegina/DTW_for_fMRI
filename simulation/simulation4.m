TR=2;
Fbp=[0.009 0.08];
t=0:TR:600'; 
f=0.06;
phase=[zeros(1,70),0:(pi/(9)):pi,pi*ones(1,140),pi:-(pi/9):0,zeros(1,71)];
phase2=[zeros(1,50),pi/2*ones(1,50),pi*ones(1,100),pi/2*ones(1,51),zeros(1,50)];
w=50;

signal1=sin(t*f);
signal2=sin(t*f+phase);

CorrSignal=corr(signal1',signal2');

figure
plot(t,signal1,'r-o',t,signal2,'b-.')
set(gca,'FontSize',20)
title(['Underlaying signals, correlation coefficient: ', num2str(CorrSignal)])
set(gca,'FontSize',20)
set(gcf,'units','normalized','outerposition',[0 0 1 1])
%print(['signals_no_noise2'],'-dpng','-r600')

% noise=wgn(length(t)+11,1002,0);
% noise=ft_preproc_bandpassfilter(noise', 1/TR, Fbp, 12, 'fir', 'twopass');
% noise=noise';
% Noise=(noise(12:end,:)./repmat(max(abs(noise(12:end,:))),length(t),1));
% 
% save('Noise_sim4.mat','Noise')
load('Noise_sim4.mat')

sig1=0.5*signal1'+0.5*Noise(:,1);
sig1=sig1/max(abs(sig1));
sig2=0.5*signal2'+0.5*Noise(:,2);
sig2=sig2/max(abs(sig2));


CorrSig=corr(sig1,sig2);

figure
plot(t',sig1,'r-o',t',sig2,'b-.')
set(gca,'FontSize',20)
title(['Noisy signals, correlation coefficient: ', num2str(CorrSig)])
set(gca,'FontSize',20)
set(gcf,'units','normalized','outerposition',[0 0 1 1])
%print(['signals_noise2'],'-dpng','-r600')


Plot=1;

DTWSignal=dtw_path( signal1', signal2', w, Plot );
set(gca,'FontSize',20)
title(['Warping path of the underlaying signals, DTW distance: ',num2str(DTWSignal)])
set(gca,'FontSize',20)
set(gcf,'units','normalized','outerposition',[0 0 1 1])
%print(['DTWpath_no_noise2'],'-dpng','-r600')

DTWSig=dtw_path( sig1, sig2, w, Plot );
set(gca,'FontSize',20)
title(['Warping path of the underlaying signals, DTW distance: ',num2str(DTWSig)])
set(gca,'FontSize',20)
set(gcf,'units','normalized','outerposition',[0 0 1 1])
%print(['DTWpath_noise2'],'-dpng','-r600')

Plot=0;

Base_CORR=corr(Noise(:,1),Noise(:,3:end));
for k=1:1000;
            Base_DTW(k)=dtw_path( Noise(:,1), Noise(:,k+2), w, Plot );
end

% sliding window: Tracking Whole-Brain Connectivity Dynamics in the Resting State
x = [-12:TR:12];
norm = normpdf(x,0,3*TR);
box=[zeros(1,6),ones(1,22),zeros(1,6)];

window=conv(box,norm,'same');

for i=1:length(t)-(length(window)-1)
    Sig1=signal1(i:i+(length(window)-1))'.*window';
    Sig2=signal2(i:i+(length(window)-1))'.*window';
    CORR_noiseless(i)=corr(Sig1,Sig2);
    
    Sig1=sig1(i:i+(length(window)-1)).*window';
    Sig2=sig2(i:i+(length(window)-1)).*window';
    CORR_noisy(i)=corr(Sig1,Sig2);
end

figure
plot(t(1:end-(length(window)-1)),CORR_noiseless,'r-o',t(1:end-(length(window)-1)),CORR_noisy,'b-o')
set(gca,'FontSize',20)
legend('Underlaying signal','Noisy signal')
hold on
plot(t(1:end-(length(window)-1)),prctile(Base_CORR,2.5)*ones(1,length(t)-(length(window)-1)),'k-.',t(1:end-(length(window)-1)),prctile(Base_CORR,97.5)*ones(1,length(t)-(length(window)-1)),'k-.')

title('Sliding window correlation of the underlaying and noisy signals')

set(gcf,'units','normalized','outerposition',[0 0 1 1])
%print(['sliding_corr2'],'-dpng','-r600')



    
    
    


