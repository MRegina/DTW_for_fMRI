TR=2;
Fbp=[0.009 0.08];
t=0:TR:600'; %10 perc TR=2 s

noise=wgn(length(t)+11,100,0);
noise=ft_preproc_bandpassfilter(noise, 1/TR, Fbp, 12, 'fir', 'twopass');
noise=noise(12:end,:)./repmat(max(abs(noise(12:end,:))),length(t),1);

L=0:10:150;
delta=0:2:50;

w=50;%2;%length(t);
Plot=0;

base_CORR=corr(noise(:,1),noise(:,2:end));
for k=2:100;
            base_DTW(k-1)=dtw_path( noise(:,1), noise(:,k), w, Plot );
end

for i=1:length(L)
    for j=1:length(delta)
        noise_mod=noise;
        noise_mod(50+delta(j):50+L(i)+delta(j),:)=repmat(noise(50:50+L(i),1),1,100);
        tmpCorr=corr(noise(:,1),noise_mod(:,2:end));
        CORR(i,j,1)=mean(tmpCorr);
        CORR(i,j,2)=std(tmpCorr);
        diffCORR(i,j,:)=tmpCorr-base_CORR;
        for k=2:100;
            tmpDTW(k-1)=dtw_path( noise(:,1), noise_mod(:,k), w, Plot );
        end
        DTW(i,j,1)=mean(tmpDTW);
        DTW(i,j,2)=std(tmpDTW);
        diffDTW(i,j,:)=tmpDTW-base_DTW;
    end
end

load('Noise.mat')
Base_CORR=corr(noise(:,1),Noise(:,1:end));
for k=1:1000;
            Base_DTW(k)=dtw_path( noise(:,1), Noise(:,k), w, Plot );
end

for i=1:length(L)
    for j=1:length(delta)
        imageDTW(i,j)=sum(Base_DTW>DTW(i,j,1));
        imageCORR(i,j)=sum(Base_CORR<CORR(i,j,1));
    end
end

figure
imagesc(imageCORR,[0 1000])
set(gca,'FontSize',20)
ax = gca;
set(ax,'XTick',3:3:26)
set(ax,'XTickLabel',{'8','20','32','44','56','68','80','92'})
set(ax,'YTick',1:3:16)
set(ax,'YTickLabel',{'0','60','120','180','240','300'})
xlabel('Time-delay (s)') % x-axis label
ylabel('Length of common period (s)') % y-axis label
axis square


figure
imagesc(imageDTW,[0 1000])
set(gca,'FontSize',20)
ax = gca;
ax = gca;
set(ax,'XTick',3:3:26)
set(ax,'XTickLabel',{'8','20','32','44','56','68','80','92'})
set(ax,'YTick',1:3:16)
set(ax,'YTickLabel',{'0','60','120','180','240','300'})
xlabel('Time-delay (s)') % x-axis label
ylabel('Length of common period (s)') % y-axis label
axis square
save
