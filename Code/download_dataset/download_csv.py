import pandas as pd
import requests
import os
import time

year = 2019
os.makedirs(f'climatological_data_{year}', exist_ok=True)
df = pd.read_csv(f'climatological_data_{year}.csv')
download_timeout = []
download_error = []
for index, row in df.iterrows():
    url = row['URL']
    file_name = row['Object']
    try:
        response = requests.get(url, timeout=10)
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
