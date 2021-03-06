function [shotmod,t,y,x]=shot_model3D(dg,dt,xmax,ymax,tmax,xshot,yshot,v,zv,r,zr,fs,params)
% SHOT_MODEL3D ... create 3D responses of simple structures
%
% [shotmod,t,y,x]=shot_model3D(dg,dt,xmax,ymax,tmax,xshot,yshot,v,zv,r,zr,fs,params)
%
% SHOT_MODEL3D models the response of nearly laterally invariant structures in 3D.
% The idea is that the velocity variation is considered as v(z) while the
% reflectivity is allowed to vary laterally. The response is computed by
% downward extrapolating the source to the reflector, multiplying by the
% spatially variable reflectivity, and upward extrapolating to the surface.
% This is essentially the "migration model" of reflectivity and can also be
% considered to be Rayleigh-Sommerfeld diffraction theory. Scalar fields
% are assumed and reflection coeficients do not vary with angle.
%
% dg ... grid spacing in x and y for the receivers. If inline and crossline
%           spacings are desired as different, then decimate appropriately 
%           afterwards
% dt ... temporal sample rate
% xmax, ymax ... size of the model in x and y. Coordinates go from 0 to
%           these values in both directions.
% tmax ... maximum record length desired. If this is not greater than the
%           two-way time to the deepest refletor, an abort will occur.
% xshot,yshot ... x and y coordinates of the shot
% v ... vector of instantaneous velocities, may be a scalar.
% zv ... vector of depths the same size as v. The first entry should be 0.
% r ... 3D matrix of reflectivities. r(iy,ix,k) is the reflection
%           coefficient at x=(ix-1)*dg, y=(iy-1)*dg, for the kth reflector.
% zr ... vector of length(zr)=size(r,3) containing the depths of the
%           reflectors specified in r.
% fs ... vector of the four Ormsby frequencies, [f1 f2 f3 f4], specifying 
%           Ormsby passband. See ormsby.m if more description is needed.
% 
%	params(1) ... maximum scattering angle (degrees) to model. Angle is translated
%	into wavenumber using the formula kx=f*sin(dip)/max(v) .
%       ***** default = 80 degrees *****
%	params(2) ... butterworth order of dip filter
%       ***** default = 12 *****
%	params(3) ... size of zero pad in time (seconds)
%       ***** default = min([.5*tmax, tmax/cos(params(3))]) ******
%   params(4) ... size of zero pad in x (length units)
%       ***** default = min([.5*xmax, xmax*sin(params(3))]) ******
%   params(5) ... size of zero pad in y (length units)
%       ***** default = result of xpad (params(6)) ******
%   params(6) ...  percentage of imaginary velocity to use
%       ***** default = 1.0 (percent) ********
%	params(7) ... =n means print a message as every n'th frequency 
%			is extrapolated.
%	    ******* default = 50 ******
%
% shotmod ... 3D matrix containing the model. shotmod(it,iy,ix) is the
%           response at t=(it-1)*dt y=(iy-1)*dg x=(ix-1)*dg. To reform into
%           an equivalent 2D matrix us shotmod2 = shotmod(:,:); Thus
%           plotimage(shotmod(:,:),t) is an easy way to display the result.
%

tstart=clock;

%parameter checking
if(dg<=0)
    error('dg must be positive')
end
if(dt<=0 || dt> .5)
    error(' dt must be positive and is specified in SECONDS not milliseconds')
end
nv=length(v);
%vmax=max(v);
if(length(zv)~=nv)
    error('v and zv must be the same length')
end
%examine parameters
nparams=7;% number of defined parameters
if(nargin<13); params= nan*ones(1,nparams); end
if(length(params)<nparams) 
		params = [params nan*ones(1,nparams-length(params))];
end
%assign parameter defaults

