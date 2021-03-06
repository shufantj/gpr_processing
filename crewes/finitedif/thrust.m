% THRUST: model a high-angle thrust
%
% Just run the script by typing its names at the command prompt
%
dx=5; %cdp interval
dt=.004; %output sample rate
dtstep=.001; %time stepping rate
tmax=2.0; %maximum record time

[vel,x,z]=thrustmodel(dx);

%plot the velocity model
plotimage(vel-.5*(vhigh+vlow),z,x)
xlabel('meters');ylabel('meters')
velfig=gcf;

disp(' Type 1 for a shot record, 2 for a VSP, 3 for exploding reflector, <CR> to end')
r=input(' response -> ')

while ~isempty(r)
switch(r)
case{1}
	%do a shot record
	disp(' Type 1 for 2nd order Laplacian, 2 for 4th order Laplacian')
	lap=input(' response-> ');
    disp(' enter x coordinate of shot')
	xshot=input(' response-> ');
    disp(' enter z coordinate of shot')
	zshot=input(' response-> ');
    vel2=vel(1:2:end,1:2:end);
    x2=x(1:2:end);
    z2=z(1:2:end);
	snap1=zeros(size(vel2));
	snap2=snap1; 
    ix=near(x2,xshot);
    iz=near(z2,zshot);
	snap2(iz(1),ix(1))=1;
	[shotf,shot,t]=afd_shotrec(2*dx,dtstep,dt,tmax, ...
 		vel2,snap1,snap2,x2,zeros(size(x2)),[5 10 40 50],0,lap);
	figure(velfig)
	line(xshot,0,1,'marker','*','markersize',6,'color','r');
	text(xshot+.02*(max(x)-min(x)),0,1,'shot point','color','r');
	%plot the seismogram
	plotimage(shotf,t,x2-xshot)
   xlabel('offset');ylabel('seconds');
case{2}
	%do a vsp model
	disp(' Type 1 for 2nd order Laplacian, 2 for 4th order Laplacian')
	lap=input(' response-> ');
    disp(' enter x coordinate of well location')
	xwell=input(' response-> ');
    disp(' enter x coordinate of shot')
	xshot=input(' response-> ');
    disp(' enter z coordinate of shot')
	zshot=input(' response-> ');
    vel2=vel(1:2:end,1:2:end);
    x2=x(1:2:end);
    z2=z(1:2:end);
	snap1=zeros(size(vel2));
	snap2=snap1; 
    ix=near(x2,xshot);
    iz=near(z2,zshot);
	snap2(iz(1),ix(1))=1;
	izrec=near(z2,max(z2)/4,3*max(z2)/4);
	zrec=z2(izrec);
	xrec=xwell*ones(size(zrec));
	[vspf,vsp,t]=afd_shotrec(2*dx,dtstep,dt,tmax, ...
 		vel2,snap1,snap2,xrec,zrec,[5 10 40 50],0,lap);
	figure(velfig)
	line(xshot,0,1,'marker','*','markersize',6,'color','g');
	text(xshot+.02*(max(x)-min(x)),0,1,'vsp shot','color','g');
	line(xrec,zrec,ones(size(zrec)),'marker','v','markersize',6,'color','g');
	%plot the vsp
	plotimage(vspf',zrec,t)%vsp's are normally plotted with depth as vert coordinate
   ylabel('depth');xlabel('seconds');
case{3}
	%do an exploding reflector model
	disp(' Type 1 for 2nd order Laplacian, 2 for 4th order Laplacian')
	lap=input(' response-> ');
	[seisfilt,seis,t]=afd_explode(dx,dtstep,dt,tmax, ...
 		vel,x,zeros(size(x)),[5 10 40 50],0,lap);
	%plot the seismogram
	plotimage(seisfilt,t,x)
   xlabel('meters');ylabel('seconds')
otherwise
	disp('invalid selection')
end

disp(' Type 1 for a shot record, 2 for a VSP, 3 for exploding reflector, <CR> to end')
r=input(' response ->')

end


