library(shiny)
library(shinyjs)


search_origin="SFO"
search_dest="ORD"



airport_data <- read.csv("data/airports_info_for_shiny.csv", stringsAsFactors = FALSE)
airline_avgtime_data <- read.csv("data/combined_flight_times.csv", stringsAsFactors = FALSE)

get_average_flight_time <- function(airline_network, origin, dest) {
  result <- airline_avgtime_data[airline_avgtime_data$Marketing_Airline_Network == airline_network & 
                   airline_avgtime_data$Origin == origin & 
                   airline_avgtime_data$Dest == dest, ]
  # 检查是否找到了对应的行
  if (nrow(result) > 0) {
    # 返回 Average_Flight_Time
    return(result$Average_Flight_Time[1])
  } else {
    return(NA)
  }
}

get_city_airport_name <- function(iata_code) {
  # Filter the data to find the row with the matching IATA code
  result <- airport_data[airport_data$IATA == iata_code, ]
  # Create and return the formatted string
  paste(result$City, " (", iata_code, ")", sep = "")
}

get_airport_name <- function(iata_code) {
  result <- airport_data[airport_data$IATA == iata_code, ]
  result$Name
}

get_airport_timezone <- function(iata_code) {
  result <- airport_data[airport_data$IATA == iata_code, ]
  timezone <- gsub("_", " ", result$Tz_database_timezone)
}

convert_to_ampm <- function(time_24) {
  Sys.setlocale("LC_TIME", "C")
  format(strptime(time_24, format = "%H:%M"), format = "%I:%M %p")
}


# 读指定航线、指定日期的所有航班
read_airport_data <- function(origin, dest, year, month, day) {
  file_path <- paste0("flights_data/", origin, "_", dest, ".csv")
  date <- paste(year, month, day, sep = "_")
  # 检查文件是否存在
  if (!file.exists(file_path)) {
    return(list())
  }
  # 读取 CSV 文件，确保列名匹配
  data <- read.csv(file_path, stringsAsFactors = FALSE)
  data <- subset(data, Date == date)
  # 指定需要的列
  required_columns <- c("CRSDepTime_timezone", "CRSArrTime_timezone", 
                        "Marketing_Airline_Network", "Flight_Number_Marketing_Airline", 
                        "IATA_Code_Operating_Airline", "Flight_Number_Operating_Airline", 
                        "Flight_Duration", "Average_ArrDelay", "Cancellation_Rate", "Predicted")
  # 提取所需列并转换为字典列表
  data_list <- lapply(1:nrow(data), function(i) {
    as.list(data[i, required_columns])
  })
  return(data_list)
}


