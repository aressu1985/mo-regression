#!/bin/bash
WORKSPACE=$(cd `dirname $0`; pwd)

SERVER=127.0.0.1
PORT=6001
USER=dump
PASS=111

MO_DIR=matrixone
MOSYSBENCH_DIR=tools/mo-sysbench
MOTESTER_DIR=tools/mo-tester
MOLOAD_DIR=tools/mo-load
MOTPCH_DIR=tools/mo-tpch

##function : start BVT test
function startBVTTest() {
  local times=$1
  cd ${WORKSPACE}/${MOTESTER_DIR}
  touch log.txt
  for i in $(seq 1 ${times})
  do
    echo "The ${i} turn has been started......." >> log.txt
    bash run.sh -p ${WORKSPACE}/${MO_DIR}/test/cases -n -g -e database
    echo `head -n 1 report/report.txt` >> log.txt
    mkdir -p ${WORKSPACE}/${MOTESTER_DIR}/report/${i}/
    mv ${WORKSPACE}/${MOTESTER_DIR}/report/*.txt ${WORKSPACE}/${MOTESTER_DIR}/report/${i}/
  done
}

##function : start sysbench mixed test
function startSysbenchTest() {
  #create test db
  mysql -h${SERVER} -P${PORT} -u${USER} -p${PASS} -e "create database if not exists sbtest" 2>/dev/null
  if [ $? -ne 0 ];then
    echo -e "The sysbench test database[sbtest] has been created failed, please check manullay"
    exit 1
  fi
    
  #init sysbench test data
  cd ${WORKSPACE}/${MOSYSBENCH_DIR}
  sysbench  --mysql-host=${SERVER} --mysql-port=${PORT} --mysql-user=${USER} --mysql-password=${PASS} oltp_common.lua  --tables=10 --table_size=100000 --threads=1 --time=30 --report-interval=10 --create_secondary=off  --auto_inc=off cleanup
  sysbench  --mysql-host=${SERVER} --mysql-port=${PORT} --mysql-user=${USER} --mysql-password=${PASS} oltp_common.lua  --tables=10 --table_size=100000 --threads=1 --time=30 --report-interval=10 --create_secondary=off  --auto_inc=off prepare
  if [ $? -eq 0 ];then
    echo -e "The sysbench test data has been initialized successfully"
  else
    echo -e "The sysbench test data has been initialized failed, please check manullay"
    exit 1
  fi
  
  #start test
  cd ${WORKSPACE}/${MOLOAD_DIR}
  cp cases/sysbench/*.yml .
  bash start.sh
}

#function : start tpch queries
function startTPCHTest() {
    cd ${WORKSPACE}/${MOTPCH_DIR}
    
    #build
    cd ${WORKSPACE}/${MOTPCH_DIR}/dbgen
    make clean & make
    cd ${WORKSPACE}/${MOTPCH_DIR}

    #init tpch test data
    ./run.sh -g -s 5
    ./run.sh -c -s 5
    ./run.sh -l -s 5
    if [ $? -eq 0 ];then
        echo -e "The tpch test data has been initialized successfully"
      else
        echo -e "The tpch test data has been initialized failed, please check manullay"
        exit 1
      fi
    #start tpch queries
    local times=$1
    touch log.txt
    for i in $(seq 1 ${times})
    do
        echo "The ${i} turn has been started......." >> log.txt
        bash run.sh -q all -s 5 >> log.txt
        mkdir -p ${WORKSPACE}/${MOTPCH_DIR}/report/${i}/
        mv ${WORKSPACE}/${MOTPCH_DIR}/report/r* ${WORKSPACE}/${MOTPCH_DIR}/report/${i}/
    done
    
}

bash deploy.sh 

startBVTTest 1000 > BVTTest.log &
echo -e "The bvt test has been started in the background"

startSysbenchTest > SysbenchTest.log &
echo -e "The sysbench test for read-write case has been started in the background"

#startTPCHTest 2 
startTPCHTest 1000 > TPCHTest.log &
echo -e "The tpch test for 0.1G scale has been started in the background"
