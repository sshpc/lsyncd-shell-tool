#!/bin/bash
export LANG=en_US.UTF-8

#初始化
initself() {
    version='0.1'
    #官方版本号
    installType='yum -y install'
    removeType='yum -y remove'
    upgrade="yum -y update"
    release='linux'
    #菜单名称(默认首页)
    menuname='首页'
    #安装目录
    installdirectory='/usr/local/lsyncdtool'

    #字体颜色定义
    _red() {
        printf '\033[0;31;31m%b\033[0m' "$1"
        echo
    }
    _green() {
        printf '\033[0;31;32m%b\033[0m' "$1"
        echo
    }
    _yellow() {
        printf '\033[0;31;33m%b\033[0m' "$1"
        echo
    }
    _blue() {
        printf '\033[0;31;36m%b\033[0m' "$1"
        echo
    }
    #按任意键继续
    waitinput() {
        echo
        read -n1 -r -p "按任意键继续...(退出 Ctrl+C)"
    }
    #检测命令是否存在
    _exists() {
        local cmd="$1"
        which $cmd >/dev/null 2>&1
        local rt=$?
        return ${rt}
    }
    #菜单头部
    menutop() {
        clear
        _green '# lsyncd 一键安装脚本'
        _green '# Github <https://github.com/sshpc/lsyncd-shell-tool>'
        _blue '# You Server:'${release}
        echo
        _blue ">~~~~~~~~~~~~~~  lsyncd tool ~~~~~~~~~~~~<  v: $version"
        echo
        _yellow "当前菜单: $menuname "
        echo
    }
    #菜单渲染
    menu() {
        menutop
        options=("$@")
        num_options=${#options[@]}
        # 计算数组中的字符最大长度
        max_len=0
        for ((i = 0; i < num_options; i++)); do
            # 获取当前字符串的长度
            str_len=${#options[i]}

            # 更新最大长度
            if ((str_len > max_len)); then
                max_len=$str_len
            fi
        done
        # 渲染菜单
        for ((i = 0; i < num_options; i += 4)); do
            printf "%s%*s  " "$((i / 2 + 1)): ${options[i]}" "$((max_len - ${#options[i]}))"
            if [[ "${options[i + 2]}" != "" ]]; then printf "$((i / 2 + 2)): ${options[i + 2]}"; fi
            echo
            echo
        done
        echo
        printf '\033[0;31;36m%b\033[0m' "q: 退出  "
        if [[ "$number" != "" ]]; then printf '\033[0;31;36m%b\033[0m' "b: 返回  0: 首页"; fi
        echo
        echo
        # 获取用户输入
        read -ep "请输入命令号: " number
        if [[ $number -ge 1 && $number -le $((num_options / 2)) ]]; then
            #找到函数名索引
            action_index=$((2 * (number - 1) + 1))
            #函数名赋值
            parentfun=${options[action_index]}
            #函数执行
            ${options[action_index]}
        elif [[ $number == 0 ]]; then
            main
        elif [[ $number == 'b' ]]; then
            ${FUNCNAME[3]}
        elif [[ $number == 'q' ]]; then
            echo
            exit
        else
            echo
            _red '输入有误  回车返回首页'
            waitinput
            main
        fi
    }
    clear
}

#检查系统
checkSystem() {
    if [[ -n $(find /etc -name "redhat-release") ]] || grep </proc/version -q -i "centos"; then
        release="centos"
        installType='yum -y install'
        removeType='yum -y remove'
        upgrade="yum update -y --skip-broken"
    elif [[ -f "/etc/issue" ]] && grep </etc/issue -q -i "debian" || [[ -f "/proc/version" ]] && grep </etc/issue -q -i "debian" || [[ -f "/etc/os-release" ]] && grep </etc/os-release -q -i "ID=debian"; then
        release="debian"
        installType='apt -y install'
        upgrade="apt update"
        removeType='apt -y autoremove'
    elif [[ -f "/etc/issue" ]] && grep </etc/issue -q -i "ubuntu" || [[ -f "/proc/version" ]] && grep </etc/issue -q -i "ubuntu"; then
        release="ubuntu"
        installType='apt -y install'
        upgrade="apt update"
        removeType='apt -y autoremove'
    elif [[ -f "/etc/issue" ]] && grep </etc/issue -q -i "Alpine" || [[ -f "/proc/version" ]] && grep </proc/version -q -i "Alpine"; then
        release="alpine"
        installType='apk add'
        upgrade="apk update"
        removeType='apt del'
    fi
    if [[ -z ${release} ]]; then
        echoContent red "\n不支持此系统\n"
        _red "$(cat /etc/issue)"
        _red "$(cat /proc/version)"
        exit 0
    fi
}

#脚本升级
updateself() {
    _blue '下载github最新版'
    wget -N http://raw.githubusercontent.com/sshpc/lsyncd-shell-tool/main/lsyncdtool.sh
    # 检查上一条命令的退出状态码
    if [ $? -eq 0 ]; then
        chmod +x ./lsyncdtool.sh && ./lsyncdtool.sh
    else
        _red "下载失败,请重试"
    fi
}

#查看状态
viewstatus() {
    echo
    _blue 'lsyncdtool status:'
    systemctl status lsyncdtool | awk '/Active/'
    echo
}

startservice() {
    _blue "启动服务"
    systemctl start lsyncdtool
    viewstatus
}

stopservice() {
    _blue "停止服务"
    systemctl stop lsyncdtool
    viewstatus
}

viewlog() {
    echo
    _blue 'log:'
    echo
    tail  $installdirectory/log/lsyncd.log
    echo
    echo
}

#卸载
uninstall() {
    stopservice
    systemctl disable lsyncdtool
    rm -rf $installdirectory
    rm -rf /usr/lib/systemd/system/lsyncdtool.service
    _blue '已卸载'
    echo
}

#安装
install() {
    #检查是否已安装
    if [ -f "/usr/lib/systemd/system/lsyncdtool.service" ]; then
        _yellow '检测到文件存在 覆盖安装...'
        uninstall
    fi
    _blue "开始安装"
    echo
    mkdir -p $installdirectory

    if _exists 'lsyncd'; then
        echo "lsyncd 已安装"
    else
        echo "lsyncd 未安装,正在安装..."
        ${installType} lsyncd

    fi

    if ! _exists 'lsyncd'; then
        _red "lsyncd 安装失败,请手动安装"
        exit 0
    fi

    #生成配置文件

    if [ ! -f "$installdirectory/lsyncd.conf.lua" ]; then
        #文件不存在
        touch $installdirectory/lsyncd.conf.lua
    fi

    #接受参数
    echo '使用绝对路径 例(默认): /root/Source-test'
    read -ep "请输入原目录: " Sourcedirectory

    if [[ "$Sourcedirectory" = "" ]]; then
        Sourcedirectory='/root/Source-test'
    fi

    echo '使用绝对路径 例(默认): /root/Target-test  ssh远程地址  例：root@x.x.x.x:/root/test'
    read -ep "请输入目标目录: " Targetdirectory

    if [[ "$Targetdirectory" = "" ]]; then
        Targetdirectory='/root/Target-test'
    fi

    _blue "检查路径是否正确"
    echo
    echo "原目录:$Sourcedirectory"
    echo
    echo "目标目录:$Targetdirectory"
    waitinput

    if [ ! -d "$Sourcedirectory" ]; then
        mkdir -p "$Sourcedirectory"
    fi
    if [ ! -d "$Targetdirectory" ]; then
        mkdir -p "$Targetdirectory"
    fi

    #创建日志文件
    if [ ! -f "$installdirectory/log/lsyncd.log" ]; then
        mkdir -p "$installdirectory/log"
        touch $installdirectory/log/lsyncd.log
    fi

    #创建状态文件
    if [ ! -f "$installdirectory/lsyncd.status" ]; then
        touch $installdirectory/lsyncd.status
    fi


    #写入配置
    cat <<EOF >$installdirectory/lsyncd.conf.lua
settings {
    logfile = "$installdirectory/log/lsyncd.log",  -- 日志文件位置
    statusFile = "$installdirectory/lsyncd.status",  -- 状态文件位置
    nodaemon   = true  -- 守护进程模式运行
}

sync {
    default.rsync,
    source = "$Sourcedirectory",  -- 源目录
    target = "$Targetdirectory",  -- 目标目录 或主机的 SSH 地址目录
    delay = 1,  
    rsync = {
        binary = "/usr/bin/rsync",  -- rsync 二进制文件路径
        archive = true,  -- 归档模式
        compress = true,  -- 压缩传输
        owner = true,  -- 保留文件所有权
        group = true,  -- 保留文件组
        times = true,  -- 保留时间戳
    },
}

EOF

    if [ ! -f "/usr/lib/systemd/system/lsyncdtool.service" ]; then
        #文件不存在
        touch /usr/lib/systemd/system/lsyncdtool.service
    fi
    cat <<EOF >/usr/lib/systemd/system/lsyncdtool.service
[Unit]
Description=lsyncd-shell-tool
After=network.target

[Service]
User=root
Type=simple
WorkingDirectory=$installdirectory
ExecStart=/usr/bin/lsyncd $installdirectory/lsyncd.conf.lua
ExecStop=pkill -f lsyncd; pkill -f rsync

[Install]
WantedBy=multi-user.target
EOF

    _blue "配置开机自启"
    systemctl enable lsyncdtool
    echo
    #启动服务
    startservice
    clear
    _green '安装成功'
    echo
}

#主函数
main() {
    menuname='首页'
    options=("安装" install "卸载" uninstall "查看状态" viewstatus "查看log" viewlog "启动服务" startservice "停止服务" stopservice "升级脚本" updateself)
    menu "${options[@]}"
}

initself
checkSystem
main
