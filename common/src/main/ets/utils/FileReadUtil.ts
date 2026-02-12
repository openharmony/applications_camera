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
import lazy { HiLog } from './HiLog';
import lazy { configPolicy, fs } from './LazyImportUtil';
import lazy { SystemParamService } from '../service/systemparameter/SystemParamService';

const TAG: string = 'fileRead';
/* instrument ignore file */
export function hasCameraProfiles(): boolean {
  try {
    const relPath: string = 'etc/camera/CameraProfiles.json';
    HiLog.begin(TAG, 'getOneCfgFile');
    const filePath: string = configPolicy.getOneCfgFileSync(relPath);
    HiLog.end(TAG, 'getOneCfgFile');
    if (filePath !== '') {
      return true;
    }
    return false;
  } catch (err) {
    HiLog.e(TAG, 'getCameraProfilesJson failed.');
    return false;
  }
}

export function isNeedHideFlashIcon(): boolean {
  try {
    let res: string = SystemParamService.getInstance().get(true, 'const.camera.need_hide_flash_icon', 'true');
    HiLog.i(TAG, `isNeedHideFlashIcon = ${res}`);
    return res === 'true';
  } catch (error) {
    HiLog.e(TAG, `isNeedHideFlashIconInSpecialZoom get error ${error}`);
    return false;
  }
}

export function getCloseFlashZoom(): number {
  let defaultZoom: number = 2;
  try {
    let res: number =
      Number(SystemParamService.getInstance().get(true, 'const.camera.close_flash_zoom', defaultZoom.toString()));
    HiLog.i(TAG, `getCloseFlashZoom = ${res}`);
    return res === 2 ? res : res - 0.1;
  } catch (error) {
    HiLog.e(TAG, `getCloseFlashZoom error ${error}`);
  }
  return defaultZoom;
}
