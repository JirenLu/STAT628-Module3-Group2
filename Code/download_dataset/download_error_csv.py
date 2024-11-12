import requests
import time

year = 2018
download_timeout = []
download_error = []

with open(f'climatological_data_{year}/download_error_{year}.txt', 'r') as file:
    lines = [line.strip() for line in file]
for file_name in lines:
    try:
        response = requests.get(f'https://www.ncei.noaa.gov/oa/local-climatological-data/v2/access/{year}/{file_name}',
                                timeout=30)
        response.raise_for_status()
        with open(f'climatological_data_{year}/{file_name}', 'wb') as file:
            file.write(response.content)
    except requests.exceptions.Timeout:
        download_timeout.append(file_name)
    except:
        download_error.append(file_name)
    time.sleep(0.2)

with open(f'climatological_data_{year}/download_timeout_{year}.txt', 'r') as file:
    lines = [line.strip() for line in file]
for file_name in lines:
    try:
        response = requests.get(f'https://www.ncei.noaa.gov/oa/local-climatological-data/v2/access/{year}/{file_name}',
                                timeout=30)
        response.raise_for_status()
        with open(f'climatological_data_{year}/{file_name}', 'wb') as file:
            file.write(response.content)
    except requests.exceptions.Timeout:
        download_timeout.append(file_name)
    except:
        download_error.append(file_name)
    time.sleep(0.2)

with open(f'climatological_data_{year}/download_timeout_{year}.txt', 'w') as file:
    for item in download_timeout:
        file.write(f"{item}\n")
with open(f'climatological_data_{year}/download_error_{year}.txt', 'w') as file:
    for item in download_error:
        file.write(f"{item}\n")
