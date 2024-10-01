
"""
This is a script that resamples 3D volumes into lower resolution for the purposes of hosting them on a 'Discovery layer' visualization platform
Instructions:
Copy the following line to an Avizo python console to execute indicating the full path on the local machine
#exec(open("C:\\Users\\ctlablovelace\\PycharmProjects\\Getting_Stacks_backup\\Avizo_VolumeResampler.py").read(), globals())

Author: Leonardo Bertini (l.bertini@nhm.ac.uk)
"""

# beggining of python script using AVIZO API
import os
import cv2 as cv
import time
import numpy as np
from tkinter import filedialog
from tkinter import *
from PyQt5.QtWidgets import QInputDialog, QMessageBox
import pandas as pd


def write_slice(input_data, slice_obj, slice_orientation, out_dir, sweep_mode,
                max_slices):

    option_viewer_settings_selected = 'values 5 0 0 1 0 0 isTristate 0 0 0 0 0 mask 1 1 1 1 1'
    option_viewer_settings_deselected = 'values 5 0 0 0 0 0 isTristate 0 0 0 0 0 mask 1 1 1 1 1'

    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    print('Slices will be saved at --> ' + out_dir)
    os.chdir(out_dir)

    if sweep_mode == 'WholeCoral':

        for item in range(0, max_slices):

            slice_obj.ports.sliceNumber.value = item

            slice_obj.all_interfaces.HxPlanarModBase.ports.options._set_state(option_viewer_settings_deselected)
            slice_obj.all_interfaces.HxPlanarModBase.ports.options._set_state(option_viewer_settings_selected)
            slice_obj.execute()  # click apply to make change and update array data

            if slice_orientation == 'VerticalAxis':

                path_out = os.path.join(out_dir, 'TIFF_VerticalAxis')

                if not os.path.exists(path_out):
                    os.makedirs(path_out)
                print('Slices will be saved at --> ' + path_out)
                os.chdir(path_out)

                img = hx_project.get("Extract Image")
                img.name = "Extract Image"

                img.ports.data.connect(slice_obj)  # connect to data
                img.fire()  # apply change
                img.execute()  # click apply to make change and update array data

                extracted_object = hx_project.get(input_data.name +'-Ortho-Slice')
                ## Need to grab by clicking the Extract image object the first time this is called
                extracted_object.selected = True
                # TODO get voxel size and update json
                VoxelSize_x, VoxelSize_y = map(float, input_data.ports.VoxelSize.text.split(" x ")[:2])
                VoxelSize_z = input_data.ports.VoxelSize.text.split(" x ")[-1].split(' [mm]')[0]
                # max_of_slices.append(math.floor(7/VoxelSize_x))
                #df[col]['VoxelSize_Growth_Stack'] = VoxelSize_x

                image_base_name = input_data.name.split(".tif")[0] + '_VerticalAxis-Slice_'

                array = extracted_object.get_array()  # getting np array for slice
                bb = np.rot90(array, k=1, axes=(1, 0))  # somehow array is flipped when loaded
                bb = np.flip(bb, 1)  # rotating..
                cv.imwrite(os.path.join(path_out, image_base_name + str(item).zfill(5) + ".tif"),bb)  # saving file under cwd

            if slice_orientation == 'HorizontalAxis':

                path_out = os.path.join(out_dir, 'TIFF_HorizontalAxis')

                if not os.path.exists(path_out):
                    os.makedirs(path_out)
                print('Slices will be saved at --> ' + path_out)
                os.chdir(path_out)


                img = hx_project.get("Extract Image(2)")
                img.name = "Extract Image(2)"

                img.ports.data.connect(slice_obj)  # connect to data
                img.fire()  # apply change
                img.execute()  # click apply to make change and update array data

                try:
                    extracted_object = hx_project.get(input_data.name.split('.resampled')[0]+'(2).resampled-Ortho-Slice')
                except:
                    extracted_object = hx_project.get(input_data.name + '-Ortho-Slice')

                extracted_object.selected = True
                # TODO get voxel size and update json
                VoxelSize_x, VoxelSize_y = map(float, input_data.ports.VoxelSize.text.split(" x ")[:2])
                VoxelSize_z = input_data.ports.VoxelSize.text.split(" x ")[-1].split(' [mm]')[0]
                #df[col]['VoxelSize_Ortho_Stack'] = VoxelSize_x

                image_base_name = input_data.name.split(".tif")[0] + '_HorizontalAxis-Slice_'

                array = extracted_object.get_array()  # getting np array for slice
                bb = np.rot90(array, k=1, axes=(1, 0))  # somehow array is flipped when loaded
                bb = np.flip(bb, 1)  # rotating..
                cv.imwrite(os.path.join(path_out, image_base_name + str(item).zfill(5) + ".tif"),bb)  # saving file under cwd

    return VoxelSize_x