if( isnan(params(1)) ); dipmax = 85;
else dipmax = params(1); if(dipmax>90); dipmax=90; end
end
if( isnan(params(2)) ); order = 12;
else order = params(2);
end
if( isnan(params(3)) ); tpad= min([.5*tmax abs(tmax/cos(pi*dipmax/180))]);
else tpad = params(3);
end
if( isnan(params(4)) ); xpad= min([.5*xmax xmax*sin(pi*dipmax/180)]);
else xpad = params(4);
end
if( isnan(params(5)) ); ypad= xpad;
else ypad = params(5);
end
if( isnan(params(6)) ); ivel= 1;
else ivel = params(6);
end
if( isnan(params(7)) ); fpflag= 50;
else fpflag = params(7);
end

%find maximum velocities for each reflector. This is the maximum vel
%between the reflector and the surface.
vmax=zeros(size(zr));
for k=1:length(zr)
    ind=find(zv<zr(k)-1);
    vmax(k)=max(v(ind));
end
%establish geometry

dx=dg;
dy=dg;
nx=round(xmax/dx)+1;
ny=round(ymax/dy)+1;
nt=round(tmax/dt)+1;

t=((0:nt-1)*dt)';
x=(0:nx-1)*dx;
y=((0:ny-1)*dy)';


%calculate pads
% the requested pads are allocated and then the dimensions are increased to
% the next power of 2.

%tpad
ntnew = round((tmax+tpad)/dt+1);
ntnew = 2^nextpow2(ntnew);
%tmaxnew = (ntnew-1)*dt;
tnew = ((0:ntnew-1)*dt)';
%ntpad = ntnew-nt;

%xpad
nxnew = round((xmax+xpad)/dx+1);
nxnew = 2^nextpow2(nxnew);
%xmaxnew = (nxnew-1)*dx+x(1);
xnew = (0:nxnew-1)*dx;
%nxpad = nxnew-nx;

%ypad
nynew = round((ymax+ypad)/dy+1);
nynew = 2^nextpow2(nynew);
%ymaxnew = (nynew-1)*dy+y(1);
ynew = ((0:nynew-1)*dy)';
%nypad = nynew-ny;

%We will build the model directly in the frequency domain and so we will
%need the frequency vector.
f=freqfft(tnew,ntnew,1)';
nf=ntnew/2+1;
f=abs(f(1:nf)); %only the positive frequecies
df=f(2)-f(1);

%determine the frequency mask. Use Gaussian ramps
dbdown=40; %frequencies down further than this will not be calculated.
if1=round(fs(1)/df)+1;
if2=round(fs(2)/df)+1;
if3=round(fs(3)/df)+1;
if4=round(fs(4)/df)+1;
%frequencies to use
ifuse=if1:if4;
%determine Gaussian halfwidths
if(if2~=1)
    alphalow=(f(if2)-f(if1))/sqrt(dbdown/(20*log10(2.718))); %low end
end
alphahi=(f(if4)-f(if3))/sqrt(dbdown/(20*log10(2.718))); %high end
%fmask
if(if2==1)
    fmask=[ones(length(1:if3-1),1); exp(-((f(if3:if4)-f(if3))/alphahi).^2); ...
        zeros(nf-if4,1)];
else
    fmask=[zeros(if1-1,1); exp(-((f(if1:if2)-f(if2))/alphalow).^2); ...
        ones(length(if2+1:if3-1),1); exp(-((f(if3:if4)-f(if3))/alphahi).^2); ...
        zeros(nf-if4,1)];
end
%allocate the seismic matrix
seisf=zeros(nf,nxnew,nynew)+i*zeros(nf,nxnew,nynew);

%compute wavenumber vectors
kxnyq = 1/(2*dx);
dkx = 1/(nxnew*dx); % or 2.*kxnyq/nxnew;
kx=2*pi*[0:dkx:kxnyq-dkx -kxnyq:dkx:-dkx]';%column vector

kynyq = 1/(2*dy);
dky = 1/(nynew*dy);
ky=2*pi*[0:dky:kynyq-dky -kynyq:dky:-dky];%row vector

