import os
import cv2 as cv
import numpy as np
import multiprocessing
from tkinter import filedialog
from tkinter import *


def find_slab_dirs(top_dir):
    paths = []
    for dirpath, dirnames, files in os.walk(top_dir):
        for item in dirnames:
            if item == 'Slabs' and len(os.listdir(
                    os.path.join(dirpath, item))) != 0:  # if there is already a slab dir which is not empty just skip
                print(f" Ignored because Slabs are already exported to {os.path.join(dirpath, item)}")
                break
            elif item == 'TIFF_HorizontalAxis':
                paths.append(os.path.join(dirpath, item))
            elif item == 'TIFF_VerticalAxis':
                paths.append(os.path.join(dirpath, item))
            elif 'masked_tiff' in item:
                paths.append(os.path.join(dirpath, item))
    return paths

def get_tiff_stack(dir_path):
    dir_items = os.listdir(dir_path)
    files = []
    for filename in dir_items:
        if filename.endswith(".tif"):
            # print(f"{filename}")
            files.append(os.path.join(dir_path, filename))
    return files

def get_centre_position(target_dic, stride):
    files = target_dic['TIFF_Stack']
    # Centre slice of the slab being produced according to the original TIFF stack
    centre_slices = range(0, len(files), stride)  # positions of centre slices --> pass this to parallel computing
    return list(centre_slices)

def get_vsize_from_CT_filetypes(folder):
    file_extensions = [".xtekct", ".xtekVolume"]
    TargetStrings = ['VoxelSizeX=', 'Voxel size = ']
    # parent_folder = os.path.dirname(folder)

    # MAIN_PATH=os.path.join(Drive_Letter, main_dir)

    for root, dirs, files in os.walk(folder, topdown=False):
        for name in files:
            if any([name.endswith(extension) for extension in file_extensions]):
                print(f"Found config file for scan in {os.path.abspath(os.path.join(root, name))}")
                target_file_path = os.path.abspath(os.path.join(root, name))
                ##TODO get voxelsize from xtect or CWI files or xteck volume files

    dummy_size = []
    with open(target_file_path, 'rt') as myfile:  # Open lorem.txt for reading text
        contents = myfile.read()  # Read the entire file to a string
        for each_line in contents.split("\n"):
            if any([item in each_line for item in TargetStrings]):
                # print(each_line)
                dummy_size = each_line
                break

    if TargetStrings[0] in dummy_size:
        voxelsize = float(dummy_size.split(TargetStrings[0])[-1])
    if TargetStrings[1] in dummy_size:
        voxelsize = float(dummy_size.split(TargetStrings[1])[-1])
    print(f"Voxel size is {voxelsize}")

    return voxelsize

