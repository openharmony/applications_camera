/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { CameraBasicFunction } from '@ohos/common/src/main/ets/default/function/CameraBasicFunction';
import { CameraNeedStatus } from '@ohos/common/src/main/ets/default/utils/Constants';
import { FeatureManager } from '@ohos/common/src/main/ets/default/featureservice/FeatureManager';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { PreferencesService } from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService';
import { ModeMap } from '../common/ModeMap';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import hilog from '@ohos.hilog';

export default class ExtensionPickerAbility extends UIExtensionAbility {
  private cameraBasicFunction: any = null;

  onCreate(): void {
    // Ability is creating, initialize resources for this ability
    Log.start(Log.ABILITY_WHOLE_LIFE);
    Log.info('Camera ExtensionPickerAbility onCreate');
    GlobalContext.get().setIsPicker(true);
    GlobalContext.get().setCameraAbilityContext(this.context);
    GlobalContext.get().setObject('permissionFlag', false);
    GlobalContext.get().setObject('cameraStartTime', new Date().getTime());
    GlobalContext.get().setObject('cameraStartFlag', true);
    GlobalContext.get().setObject('stopRecordingFlag', false);
    GlobalContext.get().setObject('doOnForeground', false);
    GlobalContext.get().setObject('doOnForeground', false);
    this.cameraBasicFunction = CameraBasicFunction.getInstance();
    this.cameraBasicFunction.initCamera({
      cameraId: 'BACK', mode: 'PHOTO'
    }, 'onCreate');
    Log.info('Camera ExtensionPickerAbility onCreate.x');
    if (GlobalContext.get().getCameraFormParam() != undefined) {
      new FeatureManager(GlobalContext.get().getCameraFormParam().mode, new ModeMap());
    } else {
      new FeatureManager('PHOTO', new ModeMap());
    }
  }

  onDestroy() {
    // Ability is creating, release resources for this ability
    Log.end(Log.ABILITY_WHOLE_LIFE);
    Log.end(Log.APPLICATION_WHOLE_LIFE);
    GlobalContext.get().setIsPicker(false);
    this.cameraBasicFunction.startIdentification = false;
    PreferencesService.getInstance().flush();
    Log.info('Camera ExtensionPickerAbility onDestroy.');
  }

  onForeground() {
    Log.start(Log.ABILITY_FOREGROUND_LIFE);
    GlobalContext.get().setIsPicker(true);
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NEED_INIT)
    if (GlobalContext.get().getT<boolean>('doOnForeground')) {
      Log.info('Camera ExtensionPickerAbility onForeground.');
      GlobalContext.get().apply('updateCameraStatus')
    } else {
      GlobalContext.get().setObject('doOnForeground', true);
    }
    GlobalContext.get().setCameraAbilityContext(this.context);
    Log.info('Camera ExtensionPickerAbility onForeground');
  }

  onBackground() {
    Log.end(Log.ABILITY_FOREGROUND_LIFE);
    Log.info('Camera ExtensionPickerAbility onBackground.');
    GlobalContext.get().setIsPicker(false);
    this.cameraBasicFunction.startIdentification = false;
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NEED_RELEASE)
    GlobalContext.get().apply('updateCameraStatus');
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    Log.info('Camera ExtensionPickerAbility onSessionCreate' + want.uri);
    GlobalContext.get().setCameraAbilityWant(want);
    GlobalContext.get().setPickerUri(want.uri);
    GlobalContext.get().setSession(session);
    let storage: LocalStorage = new LocalStorage(
      {
        'session': session,
        'mode': 'PHOTO'
      }
    )
    session.loadContent('pages/index', storage);
    try {
      session.setWindowPrivacyMode(true);
    } catch (e) {
      Log.error('Camera ExtensionPickerAbility setWindowPrivacyMode error');
    }
  }

  onSessionDestroy(session): void {
    Log.info('Camera ExtensionPickerAbility onSessionDestroy E');
    session.terminateSelf((error) => {
      Log.info('Camera ExtensionPickerAbility onSessionDestroy' + JSON.stringify(error));
    })
    Log.info('Camera ExtensionPickerAbility onSessionDestroy X');
  }
}