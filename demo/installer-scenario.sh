#/bin/bash

# Copyright 2017 NEC Corporation
# Copyright 2017 KDDI Research, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

set -xe
cd `dirname $0`

function package-install () {
    if [ "${http_proxy}" = "" ]; then
        proxy_opt=""
    else
        proxy_opt="--proxy=${http_proxy}"
    fi

    sudo yum -y install epel-release
    sudo yum -y install collectd collectd-write_redis redis
    sudo yum -y install gcc gcc-c++ numpy python-devel python2-pip scipy
    sudo pip ${proxy_opt} install -U scikit-learn redis
}


LIBRARY_DIR="/opt/dma/lib"
DUMPFILE_DIR="/opt/dma/var/sklearn-dump"

COLLECTD_DIR="/etc"
COLLECTD_PLUGIN_DIR="/etc/collectd.d"
COLLECTD_LOG_DIR="/var/log/"
REDIS_DIR="/etc"

if [ -z "$1" ]; then
    echo "Usage: ./installer-scenario.sh <scenario-directory-name>"
    exit 1
fi
SCENARIO_DIR=$1

package-install

for i in ${LIBRARY_DIR} ${DUMPFILE_DIR}
do
    [ ! -d $i ] && sudo mkdir -p $i
done
sudo chmod 777 ${DUMPFILE_DIR}

[ -f ${COLLECTD_PLUGIN_DIR}/thresholds.conf ] && sudo mv ${COLLECTD_PLUGIN_DIR}/thresholds.conf ${COLLECTD__PLUGIN_DIR}/thresholds.conf.org
sudo cp collectd.conf ${COLLECTD_DIR}
sudo cp redis.conf ${REDIS_DIR}
[ -f ${COLLECTD_LOG_DIR}/collectd.log ] && sudo touch ${COLLECTD_LOG_DIR}/collectd.log

sudo cp ${SCENARIO_DIR}/analysis/*.py transmitter/*.py ${LIBRARY_DIR}
sudo cp ${SCENARIO_DIR}/dma.conf ${COLLECTD_PLUGIN_DIR}

# is it better process restart function?
SERVICES="redis collectd"
for i in ${SERVICES}
do
    sudo systemctl enable $i
    sudo systemctl restart $i
done


echo "DMA install done!"