# 返回指定航线、指定日期的所有航班的UI卡片
generate_flight_data_cards_list <- function(search_origin, search_dest, search_year, search_month, search_day, search_airline){
  flight_data_list <- read_airport_data(search_origin, search_dest, search_year, search_month, search_day)
  if (search_airline != "ANY") {
    flight_data_list <- Filter(function(row) row$Marketing_Airline_Network == search_airline, flight_data_list)
  }
  # 渲染航班卡片
  output_flightCards <- renderUI({
    # 遍历 flight_data_list 中的每个航班信息，生成 UI 元素
    if (length(flight_data_list) == 0) {
      h4("No flight data found", style = "color: rgba(255, 255, 255, 0.6); text-align: center;font-size:16px;")
    } else {
      tagList(lapply(flight_data_list, function(flight) {
        # 提取航班信息
        dep_time <- substr(flight$CRSDepTime_timezone, 12, 16)
        arr_time <- substr(flight$CRSArrTime_timezone, 12, 16)
        flight_time <- gsub("^0?(\\d+):0?(\\d+)$", "\\1h\\2m", flight$Flight_Duration)
        origin_city_airport <- get_city_airport_name(search_origin)
        dest_city_airport <- get_city_airport_name(search_dest)
        market_airline_info <- flight$Flight_Number_Marketing_Airline
        market_airline_img<-paste0(flight$Marketing_Airline_Network, ".webp")
        
        # 渲染单个航班的卡片
        tags$button(
          class = "flight-card",
          onclick = "this.classList.toggle('expanded')",
          tags$div(
            class="card-content",
            tags$div(
              class="card-front",
              tags$img(src=market_airline_img,
                       style = "width: 50px; height: 50px; margin-right: 10px; border-radius: 5px; background-color: transparent;"),
              tags$div(
                style = "display: flex; flex-direction: column; width: 100%",
                tags$div(
                  style = "display: flex; width: 100%;",
                  tags$div(style = "width: 40%; text-align: left;flex-direction: column",
                           tags$div(dep_time, class="flight-card-time"),
                           tags$div(origin_city_airport, class = "flight-card-city")),
                  tags$div(style = "width: 30%; flex-direction: column; display: flex; align-items: center; gap: 0;",
                           tags$div(
                             style = "display: flex; align-items: center; width: 100%; justify-content: center;margin-top:9px;",
                             tags$div(class="flight-card-line"),
                             tags$div(flight_time, style = "padding: 0 8px; font-size: 13px; color: rgba(255, 255, 255, 0.9);"),
                             tags$div(class="flight-card-line"),
                           ),
                           tags$div(market_airline_info, style = "font-size: 12px;color: rgba(255, 255, 255, 0.5);margin-top:8px;")),
                  tags$div(style = "width: 40%; text-align: left;flex-direction: column",
                           tags$div(arr_time, class="flight-card-time"),
                           tags$div(dest_city_airport, class = "flight-card-city")),
                )
              )
            ),
            tags$div(
              class = "card-back",
              tags$div(style = "display: flex; flex-direction: column; padding-left: 20px; padding-right: 20px;",
                       tags$div(
                         style = "font-size: 12px; color: rgba(255, 255, 255, 0.8); text-align: left;",
                         operate_airline_info(flight)
                       ),
                       tags$div(
                         style = "display: flex; margin-top: 10px; align-items: center;",
                         tags$div(
                           style = "flex: 0 0 60%; text-align: left;",
                           tags$div(
                             style = "display: flex; align-items: flex-start;",
                             tags$img(src = "plane-departure-solid-white.png", style = "width: 16px; height: 16px; margin-top: 11px;"),
                             tags$div(
                               style = "display: flex; flex-direction: column; align-items: flex-start; margin-left: 10px;",
                               # 第一行：起飞时间和时区
                               tags$div(
                                 style = "display: flex;",
                                 tags$div(
                                   style = "color: rgba(255, 255, 255, 0.8); font-size: 17px; margin-top: 2px;",
                                   convert_to_ampm(dep_time)
                                 ),
                                 tags$div(
                                   style = "color: rgba(255, 255, 255, 0.5); font-size: 9px; margin-left: 15px; display: flex; flex-direction: column; align-items: flex-start;",
                                   tags$div("Timezone:"),
                                   tags$div(
                                     style = "margin-top: 0px;",
                                     get_airport_timezone(search_origin)
                                   )
                                 )
                               ),
                               # 第二行：机场全名
                               tags$div(
                                 style = "color: rgba(255, 255, 255, 0.9); font-size: 11px; display: flex;",
                                 get_airport_name(search_origin)
                               )
                             )
                           ),
                           tags$div(
                             style = "display: flex; align-items: flex-start; margin-top:5px;",
                             tags$img(src = "plane-arrival-solid-white.png", style = "width: 16px; height: 19px;margin-top: 11px;"),
                             tags$div(
                               style = "display: flex; flex-direction: column; align-items: flex-start; margin-left: 10px;",
                               # 第一行：降落时间和时区
                               tags$div(
                                 style = "display: flex;",
                                 tags$div(
                                   style = "color: rgba(255, 255, 255, 0.8); font-size: 17px; margin-top: 2px;",
                                   convert_to_ampm(arr_time)
                                 ),
                                 tags$div(
                                   style = "color: rgba(255, 255, 255, 0.5); font-size: 9px; margin-left: 15px; display: flex; flex-direction: column; align-items: flex-start;",
                                   tags$div("Timezone:"),
                                   tags$div(
                                     style = "margin-top: 0px;",
                                     get_airport_timezone(search_dest)
                                   )
                                 )
                               ),
                               # 第二行：机场全名
                               tags$div(
                                 style = "color: rgba(255, 255, 255, 0.9); font-size: 11px; display: flex;",
                                 get_airport_name(search_dest)
                               )
                             )
                           )
                         ),
                         tags$div(
                           style = "flex: 0 0 40%; text-align: left;",
                           tags$div(
                             style = "display: flex; flex-direction: column; gap: 5px;",
                             tags$div(
                               style = "display: flex; flex-direction: row;",
                               # 历史平均取消
                               tags$div(
                                 style = "text-align: left; font-size: 11px; color: rgba(255, 255, 255, 0.5);display: flex; align-items: flex-end;",
                                 "Avg. Cancel:"
                               ),
                               tags$div(
                                 style = "text-align: left; font-size: 14px; color: rgba(255, 255, 255, 0.8); margin-left: 12px;",
                                 percent <- sprintf("%.1f%%", flight$Cancellation_Rate * 100)
                               )
                             ),
                             tags$div(
                               style = "display: flex; flex-direction: column; gap: 5px;",
                               tags$div(
                                 style = "display: flex; flex-direction: row;",
                                 # 历史平均晚点
                                 tags$div(
                                   style = "text-align: left; font-size: 11px; color: rgba(255, 255, 255, 0.5);display: flex; align-items: flex-end;",
                                   "Avg. Arrival:"
                                 ),
                                 tags$div(
                                   style = "text-align: left; font-size: 14px; color: rgba(255, 255, 255, 0.8);margin-left: 16px;",
                                   status <- ifelse(
                                     flight$Average_ArrDelay < 0, 
                                     paste0(abs(flight$Average_ArrDelay), "min earlier"),
                                     ifelse(
                                       flight$Average_ArrDelay == 0, 
                                       "On time", 
                                       paste0(flight$Average_ArrDelay, " min late")
                                     )
                                   )
                                 )
                               )
                             ),
                             # 预计本班到达时间
                             tags$div(
                               style = "display: flex; flex-direction: column; gap: 5px;",
                               tags$div(
                                 style = "display: flex; flex-direction: row;",
                                 tags$div(
                                   style = "text-align: left; font-size: 11px; color: rgba(255, 255, 255, 0.5);display: flex; align-items: flex-end;",
                                   "Est. Arrival:"
                                 ),
                                 tags$div(
                                   style = "text-align: left; font-size: 14px; color: rgba(255, 255, 255, 0.8);margin-left: 19px;",
                                   status <- ifelse(
                                     flight$Predicted < 0,
                                     paste0(abs(flight$Predicted), "min earlier"),
                                     ifelse(
                                       flight$Predicted == 0, 
                                       "On time", 
                                       paste0(flight$Predicted, " min late")
                                     )
                                   )
                                 )
                               )
                             )
                           )
                         )
                       ))
            )
          )
        )
      }))
    }
  })
  return(output_flightCards)
}


# 定义航空公司全称和缩写的查找表函数
airline_lookup <- function(abbreviation) {
  lookup_table <- list(
    "ANY" = "Any Airline",
    "ZW" = "Air Wisconsin",
    "AS" = "Alaska Airlines",
    "G4" = "Allegiant Air",
    "AA" = "American Airlines",
    "9K" = "Cape Air",
    "C5" = "CommutAir",
    "CP" = "Compass Airlines",
    "DL" = "Delta Air Lines",
    "9E" = "Endeavor Air",
    "MQ" = "Envoy Air",
    "EM" = "Empire Airlines",
    "EV" = "ExpressJet Airlines",
    "F9" = "Frontier Airlines",
    "G7" = "GoJet Airlines",
    "HA" = "Hawaiian Airlines",
    "QX" = "Horizon Air",
    "B6" = "JetBlue Airways",
    "YV" = "Mesa Airlines",
    "KS" = "PenAir",
    "PT" = "Piedmont Airlines",
    "OH" = "PSA Airlines",
    "YX" = "Republic Airways",
    "OO" = "SkyWest Airlines",
    "WN" = "Southwest Airlines",
    "NK" = "Spirit Airlines",
    "AX" = "Trans States Airlines",
    "UA" = "United Airlines",
    "VX" = "Virgin America"
  )
  result <- lookup_table[[abbreviation]]
  if (is.null(result)) {
    return("Unknown Airline")
  } else {
    return(result)
  }
}


