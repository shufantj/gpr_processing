[m,n]=size(shotoffset);
delx=shotoffset(:,1:n-50)-shotoffset(:,51:n);
delt=shotpick(:,1:n-50)-shotpick(:,51:n);  
avgx=(shotoffset(:,1:n-50)+shotoffset(:,51:n))/2;
deriv=delx./delt;
absavgx=abs(avgx);
absderiv=abs(deriv);
figure('menubar','none')
plot(absavgx(1:189,:),absderiv(1:189,:),'o');
axis([0,3500,2,4]);                     
[m,n]=size(deriv);
delx2=delx(:,1:n-10)-delx(:,11:n);
delt2=delt(:,1:n-10)-delt(:,11:n);
avgx2=(delx(:,1:n-10)+delx(:,1:n-10))/2;
deriv2=delx2./delt2;
figure
plot(avgx2(1:189,:),deriv2(1:189,:),'o');
%axis([-4000,4000,-20,20]);  
%axis([-4000,4000,-3,3]);  
%plot(avgx(1:1,:),deriv(1:1,:),'o');
%figure
%plot(shotoffset(1:1,:),shotpick(1:1,:),'o')
%plot(delt(1:1,:),shotpick(1:1,:),'o')