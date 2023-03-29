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

import router from "@system.router"

import { Action } from '../../redux/actions/Action'
import { Log } from '../../utils/Log'
import { EventBus } from '../../worker/eventbus/EventBus'
import { EventBusManager } from '../../worker/eventbus/EventBusManager'
import { getStore } from '../../redux/store'
import { SettingManager } from '../../setting/SettingManager'
import Timer from '../../setting/settingitem/Timer'
import { ComponentPosition } from '../../utils/ComponentPosition'

let localState = (state) => {
  return {
    uiEnable: state.ContextReducer.uiEnable,
    shutterIcon: state.CameraReducer.shutterIcon,
    videoState: state.RecordReducer.videoState,
    mode: state.ModeReducer.mode,
    videoUri: state.CameraInitReducer.videoUri,
    resourceUri: state.CameraInitReducer.resourceUri,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    xComponentWidth: state.PreviewReducer.xComponentWidth,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateSmallVideoTimerVisible: (visible: boolean) => {
      dispatch(Action.updateSmallVideoTimerVisible(visible))
    },
//    updateCaptureBtnScale: (scale: number) => {
//      dispatch(Action.updateCaptureBtnScale(scale))
//    },
    updateShutterIcon: (icon: Resource) => {
      dispatch(Action.updateShutterIcon(icon))
    },
    capture: () => {
      dispatch(Action.updateShowFlashBlackFlag(true))
      dispatch(Action.capture())
    },
    startRecording: () => {
      dispatch(Action.startRecording())
      dispatch(Action.updateVideoState('startTakeVideo'))
      dispatch(Action.updateBigVideoTimerVisible(true))
      dispatch(Action.updateScreenStatus(true))
    },
    pauseRecording: () => {
      dispatch(Action.pauseRecording())
      dispatch(Action.updateVideoState('pauseTakeVideo'))
    },
    resumeRecording: () => {
      dispatch(Action.resumeRecording())
      dispatch(Action.updateVideoState('startTakeVideo'))
    },
    stopRecording: () => {
      dispatch(Action.stopRecording())
      dispatch(Action.updateVideoState('beforeTakeVideo'))
      dispatch(Action.updateBigVideoTimerVisible(false))
      dispatch(Action.updateSmallVideoTimerVisible(false))
      dispatch(Action.updateScreenStatus(false))
    },
    changeTimeLapse: (isShowtimeLapse: boolean) => {
      dispatch(Action.changeTimeLapse(isShowtimeLapse))
    }
  }
}

class StateStruct {
  uiEnable
  shutterIcon
  videoState
  mode
  videoUri
  resourceUri
  isThirdPartyCall
  xComponentWidth
  xComponentHeight
  thumbnail
  updateSmallVideoTimerVisible: Function
  updateShutterIcon: Function
  capture: Function
  startRecording: Function
  pauseRecording: Function
  resumeRecording: Function
  stopRecording: Function
  changeTimeLapse: Function
}

type ScreenSizeType = {
  width: number
  height: number
}

@Component
export struct ShutterButtonLand {
  private TAG: string = '[ShutterButtonLand]:'
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private settingManager = SettingManager.getInstance()
  private lastTime = 0
  @Link screenSize: ScreenSizeType

  type: ButtonType
  stateEffect: boolean

  @State state: StateStruct = new StateStruct()
  @State captureBtnScale: number = 1

