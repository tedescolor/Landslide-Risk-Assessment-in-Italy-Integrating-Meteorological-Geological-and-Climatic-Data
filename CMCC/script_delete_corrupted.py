import os
import netCDF4

def check_and_delete_nc_files(directory_path):
    corrupted_files = []

    # Iterate over each file in the directory
    for filename in os.listdir(directory_path):
        if filename.endswith(".nc"):  # Check if the file is a NetCDF file
            file_path = os.path.join(directory_path, filename)
            try:
                # Attempt to open the file
                with netCDF4.Dataset(file_path, 'r') as dataset:
                    # You can perform additional checks here if necessary
                    pass
                print(f"File {filename} is OK.")
            except Exception as e:
                # If an error occurs, add the file to the list of corrupted files
                corrupted_files.append(filename)
                print(f"Failed to open file {filename}: {e}. Deleting file.")
                # Delete the corrupted file
                os.remove(file_path)

    return corrupted_files

# Directory containing the .nc files
directory_path = '/media/lorenzo/External HDD/03_CMCC'

# Check the files, delete corrupted ones, and get the list of deleted files
corrupted_files = check_and_delete_nc_files(directory_path)
if corrupted_files:
    print("Deleted corrupted or incomplete files:")
    print('\n'.join(corrupted_files))
else:
    print("All files are good and no deletions were necessary.")