def make_slab(target_dic, stride, slab_centre, voxel_size):
    files = target_dic['TIFF_Stack']
    scan_dir = os.path.dirname(target_dic['Path'])

    # Centre slice of the slab being produced according to the original TIFF stack
    centre_slice = slab_centre
    default_size = stride

    for slab_size in range(default_size, default_size + 1, default_size):  # just do default_size

        if int(centre_slice - int(slab_size / 2)) < 0 or int(centre_slice + int(slab_size / 2)) > int(
                len(files)):  # if centre slice + or - slab/2 is outside the range of slices
            continue

        im_gray_example = cv.imread(os.path.join(scan_dir, files[0]),-1)  # this is to get the dimensions for the np array in 16bit

        dummy_array = np.empty((im_gray_example.shape[0], im_gray_example.shape[1], slab_size))
        dummy_array[:] = np.NaN

        for k in range(int(centre_slice - slab_size / 2),
                       int(centre_slice + slab_size / 2)):  # grab slices that form the slab and load them in memory

            first_idx = int(centre_slice - slab_size / 2)
            # print(f"reading image {files[k]}")

            IMG = cv.imread(os.path.join(scan_dir, files[k]), -1)

            for i in range(0, im_gray_example.shape[0]):
                for j in range(0, im_gray_example.shape[1]):
                    dummy_array[i][j][k - first_idx] = IMG[i][j]  ##loading entire stack in memory to then calculate the median grey for each pixel position

        out_array_median = np.zeros((im_gray_example.shape[0], im_gray_example.shape[1]), dtype='uint16')

        # other images that can be produced with different operations include
        # out_array_avg = np.zeros((im_gray_example.shape[0], im_gray_example.shape[1]), dtype='uint16')
        # out_array_sum = np.zeros((im_gray_example.shape[0], im_gray_example.shape[1]), dtype='float')
        # c = np.zeros((im_gray_example.shape[0], im_gray_example.shape[1]), dtype='uint16')
        # new_array = np.zeros((im_gray_example.shape[0], im_gray_example.shape[1]), dtype='uint16')
        # d1 = np.zeros((im_gray_example.shape[0], im_gray_example.shape[1]), dtype='uint16')

        for line in range(0, im_gray_example.shape[0]):  #
            # print(f"{str(line)}")
            for col in range(0, im_gray_example.shape[1]):
                series = []  # flush out old values
                series = dummy_array[line][col][:]

                if np.all(series == series[0]):  # if all elements are the same
                    # new_array[line][col] = series[0]
                    pass
                else:
                    out_array_median[line][col] = int(np.median(series))  # get the grey median along the k dimension
                    # out_array_avg[line][col] = int(series.mean())  # get the mean grey along the k dimension
                    # out_array_sum[line][col] = series.sum() # get the grey sum along the k dimension

                    # if series[-1] != 0: #if last one is different than zero then perform scaling acording to median dif doing stepwise transform
                    # Todo function that do scaling of time_series based on moving median?
                    # d1[line][col] = int((np.median(series[0:len(series)-1])/series[-1]) * series[-1])
                    # else: #if last one is zero then get just median of the last elements
                    #    d1[line][col] = int(np.median(series[0:len(series)-1]))

                # if np.all(series == series[0]):  # if all elements are the same
                #     new_array[line][col] = series[0]
                # elif np.corrcoef(range(0, dummy_array.shape[2]), series)[0][1] < 0:
                #     new_array[line][col] = series.min()
                # elif np.corrcoef(range(0, dummy_array.shape[2]), series)[0][1] > 0:
                #     new_array[line][col] = series.max()

        # scaler = MinMaxScaler(feature_range=(0, 65536))
        # scaler.fit(out_array_sum)
        # c = scaler.transform(out_array_sum)
        # c_int_array = c.astype(dtype='uint16')

        # d_int_array = d1.astype(dtype='uint16')

        # saving out arrays

        if not os.path.exists(os.path.join(scan_dir, 'Slabs')):  # add path in dir if does not exist
            os.makedirs(os.path.join(scan_dir, 'Slabs'))

        out_path = os.path.join(scan_dir, 'Slabs')

        print('The virtual slab will be saved at --> ' + os.path.join(scan_dir, 'Slabs'))
        # os.chdir(os.path.join(top_dir, 'Slabs'))

        # Flags to identify if folders exist and the type of slab the run is handling
        Ortho = False
        Growth = False
        OtherFormat = False

        if 'TIFF_VerticalAxis' in files[0].split("\\"):
            basefilename = files[0].split("\\")[-1].split('VerticalAxis')[0]
            centre_slice_original_index = (files[k].split("VerticalAxis")[-1]).split(".tif")[0]
            Growth = True

        elif 'TIFF_HorizontalAxis' in files[0].split("\\"):
            basefilename = files[0].split("\\")[-1].split('HorizontalAxis')[0]
            centre_slice_original_index = (files[k].split("HorizontalAxis")[-1]).split(".tif")[0]
            Ortho = True

        elif not Ortho and not Growth:
            basefilename = files[0].split("\\")[-1].split('.tif')[0]
            centre_slice_original_index = files[k].split("\\")[-1].split(".tif")[0].split('_')[1]
            OtherFormat = True

        # cv.imwrite(f"{basefilename}_CentreSlice_{centre_slice_original_index}_Slab_size_{slab_size}_avg.tif",out_array_avg)  # this is to get the dimensions for the np array
        # cv.imwrite(f"{basefilename}_CentreSlice_{centre_slice_original_index}_Slab_size_{slab_size}_sum_scaled.tif", c_int_array)
        # cv.imwrite(f"{basefilename}_CentreSlice_{centre_slice_original_index}_Slab_size_{slab_size}_min_max_filtered.tif", new_array)

        if Ortho:  # if handling an orthogonal slab
            filename = f"{basefilename}_Axis_Horizontal_CentreSlice_{centre_slice_original_index}_Slab_num_{slab_size}_Slab_size_{round(slab_size*voxel_size,1)}_mm.tif"
        if Growth:  # if handling a growth axis slab
            filename = f"{basefilename}_Axis_Vertical_CentreSlice_{centre_slice_original_index}_Slab_num_{slab_size}_Slab_size_{round(slab_size*voxel_size,1)}_mm.tif"
        if OtherFormat:
            filename = f"{basefilename}_Axis_Growth_CentreSlice_{centre_slice_original_index}_Slab_num_{slab_size}_Slab_size_{round(slab_size*voxel_size,1)}_mm.tif"

        cv.imwrite(os.path.join(out_path, filename), out_array_median)
        # cv.imwrite(f"{basefilename}_CentreSlice_{centre_slice_original_index}_Slab_size_{slab_size}_median_scaled_top.tif", d_int_array)


