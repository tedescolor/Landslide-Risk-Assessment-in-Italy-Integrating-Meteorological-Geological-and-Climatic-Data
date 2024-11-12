# Data Download Script

This script automates the download of ERA5 downscaled data for Italy from the Climate Data Store (CDS).

## Prerequisites
- Python 3.x
- `ddsapi` library (can be installed via pip)

## Configuration
- Edit the script to include your own API key for the CDS.
- The script is set to download data for multiple variables and vertical levels from the year 2000 to 2022.

## How It Works
- The script checks if a file already exists to avoid re-downloading.
- Utilizes a ThreadPoolExecutor to parallelize downloads and increase efficiency.
- Files are named in the format `era5downscaled_{variable}_vertical_{vertical}_{year}_{month}.nc`.

## Running the Script
Execute the script in your Python environment:
```bash
python script.py
```

### README.md for `script_check_files.py`
```markdown
# File Integrity Check Script

This script checks the integrity of downloaded ERA5 downscaled data files by verifying their existence and attempting to open them to ensure they are not corrupted.

## Prerequisites
- Python 3.x
- `netCDF4` library (can be installed via pip)

## Configuration
- The script is pre-configured to check data files spanning from 2000 to 2022 for multiple variables and vertical levels.

## How It Works
- Identifies missing files and attempts to open each existing file to check for corruption.
- Reports missing and corrupted files, providing a list of such files.

## Running the Script
Execute the script in your Python environment:
```bash
python script_check_files.py
```


### README.md for `script_delete_corrupted.py`
```markdown
# Corrupted File Deletion Script

This script scans a directory for NetCDF files and deletes those that cannot be opened (indicative of file corruption).

## Prerequisites
- Python 3.x
- `netCDF4` library (can be installed via pip)

## Configuration
- Specify the directory containing your `.nc` files by editing the `directory_path` variable.

## How It Works
- Scans the specified directory for `.nc` files.
- Attempts to open each file and deletes it if an error occurs, indicating corruption.
- Reports the names of deleted files, if any.

## Running the Script
Execute the script in your Python environment:
```bash
python script_delete_corrupted.py
```
