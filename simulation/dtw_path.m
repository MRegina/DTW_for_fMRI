function [ DTW,M, coord ] = dtw_path( s, t, w, plot )
%

Dtw=ones(length(s)+1,length(t)+1)*Inf;

w=max(w,abs(length(s)-length(t)));

Dtw(1,1)=0;

cost=(repmat(s,1,length(t))-repmat(t',length(s),1)).^2;

for i=1:length(s)
    for j=max(1,i-w):min(length(t),i+w)
        Dtw(i+1,j+1)=cost(i,j)+min([Dtw(i,j+1),Dtw(i+1,j),Dtw(i,j)]);
    end
end

DTW=Dtw(end,end).^0.5;

M=Dtw*(50/max(max(Dtw(~isinf(Dtw)))));

i=length(s)+1;
j=length(t)+1;

leng=1;
while (i>1 && j>1)
    v=[M(i,j-1),M(i-1,j),M(i-1,j-1)];
    coord(leng,:)=[i,j];
    leng=leng+1;
    M(i,j)=60;
    Case=find(v==min(v));
    if length(Case)>1 & ismember(3,Case)
        clear Case
        Case=3;
    elseif length(Case)>1
        clear Case
        Case=1;
    end
        
    switch Case
        case 1
            j=j-1;
        case 2
            i=i-1;
        case 3
            i=i-1; 
            j=j-1;
    end
end

% i=1;
% j=1;
% 
% leng=1;
% while (i<length(s)+1 && j<length(t)+1)
%     
%     if M(i,j)== min([M(i,j+1),M(i+1,j),M(i,j)])
%         M(i,j)=60;
%         coord(leng,:)=[i,j];
%         leng=leng+1;
%         i=i+1;
%         j=j+1;
%     elseif M(i,j+1)== min([M(i,j+1),M(i+1,j),M(i,j)])
%         M(i,j)=60;
%         coord(leng,:)=[i,j];
%         leng=leng+1;
%         j=j+1;
%     else
%     %M(i+1,j)== min([M(i,j+1),M(i+1,j),M(i,j)])
%         M(i,j)=60;
%         coord(leng,:)=[i,j];
%         leng=leng+1;
%         i=i+1;
%     end
% end
M=M+eye(size(M))*60;
M(end,end)=60;
if plot
figure
image(M)
axis square
end

end

