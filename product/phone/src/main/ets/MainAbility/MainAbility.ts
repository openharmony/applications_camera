/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import Ability from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { CameraBasicFunction } from '@ohos/common/src/main/ets/default/function/CameraBasicFunction';
import { CameraNeedStatus } from '@ohos/common/src/main/ets/default/utils/Constants';
import { FeatureManager } from '@ohos/common/src/main/ets/default/featureservice/FeatureManager';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { PreferencesService } from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService';
import { ModeMap } from '../common/ModeMap';
import wantConstant from '@ohos.ability.wantConstant';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';

export default class MainAbility extends Ability {
  private cameraBasicFunction: any = null;

  onCreate(want, launchParam) {
    // Ability is creating, initialize resources for this ability
    Log.start(Log.ABILITY_WHOLE_LIFE);
    Log.info('Camera MainAbility onCreate.e');
    GlobalContext.get().setCameraAbilityContext(this.context);
    GlobalContext.get().setCameraAbilityWant(this.launchWant);
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
    Log.info('Camera MainAbility onCreate.x');
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
    this.cameraBasicFunction.startIdentification = false;
    PreferencesService.getInstance().flush();
    Log.info('Camera MainAbility onDestroy.');
  }

  async onWindowStageCreate(windowStage) {
    // Main window is created, set main page for this ability
    Log.start(Log.ABILITY_VISIBLE_LIFE);
    Log.info('Camera MainAbility onWindowStageCreate.');
    windowStage.on('windowStageEvent', (event) => {
      Log.info('Camera MainAbility onWindowStageEvent: ' + JSON.stringify(event));
      GlobalContext.get().setCameraWindowStageEvent(event);
      if (event === window.WindowStageEventType.INACTIVE || event === window.WindowStageEventType.HIDDEN) {
        GlobalContext.get().setObject('stopRecordingFlag', true);
        GlobalContext.get().apply('stopCameraRecording');
      } else {
        GlobalContext.get().setObject('stopRecordingFlag', false);
      }
    })

    windowStage.getMainWindow().then((win) => {
      try {
        win.setLayoutFullScreen(true).then(() => {
          Log.info('Camera setFullScreen finished.');
          win.setSystemBarEnable(['navigation']).then(() => {
            win.setSystemBarProperties({
              navigationBarColor: '#00000000', navigationBarContentColor: '#B3B3B3'
            }).then(() => {
              Log.info('Camera setSystemBarProperties.');
            })
            Log.info('Camera setSystemBarEnable finished.');
          })
        })
        GlobalContext.get().setCameraWinClass(win);
      } catch (err) {
        Log.error('Camera setFullScreen err: ' + err);
      }
    })

    if (this.launchWant?.action === wantConstant.Action.ACTION_IMAGE_CAPTURE ||
    this.launchWant?.parameters?.action === wantConstant.Action.ACTION_IMAGE_CAPTURE) {
      GlobalContext.get().setCameraFormParam({
        action: 'capture',
        cameraPosition: 'PHOTO',
        mode: 'PHOTO'
      });
    } else if (this.launchWant?.action === wantConstant.Action.ACTION_VIDEO_CAPTURE ||
    this.launchWant?.parameters?.action === wantConstant.Action.ACTION_VIDEO_CAPTURE) {
      GlobalContext.get().setCameraFormParam({
        action: 'video',
        cameraPosition: 'VIDEO',
        mode: 'VIDEO'
      });
    }
    windowStage.setUIContent(this.context, 'pages/index', null);
  }

  onWindowStageDestroy() {
    Log.end(Log.ABILITY_VISIBLE_LIFE);
    Log.info('Camera MainAbility onWindowStageDestroy.');
  }

  onForeground() {
    Log.start(Log.ABILITY_FOREGROUND_LIFE);
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NEED_INIT)
    if (GlobalContext.get().getT<boolean>('doOnForeground')) {
      Log.info('Camera MainAbility onForeground.');
      GlobalContext.get().apply('updateCameraStatus')
    } else {
      GlobalContext.get().setObject('doOnForeground', true);
    }
    Log.info('Camera MainAbility onForeground');
  }

  onBackground() {
    Log.end(Log.ABILITY_FOREGROUND_LIFE);
    Log.info('Camera MainAbility onBackground.');
    this.cameraBasicFunction.startIdentification = false;
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NEED_RELEASE)
    GlobalContext.get().apply('updateCameraStatus');
  }

  onNewWant(want) {
    Log.info('Camera MainAbility E onNewWant.');
    GlobalContext.get().setCameraAbilityWant(want);
    Log.info(`Camera MainAbility X newWantAction: ${JSON.stringify(GlobalContext.get().getCameraAbilityWant())}`);
  }
}