operate_airline_info <- function(flight) {
  # 查找Marketing和Operating的全称
  marketing_airline <- airline_lookup(flight$Marketing_Airline_Network)
  operating_airline <- airline_lookup(flight$IATA_Code_Operating_Airline)
  
  # 如果marketing和operating的缩写相同，返回Marketing的全称
  if (flight$Marketing_Airline_Network == flight$IATA_Code_Operating_Airline) {
    return(marketing_airline)
  } else {
    # 如果不同，返回格式化字符串 "Marketing航司全称 operated by Operating航司全称"
    return(paste(marketing_airline, "operated by", operating_airline))
  }
}



ui <- fluidPage(
  useShinyjs(),
  # 启用 shinyjs
  
  tags$head(
    tags$style(
      HTML(
        "
      .main-container{
        display: block;
      }
      
      .main-container-second-page {
        display: none;
      }
        
      .title-container {
        position: absolute;
        top: 20%; /* 页面的位置 */
        left: 50%;
        transform: translate(-50%, -50%);
        font-family: 'Palatino Linotype', 'Palatino', sans-serif;
        font-size: 50px;
        font-weight: bold;
        color: rgba(255, 255, 255, 0.8); /* 标题颜色 */
        text-align: center;
        display: block;
      }

      .title-underline {
        width: 80%; /* 直线的总宽度 */
        height: 2px; /* 设置中间的粗度 */
        margin: 19px auto; /* 居中对齐并设置与标题的距离 */
        background: linear-gradient(to right, transparent, rgb(215, 53, 57) 20%, rgb(215, 53, 57) 50%, rgb(215, 53, 57) 80%, transparent);
      }

      .video-bg {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          object-fit: cover;
          z-index: -1;/* 其他内容的后方 */
        }

      .main-content-box {
        position: absolute;
        top: 68%;  /* 距离页面顶部 */
        left: 68%;  /* 居中对齐页面 */
        transform: translate(-50%, -50%);
        display: flex;  /* 使用 Flexbox 布局，使内部元素可以水平排列 */
        justify-content: center;  /* 水平居中内部的元素 */
        align-items: center;  /* 垂直居中内部的元素 */
        flex-direction: column;/* 垂直排列内容，使每个内部 div 在新行显示 */
        gap: 0px;  /* 设置内部元素之间的间距 */
        padding: 20px;  /* 为内容框添加内部边距 */
        background-color: rgba(255, 255, 255, 0.2);  /* 设置内容框为半透明白色背景 */
        border-radius: 15px;  /* 设置内容框的圆角，使其有更柔和的外观 */
        box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.2);  /* 添加阴影效果，使内容框更加突出 */
        max-width: 600px;  /* 限制内容框的最大宽度为 600px */
      }

      .custom-input {
        width: 240px;  /* 设置输入框的宽度 */
        padding: 10px;  /* 设置输入框的内部边距 */
        font-size: 16px;  /* 设置输入框的字体大小 */
        border: none;
        border-radius: 5px;  /* 设置输入框的圆角 */
      }

      /* 小标题样式 */
      .input-label {
        font-weight: bold;
        font-size: 16px;
        margin-bottom: 5px;
        color: #B0B0B0;
      }

      /* 按钮样式 */
      .main-content-box-swap-button {
        font-size: 30px;
        padding: 5px 10px;
        color: #D73539; /* 按钮文字颜色为蓝色 */
        background: none; /* 无背景颜色 */
        border: none; /* 移除按钮的边框 */
        border-radius: 50%; /* 将按钮变为圆形 */
        cursor: pointer;
        margin-top: 22px;
      }

      .main-content-box-row-container {
        display: flex;
        gap: 5px;
        justify-content: center;
        width: 100%; /* 确保每行的宽度一致 */
      }

      .main-content-box-column-container {
        display: flex;
        flex-direction: column;
        gap: 0px;
      }

      /* 弹窗样式 */
      .suggestions-container {
        position: absolute;
        width: 220px;
        background-color: white;
        border: 1px solid #ddd;
        z-index: 1000;
        max-height: 200px;
        overflow-y: auto;
        padding: 10px;
        box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1);
      }
      
      .airline-select {
        width: 220px; /* 固定宽度 */
        height: 350px; /* 固定高度，显示特定数量的选项 */
        overflow-y: auto; /* 启用垂直滚动 */
      }

      .main-content-box-red-button {
        position: absolute;
        bottom: -20px; /* Half inside, half outside */
        left: 50%;
        transform: translateX(-50%);
        width: 150px;
        background-color: rgba(215, 53, 57, 0.9); /* Background color */
        color: #FFFFFF; /* White text color */
        padding: 10px 20px; /* Padding for the button */
        border: none;
        border-radius: 30px; /* Rounded corners */
        font-size: 18px; /* Font size */
        font-weight: bold;
        cursor: pointer;
        box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.2); /* Shadow effect */
        z-index: 10; /* Ensure it appears above other elements */
      }
      
      .main-content-box-second-page {
        display: flex;
        justify-content: space-around;
        align-items: flex-start;
        height: 100vh;
        padding: 10vh 5vw 3vh 8vw; /* 上右下左 */
      }
      
      .left-box {
        background-color: rgba(255, 255, 255, 0.8);
        border-radius: 10px;
        padding: 4.3vh 2vw;
        width: 25vw;    /* 左侧方框宽度为视窗宽度的35% */
        height: 30vh;   /* 左侧方框高度为视窗高度的40% */
        gap: 2vh;
        display: flex;
        flex-direction: column;
        #justify-content: space-around;
        align-items: center;
        background-color: rgba(255, 255, 255, 0.1);  /* 设置内容框为半透明白色背景 */
        border-radius: 15px;  /* 设置内容框的圆角，使其有更柔和的外观 */
        box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.2);  /* 添加阴影效果，使内容框更加突出 */
        #box-shadow: 0px 4px 4px rgba(215, 53, 57, 0.1);
        position: relative;
      }
      
      /* 右侧方框样式 */
      .right-box {
        background-color: rgba(255, 255, 255, 0.1);
        border-radius: 10px;
        padding: 2vh 2vw;
        display: flex;
        width: 40vw;   /* 右侧方框宽度为视窗宽度的50% */
        height: 80vh;  /* 右侧方框高度为视窗高度的80% */
        border-radius: 15px;  /* 设置内容框的圆角，使其有更柔和的外观 */
        #flex-direction: column;
        justify-content: center;
        align-items: center; 
        box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.2);
        backdrop-filter: blur(8px); /* 模糊效果 */
        -webkit-backdrop-filter: blur(8px); /* Safari兼容 */
        overflow: hidden;
      }
      
      .scrollable-table {
        width: 99%;   /* 表格容器宽度为 right-box 的 90% */
        height: 99%;  /* 表格容器高度为 right-box 的 90% */
        overflow-y: scroll;
        overflow-x: visible;
        #border: 1px solid #ccc;
        padding: 0px;
        background-color: transparent;
        padding-left: 16px;        
        padding-right: 16px;
      }
      
      .scrollable-table::-webkit-scrollbar {
        width: 8px; /* 水平滚动条的高度 */
        height: 8px; /* 水平滚动条的高度 */
    }
    
    .scrollable-table::-webkit-scrollbar-thumb {
        background-color: rgba(0, 0, 0, 0.2); /* 滚动条的颜色 */
        border-radius: 4px; /* 滚动条圆角 */
    }
    
    .scrollable-table::-webkit-scrollbar-track {
        background-color: transparent; /* 滚动条轨道颜色 */
    }
    
    .scrollable-table::-webkit-scrollbar:vertical {
        display: none; /* 隐藏垂直滚动条 */
    }
      
      /* 圆角长条按钮样式 */
      .long-return-button {
        position: absolute;
        bottom: -15px; /* 部分溢出到 .left-box 下方 */
        left: 50%;
        transform: translateX(-50%); /* 水平居中 */
        padding: 5px 15px;
        background: rgba(215, 53, 57, 0.9);
        border-radius: 20px;
        color: white;
        font-size: 14px;
        font-weight: bold;
        cursor: pointer;
        box-shadow: 0px 5px 10px rgba(0, 0, 0, 0.3);
        border: none;
      }

      /* 航班信息样式 */
      .flight-info {
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-size: 2.2vh;
        font-weight: bold;
        color: #333333;
        margin: 0;
      }

      /* 航班代码样式 */
      .airport-code {
        padding: 0vh 0vw;
        border-radius: 5px;
        width: 25%;
        text-align: center;
      }
      
       /* 出发地、目的地和箭头的比例划分 */
      .departure, .destination {
        flex: 0 0 45%;  /* 40% 宽度 */
        padding: 0vh 1vw;
        border-radius: 0px;
        text-align: center;
        font-size: clamp(3vh,7vw, 6vh);
        color: rgba(255, 255, 255, 0.9);
      }
      
      .arrow {
        flex: 0 0 10%; /* 20% 宽度 */
        font-size: 4vh;
        color: rgba(255, 255, 255, 0.4);
        #color: rgba(215, 53, 57, 0.8);
        text-align: center;
      }

      /* 日期和航空公司信息，居中显示 */
      .date-info, .airline-info {
        font-size: 2.6vh;
        color: rgba(255, 255, 255, 0.8);
        margin: 0;
      }
      
      .flight-card {
        cursor: pointer;
        background: none;
        border: none;
        display: flex;
        flex-direction: column;  /* 垂直排列子元素 */
        align-items: center;
        width: 100%;
        overflow: visible;
        max-height: 70px;        /* 初始高度（收起状态） */
        transition: max-height 0.6s ease, transform 0.3s ease, box-shadow 0.3s ease;
        margin-bottom: 5px;
        box-sizing: border-box;
        position: relative;
      }
      
      .flight-card.expanded {
        position: relative;
        max-height: 500px;       /* Expanded max height */
        transform: scale(1.01);  /* Slightly enlarge the card */
        box-shadow: 0px 0px 15px rgba(0, 0, 0, 0.5); /* Add shadow around the card */
        z-index: 2;
        overflow: visible; 
        border-radius: 7px;
        align-items: center;
      }
      
      .card-content {
        width: 100%;
        overflow: visible;
      }
      
      .card-front {
        width: 100%;
        display: flex;
        align-items: center;
        padding: 10px;
        border-radius: 5px;
        box-sizing: border-box;
        overflow: visible;
      }
      
      .card-back {
        width: 100%;
        padding: 3px;
        box-sizing: border-box;
        background-color: rgba(255, 255, 255, 0.1);  /* 背景色可自行调整 */
        color: #fff;                                  /* 文字颜色 */
        display: none;                                /* 默认隐藏 */
        margin-bottom: 5px;
        border-radius: 7px;
      }
      
      .flight-card.expanded .card-back {
        display: block;                               /* 展开后显示 */
      }

      .flight-card-time {
      font-size: 26px; 
      font-weight: bold; 
      text-align: center;
      margin-top:0px;
      color: rgba(255, 255, 255, 0.9);
      }
      
      .flight-card-city {
      font-size: 13px;
      text-align: center;
      color: rgba(255, 255, 255, 0.5);
      }
      
      .flight-card-line {
      flex-grow: 1; 
      height: 2px; 
      background-color: rgba(255, 255, 255, 0.5); 
      position: relative;
      }
      
      .flight-card-line-2 {
      flex-grow: 1; 
      height: 2px; 
      background-color: rgba(255, 255, 255, 0.5); 
      position: relative;
      }
      
      .create_flight_box {
        display: none; 
        position: absolute; 
        bottom: 0; 
        left: 0; 
        right: 0; 
        height: 150px; 
        background: rgba(173, 170, 178, 0.95);
        box-shadow: 0px -3px 10px rgba(215, 53, 57, 0.2);
        #backdrop-filter: blur(4px); /* 模糊效果 */
        #-webkit-backdrop-filter: blur(8px); /* Safari兼容 */
        border-radius: 10px; 
        padding: 20px; 
        text-align: center; 
        animation: slideUp 0.6s ease-in-out;
      }
      
      .close_create_flight_box_bottom {
        position: absolute; 
        top: -10px; 
        left: 50%; 
        transform: translateX(-50%); 
        background-color: rgba(215, 53, 57, 0.8);
        box-shadow: 0px -4px 10px rgba(215, 53, 57, 0.4);
        color: rgba(255, 255, 255, 0.9);
        width: 80px; 
        height: 20px; 
        display: flex; 
        align-items: center; 
        justify-content: center; 
        cursor: pointer;
        border-radius: 20px;
        font-size: 14px;
        font-weight: bold;
        cursor: pointer;
        border: none;
      }
      
      .create_flight_time_box{
        width: 50px; 
        height: 50px;
        background-color: rgba(255, 255, 255, 0.9);
        border: none;
        border-radius: 6px;
        display: flex; 
        justify-content: center; 
        align-items: center;
      }
      
      .create_flight_time_box_select {
        font-size: 30px;         /* 设置选择框的字体大小 */
        text-align: center;      /* 选择框文本居中 */
        font-weight: bold;       /* 加粗选择框的文本 */
        width: 60px;             /* 控制选择框的宽度 */
        padding: 2px;            /* 增加上下间距 */
        border: none;
        appearance: none;        /* 隐藏下拉按钮 */
        -webkit-appearance: none; /* Safari 浏览器兼容 */
        padding: 0; 
        border-radius: 6px;
        height: 40px; 
        background-color: rgba(92, 86, 101, 0.4),
        overflow: hidden;
        display: flex; 
        justify-content: center; 
        align-items: center;
      }
      
     .create_flight_time_box_select option {
        font-size: 16px;         /* 设置选项列表的字体大小 */
        font-weight: normal;     /* 不加粗选项列表的文本 */
      }
      
      .create_flight_time_box_select::-webkit-scrollbar {
        display: none;           /* 隐藏 Chrome、Safari 滚动条 */
      }
      
      .predict_flight_red_button {
        width: 90px;
        height: 25px;
        font-size: 14px;
        font-weight: bold;
        color: white;
        background-color: rgba(215, 53, 57, 0.9);
        color: rgba(255, 255, 255, 0.8);
        border: none;
        cursor: pointer;
        margin-top: 22px;
        border-radius: 20px;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0px -4px 8px rgba(0, 0, 0, 0.5); /* 黑色阴影 */
      }
      
      #footer {
        position: fixed;
        bottom: 0;
        width: 100%;
        text-align: center;
        font-size: 9px;
        color: rgba(255, 255, 255, 0.8);
        padding: 0px 0;
        background-color: transparent;
        #border-top: 1px solid #ddd;  /* Optional: Top border for separation */
      }
    "
      )
    )
  ),
  
  # 动态定位 JavaScript
  tags$script(
    HTML(
      "
    function positionSuggestions(id, inputId) {
      var input = $('#' + inputId);
      var suggestions = $('#' + id);
      var offset = input.offset();
      suggestions.css({
        top: offset.top + input.outerHeight() + 'px',
        left: offset.left + 'px',
        width: input.outerWidth() + 'px'
      });
    }
  "
    )
  ),
  
  tags$video(
    src = "bg-video-720p.mp4",
    # 放在 www 文件夹中的视频文件
    type = "video/mp4",
    class = "video-bg",
    autoplay = NA,
    loop = NA,
    #循环播放
    muted = NA #启用静音
  ),
  
  div(
    class = "main-container",
    div(
      class = "title-container",
      "Flight Information Lookup",
      div(class = "title-underline")
    ),
    
    div(
      class = "main-content-box",
      
      # 行容器，包含左侧和右侧的列
      div(
        class = "main-content-box-row-container",
        
        # 左侧列，包含 From 和 Date
        div(
          class = "main-content-box-column-container",
          div(
            class = "input-label",
            "From*",
            textInput("from_airport", NULL, value =  "Madison (MSN)"),
            div(id = "origin_suggestions_container", uiOutput("origin_suggestions")),
            class = "custom-input"
          ),
          div(
            class = "input-label",
            "Date*",
            dateInput(
              "flight_date",
              NULL,
              value = Sys.Date() + 1,
              min = max(Sys.Date(), as.Date("2024-11-01")),
              max = as.Date("2025-01-31"),
              format = "M dd"
            ),
            class = "custom-input"
          )
        ),
        
        # 中间的转换按钮
        div(
          actionButton("swap_btn", "⇆", class = "main-content-box-swap-button")
        ),
        
        # 右侧列，包含 To 和 Airline
        div(
          class = "main-content-box-column-container",
          div(
            class = "input-label",
            "To*",
            textInput("to_airport", NULL, placeholder = "City or airport"),
            div(id = "destination_suggestions_container", uiOutput("destination_suggestions")),
            class = "custom-input"
          ),
          div(
            class = "input-label",
            "Airline",
            selectInput(
              "airline",
              NULL,
              choices = c(
                "Any Airline" = "ANY",  # 任意航司的默认选项
                "Air Wisconsin" = "ZW",
                "Alaska Airlines" = "AS",
                "Allegiant Air" = "G4",
                "American Airlines" = "AA",
                "Cape Air" = "9K",
                "CommutAir" = "C5",
                "Compass Airlines" = "CP",
                "Delta Air Lines" = "DL",
                "Endeavor Air" = "9E",
                "Envoy Air" = "MQ",
                "Empire Airlines" = "EM",
                "ExpressJet Airlines" = "EV",
                "Frontier Airlines" = "F9",
                "GoJet Airlines" = "G7",
                "Hawaiian Airlines" = "HA",
                "Horizon Air" = "QX",
                "JetBlue Airways" = "B6",
                "Mesa Airlines" = "YV",
                "PenAir" = "KS",
                "Piedmont Airlines" = "PT",
                "PSA Airlines" = "OH",
                "Republic Airways" = "YX",
                "SkyWest Airlines" = "OO",
                "Southwest Airlines" = "WN",
                "Spirit Airlines" = "NK",
                "Trans States Airlines" = "AX",
                "United Airlines" = "UA",
                "Virgin America" = "VX"
              ),
              selected = "ANY",
              selectize = FALSE # 禁用 Selectize 插件以使用原生下拉列表
            ),
            class = "custom-input"
          )
        )
      ),
      div(
        actionButton("search_button", "Search", class = "main-content-box-red-button")
      )
    ),
    
    div(
      id = "results_content",
      class = "results-content",
      textOutput("result_text")
    )
  ),
  
  div(
    class="main-container-second-page",
    div(
      class = "main-content-box-second-page",
      
      # 左侧方框
      div(
        class = "left-box",
        actionButton("edit_search", "Edit Search", class = "long-return-button"),
        div(
          class = "flight-info",
          div(class = "departure", textOutput("output_global_origin")),  # 出发机场代码
          div(class = "arrow", HTML("&#9992;")),  # 箭头
          div(class = "destination", textOutput("output_global_dest"))  # 到达机场代码
        ),
        div(
          class = "date-info", textOutput("output_global_dep_date_str")
        ),
        div(
          class = "airline-info", textOutput("output_global_marketing_airline_fullname")
        )
      ),
      
      # 右侧方框
      div(
        class = "right-box",
        div(
          class = "scrollable-table",
          tableOutput("flightCards"),  # 显示航班表格
          tags$div(
            style = "text-align: center; margin-top: 20px; color: #666; font-size: 12px;",
            actionLink("create_flight", "Flight not found? Create one.")
          ),
          tags$div(
            id = "modal_popup",
            class="create_flight_box",
            actionButton("close_modal",
                         class="close_create_flight_box_bottom",
                         tags$img(src="arrow-white.png",
                                  style = "width: 28px; height: 8px; "),
            ),
            tags$div(
              style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%;",
              tags$div(
                style = "display: flex; flex-direction: row; width: 100%;",
                tags$div(style = "flex: 0 0 40%; background-color: transparent; text-align: center; padding: 10px;",
                         tags$div(
                           style = "height: 60px; text-align: center; padding: 10px;",
                           tags$div(
                             style = "height: 100%; display: flex; align-items: center; justify-content: center; text-align: center; padding: 10px;",
                             # 输入分钟的输入框
                             tags$div(
                               class="create_flight_time_box",
                               tags$select(
                                 id = "create_flight_hour",
                                 class = "create_flight_time_box_select",  # 使用自定义样式
                                 lapply(0:23, function(i) {
                                   # 设置默认选中的值为 "08"
                                   if (i == 10) {
                                     tags$option(sprintf("%02d", i), selected = "selected")
                                   } else {
                                     tags$option(sprintf("%02d", i))
                                   }
                                 })
                               )
                             ),
                             # 冒号分隔符
                             tags$span(":", style = "margin: 0 8px; font-size: 25px;font-weight: bold;"),
                             # 输入秒的输入框
                             tags$div(
                               class="create_flight_time_box",
                               tags$select(
                                 id = "create_flight_minute",
                                 class = "create_flight_time_box_select",  # 使用自定义样式
                                 choices = sprintf("%02d", 0:59),
                                 selected = "30",
                                 selectize = FALSE,
                                 lapply(0:59, function(i) {
                                   # 设置默认选中的值为 "30"
                                   if (i == 30) {
                                     tags$option(sprintf("%02d", i), selected = "selected")
                                   } else {
                                     tags$option(sprintf("%02d", i))
                                   }
                                 })
                               )
                             )
                           )
                         ),
                         tags$div(
                           style = "background-color: transparent; display: flex; align-items: center; justify-content: center; flex-direction: column;",
                           tags$div(
                             style = "font-size: 16px;text-align: center;color: rgba(255, 255, 255, 0.9);",
                             textOutput("output_get_city_origin_name")
                           ),
                           tags$div(
                             style=" display: flex; text-align: center;",
                             tags$div(
                               style = "font-size: 10px;color: rgba(255, 255, 255, 0.5); display: flex; align-items: flex-end;",
                               "Timezone:"
                             ),
                             tags$div(
                               style = "font-size: 13px; color: rgba(255, 255, 255, 0.8); margin-left: 5px",
                               textOutput("output_get_origin_timezone")
                             )
                           )
                         )
                ),
                tags$div(
                  style = "flex: 0 0 20%; background-color: transparent; text-align: center; padding: 10px;",
                  tags$div(
                    style="",
                    tags$div(
                      style="font-size: 18px; color: rgba(255, 255, 255, 0.9); margin-top: 3px;font-weight: bold;",
                      textOutput("output_global_marketing_airline")
                    ),
                    tags$div(
                      style = "display: flex; flex-direction: column; text-align: center; background-color: rgba(255, 255, 255, 0.9); border-radius: 4px;margin-top: 5px;",
                      tags$div(
                        style = "font-size: 8px; color: rgba(92, 86, 101, 0.6); align-items: flex-end;",
                        "Flight Duration"
                      ),
                      tags$div(
                        style = "display: flex; justify-content: center;align-items: center;",
                        tags$div(textOutput("output_global_est_flight_duration_hm"), style = "padding: 0 8px; font-size: 16px;")
                      )
                    ),
                    tags$div(
                      style = "display: flex; align-items: center; justify-content: center;",
                      actionButton("predict_flight_button", label = "Predict", class = "predict_flight_red_button")
                    )
                  )
                ),
                tags$div(
                  style = "flex: 0 0 40%; background-color: transparent; text-align: center; padding: 10px;",
                  tags$div(
                    style = "height: 60px; text-align: center; padding: 10px;",
                    tags$div(
                      style = "height: 100%; display: flex; align-items: center; justify-content: center; text-align: center; padding: 10px;",
                      # 输入分钟的输入框
                      tags$div(
                        class="create_flight_time_box",
                        style = "font-size: 30px;text-align: center;font-weight: bold;",
                        textOutput("output_global_est_arr_time_hour")
                      ),
                      # 冒号分隔符
                      tags$span(":", style = "margin: 0 8px; font-size: 25px;font-weight: bold;"),
                      # 输入秒的输入框
                      tags$div(
                        class="create_flight_time_box",
                        style = "font-size: 30px;text-align: center;font-weight: bold;",
                        textOutput("output_global_est_arr_time_minute")
                      )
                    )
                  ),
                  tags$div(
                    style = "background-color: transparent; display: flex; align-items: center; justify-content: center; flex-direction: column;",
                    tags$div(
                      style = "font-size: 16px;text-align: center;color: rgba(255, 255, 255, 0.9);",
                      textOutput("output_get_city_dest_name")
                    ),
                    tags$div(
                      style=" display: flex; text-align: center;",
                      tags$div(
                        style = "font-size: 10px;color: rgba(255, 255, 255, 0.5); display: flex; align-items: flex-end;",
                        "Timezone:"
                      ),
                      tags$div(
                        style = "font-size: 13px; color: rgba(255, 255, 255, 0.8); margin-left: 5px",
                        textOutput("output_get_dest_timezone")
                      )
                    )
                  )
                )
              )
            )
          )
          
        )
      )
    )
  ),
  
  tags$div(
    id = "footer",
    tags$p("If you have any questions, please contact: jlu396@wisc.edu"),
    tags$p("© 2024 All rights reserved.")
  )
)