def getTextInput(title, message):
    answer = QInputDialog.getText(None, title, message)
    if answer[1]:
        print(answer[0])
        return answer[0]
    else:
        return None

#COMPLETE TODO READ in slice orientations for all scans from spreadsheet
spreadsheet_path = filedialog.askopenfilename(title='Select the csv file containing orientation of cuts. Scans_AlignmentOrientations.csv')
orientations_dataframe= pd.read_csv(spreadsheet_path)


# input_data = hx_project.get(df[col]['Avizo_object_name'].split('masked')[0]+'Aligned.am') # todo fix this with full path detecting Aligned objects
folder_selected = filedialog.askopenfilename(title='Select the folder containing .am files of aligned scans')
base_dir = folder_selected


#COMPLETE TODO prompt user for downsampling factor
UserDownsampling = getTextInput(title='Define a downsampling factor', message='Type in a number between 0-10 for a downsampling factor')
Downsampling_factor=int(UserDownsampling)

time_start=time.time()

for file in os.listdir(base_dir): ####starts loop over all files

    if file.endswith('.am'):
        #file = os.listdir(base_dir)[0] #test on a single volume
        filepath = os.path.join(base_dir,file)

        print('Opening Scan')
        print(filepath)
        dataobject = hx_object_factory.load(filepath)
        hx_project.add(dataobject)
        dataobject.selected = True
        VoxelSize_x, VoxelSize_y = map(float, dataobject.ports.VoxelSize.text.split(" x ")[:2])

        NewVoxelSize = VoxelSize_x * Downsampling_factor

        #COMPLETE TODO touch object and apply resample

        hx_project.create("HxResample")
        try:
            resamplebox = hx_project.get("Resample(2)")  # Assign Ortho Object to a variable
        except:
            resamplebox = hx_project.get("Resample")  # Assign Ortho Object to a variable

        resamplebox.name = "Resample"

        resamplebox.ports.data.connect(dataobject)
        resamplebox.selected=TRUE
        resamplebox.ports.mode._set_state('value 0')    #select dimensions-based
        resamplebox.fire() #with every change in buttons selected, invoke fire to update data tables in the backgroud (otherwise Avizo crashes)
        resamplebox.ports.mode._set_state('value 1')    #select voxel size based resampling

        voxel_resampling_state = resamplebox.ports.voxelSize._get_state()

        elements = voxel_resampling_state.split(' ')

        elements[-1],elements[-2],elements[-3], = str(NewVoxelSize) ,str(NewVoxelSize) ,str(NewVoxelSize)

        elements_new = ' '.join(elements)

        resamplebox.ports.voxelSize._set_state(elements_new)
        resamplebox.fire() #with every change in buttons selected, invoke fire to update data tables in the backgroud (otherwise Avizo crashes)

        resamplebox.execute() #click apply buttom

        #COMPLETE TODO create dir for tiff stack
        path_stack=os.path.join(base_dir,'ResampledStacks',file.split('.aligned.am')[0])
        if not os.path.exists(path_stack):
            os.makedirs(path_stack)
        print('Slices will be saved at --> ' + path_stack)

        #COMPLETE TODO LOCATE SCAN ON DATAFREAME AND GET HORIZONTAL AND VERTICAL ORIENTATIONS
        for item in orientations_dataframe['ScanName']:
            if item in file:
                filtered_df = orientations_dataframe.loc[orientations_dataframe['ScanName'] == item]
                filtered_df = filtered_df.reset_index()
                HorizontalAxisPlane = filtered_df['HorizontalCut'][0]
                VerticalAxisPlane = filtered_df['VerticalCut'][0]

        # COMPLETE TODO export tiff stack from resampled coral
        resampled_obj_name = file.replace('am','resampled')
        LowResCoral = hx_project.get(resampled_obj_name)

        LowResCoral.selected = True
        x_max = int(LowResCoral.ports.LatticeInfo.text.split('x')[0].split(' ')[0])
        y_max = int(LowResCoral.ports.LatticeInfo.text.split('x')[1].split(' ')[1])
        z_max = int(LowResCoral.ports.LatticeInfo.text.split('x')[2].split(',')[0])

        hx_project.create("HxOrthoSlice")  # create Ortho Object
        slice1 = hx_project.get("Ortho Slice")  # Assign Ortho Object to a variable
        slice1.name = "Slice 1"
        hx_project.create("HxCreateImage")  # create Extract Image object

        if str.lower(VerticalAxisPlane) == 'xy':
            slice1.ports.sliceOrientation._set_state(
                'value 0')  # setting orientation to xy of the volume already transformed to match global xy axes
            max_slice1 = z_max

        elif str.lower(VerticalAxisPlane) == 'xz':
            slice1.ports.sliceOrientation._set_state(
                'value 1')  # setting orientation to xz of the volume already transformed to match global xy axes
            max_slice1 = y_max

        elif str.lower(VerticalAxisPlane) == 'yz':
            slice1.ports.sliceOrientation._set_state(
                'value 2')  # setting orientation to yz of the volume already transformed to match global xy axes
            max_slice1 = x_max


        slice1.ports.data.connect(LowResCoral)  # connect to data
        slice1.fire()

        hx_project.create("HxOrthoSlice")  # create Ortho Object
        slice2 = hx_project.get("Ortho Slice")  # Assign Ortho Object to a variable
        slice2.name = "Slice 2"
        hx_project.create("HxCreateImage")  # create Extract Image object

        if str.lower(HorizontalAxisPlane) == 'xy':
            slice2.ports.sliceOrientation._set_state(
                'value 0')  # setting orientation to xy of the volume already transformed to match global xy axes
            max_slice2 = z_max

        elif str.lower(HorizontalAxisPlane) == 'xz':
            slice2.ports.sliceOrientation._set_state(
                'value 1')  # setting orientation to xz of the volume already transformed to match global xy axes
            max_slice2 = y_max

        elif str.lower(HorizontalAxisPlane) == 'yz':
            slice2.ports.sliceOrientation._set_state(
                'value 2')  # setting orientation to yz of the volume already transformed to match global xy axes
            max_slice2 = x_max

        slice2.ports.data.connect(LowResCoral)  # connect to data
        slice2.fire()



        # VoxelsizeGrowthPlane = write_slice(input_data=LowResCoral, slice_obj=slice1, max_slices=max_slice1, out_dir=path_stack,
        #                                   sweep_mode='WholeCoral', slice_orientation='VerticalAxis')

        VoxelsizeOrthoPlane = write_slice(input_data=LowResCoral, slice_obj=slice2, max_slices=max_slice2,
                                          slice_orientation='HorizontalAxis',
                                          out_dir=path_stack, sweep_mode='WholeCoral')


        #COMPLETE TODO close current scan and move onto the next
        hx_project.remove_all()  #close scan

time_end=time.time()
time_elapsed = (time_end-time_start)/60
print('time_elapsed in minutes')
print(time_elapsed)