# lsyncd 文件实时同步一键安装脚本

## 安装&卸载

### 一键安装
> 推荐 root 用户

```sh
wget -N  http://raw.githubusercontent.com/sshpc/lsyncd-shell-tool/main/lsyncdtool.sh && chmod +x ./lsyncdtool.sh && ./lsyncdtool.sh
```

> 再次执行

```sh
./lsyncdtool.sh
```

## 配置

源主机运行此脚本  

目标主机无需安装

需要源主机可以ssh连接目标主机（推荐秘钥验证）

可使用脚本快速配置

rep：https://github.com/sshpc/initsh

Document：
https://github.com/sshpc/initsh/blob/main/Documents.md#%E7%94%9F%E6%88%90ssh%E5%AF%86%E9%92%A5%E5%AF%B9

>若连接失败,请检查ssh 22端口是否打开 

## 其他

官方rep： https://github.com/lsyncd/lsyncd

* 默认安装目录 (可在安装脚本里修改)
>/usr/local/lsyncdtool
* 服务安装目录
>/usr/lib/systemd/system/lsyncdtool.service







