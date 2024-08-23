#!/bin/bash
# 下班操作方法：  ./auto_check.sh <公司IP> in 公司代號 帳號 密碼
# 下班操作方法：  ./auto_check.sh <公司IP> out 公司代號 帳號 密碼
# 要記得把地理坐標換掉喔

# 檢查參數數量
if [ $# -lt 5 ]; then
    echo "用法: $0 <公司IP> <in|out> <公司代號> <帳號> <密碼>"
    exit 1
fi

# 設置參數
company_ip="$1"
action="$2"
company_code="$3"
username="$4"
password="$5"

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
if [ "$ip" = "$company_ip" ]; then
    # 上班或下班打卡
    if [ "$action" = "in" ] || [ "$action" = "out" ]; then
        log_file="$HOME/.neuip/clock_${action}_log"
        echo "start: $(date '+%Y-%m-%d %H:%M:%S')" >> "$log_file"

        # 第一次請求
        curl -v -L 'https://cloud.nueip.com/login/index/param' \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            --data-urlencode "inputCompany=$company_code" \
            --data-urlencode "inputID=$username" \
            --data-urlencode "inputPassword=$password" \
            -o /dev/null 2>&1 | grep 'set-cookie' | grep -v 'deleted' | awk '{print $3}' | sed 's/;$//' > ~/.neuip/neuip_cookie.txt

        awk -F= '!/^#/ {cookie_name=$1; cookie_value=$2; cookies[cookie_name]=cookie_value} END {for (name in cookies) print name "=" cookies[name]}' ~/.neuip/neuip_cookie.txt > ~/.neuip/final_cookies.txt

        cookie_header=$(awk '{print}' ORS='; ' ~/.neuip/final_cookies.txt | sed 's/; $//')

        # 第二次請求
        response=$(curl -L 'https://cloud.nueip.com/login/index/param' --header 'Content-Type: application/x-www-form-urlencoded' \
            -H "Cookie: $cookie_header" \
            --data-urlencode "inputCompany=$company_code" \
            --data-urlencode "inputID=$username" \
            --data-urlencode "inputPassword=$password"
        )

        token=$(echo "$response" | grep -o 'name="token" value="[^"]*' | head -n 1 | awk -F '"' '{print $4}')
        id=$([ "$action" = "in" ] && echo "1" || echo "2")
        form_data="action=add&id=$id&attendance_time=$(date '+%Y-%m-%d %H:%M:%S')&token=$token&lat=$latitude&lng=$longitude"
        clockResponse=$(curl -L 'https://cloud.nueip.com/time_clocks/ajax' --header 'Content-Type: application/x-www-form-urlencoded' \
            -H "Cookie: $cookie_header" \
            --data-raw "$form_data"
        )

        echo "$clockResponse" >> "$log_file"

    else
        echo "無效的打卡類型，請使用 'in' 或 'out'" >&2
    fi
else
    echo "IP 不在公司" >> ~/.neuip/clock_log
fi
