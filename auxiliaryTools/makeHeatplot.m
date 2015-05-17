function heatplot = makeHeatplot(varargin)
% function heatplot = makeHeatplot(varargin)
%
% MAKEHEATPLOT(COORDINATES,KERNELSIZE);
% COORDINATES Nx2 matrix of point coordinates.
% KERNELSIZE defines the size of gaussian window used to smooth the image.
% The returned HEATPLOT is normalized to have values between 0 and 1.
%
% EXAMPLE:
% imagesc(makeHeatplot)
% Creates a set of random dots and shows the heatplot based on these
% points.

if nargin==0
    points=rand(1000,2)*512;
else
    points=varargin{1};
end

if size(points,1)<size(points,2)
    points=points';
end

if nargin<4
    options=[1 1];
else
    options=varargin{4};
end

points=round(points);
if options(1)==1
    points(:,1)=points(:,1)-min(points(:,1))+1;
end
m=min(points(:,1));
M=max(points(:,1));
Ydim=m:M;
if options(1)==1
    points(:,2)=points(:,2)-min(points(:,2))+1;
end
m=min(points(:,2));
M=max(points(:,2));
Xdim=m:M;

if nargin<2
    kernelSize=round(mean([length(Xdim) length(Ydim)])/5);
else
    kernelSize=varargin{2};
end

if nargin<3
    heatplot=zeros(length(Xdim),length(Ydim));
else
    dimensions=varargin{3};
    heatplot=zeros(dimensions(1),dimensions(2));
end


nPoints=size(points,1);
for index=1:nPoints
    heatplot(points(index,2),points(index,1))=heatplot(points(index,2),points(index,1))+1;
end

sigma=kernelSize*.2;
kernel = Gauss(kernelSize,sigma);
if exist('conv2_gpu','file')
    heatplot=conv2_gpu(heatplot,kernel,'same');
else
    heatplot=conv2(heatplot,kernel,'same');
end
if options(2)==1
    heatplot=heatplot./max(heatplot(:));
end


function im = Gauss(imSize, FWHM)
X=-imSize/2:imSize/2;
X=X(2:end);

a=1;
b=0;
c=1 /imSize / FWHM*2 * imSize*1.17;

Y = a * exp(-((X-b).^2)/2*c.^2);
Y=Y./max(Y(:));

vert=repmat(Y,imSize,1);
hor=repmat(Y',1,imSize);

im=vert.*hor;

