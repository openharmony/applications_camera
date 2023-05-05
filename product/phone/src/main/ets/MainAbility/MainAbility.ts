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

import Ability from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'
import { CameraBasicFunction } from '@ohos/common/src/main/ets/default/function/CameraBasicFunction'
import { CameraNeedStatus }  from '@ohos/common/src/main/ets/default/utils/Constants'
import { FeatureManager } from '@ohos/common/src/main/ets/default/featureservice/FeatureManager'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { PreferencesService } from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService'
import { ModeMap } from '../common/ModeMap';

export default class MainAbility extends Ability {
  private cameraBasicFunction: any = null
  onCreate(want, launchParam) {
    // Ability is creating, initialize resources for this ability
    Log.start(Log.ABILITY_WHOLE_LIFE)

    Log.info('Camera MainAbility onCreate.e')
    globalThis.cameraAbilityContext = this.context
    globalThis.cameraAbilityWant = this.launchWant
    globalThis.permissionFlag = false
    globalThis.cameraStartTime = new Date().getTime()
    globalThis.cameraStartFlag = true
    globalThis.stopRecordingFlag = false;
    globalThis.doOnForeground = false
    this.cameraBasicFunction = CameraBasicFunction.getInstance()
    this.cameraBasicFunction.initCamera({ cameraId: 'BACK', mode: 'PHOTO' }, 'onCreate')

    Log.info('Camera MainAbility onCreate.x')
    if (globalThis.cameraFormParam != undefined) {
      new FeatureManager(globalThis.cameraFormParam.mode, new ModeMap())
    } else {
      new FeatureManager('PHOTO', new ModeMap())
    }
  }

  onDestroy() {
    // Ability is creating, release resources for this ability
    Log.end(Log.ABILITY_WHOLE_LIFE)
    Log.end(Log.APPLICATION_WHOLE_LIFE)
    this.cameraBasicFunction.startIdentification = false
    PreferencesService.getInstance().flush()
    Log.info('Camera MainAbility onDestroy.')
  }

  async onWindowStageCreate(windowStage) {
    // Main window is created, set main page for this ability
    Log.start(Log.ABILITY_VISIBLE_LIFE)
    Log.info('Camera MainAbility onWindowStageCreate.')
    windowStage.on('windowStageEvent', (event) => {
      Log.info('Camera MainAbility onWindowStageEvent: ' + JSON.stringify(event))
      globalThis.cameraWindowStageEvent = event
      if (event === window.WindowStageEventType.INACTIVE || event === window.WindowStageEventType.HIDDEN) {
        globalThis.stopRecordingFlag = true
        globalThis?.stopCameraRecording && globalThis.stopCameraRecording()
      } else {
        globalThis.stopRecordingFlag = false
      }
    })

    windowStage.getMainWindow().then((win) => {
      try {
        win.setLayoutFullScreen(true).then(() => {
          Log.info('Camera setFullScreen finished.')
          win.setSystemBarEnable(['navigation']).then(() => {
            Log.info('Camera setSystemBarEnable finished.')
          })
        })

        win.setSystemBarProperties({
          navigationBarColor: '#00000000', navigationBarContentColor: '#B3B3B3'
        }).then(() => {
          Log.info('Camera setSystemBarProperties.')
        })

        globalThis.cameraWinClass = win

      } catch (err) {
        Log.error('Camera setFullScreen err: ' + err)
      }
    })

    if (this.launchWant.parameters.uri === 'capture') {
      globalThis.cameraFormParam = {
        action: 'capture',
        cameraPosition: 'PHOTO',
        mode: 'PHOTO'
      }
    } else if (this.launchWant.parameters.uri === 'video') {
      globalThis.cameraFormParam = {
        action: 'video',
        cameraPosition: 'VIDEO',
        mode: 'VIDEO'
      }
    }


    windowStage.setUIContent(this.context, 'pages/index', null)
  }

  onWindowStageDestroy() {
    Log.end(Log.ABILITY_VISIBLE_LIFE)
    Log.info('Camera MainAbility onWindowStageDestroy.')
  }

  onForeground() {
    Log.start(Log.ABILITY_FOREGROUND_LIFE)
    Log.info('Camera MainAbility onForeground. e')
    globalThis.cameraNeedStatus = CameraNeedStatus.CAMERA_NEED_INIT
    if (globalThis?.doOnForeground && globalThis.doOnForeground) {
      Log.info('Camera MainAbility onForeground.')
      globalThis?.updateCameraStatus && globalThis.updateCameraStatus()
    } else {
      globalThis.doOnForeground = true
    }
    Log.info('Camera MainAbility onForeground. x')
  }

  onBackground() {
    Log.end(Log.ABILITY_FOREGROUND_LIFE)
    Log.info('Camera MainAbility onBackground.')
    this.cameraBasicFunction.startIdentification = false
    globalThis.cameraNeedStatus = CameraNeedStatus.CAMERA_NEED_RELEASE
    globalThis?.updateCameraStatus && globalThis.updateCameraStatus()
  }

  onNewWant(want) {
    Log.info('Camera MainAbility E onNewWant.')
    globalThis.cameraAbilityWant = want
    Log.info(`Camera MainAbility X newWantAction: ${JSON.stringify(globalThis.cameraAbilityWant )}`)
  }
}