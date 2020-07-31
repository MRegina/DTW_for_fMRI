TR=2;
Fbp=[0.009 0.08];
t=0:TR:600'; %10 perc TR=2 s
f1=0.009;
f2=0.08;
f3=(0.009+0.08)/2+(0.08-0.009)/2*sin((1:301)*pi/150);

delta=0:pi/100:pi;

sig1=wgn(length(t)+11,1,0);
sig1=ft_preproc_bandpassfilter(sig1', 1/TR, Fbp, 12, 'fir', 'twopass');
sig1=sig1';
sig1=sig1(12:end,:)./repmat(max(abs(sig1(12:end,:))),length(t),1);
sig2=wgn(length(t)+11,1,0);
sig2=ft_preproc_bandpassfilter(sig2', 1/TR, Fbp, 12, 'fir', 'twopass');
sig2=sig2';
sig2=sig2(12:end,:)./repmat(max(abs(sig2(12:end,:))),length(t),1);

noise1=wgn(length(t)+11,1,0);
noise1=ft_preproc_bandpassfilter(noise1', 1/TR, Fbp, 12, 'fir', 'twopass');
noise1=noise1';
noise1=noise1(12:end,:)./repmat(max(abs(noise1(12:end,:))),length(t),1);
noise2=wgn(length(t)+11,1,0);
noise2=ft_preproc_bandpassfilter(noise2', 1/TR, Fbp, 12, 'fir', 'twopass');
noise2=noise2';
noise2=noise2(12:end,:)./repmat(max(abs(noise2(12:end,:))),length(t),1);

%sig1=0.55*sin(f2*t)'+0.45*noise1;
%sig2=0.55*sin(f2*t+pi)'+0.45*noise2;
corr(sig1,sig2)

noise=wgn(length(t)+11,1,0);
noise=ft_preproc_bandpassfilter(noise', 1/TR, Fbp, 12, 'fir', 'twopass');
noise=noise';
noise=noise(12:end,:)./repmat(max(abs(noise(12:end,:))),length(t),1);

sig_noisy1=repmat(sig1,1,length(delta)).*repmat(1:-0.01:0,length(t),1)+repmat(noise,1,length(delta)).*repmat(0:0.01:1,length(t),1);
sig_noisy2=repmat(sig2,1,length(delta)).*repmat(1:-0.01:0,length(t),1)+repmat(noise,1,length(delta)).*repmat(0:0.01:1,length(t),1);


Corr=corr(sig_noisy1,sig_noisy2);
CORR=diag(Corr);

w=length(t);
Plot=0;
for i=1:length(delta)
    DTW(i)=dtw_path( sig_noisy1(:,i), sig_noisy2(:,i), w, Plot );
end

Noise=wgn(length(t)+11,1000,0);
Noise=ft_preproc_bandpassfilter(Noise', 1/TR, Fbp, 12, 'fir', 'twopass');
Noise=Noise';
Noise=Noise(12:end,:)./repmat(max(abs(Noise(12:end,:))),length(t),1);

for i=1:1000
    DTW_null1(i)=dtw_path( sig_noisy1(:,1), Noise(:,i), w, Plot );
    DTW_null2(i)=dtw_path( sig_noisy2(:,1), Noise(:,i), w, Plot );
end

mean([DTW_null1';DTW_null2'])
std([DTW_null1';DTW_null2'])
prcDTW=prctile([DTW_null1';DTW_null2'],[5,95])

Corr_null1=corr(sig_noisy1(:,1),Noise);
Corr_null2=corr(sig_noisy2(:,1),Noise);

mean([Corr_null1';Corr_null2'])
std([Corr_null1';Corr_null2'])
prcCORR=prctile([Corr_null1';Corr_null2'],[5,95])

figure
plot(1:51,CORR(1:51),'b',1:51,mean([Corr_null1';Corr_null2']),'--r',1:51,prcCORR(1),'-.r',1:51,prcCORR(2),'-.r')
set(gca,'FontSize',15)
legend('Correlation coefficient','Mean corr. coeff. of noise','5% percentile of corr. coeff. of noise','95% percentile corr. coeff. of noise')
xlabel('Common noise level (%)')
ylabel('Correlation coefficient')


figure
plot(1:51,DTW(1:51),'b',1:51,mean([DTW_null1';DTW_null2']),'r--',1:51,prcDTW(1),'r-.')
set(gca,'FontSize',15)
legend('DTW distance','Mean DTW dist. of noise','5% percentile of DTW dist. of noise','95% percentile of DTW dist. of noise')
xlabel('Common noise level (%)')
ylabel('DTW distance')
