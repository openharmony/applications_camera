/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import FileIo from '@ohos.fileio';
import settings from '@ohos.settings';

/**
  * @file read local file
  */

const DFAULT_SIZE = 4096;
const CHAR_CODE_AT_INDEX = 0;

export class BaseConfModel {
  constructor() {
  }

  public getJsonData(fileName: string): any[]{
    console.info('settings BaseConfModel getJsonData start');
    return this.readLocalFile(fileName);
    console.info('settings BaseConfModel getJsonData end');
  }

  public getJsonDataBase(fileName, callback) {
    console.info('settings BaseParseConfModel getJsonDataBase in');
    callback(this.readLocalFile(fileName));
    console.info('settings BaseParseConfModel getJsonDataBase end');
  }

  readLocalFile(fileName): any[]{
    try {
      let stream = FileIo.createStreamSync(fileName, 'r');
      console.info(`settings BaseConfModel getJsonData try stream: ${stream}`);
      let buf = new ArrayBuffer(DFAULT_SIZE);
      let len = stream.readSync(buf);
      console.info(`settings BaseConfModel getJsonData try len: ${len}`);
      let arr = new Uint8Array(buf);
      let charAt = ' '.charCodeAt(CHAR_CODE_AT_INDEX);
      for (let i = len;i < DFAULT_SIZE; i++) {
        arr[i] = charAt;
      }
      let content = String.fromCharCode.apply(null, arr);
      stream.closeSync();
      console.info(`settings BaseConfModel getJsonData try content: ${JSON.stringify(content)}`);
      return JSON.parse(content);
    } catch (jsonError) {
      console.info(`settings BaseConfModel getJsonData catch jsonError: ${jsonError}`);
    }
  }
}

let baseConfModel = new BaseConfModel();

export default baseConfModel as BaseConfModel;