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
import window from '@ohos.window';
import wantConstant from '@ohos.ability.wantConstant'
import { CameraBasicFunction } from '@ohos/common/src/main/ets/default/function/CameraBasicFunction'
import { CameraNeedStatus,Constants }  from '@ohos/common/src/main/ets/default/utils/Constants'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { FeatureManager } from '@ohos/common/src/main/ets/default/featureservice/FeatureManager'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { PreferencesService } from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService'
import { ModeMap } from '../common/ModeMap';

export default class MainAbility extends Ability {
  private cameraBasicFunction: any = null
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private readonly foreRoundCountLimit: number = 1
  private foreRoundOverCount: number = 0
  onCreate(want, launchParam) {
    // Ability is creating, initialize resources for this ability
    Log.start(Log.ABILITY_WHOLE_LIFE)
    if (globalThis.cameraFormParam != undefined) {
      var featureManager = new FeatureManager(globalThis.cameraFormParam.mode, new ModeMap())
    } else {
      var featureManager = new FeatureManager('PHOTO', new ModeMap())
    }
    Log.info('Camera MainAbility onCreate.')
    globalThis.cameraAbilityContext = this.context
    globalThis.cameraAbilityWant = this.launchWant
    globalThis.permissionFlag = false

    Log.info(`Camera MainAbility onCreate launchWant. ${JSON.stringify(globalThis.cameraAbilityWant )}`)
    globalThis.cameraStartTime = new Date().getTime()
    globalThis.cameraStartFlag = true
    globalThis.stopRecordingFlag = false;
    globalThis.doOnForeground = false
    this.cameraBasicFunction = CameraBasicFunction.getInstance()
    this.cameraBasicFunction.initCamera({ cameraId: 'BACK', mode: 'PHOTO' }, 'onCreate')
  }

  onDestroy() {
    // Ability is creating, release resources for this ability
    Log.end(Log.ABILITY_WHOLE_LIFE)
    Log.end(Log.APPLICATION_WHOLE_LIFE)
    this.cameraBasicFunction.startIdentification = false
    PreferencesService.getInstance().flush()
    Log.info('Camera MainAbility onDestroy.')
  }

  onWindowStageCreate(windowStage) {
    // Main window is created, set main page for this ability
    Log.start(Log.ABILITY_VISIBLE_LIFE)
    Log.info('Camera MainAbility onWindowStageCreate.')
    windowStage.on('windowStageEvent', (event) => {
      Log.info('Camera MainAbility onWindowStageEvent: ' + JSON.stringify(event))
      if (event === window.WindowStageEventType.SHOWN) {
        if (++this.foreRoundOverCount > 1) {
          this.foreRoundOverCount = 1
          Log.info("multi task interface: reset zoomRatio to 1")
          globalThis?.resetZoomRatio && globalThis.resetZoomRatio()
        }
      } else if (event === window.WindowStageEventType.HIDDEN) {
        this.foreRoundOverCount--
      }
      globalThis.cameraWindowStageEvent = event
      if (event === window.WindowStageEventType.INACTIVE) {
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

        win.on('windowSizeChange', (data) => {
          data.width = (data.height != 1600) ? px2vp(data.width) - 8 : px2vp(data.width)
          data.height = (data.height != 1600) ? px2vp(data.height) - 43 : px2vp(data.height)
          AppStorage.SetOrCreate(Constants.APP_KEY_WINDOW_SIZE, data)
          this.appEventBus.emit("windowSize", [data])
        });

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

    windowStage.setUIContent(this.context, 'pages/indexLand', null)
  }

  onWindowStageDestroy() {
    Log.end(Log.ABILITY_VISIBLE_LIFE)
    Log.info('Camera MainAbility onWindowStageDestroy.')
  }

  onForeground() {
    Log.start(Log.ABILITY_FOREGROUND_LIFE)
    Log.info('Camera MainAbility onForeground.')
    globalThis.cameraNeedStatus = CameraNeedStatus.CAMERA_NEED_INIT
    if (globalThis?.doOnForeground && globalThis.doOnForeground) {
      console.info('Camera MainAbility onForeground.')
      globalThis?.updateCameraStatus && globalThis.updateCameraStatus()
    } else {
      globalThis.doOnForeground = true
    }
    Log.info('Camera MainAbility onForeground end.')
  }

  onBackground() {
    Log.end(Log.ABILITY_FOREGROUND_LIFE)
    Log.info('Camera MainAbility onBackground.')
    this.cameraBasicFunction.startIdentification = false
    globalThis.cameraNeedStatus = CameraNeedStatus.CAMERA_NEED_RELEASE
    globalThis?.updateCameraStatus && globalThis.updateCameraStatus()
  }

  onNewWant(want) {
    Log.info('Camera MainAbility onNewWant.')
    globalThis.cameraAbilityWant = want
    Log.info(`Camera MainAbility E newWantAction: ${JSON.stringify(globalThis.cameraAbilityWant )}`)
  }
}