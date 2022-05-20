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

import router from "@system.router"

//import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import {EventBus} from '../../../../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../../../../common/src/main/ets/default/Utils/EventBusManager'

let localState = (state) => {
  return {
    uiEnable: state.UiReducer.uiEnable,
    shutterIcon: state.UiReducer.shutterIcon,
    captureBtnScale: state.UiReducer.captureBtnScale,
    videoState: state.RecordReducer.videoState,
    mode: state.ModeReducer.mode,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateSmallVideoTimerVisible: (visible: boolean) => {
      dispatch(Action.UpdateSmallVideoTimerVisible(visible))
    },
    updateCaptureBtnScale: (scale: number) => {
      dispatch(Action.UpdateCaptureBtnScale(scale))
    },
    updateShutterIcon: (icon: Resource) => {
      dispatch(Action.UpdateShutterIcon(icon))
    },
    capture: () => {
      dispatch(Action.UpdateShowFlashBlackFlag(true))
      dispatch(Action.capture())
    },
    startRecording: () => {
      dispatch(Action.startRecording())
      dispatch(Action.UpdateVideoState('startTakeVideo'))
      dispatch(Action.UpdateBigVideoTimerVisible(true))
    },
    pauseRecording: () => {
      dispatch(Action.pauseRecording())
      dispatch(Action.UpdateVideoState('pauseTakeVideo'))
    },
    resumeRecording: () => {
      dispatch(Action.resumeRecording())
      dispatch(Action.UpdateVideoState('startTakeVideo'))
    },
    stopRecording: () => {
      dispatch(Action.stopRecording())
      dispatch(Action.UpdateVideoState('beforeTakeVideo'))
      dispatch(Action.UpdateBigVideoTimerVisible(false))
      dispatch(Action.UpdateSmallVideoTimerVisible(false))
    },
  }
}

@Component
export struct ShutterButton {
  private TAG: string = '[ShutterButton]:'
  private mConnect: any
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  width: number
  height: number
  type: ButtonType
  stateEffect: boolean

  @State state: any = {}

  private aboutToAppear() {
    CLog.debug(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_CHANGE_MODE, this.changeShutterIcon.bind(this))
    this.appEventBus.on(Action.ACTION_START_PREVIEW, this.changeShutterIcon.bind(this))
    CLog.debug(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.debug(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_CHANGE_MODE, this.changeShutterIcon.bind(this))
    this.appEventBus.off(Action.ACTION_START_PREVIEW, this.changeShutterIcon.bind(this))
    this.mConnect.destroy()
    CLog.debug(`${this.TAG} aboutToDisappear X`)
  }

  private async changeShutterIcon(data) {
    CLog.debug(`${this.TAG} resetShutterIcon E`)
    if ((data.mode || this.state.mode) === 'PHOTO') {
      this.state.updateShutterIcon($r('app.media.ic_circled_filled'))
    } else if ((data.mode || this.state.mode) === 'VIDEO') {
      this.state.updateShutterIcon($r('app.media.take_video_normal'))
    } else {
      this.state.updateShutterIcon($r('app.media.ic_circled_filled'))
    }
    CLog.debug(`${this.TAG} resetShutterIcon X`)
  }

  build() {
    if (this.state.videoState === 'beforeTakeVideo') {
      Stack({ alignContent: Alignment.Center }) {
        if (this.state.mode === 'VIDEO') {
          Image(this.state.shutterIcon)
            .width(76).aspectRatio(1).enabled(this.state.uiEnable)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Up) {
                this.state.startRecording()
              }
            })
        } else {
          Image($r('app.media.ic_circled')).fillColor(Color.White)
          Image(this.state.shutterIcon).width(54).aspectRatio(1).fillColor(Color.White)
            .scale({ x: this.state.captureBtnScale, y: this.state.captureBtnScale, z: this.state.captureBtnScale })
            .enabled(this.state.uiEnable)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                animateTo(
                  { duration: 125, curve: Curve.Sharp, delay: 0 },
                  () => { this.state.updateCaptureBtnScale(0.85) })
              } else if (event.type === TouchType.Up) {
                animateTo(
                  { duration: 125, curve: Curve.Sharp, delay: 0,
                    onFinish: () => { this.state.updateCaptureBtnScale(1) }},
                  () => { this.state.updateCaptureBtnScale(1) })
                this.state.capture()
              }
            })
        }
      }.width(76).aspectRatio(1).margin({ left: 48, right: 48 })
    } else {
      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r('app.media.ic_video_end'))
            .width(20).aspectRatio(1).fillColor(Color.White)
            .margin({ right: 16 })
            .enabled(this.state.uiEnable)
            .onClick(() => {
              this.state.stopRecording()
            })
          if (this.state.videoState === 'startTakeVideo') {
            Image($r('app.media.ic_video_recording'))
              .width(20).aspectRatio(1).fillColor(Color.White)
              .margin({ left: 16 })
              .enabled(this.state.uiEnable)
              .onClick(() => {
                this.state.pauseRecording()
              })
          } else if (this.state.videoState === 'pauseTakeVideo') {
            Image($r('app.media.ic_video_pause')).width(20).aspectRatio(1).fillColor(Color.Red)
              .margin({ left: 16 })
              .enabled(this.state.uiEnable)
              .onClick(() => {
                this.state.resumeRecording()
              })
          }
        }.width('100%').height('100%')
      }
      .width(120).height(56).borderRadius(28)
      .border({ width: 1, color: Color.White, style: BorderStyle.Solid })
      .margin({ left: 26, right: 26 })
    }
  }
}