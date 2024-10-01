"""
# This code extracts X-ray slice stacks across orientations given by the user, which correspond to vertical and
# horizontal growth planes of coral skeletons
# these stacks are then later passed to 'parallel_make_slabs_from_tif.py' to produce virtual slabs of chosen thicknesses
Author: Leonardo Bertini (l.bertini@nhm.ac.uk)
"""

"""
Instructions:
The following code under triple quotes should be 'pasted' into an AVIZO Python console...
and point to the path of AVIZO_oblique_slice_extractor.py on the local drive 
adjusted accordingly on line 70 of this script
"""

"""
import sys
import os
import math
from ctypes import windll, create_unicode_buffer, c_wchar_p, sizeof
from string import ascii_uppercase

def get_win_drive_names(DriveLabel):
    volumeNameBuffer = create_unicode_buffer(1024)
    fileSystemNameBuffer = create_unicode_buffer(1024)
    serial_number = None
    max_component_length = None
    file_system_flags = None
    drive_names = []
    drive_letters = []
    #  Get the drive letters, then use the letters to get the drive names
    bitmask = (bin(windll.kernel32.GetLogicalDrives())[2:])[::-1]  # strip off leading 0b and reverse
    drives = [ascii_uppercase[i] + ':/' for i, v in enumerate(bitmask) if v == '1']

    for d in drives:
        rc = windll.kernel32.GetVolumeInformationW(c_wchar_p(d), volumeNameBuffer, sizeof(volumeNameBuffer),
                                                   serial_number, max_component_length, file_system_flags,
                                                   fileSystemNameBuffer, sizeof(fileSystemNameBuffer))

        if rc: #detects if drive is connected
            drive_letters.append(d)
            drive_names.append(volumeNameBuffer.value)
            #drive_names.append(f"{volumeNameBuffer.value}({d[:2]})")  # disk_name(C:)


    Dict = dict(zip(drive_names,drive_letters))

    # up to this point Dic has a mapping of Drive Names to Drive Letters
    # get the drive letter corresponding to DriveLabel
    print('The Drive')
    print(DriveLabel)
    print('Is connected as')
    print(Dict[DriveLabel])
    selected_drive_letter = Dict[DriveLabel]
    return selected_drive_letter

DriveRootLetter = get_win_drive_names('SeagateBackupPlusDrive')
Code_Location = os.path.join(os.path.abspath(DriveRootLetter),'4d_reef\\Coding\\Getting_Stacks\\')
sys.path.append(Code_Location)


# exec(open(os.path.join(Code_Location, 'crawler_for_new_xy_Stacks.py')).read(), globals())
# exec(open(os.path.join(Code_Location, 'AVIZO_oblique_slice_volume_alignment.py')).read(), globals())

...
The extraction of slices out of the raw volume files is automatic and the code below is executed

PS: before pasting the code into the Python Console on AVIZO, make sure the program
'craweler_for_new_xy_Stacks.py' is running OK to get the latest directories for which TIFF stacks
will be created.

PS. if you want to generate metadata from raw volumes without exporting stacks .. change line 14 in
'craweler_for_new_xy_Stacks.py' so a dummy dir is used in the search and all the raw volumes are grabbed 
wihtout exporting the stacks (change this in the future to a 'Metadata extract mode'

#exec(open("C:\\Users\\ctlablovelace\\PycharmProjects\\Getting_Stacks_backup\\AVIZO_oblique_slice_extractor.py").read(), globals())
"""

# beggining of python script using AVIZO API
import os
import cv2 as cv
import time
import numpy as np
from tkinter import filedialog
from tkinter import *
from PyQt5.QtWidgets import QInputDialog, QMessageBox

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

                extracted_object = hx_project.get(input_data.name.split('.am')[0]+'(2).am-Ortho-Slice')
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


# 1) Loading Aligned Vol and getting dimensions
#after alinging the volume the usual yz plane is the one showing the major growth axis

# os.chdir("F:\\4d_reef\\Coding\\Getting_Stacks") #path to the code
# Drive_Letter = Utils.Leo_Utils.get_win_drive_names('SeagateBackupPlusDrive')
# df = pd.read_json(os.path.join(Drive_Letter, '4d_reef', 'Coding', 'Getting_Stacks', 'points_defined.json'))
# col = df.columns[1]

########## -MANUAL SLICE EXTRACTION FROM THIS POINT #####################