server <- function(input, output, session) {
  #hide("main_container_second_page")
  
  globals <- reactiveValues(
    global_origin = "",
    global_dest = "",
    global_marketing_airline = "",
    global_dep_date = as.Date(NA),
    global_dep_datetime = NULL,
    global_arr_date = as.Date(NA),
    global_est_arr_datetime = NULL,
    global_est_flight_duration = NULL,
    global_est_flight_duration_hm = "- h - min",
    global_est_arr_time_hour = "- -",
    global_est_arr_time_minute = "- -",
  )
  
  output$output_global_origin <- renderText({globals$global_origin})
  output$output_global_dest <- renderText({globals$global_dest})
  output$output_global_marketing_airline_fullname <- renderText({airline_lookup(globals$global_marketing_airline)})
  output$output_global_marketing_airline <- renderText({globals$global_marketing_airline})
  output$output_global_dep_date_str <- renderText({
    Sys.setlocale("LC_TIME", "C")
    format(globals$global_dep_date, "%b %d %Y")})
  output$output_get_city_origin_name <- renderText({get_city_airport_name(globals$global_origin)})
  output$output_get_city_dest_name <- renderText({get_city_airport_name(globals$global_dest)})
  output$output_get_origin_timezone <- renderText({get_airport_timezone(globals$global_origin)})
  output$output_get_dest_timezone <- renderText({get_airport_timezone(globals$global_dest)})
  output$output_global_est_flight_duration_hm <- renderText({globals$global_est_flight_duration_hm})
  output$output_global_est_arr_time_hour <- renderText({globals$global_est_arr_time_hour})
  output$output_global_est_arr_time_minute <- renderText({globals$global_est_arr_time_minute})
  
  
  # 定义通用的建议弹窗显示逻辑
  updateSuggestions <-
    function(input_text,
             output_id,
             suggestions_id,
             selected_airport_id,
             input_field_id) {
      req(input_text)  # 确保输入框中有内容
      
      # 使用 tolower() 函数以忽略大小写差异，并移除特殊字符
      clean_input <- gsub("[^a-zA-Z0-9]", "", tolower(input_text))
      
      # 将机场数据的 Name、City 和 IATA 列也进行相同的处理，以支持模糊匹配
      airport_data$clean_name <-
        gsub("[^a-zA-Z0-9]", "", tolower(airport_data$Name))
      airport_data$clean_city <-
        gsub("[^a-zA-Z0-9]", "", tolower(airport_data$City))
      airport_data$clean_iata <-
        gsub("[^a-zA-Z0-9]", "", tolower(airport_data$IATA))
      
      # 创建一个新的数据框，包含匹配和相似度分数
      matches <-
        airport_data[grepl(clean_input, airport_data$clean_name) |
                       grepl(clean_input, airport_data$clean_city) |
                       grepl(clean_input, airport_data$clean_iata),]
      
      if (nrow(matches) == 0) {
        # 隐藏 suggestions 容器
        hide(suggestions_id)
      } else {
        # 生成匹配结果列表，格式为 "City (IATA)"，每个选项独占一行
        result_list <- lapply(1:nrow(matches), function(i) {
          airport_info <- paste0(matches$City[i], " (", matches$IATA[i], ")")
          tags$p(
            airport_info,
            style = "margin: 0; padding: 5px; cursor: pointer; border-bottom: 1px solid #ddd;",
            onclick = sprintf(
              'Shiny.setInputValue("%s", "%s", {priority: "event"})',
              selected_airport_id,
              airport_info
            )
          )
        })
        
        # 将匹配结果放入小弹窗
        output[[output_id]] <- renderUI({
          div(class = "suggestions-container", result_list)
        })
        
        # 显示 suggestions 容器并调整位置
        show(suggestions_id)
        runjs(sprintf(
          "positionSuggestions('%s', '%s');",
          suggestions_id,
          input_field_id
        ))
      }
    }
  
  # 出发地机场的建议弹窗逻辑
  observeEvent(input$from_airport, {
    updateSuggestions(
      input_text = input$from_airport,
      output_id = "origin_suggestions",
      suggestions_id = "origin_suggestions_container",
      selected_airport_id = "selected_from_airport",
      input_field_id = "from_airport"
    )
  }, ignoreInit = TRUE)
  
  # 目的地机场的建议弹窗逻辑
  observeEvent(input$to_airport, {
    updateSuggestions(
      input_text = input$to_airport,
      output_id = "destination_suggestions",
      suggestions_id = "destination_suggestions_container",
      selected_airport_id = "selected_destination_airport",
      input_field_id = "to_airport"
    )
  }, ignoreInit = TRUE)
  
  # 监听选择事件，将内容填入出发地输入框，同时隐藏出发地弹窗
  observeEvent(input$selected_from_airport, {
    updateTextInput(session,
                    "from_airport",
                    value = input$selected_from_airport)
    hide("origin_suggestions_container")  # 隐藏出发地弹窗
  }, ignoreInit = TRUE)
  
  # 监听选择事件，将内容填入目的地输入框，同时隐藏目的地弹窗
  observeEvent(input$selected_destination_airport, {
    updateTextInput(session,
                    "to_airport",
                    value = input$selected_destination_airport)
    hide("destination_suggestions_container")  # 隐藏目的地弹窗
  }, ignoreInit = TRUE)
  
  # 监听转换按钮的点击事件
  observeEvent(input$swap_btn, {
    # 获取当前出发地和目的地输入框的值
    origin_value <- input$from_airport
    destination_value <- input$to_airport
    # 交换两个输入框的内容
    updateTextInput(session, "from_airport", value = destination_value)
    updateTextInput(session, "to_airport", value = origin_value)
  })
  
  # Reactive value to store error messages for inline display
  error_message <- reactiveVal("")
  
  extract_and_uppercase <- function(text) {
    # 使用正则表达式查找括号内的内容并转换为大写
    match <- regmatches(text, regexpr("\\(([^)]+)\\)", text))
    # 如果匹配不到内容，返回空字符串，否则去掉括号并转换为大写
    if (length(match) == 0 || is.na(match)) {
      return("")
    } else {
      return(toupper(gsub("[()]", "", match)))
    }
  }
  
  # Add an observer for the "Search" button
  observeEvent(input$search_button, {
    origin_airport <- input$from_airport
    dest_airport <- input$to_airport
    
    # Check if "To" field is empty
    if (is.null(dest_airport) || dest_airport == "") {
      error_message("Please enter a 'To' airport.")
      runjs("$('#to_airport').css('border-color', 'red');")
    }else if(is.null(origin_airport) || origin_airport == ""){
      error_message("Please enter a 'From' airport.")
      runjs("$('#from_airport').css('border-color', 'red');")
    }else{
      origin_airport_code <- extract_and_uppercase(origin_airport)
      dest_airport_code <- extract_and_uppercase(dest_airport)
      # print(origin_airport_code)
      # print(dest_airport_code)
      if(origin_airport_code=="" || !(origin_airport_code %in% airport_data$IATA)){
        updateTextInput(session, "from_airport", value = "")
        error_message("The 'From' airport code is not valid. Please enter a valid airport.")
        runjs("$('#from_airport').css('border-color', 'red');")
      }else if(dest_airport_code=="" || !(dest_airport_code %in% airport_data$IATA)){
        updateTextInput(session, "to_airport", value = "")
        error_message("The 'To' airport code is not valid. Please enter a valid airport.")
        runjs("$('#to_airport').css('border-color', 'red');")
      }else if(origin_airport_code == dest_airport_code){
        updateTextInput(session, "to_airport", value = "")
        error_message("The 'From' and 'To' airports cannot be the same. Please select a different destination.")
        runjs("$('#to_airport').css('border-color', 'red');")
      }else{
        globals$global_origin <- origin_airport_code
        globals$global_dest <- dest_airport_code
        globals$global_dep_date <- input$flight_date
        globals$global_marketing_airline <- input$airline
        # 隐藏主内容并显示结果页面
        runjs("$('.main-container').fadeOut(600);")
        #hide("main_container", anim = TRUE, animType = "fade", time = 0.6)
        search_year <- format(globals$global_dep_date, "%Y")
        search_month <- format(globals$global_dep_date, "%m")
        search_day <- format(globals$global_dep_date, "%d")
        output$flightCards <- generate_flight_data_cards_list(globals$global_origin, globals$global_dest, search_year, search_month, search_day, globals$global_marketing_airline)
        #print(globals$global_origin)
        #print(globals$global_dest)
        runjs("$('.main-container-second-page').fadeIn(600);")
        #show("main_container_second_page", anim = TRUE, animType = "fade", time = 0.6)
        #show("modal_popup")
        hide("modal_popup")
      }
    }
  })
  
  observeEvent(input$edit_search, {
    # 执行动画：隐藏第二页面，显示主页面
    runjs("$('.main-container-second-page').fadeOut(600, function() {$('.main-container').fadeIn(600);});")
    #hide("main_container_second_page", anim = TRUE, animType = "fade", time = 0.6)
    #show("main_container", anim = TRUE, animType = "fade", time = 0.6)
    globals$global_est_flight_duration <- NULL
    globals$global_est_flight_duration_hm <- "- h - min"
    globals$global_est_arr_time_hour <- "- -"
    globals$global_est_arr_time_minute <- "- -"
  })
  
  # Display the error message below the inputs if any
  output$error_message_ui <- renderUI({
    if (error_message() != "") {
      tags$p(error_message(), style = "color: red; margin-top: 5px;")
    }
  })
  
  # Insert the error message UI below the search button
  observe({
    insertUI(
      selector = "#search_button",
      where = "afterEnd",
      ui = uiOutput("error_message_ui")
    )
  })
  
  # 监听创建航班链接的点击事件，显示模态窗口
  observeEvent(input$create_flight, {
    show("modal_popup")  # 显示模态窗口
  })
  
  # 监听关闭按钮，隐藏模态窗口
  observeEvent(input$close_modal, {
    hide("modal_popup")  # 隐藏模态窗口
  })
  
  # 监听 predict_flight_button 的点击事件
  observeEvent(input$predict_flight_button, {
    create_hour <- input$create_flight_hour
    create_minute <- input$create_flight_minute
    time_string <- paste(create_hour, create_minute, sep = ":")
    origin_timezone <- gsub(" ", "_", get_airport_timezone(globals$global_origin))
    globals$global_dep_datetime <- as.POSIXct(paste(globals$global_dep_date, time_string), format = "%Y-%m-%d %H:%M", tz = origin_timezone)
    #print(globals$global_dep_datetime)
    # est_flight_duration <- 180
    est_flight_duration <- get_average_flight_time(globals$global_marketing_airline, globals$global_origin, globals$global_dest)
    if (is.na(est_flight_duration)) {
      showModal(modalDialog(
        title = "Error",
        "This airline does not operate this route or this route does not exist. Please check other airlines or consider connecting flights.",
        easyClose = TRUE
      ))
    }
    est_flight_duration_hours <- est_flight_duration %/% 60
    est_flight_duration_minutes <- est_flight_duration %% 60
    globals$global_est_flight_duration_hm <- paste(est_flight_duration_hours, "h", est_flight_duration_minutes, "min") # 几小时几分钟
    est_arr_datetime <- globals$global_dep_datetime + est_flight_duration * 60 # 起飞机场时区
    dest_timezone <- gsub(" ", "_", get_airport_timezone(globals$global_dest))
    globals$global_est_arr_datetime <- format(est_arr_datetime, tz = dest_timezone, usetz = TRUE)
    #print(globals$global_est_arr_datetime)
    datetime_str <- as.character(globals$global_est_arr_datetime)
    globals$global_est_arr_time_hour <- sub(".*\\s(\\d{2}):\\d{2}:\\d{2}.*", "\\1", datetime_str)
    globals$global_est_arr_time_minute <- sub(".*\\s\\d{2}:(\\d{2}):\\d{2}.*", "\\1", datetime_str)
    #print(globals$global_est_arr_time_hour)
    #print(globals$global_est_arr_time_minute)
  })
}

shinyApp(ui, server)
