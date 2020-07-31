TR=2;
Fbp=[0.009 0.08];
t=0:TR:600'; %10 perc TR=2 s
f1=0.009;
f2=0.08;
f3=(0.009+0.08)/2+(0.08-0.009)/2*sin((1:301)*pi/150);

delta=0:pi/100:pi;
for i=1:length(delta)
    s1(:,i)=sin(t*f1+delta(i))';
    
    s2(:,i)=sin(t*f2+delta(i))';
    
    s3(:,i)=sin(t.*f3+delta(i))';
end

noise=wgn(length(t)+11,length(delta),0);
noise=ft_preproc_bandpassfilter(noise, 1/TR, Fbp, 12, 'fir', 'twopass');
noise=noise(12:end,:)./repmat(max(abs(noise(12:end,:))),length(t),1);


plot(s3);
CORRs3=corr(s3(:,1),s3);
CORRs3_null=corr(s3(:,1),noise);

w=length(t);
Plot=0;
for i=1:length(delta)
    DTWs3(i)=dtw_path( s3(:,1), s3(:,i), w, Plot );
    DTWs3_null(i)=dtw_path( s3(:,1), noise(:,i), w, Plot );
end

figure
plot(delta*180/pi,CORRs3,'*',delta*180/pi,CORRs3_null,'-.')
figure
plot(delta*180/pi,DTWs3,'*',delta*180/pi,DTWs3_null,'-.')


