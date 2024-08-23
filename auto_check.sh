#!/bin/bash
# 下班操作方法：  ./nueip_auto_gps.sh in 公司代號 帳號 密碼
# 下班操作方法：  ./nueip_auto_gps.sh out 公司代號 帳號 密碼
# 要記得把地理坐標和公司ip 換掉喔

# 左營巨蛋的地理坐标
latitude="22.6650"
longitude="120.3034"


# 檢查並創建 ~/.neuip 目錄
if [ ! -d ~/.neuip ]; then
    echo "mkdir neuip..."
    mkdir ~/.neuip
fi

# 獲取當前 IP 地址
ip="$(curl -s ifconfig.me)"

# 檢查 IP 是否為公司的 IP
if [ "$ip" = "22.24.24.25" ]; then
    # 上班打卡
    if [ "$1" = "in" ]; then
        echo "start: $(date '+%Y-%m-%d %H:%M:%S')" >> ~/.neuip/clock_in_log


        # 第一次請求
        curl -v -L 'https://cloud.nueip.com/login/index/param' \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            --data-urlencode "inputCompany=$2" \
            --data-urlencode "inputID=$3" \
            --data-urlencode "inputPassword=$4" \
            -o /dev/null 2>&1 | grep 'set-cookie' | grep -v 'deleted' | awk '{print $3}' | sed 's/;$//' > ~/.neuip/neuip_cookie.txt

        awk -F= '!/^#/ {cookie_name=$1; cookie_value=$2; cookies[cookie_name]=cookie_value} END {for (name in cookies) print name "=" cookies[name]}' ~/.neuip/neuip_cookie.txt > ~/.neuip/final_cookies.txt

        cookie_header=$(awk '{print}' ORS='; ' ~/.neuip/final_cookies.txt | sed 's/; $//')

        # 第二次請求
        response=$(curl -L 'https://cloud.nueip.com/login/index/param' --header 'Content-Type: application/x-www-form-urlencoded' \
            -H "Cookie: $cookie_header" \
            --data-urlencode "inputCompany=$2" \
            --data-urlencode "inputID=$3" \
            --data-urlencode "inputPassword=$4"
        )

        token=$(echo "$response" | grep -o 'name="token" value="[^"]*' | head -n 1 | awk -F '"' '{print $4}')
        form_data="action=add&id=1&attendance_time=$(date '+%Y-%m-%d %H:%M:%S')&token=$token&lat=$latitude&lng=$longitude"
        clockInResponse=$(curl -L 'https://cloud.nueip.com/time_clocks/ajax' --header 'Content-Type: application/x-www-form-urlencoded' \
            -H "Cookie: $cookie_header" \
            --data-raw "$form_data" \
        ) >> ~/.neuip/clock_in_log

        echo "$clockInResponse" >> ~/.neuip/clock_in_log

    elif [ "$1" = "out" ]; then
        echo "start: $(date '+%Y-%m-%d %H:%M:%S')" >> ~/.neuip/clock_out_log


        # 第一次請求
        curl -v -L 'https://cloud.nueip.com/login/index/param' \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            --data-urlencode "inputCompany=$2" \
            --data-urlencode "inputID=$3" \
            --data-urlencode "inputPassword=$4" \
            -o /dev/null 2>&1 | grep 'set-cookie' | grep -v 'deleted' | awk '{print $3}' | sed 's/;$//' > ~/.neuip/neuip_cookie.txt

        awk -F= '!/^#/ {cookie_name=$1; cookie_value=$2; cookies[cookie_name]=cookie_value} END {for (name in cookies) print name "=" cookies[name]}' ~/.neuip/neuip_cookie.txt > ~/.neuip/final_cookies.txt

        cookie_header=$(awk '{print}' ORS='; ' ~/.neuip/final_cookies.txt | sed 's/; $//')

        # 第二次請求
        response=$(curl -L 'https://cloud.nueip.com/login/index/param' --header 'Content-Type: application/x-www-form-urlencoded' \
            -H "Cookie: $cookie_header" \
            --data-urlencode "inputCompany=$2" \
            --data-urlencode "inputID=$3" \
            --data-urlencode "inputPassword=$4"
        )

        token=$(echo "$response" | grep -o 'name="token" value="[^"]*' | head -n 1 | awk -F '"' '{print $4}')
        form_data="action=add&id=2&attendance_time=$(date '+%Y-%m-%d %H:%M:%S')&token=$token&lat=$latitude&lng=$longitude"
        clockInResponse=$(curl -L 'https://cloud.nueip.com/time_clocks/ajax' --header 'Content-Type: application/x-www-form-urlencoded' \
            -H "Cookie: $cookie_header" \
            --data-raw "$form_data" \
        ) >> ~/.neuip/clock_out_log

        echo "$clockInResponse" >> ~/.neuip/clock_out_log

    else
        echo "無效的打卡類型，請使用 'in' 或 'out'" >&2
    fi
else
    echo "IP 不在公司" >> ~/.neuip/clock_log
fi
