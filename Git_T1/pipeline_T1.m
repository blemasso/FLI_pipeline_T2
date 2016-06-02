function pipeline_T1(SR_map_filename, json_filename)
%**************************************************************************
%**********************pipeline_T1 version 1.0*****************************
%**************************************************************************
%
% Generate a T1_map from a Saturation/Recuperation (SR) sequence 
%
% Input = 
%       SR_map_filename = Nifti data (3D volume + 1D for echo values)
%       json_filename = Metadata associated with the the SR_map
%
% Output = 
%       n = 4 volumes Nifti (3D images) in the same directory as the RAW data
%           T1map	  		= 3D image with T2 fitted values for each voxel
%           M0map			= 3D image with M0 (fitted values (amplitude) for each voxel
%           T1_Error_map    = 3D image with the error value on the T1 adjustment
%           M0_Error_map    = 3D image with the error value on the M0 adjustment
%
% Authors :  B. Lemasson


%% load input Nii file
data.hdr = spm_vol(SR_map_filename);
data.img = spm_read_vols(data.hdr);

%% load input JSON file
fid = fopen(json_filename);
raw = fread(fid,inf);
str = char(raw');
fclose(fid);
data.json = JSON.parse(str);

% Get information from the JASON data
% Repetition_time = cell2num([data.json.RepetitionTime{:}]);
Repetition_time = [data.json.RepetitionTime{:}];


% reshape the data 4D --> vector (to speed the process)
data_to_fit = reshape(double(data.img), [size(data.img,1)*size(data.img, 2)*size(data.img,3) numel(Repetition_time)]);

%% create empty structures
T1map_tmp = NaN(size(data_to_fit,1),1);
M0map_tmp = NaN(size(data_to_fit,1),1);
T1_Error_map_tmp = NaN(size(data_to_fit,1),1);
M0_Error_map_tmp = NaN(size(data_to_fit,1),1);

% Fitting initialization data
[~, T1approximatif_index] = min(abs(data_to_fit - repmat(max(data_to_fit, [], 2)*0.66, [1 size(data_to_fit,2)])), [], 2);
T1_init = Repetition_time(T1approximatif_index);
M0_init = max(data_to_fit, [], 2);

%% Fitting
parfor voxel_nbr=1:size(data_to_fit,1)
        [aaa, bbb,  ~]=levenbergmarquardt('fit_T1_SatRec',Repetition_time,data_to_fit(voxel_nbr,:),[T1_init(voxel_nbr) M0_init(voxel_nbr) 1]);     
            T1map_tmp(voxel_nbr)=aaa(1);
            T1_Error_map_tmp(voxel_nbr)=bbb(1);
            
            M0map_tmp(voxel_nbr)=aaa(2);
            M0_Error_map_tmp(voxel_nbr)=bbb(2);
end

% reshape the data vector -->
T1map.img=reshape(T1map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);
M0map.img=reshape(M0map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);
T1_Error_map.img=reshape(T1_Error_map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);
M0_Error_map.img=reshape(M0_Error_map_tmp,[size(data.img,1) size(data.img, 2) size(data.img,3)]);

% save the T1 map
T1map.hdr = spm_vol([SR_map_filename, ', 1']);
T1map.hdr.fname = char(strcat(data.json.PatientID, '-T1map.nii'));
T1map.hdr.dt = [64 0];
T1map.hdr.pinfo = [1 0 352]';
T1map.img(T1map.img < 0) = -1;
T1map.img(T1map.img > 20000) = -1;
T1map.img(isnan(T1map.img)) = -1;
spm_write_vol(T1map.hdr, T1map.img);

% save the M0map map
M0map.hdr = spm_vol([SR_map_filename, ', 1']);
M0map.hdr.fname = char(strcat(data.json.PatientID, '-M0map.nii'));
M0map.hdr.dt = [64 0];
M0map.hdr.pinfo = [1 0 352]';
M0map.img(isnan(M0map.img)) = -1;
spm_write_vol(M0map.hdr, M0map.img);

% save the T1_Error_map 
T1_Error_map.hdr = spm_vol([SR_map_filename, ', 1']);
T1_Error_map.hdr.fname = char(strcat(data.json.PatientID, '-T1_Error.nii'));
T1_Error_map.hdr.dt = [64 0];
T1_Error_map.hdr.pinfo = [1 0 352]';
T1_Error_map.img(T1_Error_map.img < 0) = -1;
T1_Error_map.img(T1_Error_map.img > 1000) = -1;
T1_Error_map.img(isnan(T1_Error_map.img)) = -1;
spm_write_vol(T1_Error_map.hdr, T1_Error_map.img);

% save the M0_Error_map map
M0_Error_map.hdr = spm_vol([SR_map_filename, ', 1']);
M0_Error_map.hdr.fname = char(strcat(data.json.PatientID, '-M0_Error.nii'));
M0_Error_map.hdr.dt = [64 0];
M0_Error_map.hdr.pinfo = [1 0 352]';
M0_Error_map.img(isnan(M0_Error_map.img)) = -1;
spm_write_vol(M0_Error_map.hdr, M0_Error_map.img);