  aboutToAppear(): void {
    Log.debug(`${this.TAG} aboutToAppear E`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_CHANGE_MODE, this.changeShutterIcon.bind(this))
    this.appEventBus.on(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    this.appEventBus.on(Action.ACTION_INIT_MODE, this.changeShutterIcon.bind(this))
    this.refreshIcon(this.state.mode)
    Log.debug(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.debug(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_CHANGE_MODE, this.changeShutterIcon.bind(this))
    this.appEventBus.off(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    this.appEventBus.off(Action.ACTION_INIT_MODE, this.changeShutterIcon.bind(this))
    Log.debug(`${this.TAG} aboutToDisappear X`)
  }

  private async onThumbnailUpdate(data) {
    Log.info(`${this.TAG} onThumbnailUpdate data: ${JSON.stringify(data)} E`)
    Log.debug(`${this.TAG} onThumbnailUpdate resourceUri= ${JSON.stringify(this.state.resourceUri)} E`)
    Log.info(`${this.TAG} onThumbnailUpdate isThirdPartyCall= ${this.state.isThirdPartyCall} E`)
    Log.debug(`${this.TAG} onThumbnailUpdate videoUri= ${this.state.videoUri} E`)
    if (this.state.isThirdPartyCall) {
      Log.info(`${this.TAG} onThumbnailUpdate start router to ThirdPreviewView`)
      router.push({
        uri: "pages/ThirdPreviewView",
        params: {
          width: this.state.xComponentWidth,
          height: this.state.xComponentHeight,
          mode: this.state.mode,
          uri: this.state.resourceUri,
          videoUri: this.state.videoUri,
          callBundleName:globalThis.cameraAbilityWant?.parameters?.callBundleName
        }
      })
    }
    Log.info(`${this.TAG} onThumbnailUpdate this.state.thumbnail: ${JSON.stringify(this.state.thumbnail)} X`)
  }

  private async changeShutterIcon(data) {
    Log.debug(`${this.TAG} resetShutterIcon E`)
    this.refreshIcon(data.mode)
    Log.debug(`${this.TAG} resetShutterIcon X`)
  }

  private async refreshIcon(mode: string) {
    Log.debug(`${this.TAG} refreshIcon E`)
    if (mode === 'PHOTO') {
      this.state.updateShutterIcon($r('app.media.ic_circled_filled'))
    } else if (mode === 'VIDEO') {
      this.state.updateShutterIcon($r('app.media.take_video_normal'))
    } else {
      this.state.updateShutterIcon($r('app.media.ic_circled_filled'))
    }
    Log.debug(`${this.TAG} refreshIcon X`)
  }

  build() {
    if (this.state.videoState === 'beforeTakeVideo') {
      Stack({alignContent: Alignment.Center}) {
        if (this.state.mode === 'VIDEO'){
          Image(this.state.shutterIcon)
            .width(76).aspectRatio(1).enabled(this.state.uiEnable)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Up) {
                let timerLapse = this.settingManager.getTimeLapse()
                Log.log(`${this.TAG} startRecording getValue= ${JSON.stringify(timerLapse)}`)
                if (timerLapse && timerLapse.id !== Timer.RESOURCE_OFF.id) {
                  this.state.changeTimeLapse(true)
                } else {
                  this.state.startRecording()
                }
              }
            })
        } else {
          Image($r("app.media.ic_circled")).fillColor(Color.White).width(76).aspectRatio(1)
          Image(this.state.shutterIcon).width(54).aspectRatio(1).fillColor(Color.White)
            .scale({ x: this.captureBtnScale, y: this.captureBtnScale, z: this.captureBtnScale })
            .enabled(this.state.uiEnable)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                animateTo(
                  { duration: 125, curve: Curve.Sharp, delay: 0 },
                  () => { this.captureBtnScale = 0.85 })
              } else if (event.type === TouchType.Up) {
                animateTo(
                  { duration: 125, curve: Curve.Sharp, delay: 0,
                    onFinish: () => { this.captureBtnScale = 1 }},
                  () => { this.captureBtnScale = 1 })
                let timerLapse = this.settingManager.getTimeLapse()
                Log.log(`${this.TAG} startCapture getValue= ${JSON.stringify(timerLapse)}`)
                if (timerLapse && timerLapse.id !== Timer.RESOURCE_OFF.id) {
                  this.state.changeTimeLapse(true)
                } else {
                  let waitTime = 450
                  let curTime = Date.now();
                  if (Math.abs(curTime - this.lastTime) >= waitTime) {
                    Log.log(`${this.TAG} throttle invoke time = ${JSON.stringify(curTime - this.lastTime)}`)
                    this.state.capture()
                    this.lastTime = curTime;
                  }
                }
              }
            })
        }
      }.width(76).aspectRatio(1).margin({
        top: ComponentPosition.getShutterButtonMargin(this.screenSize.width, this.screenSize.height, this.state.xComponentHeight),
        bottom: ComponentPosition.getShutterButtonMargin(this.screenSize.width, this.screenSize.height, this.state.xComponentHeight) })
    } else {
      Column() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          if (this.state.videoState === 'startTakeVideo') {
            Image($r('app.media.ic_video_recording'))
              .width(20).aspectRatio(1).fillColor(Color.White)
              .margin({ bottom: 16 })
              .enabled(this.state.uiEnable)
              .onClick(() => {
                this.state.pauseRecording()
              })
          } else if (this.state.videoState === 'pauseTakeVideo') {
            Image($r('app.media.ic_video_pause')).width(20).aspectRatio(1).fillColor(Color.Red)
              .margin({ bottom: 16 })
              .enabled(this.state.uiEnable)
              .onClick(() => {
                this.state.resumeRecording()
              })
          }
          Image($r('app.media.ic_video_end'))
            .width(20).aspectRatio(1).fillColor(Color.White)
            .margin({ top: 16 })
            .enabled(this.state.uiEnable)
            .onClick(() => {
              this.state.stopRecording()
            })
        }
      }
      .width(56)
      .height(120)
      .borderRadius(28)
      .border({ width: 1, color: 0xffffff, style: BorderStyle.Solid })
      .margin({ top: 26, bottom: 26 })
    }
  }
}