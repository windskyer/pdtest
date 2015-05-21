The Choose Your Own Adventure README for pdtest 
===================================================
## 最开始 使用  pdtest_release.sh  脚本进行打包
## 打包后 在dist 目录中 有 .tar 文件 
## 该压缩文件就是 shell 测试框架

#######################################################
###                                                 ###
###当 pdtest_release.sh 脚本执行不成功的时候        ### 
###在测试 pdtest.sh 脚本时候 就要使用 -d 参数       ###
###eg: pdtest.sh -d /tmp/client                     ### 
###eg: /tmp/client/ 表示最新开发的脚本目录          ###
###                                                 ###
#######################################################

## 操作参数说明
    pdtest  <options>
        -d <script dir>         eg: -d client
        -f <script fullnames>   eg: -f get_host_info.sh
        -n <script names>       eg: -n getinfo
        -s <script subnames>    eg: -s host
        -v <script version>     eg: -v v2.0
        -A exec all shell script
        -F exec all [shell] group script
        -H or -h or -? Output hellp info  

    pdtest.sh -d client  #修改 需要测试的脚本的目录  默认 是 当前的 client 目录 

    pdtest.sh -f get_host_info.sh  #测试 etc/pdclient.conf 文件中的[shell] 组中的 脚本名称 并 进行测试  eg pdtest.sh -f get_host_info.sh 则会测试 client/get_host_info.sh 脚本

    pdtest.sh -n getinfo  #测试 etc/pdserver.conf 文进中的[getinfo] 组中的 所有脚本 进行测试
    pdtest.sh -n getinfo -n createvm  #测试 etc/pdserver.conf 文进中的[getinfo] 和 [createvm]组中的 所有脚本 进行测试
    pdtest.sh -n "getinfo createvm " #测试 etc/pdserver.conf 文进中的[getinfo] 和 [createvm]组中的 所有脚本 进行测试

    pdtest.sh -n getinfo -s host  #测试 etc/pdserver.conf 文进中的[getinfo] 组中的 host 脚本 进行测试
    pdtest.sh -n getinfo -s host -s vg  #测试 etc/pdserver.conf 文进中的[getinfo] 组中的 host 和 vg  脚本 进行测试
    pdtest.sh -n getinfo -s "host vg"  #测试 etc/pdserver.conf 文进中的[getinfo] 组中的 host 和 vg  脚本 进行测试

    pdtest.sh -n getinfo -s vm -v v2.0  #测试 etc/pdserver.conf 文进中的[getinfo] 组中的 vm_v2.0 脚本 进行测试

    pdtest.sh -A  #测试 etc/pdserver.conf 文进中的 所有  组中的  脚本 进行测试

    pdtest.sh -F  #测试 etc/pdclient.conf 文进中的 [shell] 组中的 所有脚本 进行测试
            

## 目录说明
    .
├── AUTHORS
├── ChangeLog
├── client  # 测试 脚本存放目录
├── etc     # 项目 配置文件存放目录
├── LICENSE
├── MANIFEST.in
├── pdtest.sh
├── README.rst
├── service  #测试框架主要脚本
└── unit     #框架公共函数

## 文件说明
    pdtest.sh 程序的入口脚本
    README.rst 使用手册


## 配置文件书写说明

    "#"号开头为注释
    etc/pdclient.conf 
         [getinfo]
         host = 172.24.23.140@padmin
         vg = 172.24.23.140#padmin#rootvg
         vm_v2.0 = 172.24.23.140#padmin
         [createvm]
         vm = 172.24.23.140@padmin

         [shell]
         get_host_info.sh = 172.24.23.140@padmin
         get_vg_info.sh = 172.24.23.140@padmin@rootvg

         [getinfo] 和 etc/pdserver.conf 文件中的 [getinfo] 对应
         host #代表 脚本的 别名
         =    #分割符号
         172.24.23.140@padmin #对应着 host 脚本 所需要的参数 必须是 顺序一致 172.24.23.140 表示 $1,  padmin 表示 $2  参数之间 用@ 或 # 分割
         host = 172.24.23.140@padmin "=" 

         [shell] 是一个特殊的组 
         get_host_info.sh = 172.24.23.140@padmin #前面是 脚本的名称 后面是 脚本的参数 = 两边必须没有空格

    "#"号开头为注释
    etc/pdserver.conf     
        ## get host info
        [getinfo]
        pv = get_pv_info.sh
        vg = get_vg_info.sh
        vm = get_vm_info.sh
        vm_v2.0 = get_vm_info_v2.0.sh
        vm_state = get_vm_state.sh
        host = get_host_info.sh
        
        ## set vm info
        [createvm]
        vm= create_vm.sh
        
        [getinfo] 是函数组 对应 etc/pdclient 中的[getinfo]组
        host #代表脚本的别名
        =    #分割符合
        get_host_info.sh #client 目录中的脚本名称
