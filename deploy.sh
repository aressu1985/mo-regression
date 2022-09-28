#!/bin/bash
WORKSPACE=$(cd `dirname $0`; pwd)

MO_PORT=6001
MO_DIR=matrixone
MOSYSBENCH_DIR=tools/mo-sysbench
MOTESTER_DIR=tools/mo-tester
MOLOAD_DIR=tools/mo-load
MOTPCH_DIR=tools/mo-tpch
MO_GIT_HTTPS_ADDR=https://github.com/matrixorigin/matrixone.git
MOTESTER_GIT_HTTPS_ADDR=https://github.com/matrixorigin/mo-tester.git
MOSYSBENCH_GIT_HTTPS_ADDR=https://github.com/aressu1985/mo-sysbench.git
MOLOAD_GIT_HTTPS_ADDR=https://github.com/aressu1985/mo-load.git
MOTPCH_GIT_HTTPS_ADDR=https://github.com/aressu1985/mo-tpch.git

##fucntion: to clean up old test resourse and program
function cleanup() {
  local pid=`lsof -i:${MO_PORT}|grep LISTEN|awk -F' ' '{print $2}'`
  if [ -n "${pid}" ];then
    echo -e "The MO server has existed[pid=${pid}], and will be killed"
    kill -9 ${pid}
  fi 
  
  #backup
  cd ${WORKSPACE}
  if [ -d ${MO_DIR} ];then
    local now=$(date "+%Y%m%d%H%M%S")
    echo -e "Now start to backup ${MO_DIR} to ${MO_DIR}_${now}.tar.gz"
    #tar -czf ${MO_DIR}_${now}.tar.gz ${MO_DIR}
    echo -e "Backup ${MO_DIR} successfully"
  fi
  
  #remove 
  rm -rf ${MO_DIR} ${MOLOAD_DIR} ${MOTESTER_DIR} ${MOSYSBENCH_DIR} ${MOTPCH_DIR}
  
}

##fuction: to download mo project and test tools
function download() {
    cd ${WORKSPACE}
    git clone ${MO_GIT_HTTPS_ADDR}
    if [ $? -eq 0 ];then
      echo -e "Download mo project successfully,"
    else
      echo -e "Download mo project failed, please check the reason manually."
      exit 1
    fi
    
    git clone ${MOTESTER_GIT_HTTPS_ADDR} ${MOTESTER_DIR}
    if [ $? -eq 0 ];then
      echo -e "Download mo tester successfully,"
    else
      echo -e "Download mo tester failed, please check the reason manually."
      exit 1
    fi
    
    git clone ${MOSYSBENCH_GIT_HTTPS_ADDR} ${MOSYSBENCH_DIR}
    if [ $? -eq 0 ];then
      echo -e "Download mo sysbench successfully,"
    else
      echo -e "Download mo sysbench failed, please check the reason manually."
      exit 1
    fi
        
    git clone ${MOLOAD_GIT_HTTPS_ADDR} ${MOLOAD_DIR}
    if [ $? -eq 0 ];then
      echo -e "Download mo load successfully,"
    else
      echo -e "Download mo load failed, please check the reason manually."
      exit 1
    fi
    
    git clone ${MOTPCH_GIT_HTTPS_ADDR} ${MOTPCH_DIR}
    if [ $? -eq 0 ];then
      echo -e "Download mo tpch successfully,"
    else
      echo -e "Download mo tpch failed, please check the reason manually."
      exit 1
    fi
}

##function: to build and start MO server
function startMOServer() {
    cd ${WORKSPACE}/${MO_DIR}
    sed -i s'/debug/info/g' ./etc/cn-standalone-test.toml
    make build
    nohup ./mo-service -cfg ./etc/cn-standalone-test.toml > server.log 2>&1 &
    sleep 5
    local pid=`lsof -i:${MO_PORT}|grep LISTEN|awk -F' ' '{print $2}'`
    echo "pid=${pid}"
    if [ -n "${pid}" ];then
      echo -e "The MO server has been started successfully"
    else
      echo -e "The MO server started failed,please check server.log manually"
      exit 1
    fi 
}

cleanup
download
startMOServer