kx2= kx.*kx;
ky2= ky.*ky;
wavenumbers = kx2*ones(size(ky2)) + ones(size(kx2))*ky2;

%velocity manipulations
v=(1+i*ivel/100)*v;
iv2= v.^(-2);

%determine depth to seed the greens function
if(length(zv)==1)
    zg=min([dg zr(1)]);
    vg=v;
else
    zg=min([dg zr(1) zv(2)]);
    vg=v(1);
end

%radius from shot to each point on grid at depth zg
%rg=sqrt((ynew*ones(1,nxnew)-yshot).^2+(ones(nynew,1)*xnew-xshot).^2+zg^2);

% disp(['There are ' int2str(length(ifuse)) ' frequencies to calculate'])
% disp([' for ' int2str(length(zr)) ' reflectors']);

jjj=near(f,100);

disp(['There are ' int2str(length(ifuse)) ' frequencies to model'])

%loop over frequencies
for k=1:length(ifuse)
    w=2*pi*f(ifuse(k));
    %seed the Green's function at depth zg
    %seisf(ifuse(k),:,:)=fmask(ifuse(k))*exp(-i*(w/vg)*rg)./rg;
     green=greenseed(fmask(ifuse(k)),xnew,ynew,xshot,yshot,...
         f(ifuse(k)),f(ifuse(end)),vg,zg);
        
    %loop over reflectors
    for kk=1:length(zr)
        %build phase shift operator down to reflector
        %build phase shift operator
        if(nv==1)
            %homogeneous case
            dz=zr(kk)-zg;
            phasedown = -dz*sqrt(w*w*iv2 - wavenumbers);
        else
            %WKBJ case 
            ind=between(zg,zr(kk),zv,1);
            phasedown=zeros(size(wavenumbers));
            zv2 = [zg zv(ind) zr(kk)];
            for jj=1:length(zv2)-1
                phasedown=phasedown -(zv2(jj+1)-zv2(jj))*sqrt(w*w*iv2(jj)-wavenumbers);
            end          
        end
        psopdown = exp(i*real(phasedown) - abs(imag(phasedown)));
        
        %build dip filter
        if(k==1||dipmax==90)
            dipfilt=ones(size(wavenumbers));
        else
            %dip filter prep
            pr = sin(pi*dipmax/180)./vmax(kk); %slowness at dipmax
            ikrnot2= 1/(w*w*pr*pr);
            dipfilt = (1+(wavenumbers*ikrnot2).^order).^(-1);
        end
        %extrapolate down
        %tmp = ifft2(dipfilt.*psopdown.*fft2(squeeze(seisf(ifuse(k),:,:))));
        tmp = ifft2(psopdown.*fft2(squeeze(green)));
        
        %apply reflectivity
        tmp2=[squeeze(r(kk,:,:)) zeros(ny,nxnew-nx); ...
                                zeros(nynew-ny,nxnew)].*tmp;
        %seisf(ifuse(k),:,:)=tmp;
        
        %now build operator to go up. It is the same as the down operator
        %except for a little extra phase in the first layer corresponding
        %to the depth that the greens function was seeded.
        extraphaseup= -zg*sqrt(w*w*iv2(1) - wavenumbers);
        psopup=psopdown.*(exp(i*real(extraphaseup) - abs(imag(extraphaseup))));
        
        %extrapolate up
        seisf(ifuse(k),:,:) = seisf(ifuse(k),:,:)+shiftdim(ifft2(dipfilt.*psopup.*fft2(tmp2)),-1);

    end
    
%     if(k==jjj)
%         disp('hoot')
%     end

    if( floor(k/fpflag)*fpflag == k)
        disp(['finished frequency ' int2str(k)]);
    end

end

%remove spatial pad
seisf=seisf(:,1:ny,1:nx);

%inverse transform over f
shotmod=ifftrl(seisf,f);

%remove temporal pad
shotmod=shotmod(1:nt,:,:);
	
tend=etime(clock,tstart);
disp(['Total elapsed time ' num2str(tend)])

