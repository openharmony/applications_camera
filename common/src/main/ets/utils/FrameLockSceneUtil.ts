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

// import apsManager from '@hms.graphic.apsManager';
import lazy { HiLog } from './HiLog';

const TAG: string = 'apsSetScene';

export function apsSetScene(sceneName: string, sceneState: boolean): void { // 1进入,0退出
  try {
    HiLog.i(TAG, `setApsScene start: ${sceneName}, ${sceneState}.`);
    // apsManager?.setScene('com.ohos.camera', getCameraSceneName(sceneName) as never, sceneState ? 1 : 0);
  } catch (error) {
    HiLog.e(TAG, `setApsScene error: ${error}.`);
  }
}

function getCameraSceneName(sceneName: string): string {
  switch (sceneName) {
    case 'SettingView':
      return 'CAMERA_SETTING_VIEW';
    case 'TreasureBox':
      return 'CAMERA_TREASURE_BOX';
    case 'PhotoBrowser':
      return 'CAMERA_PHOTO_BROWSER';
    default:
      return '';
  }
}