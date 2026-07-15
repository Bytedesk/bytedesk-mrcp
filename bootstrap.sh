#!/bin/bash

echo "bootstrap: gcc8.2环境初始化..."
GCC_PATH=/opt/compiler/gcc-8.2

PWD="$(pwd)"
#PWD="$(cd $(dirname "$0"); pwd)"

BAIDU_GCC_TAR=compiler.tar.gz

CHECK_ERROR=1
CHECK_OK=0

setup_gcc() {
    if [ -d ${GCC_PATH} ]; then
        rm -rf ${GCC_PATH} > /dev/null 2>&1
	if test $? != 0; then
	    echo "删除${GCC_PATH}失败，请确认是否有root权限。"
	    return ${CHECK_ERROR}
	fi
    fi
	
    if [ ! -f ${PWD}/${BAIDU_GCC_TAR} ]; then
       echo "检测到${PWD}/${BAIDU_GCC_TAR}不存在。请联系相关工作人员。"
       return ${CHECK_ERROR}
    fi
    
    tar -zxf ${PWD}/${BAIDU_GCC_TAR} -C /opt/
    if [ $? != 0 ]; then
        echo "解压缩到/opt/失败，请确认是否有root权限。"
	return ${CHECK_ERROR}
    fi
    
    return ${CHECK_OK}
}

run() {
    setup_gcc
    if [ $? -eq 0 ]; then
        echo "初始化成功"
    fi
}

run
