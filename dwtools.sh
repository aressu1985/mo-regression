#!/bin/bash
WORKSPACE=$(cd `dirname $0`; pwd)

MOTESTER_GIT_HTTPS_ADDR=https://github.com/matrixorigin/mo-tester.git
MOSYSBENCH_GIT_HTTPS_ADDR=https://github.com/aressu1985/mo-sysbench.git
MOLOAD_GIT_HTTPS_ADDR=https://github.com/aressu1985/mo-load.git
MOTPCH_GIT_HTTPS_ADDRhttps://github.com/aressu1985/mo-tpch.git

function downloadTools() {
    cd ${WORKSPACE}
    echo -e "Now Start to download test tools from github, please wait for a moment..."
    git clone ${MO_GIT_HTTPS_ADDR}
    if [ $? -eq 0 ];then
      echo -e "Download mo project successfully,"
    else
      echo -e "Download mo project failed, please check the reason manually."
      exit 1
    fi
}