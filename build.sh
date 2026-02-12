#!/bin/bash
#
# Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -ex

echo "old NODE_HOME is ${NODE_HOME}"

# NODE_HOME的环境变量多配置了一个bin目录, 在这里去除掉
[[ "${NODE_HOME}" =~ .*\bin$ ]] && NODE_HOME=${NODE_HOME%\bin*}
echo "new NODE_HOME is ${NODE_HOME}" # /opt/buildtools/node.js-v18.20.1
echo "HM_SDK_HOME is ${HM_SDK_HOME}"
echo "OHOS_SDK_HOME is ${OHOS_SDK_HOME}"
echo "OHOS_BASE_SDK_HOME is ${OHOS_BASE_SDK_HOME}"
node -v
npm -v

# 初始化相关路径
PROJECT_PATH="$(pwd -P)"  # 工程目录
OHPM_INSTALL_DIR="$(pwd -P)" # commandline-tools安装目录

# 导入基础函数
chmod -R 777 "${PROJECT_PATH}"/signature
source "${PROJECT_PATH}"/signature/build_base_functions.sh
source "${PROJECT_PATH}"/signature/build_third_functions.sh

# Setup npm
npm config set strict-ssl false

function ohpm_install() {
    cd  $1
    ohpm install
}

function init_har() {
  cd $1
  # 目前内网的ohpm仓库未准备好，过渡期间还是往npm仓库发布，所以需要package.json文件
  cp oh-package.json5 package.json
}

function upload_har() {
  # 进入构建产物目录，修改har包后缀，然后发布到npm仓库
  mv product/pc/build/default/outputs/default/pc-default-signed.hap product/pc/build/default/outputs/default/Camera.hap
  mv product/tablet/build/default/outputs/default/tablet-default-signed.hap product/tablet/build/default/outputs/default/Camera.hap
  mv product/phone/build/default/outputs/default/phone-default-signed.hap product/phone/build/default/outputs/default/Camera.hap
  mv product/picker/build/default/outputs/default/picker-phone-default-signed.hap product/picker/build/default/outputs/default/CameraPicker.hap
  mv product/pcpicker/build/default/outputs/default/pcpicker-phone-default-signed.hap product/pcpicker/build/default/outputs/default/CameraPicker.hap
}

function main() {
  local start_time=$(date '+%s')
  build_third
  build $1
  upload_har

  local end_time=$(date '+%s')
  local elapsedTime=$(expr $end_time - $start_time)
  echo "build success in ${elapsedTime}s..."
}

function build_third() {
  echo "GRADLEW_CAM start build third"
  echo "GRADLEW_CAM build third finished"
}

function build_with_param() {
  if [ "$1" = "clean" ]
  then
    echo "gradlew clean, no need to do anything"
    return 0
  else
    echo "continue to build"
    main $1
  fi
}

echo $1
build_with_param $1