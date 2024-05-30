clc;
clear all;
close all;
input_image = imread('rainy.png'); % Replace 'RainyImage2.jpg' with your image file

% Ground truth Image
ground_truthImg = imread('gt.png');

%% Resizing the images
% Resize the ground_truthImg to match the size of input image
ground_truthImg = imresize(ground_truthImg, [size(input_image, 1), size(input_image, 2)]);

%% Apply Gaussian filter for smoothing
smoothed_image = imgaussfilt(input_image);

% Convert to grayscale
gray_image = rgb2gray(smoothed_image);

%% Apply morphological operations to enhance and extract raindrops
se = strel('disk', 5);
opened_image = imopen(gray_image, se);
raindrop_mask = gray_image - opened_image;

% Invert the raindrop mask
clean_mask = imcomplement(imbinarize(raindrop_mask, 0.1));

% Apply the clean mask to the original image
cleaned_image = input_image;
for c = 1:3
    cleaned_image(:,:,c) = cleaned_image(:,:,c) .* uint8(clean_mask);
end

%% Applying Filter on the cleaned image to remove black spots
% Get the dimensions of the image. numberOfColorBands should be = 3.
[rows, columns, ~] = size(cleaned_image);

% Extract the individual red, green, and blue color channels.
redChannel = cleaned_image(:, :, 1);
greenChannel = cleaned_image(:, :, 2);
blueChannel = cleaned_image(:, :, 3);

% Median Filter the channels:
redMF = medfilt2(redChannel, [3 3]);
greenMF = medfilt2(greenChannel, [3 3]);
blueMF = medfilt2(blueChannel, [3 3]);

% Find the noise in the red.
noiseImage = (redChannel == 0 | redChannel == 255);
% Get rid of the noise in the red by replacing with median.
noiseFreeRed = redChannel;
noiseFreeRed(noiseImage) = redMF(noiseImage);

% Find the noise in the green.
noiseImage = (greenChannel == 0 | greenChannel == 255);
% Get rid of the noise in the green by replacing with median.
noiseFreeGreen = greenChannel;
noiseFreeGreen(noiseImage) = greenMF(noiseImage);

% Find the noise in the blue.
noiseImage = (blueChannel == 0 | blueChannel == 255);
% Get rid of the noise in the blue by replacing with median.
noiseFreeBlue = blueChannel;
noiseFreeBlue(noiseImage) = blueMF(noiseImage);

% Reconstruct the noise-free RGB image
rgbFixed = cat(3, noiseFreeRed, noiseFreeGreen, noiseFreeBlue);

%% Inpainting
rgbFixed_gray_image = rgb2gray(rgbFixed);
% Find black streaks in the rain-removed image
blackStreaks = rgbFixed_gray_image == 0;
% Inpaint the black streaks using the inpaint function
inpaintedImage = inpaintExemplar(rgbFixed, blackStreaks);

%% Contrast Stretching
% Apply contrast stretching to the inpainted image
min_in = double(min(inpaintedImage(:))) / 255;
max_in = double(max(inpaintedImage(:))) / 255;
min_out = 0;
max_out = 1;
stretchedImage = imadjust(inpaintedImage, [min_in, max_in], [min_out, max_out]);

%% Histogram Equalization
equalizedImage = histeq(stretchedImage);

%% Applying Sharpening Filter on the equalized image
sharpenedImage = imsharpen(equalizedImage);

%% Display the original and cleaned images
figure(1);
imshow(input_image);
title('Original Image');

figure(2);
imshow(rgbFixed);
title('Restored Image');

figure(3);
imshow(inpaintedImage);
title("Inpainted image");

figure(4);
imshow(stretchedImage);
title("Image after contrast stretching");

figure(5);
imshow(ground_truthImg);
title("Ground truth");
%% PSNR and SSNR calculation
getPSNR = psnr(stretchedImage, ground_truthImg);
getSSIM = ssim(stretchedImage, ground_truthImg);

disp('PSNR: ');
disp(getPSNR); 

disp('SSIM: '); 
disp(getSSIM);
