#!/bin/bash
if [ $# -gt 0 ]; then
        echo "传入的so库路径为: "$1
        strings $1 | grep commitid
else
        echo "没有传入so库路径，使用默认相对路径: ../plugin/libbaidu-asr.so"
        strings ../plugin/libbaidu-asr.so  | grep commitid
fi