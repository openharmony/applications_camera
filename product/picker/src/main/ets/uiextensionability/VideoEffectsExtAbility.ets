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

import lazy { Want, UIExtensionAbility, UIExtensionContentSession } from '@kit.AbilityKit';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { VideoEffectsManager } from './VideoEffectsManager';

const TAG: string = 'VideoEffectsExtAbility';

export default class VideoEffectsExtAbility extends UIExtensionAbility {
  onCreate() {
    HiLog.i(TAG, `onCreate`);
  }

  onForeground() {
    HiLog.i(TAG, `onForeground`);
  }

  onBackground() {
    HiLog.i(TAG, `onBackground`);
  }

  onDestroy() {
    HiLog.i(TAG, `onDestroy`);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    HiLog.i(TAG, 'onSessionCreate');
    let storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('session', session);
    session.loadContent('pages/VideoEffects', storage);
    session.setWindowBackgroundColor('#00000000');
    VideoEffectsManager.getInstance().init(this.context, session);
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    HiLog.i(TAG, `onSessionDestroy`);
    VideoEffectsManager.getInstance().release();
  }
}