if __name__ == '__main__':

    root = Tk()
    root.withdraw()
    folder_selected = filedialog.askdirectory(title='Select the parent folder containing the oblique stacks. This is where a Slab dir will be saved')
    top_dir = folder_selected
    voxel_size = get_vsize_from_CT_filetypes(top_dir)

    print(f"Sweeping though {top_dir} to find new slab directories to produce virtual slabs \n")
    paths = find_slab_dirs(top_dir)

    if bool(paths) is True:  # if there are new paths to have slabs produced for then
        slab_dic = {}
        for i in range(0, len(paths)):
            print(f" New directory found {paths[i]}")
            file_list = get_tiff_stack(paths[i])
            slab_dic[i] = {'Path': paths[i],
                           'TIFF_Stack': file_list}

        slab_thickness = 3 #each slab with 3mm thickness as default
        default_size = int(slab_thickness / voxel_size)   #equivalent number of slices to make a 3 mm slab
        strides = [default_size, int(default_size/2)] # modify stride so jump from centre slices is equally spaced (first is a 3mm equivalent slab, second is flexible size)

        # build iterator tuple
        iterator = []
        slab_mode = str.lower(input("Type in the slab mode you want to execute (Simple (i.e., stride fixed) or Flexible (i.e., 3 mm and 1.5 mm slabs))?: \n"))

        for i in range(0, len(slab_dic)):
            if slab_mode == 'simple':
                #for j in range(0,len(strides)):
                slab_centres = get_centre_position(slab_dic[i], strides[0]) ##only get going with first stride element
                for k in range(0, len(slab_centres)):
                    iterator.append((slab_dic[i], strides[0], slab_centres[k], voxel_size))

            elif slab_mode == 'flexible':
                for j in range(0,len(strides)):
                    slab_centres = get_centre_position(slab_dic[i], strides[j]) ##get going with all stride elements
                    for k in range(0, len(slab_centres)):
                        iterator.append((slab_dic[i], strides[j], slab_centres[k], voxel_size))

        # bbb = zip(itertools.repeat(slab_dic[0], strides)
        with multiprocessing.Pool(processes=20) as p:
            p.starmap(make_slab, iterator)

        # test
        # make_slab(iterator[-1][0], iterator[-1][1], iterator[-1][2])

    else:
        print(f"All scans in {top_dir} have had their slabs produced")
