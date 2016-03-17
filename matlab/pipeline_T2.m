function pipeline_T2(MSE_map_filename, json_filename, threshold)
%**************************************************************************
%**********************pipeline_T2 version 1.0*****************************
%**************************************************************************
%
% Generate a T2_map from a MultiSpinEcho (MSE) sequence 
%
% Input = 
%       MSE_map_filename = Dicom data (3D volume + 1D for echo values)
%       json_filename = Metadata associated with the the MSE_map
%       threshold       = Number between 0 and 100 define the minimal
%       signal rate needed for the fitting process   
%
% Output = 
%       n = 4 volumes Nifti (3D images) in the same directory as the RAW data
%       If a value equal to -1: the voxel signal is below the threshold or the fitting algorithm did not converge
% 
%       T2map	  		= 3D image with T2 fitted values for each voxel
%       M0map			= 3D image with M0 (fitted values (amplitude) for each voxel
% 
%       T2_Error_map	= 3D image with the error value on the T2 adjustment
%       M0_Error_map	= 3D image with the error value on the M0 adjustment
%
% Authors : B. Lemasson

%% load input Nii file
data.hdr = spm_vol(MSE_map_filename);
data.img = spm_read_vols(data.hdr);

%% load input JSON file
fid = fopen(json_filename);
raw = fread(fid,inf);
str = char(raw');
fclose(fid);
data.json = JSON.parse(str);

% Get information from the JSON data
EchoTime = cell2num([data.json.EchoTime{:}]);

% reshape the data to a vector matric (speed the fitting process)
data_to_fit = reshape(double(data.img), [size(data.img,1)*size(data.img, 2)*size(data.img,3) numel(EchoTime)]);

%% create empty structures
T2map_tmp = NaN(size(data_to_fit,1),1);
M0map_tmp = NaN(size(data_to_fit,1),1);
T2_Error_map_tmp = NaN(size(data_to_fit,1),1);
M0_Error_map_tmp = NaN(size(data_to_fit,1),1);

% define the threshold and variables
ratio = double(threshold) / 100.0
ratio_test = threshold/100
maxim=max(data_to_fit(:)) * ratio;

t2init_Cte = EchoTime(1) - EchoTime(end-1);

parfor voxel_nbr = 1:size(data_to_fit,1)
    tmp_voxel_data=data_to_fit(voxel_nbr,:);
    if max(tmp_voxel_data(:))>= maxim
        %% fit data
        t2init=(t2init_Cte)/log(tmp_voxel_data(end-1)/tmp_voxel_data(1));
        if t2init<=0 || isnan(t2init),
            t2init=30;
        end
        [aaa, bbb,  convergence]=levenbergmarquardt('AB_t2s',EchoTime, abs(tmp_voxel_data),[t2init max(abs(tmp_voxel_data))*1.5]);
        % the algorithm converged
        if convergence == -1
            % to remove when good input data
            if isreal(aaa(1))
                T2map_tmp(voxel_nbr)=aaa(1);
                M0map_tmp(voxel_nbr)=aaa(2);
                T2_Error_map_tmp(voxel_nbr)=bbb(1);
                M0_Error_map_tmp(voxel_nbr)=bbb(2);
            end
        end
    end
end

% reshape matrix
T2map.img=reshape(T2map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);
M0map.img=reshape(M0map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);
T2_Error_map.img=reshape(T2_Error_map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);
M0_Error_map.img=reshape(M0_Error_map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);

% save the T2 map
T2map.hdr = spm_vol([MSE_map_filename, ', 1']);
%T2map.hdr.fname = char(strcat(data.json.PatientID, '-T2map.nii'));
T2map.hdr.fname = 'T2map.nii';

T2map.hdr.dt = [64 0];
T2map.hdr.pinfo = [1 0 352]';
T2map.img(T2map.img < 0) = -1;
T2map.img(T2map.img > 5000) = -1;
T2map.img(isnan(T2map.img)) = -1;
spm_write_vol(T2map.hdr, T2map.img);

% save the M0map map
M0map.hdr = spm_vol([MSE_map_filename, ', 1']);
M0map.hdr.fname = char(strcat(data.json.PatientID, '-M0map.nii'));
M0map.hdr.dt = [64 0];
M0map.hdr.pinfo = [1 0 352]';
M0map.img(isnan(M0map.img)) = -1;
spm_write_vol(M0map.hdr, M0map.img);

% save the T2_Error_map 
T2_Error_map.hdr = spm_vol([MSE_map_filename, ', 1']);
T2_Error_map.hdr.fname = char(strcat(data.json.PatientID, '-T2_Error.nii'));
T2_Error_map.hdr.dt = [64 0];
T2_Error_map.hdr.pinfo = [1 0 352]';
T2_Error_map.img(T2_Error_map.img < 0) = -1;
T2_Error_map.img(T2_Error_map.img > 50) = -1;
T2_Error_map.img(isnan(T2_Error_map.img)) = -1;
spm_write_vol(T2_Error_map.hdr, T2_Error_map.img);

% save the M0_Error_map map
M0_Error_map.hdr = spm_vol([MSE_map_filename, ', 1']);
M0_Error_map.hdr.fname = char(strcat(data.json.PatientID, '-M0_Error.nii'));
M0_Error_map.hdr.dt = [64 0];
M0_Error_map.hdr.pinfo = [1 0 352]';
M0_Error_map.img(isnan(M0_Error_map.img)) = -1;
spm_write_vol(M0_Error_map.hdr, M0_Error_map.img);

 

