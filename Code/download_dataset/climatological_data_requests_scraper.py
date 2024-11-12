import requests
from bs4 import BeautifulSoup
import pandas as pd
import time

# 请求网页
year = 2018
url = f'https://www.ncei.noaa.gov/oa/local-climatological-data/index.html#v2/access/{str(year)}/'
response = requests.get(url)
if not response.status_code == 200:
    print(f"无法访问网页，状态码：{response.status_code}")

# 解析
html_content = response.text
soup = BeautifulSoup(html_content, 'html.parser')
file_list_table = soup.find('tbody', id='tbody-s3objects')
print(file_list_table)

# 逐行数据
for row in file_list_table.find_all('tr'):
    columns = row.find_all('td')
    link = columns[0].find('a')
    href = link.get('href')
    file_name = link.get_text(strip=True)
    file_last_modified=columns[1].get_text(strip=True)
    file_timestamp = columns[2].get_text(strip=True)
    file_size = columns[3].get_text(strip=True)
    print(file_name, file_last_modified, file_timestamp, file_size)
    break