#input_data = hx_project.get(df[col]['Avizo_object_name'].split('masked')[0]+'Aligned.am') # todo fix this with full path detecting Aligned objects
folder_selected = filedialog.askdirectory(title='Select the scan parent folder where tif oblique directories will be created')
base_dir = folder_selected

msg = QMessageBox()
msg.setIcon(QMessageBox.Critical)
# setting message for Message Box
msg.setText("Keep the name of the aligned object in the clipboard so it can be pasted next")
# setting Message box window title
msg.setWindowTitle("WARNING")
msg.setStandardButtons(QMessageBox.Ok)
retval = msg.exec_()

aligned_vol_name = getTextInput('Indicate volume object to process', 'Enter the name of Avizo aligned volume from project space: ')
input_data = hx_project.get(aligned_vol_name)
#aligned_vol_name = 'LB_Porites_RMNH-COEL-10165_140kV_Cu2mm_perc.aligned.am'

input_data.selected = True
x_max = int(input_data.ports.LatticeInfo.text.split('x')[0].split(' ')[0])
y_max = int(input_data.ports.LatticeInfo.text.split('x')[1].split(' ')[1])
z_max = int(input_data.ports.LatticeInfo.text.split('x')[2].split(',')[0])

msg = QMessageBox()
msg.setIcon(QMessageBox.Critical)
# setting message for Message Box
msg.setText("Next, inform the Orientation for the aligned planes that correspond to the Vertical and Horizontal growth axes")
# setting Message box window title
msg.setWindowTitle("WARNING")
msg.setStandardButtons(QMessageBox.Ok)
retval = msg.exec_()


VerticalAxisPlane = getTextInput('Indicate Vertical Growth Axis Plane', 'Type one of the following - XY or XZ or YZ')
HorizontalAxisPlane = getTextInput('Indicate Horizontal Growth Axis Plane', 'Type one of the following - XY or XZ or YZ')

# 2) Exporting growth axis stack

#base_dir = df[col]['base_dir']
hx_project.create("HxOrthoSlice")  # create Ortho Object
slice1 = hx_project.get("Ortho Slice")  # Assign Ortho Object to a variable
slice1.name = "Slice 1"
hx_project.create("HxCreateImage")  # create Extract Image object

if str.lower(VerticalAxisPlane) == 'xy':
    slice1.ports.sliceOrientation._set_state('value 0') #setting orientation to xy of the volume already transformed to match global xy axes
    max_slice1 = z_max

elif str.lower(VerticalAxisPlane) == 'xz':
    slice1.ports.sliceOrientation._set_state('value 1') #setting orientation to xz of the volume already transformed to match global xy axes
    max_slice1 = y_max

elif str.lower(VerticalAxisPlane) == 'yz':
    slice1.ports.sliceOrientation._set_state('value 2')  # setting orientation to yz of the volume already transformed to match global xy axes
    max_slice1 = x_max

slice1.ports.data.connect(input_data)  # connect to data
slice1.fire()


#then take one that is perpendicular and export too
#this can be set by changing from xy to yz --> exporting across x
#so max_slices gets x_max

#base_dir = df[col]['base_dir']
folder_out = os.path.join(base_dir)
hx_project.create("HxOrthoSlice")  # create Ortho Object
slice2 = hx_project.get("Ortho Slice")  # Assign Ortho Object to a variable
slice2.name = "Slice 2"
hx_project.create("HxCreateImage")  # create Extract Image object

if str.lower(HorizontalAxisPlane) == 'xy':
    slice2.ports.sliceOrientation._set_state('value 0') #setting orientation to xy of the volume already transformed to match global xy axes
    max_slice2 = z_max

elif str.lower(HorizontalAxisPlane) == 'xz':
    slice2.ports.sliceOrientation._set_state('value 1') #setting orientation to xz of the volume already transformed to match global xy axes
    max_slice2 = y_max

elif str.lower(HorizontalAxisPlane) == 'yz':
    slice2.ports.sliceOrientation._set_state('value 2')  # setting orientation to yz of the volume already transformed to match global xy axes
    max_slice2 = x_max

slice2.ports.data.connect(input_data)  # connect to data
slice2.fire()


VoxelsizeGrowthPlane = write_slice(input_data, slice_obj=slice1, max_slices=max_slice1, out_dir=base_dir,
                                   sweep_mode='WholeCoral', slice_orientation='VerticalAxis')

VoxelsizeOrthoPlane = write_slice(input_data, slice_obj=slice2, max_slices=max_slice2, slice_orientation='HorizontalAxis',
                                  out_dir=base_dir, sweep_mode='WholeCoral')

