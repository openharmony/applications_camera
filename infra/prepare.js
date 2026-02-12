/*
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const process = require('child_process');
(function () {
  let script = {
    'installVideo': 'cd features/video & npm install',
    'installPhoto': 'cd features/photo & npm install',
    'installMulti': 'cd features/multi & npm install',
    'installPhone': 'cd product/phone & npm install',
    'installTablet': 'cd product/tablet & npm install',
    'installAll': 'npm install'
  };

  process.exec(script.installVideo, (error, stdout, stderr) => {
    if (!error) {
      console.log('installVideo succeed.');
    } else {
      console.error('installVideo failed.');
    }
  });

  process.exec(script.installPhoto, (error, stdout, stderr) => {
    if (!error) {
      console.log('installPhoto succeed.');
    } else {
      console.error('installPhoto failed.');
    }
  });

  process.exec(script.installMulti, (error, stdout, stderr) => {
    if (!error) {
      console.log('installMulti succeed.');
    } else {
      console.error('installMulti failed.');
    }
  });

  process.exec(script.installPhone, (error, stdout, stderr) => {
    if (!error) {
      console.log('installPhone succeed.');
    } else {
      console.error('installPhone failed.');
    }
  });

  process.exec(script.installTablet, (error, stdout, stderr) => {
    if (!error) {
      console.log('installTablet succeed.');
    } else {
      console.error('installTablet failed.');
    }
  });

  process.exec(script.installAll, (error, stdout, stderr) => {
    if (!error) {
      console.log('installAll succeed.');
    } else {
      console.error('installAll failed.');
    }
  });
})();