from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from bs4 import BeautifulSoup
import pandas as pd
import time

geckodriver_path = r'C:\Users\15721\AppData\Local\Mozilla\Firefox\geckodriver.exe'
options = Options()
service = Service(executable_path=geckodriver_path)
driver = webdriver.Firefox(service=service, options=options)

df = pd.DataFrame(columns=['Object', 'URL', 'Last_Modified', 'Timestamp', 'Size', 'Page'])

# 请求网页
year = 2024
url = f'https://www.ncei.noaa.gov/oa/local-climatological-data/index.html#v2/access/{str(year)}/'
driver.get(url)
time.sleep(5)
for page in range(1, 230):  # 默认每页50行数据
    time.sleep(0.5)
    # 解析
    html_content = driver.page_source
    soup = BeautifulSoup(html_content, 'html.parser')
    file_list_table = soup.find('tbody', id='tbody-s3objects')
    # 解析逐行数据
    rows_list = []
    for row in file_list_table.find_all('tr'):
        columns = row.find_all('td')
        link = columns[0].find('a')
        href = link.get('href')
        file_name = link.get_text(strip=True)
        file_last_modified = columns[1].get_text(strip=True)
        file_timestamp = columns[2].get_text(strip=True)
        file_size = columns[3].get_text(strip=True)
        # print(file_name, file_last_modified, file_timestamp, file_size)
        row_dict = {'Object': file_name,
                    'URL': href,
                    'Last_Modified': file_last_modified,
                    'Timestamp': file_timestamp,
                    'Size': file_size,
                    'Page': page}
        rows_list.append(row_dict)
    df = pd.concat([df, pd.DataFrame(rows_list)], ignore_index=True)
    next_button = driver.find_element(By.XPATH, '//*[@id="tb-s3objects_next"]/a')
    next_button.click()

df.to_csv(f'climatological_data_{year}.csv', index=False)
driver.quit()
