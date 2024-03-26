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

import router from '@system.router';

import { Action } from '../../redux/actions/Action';
import { Log } from '../../utils/Log';
import { EventBus } from '../../worker/eventbus/EventBus';
import { EventBusManager } from '../../worker/eventbus/EventBusManager';
import { Dispatch, OhCombinedState } from '../../redux/store';
import { getStore } from '../../redux/store';
import { SettingManager } from '../../setting/SettingManager';
import Timer from '../../setting/settingitem/Timer';
import { ComponentPosition } from '../../utils/ComponentPosition';
import { GlobalContext } from '../../utils/GlobalContext';
import image from '@ohos.multimedia.image';

class StateStruct {
  uiEnable: boolean = true;
  shutterIcon: Resource = $r('app.media.ic_circled_filled');
  captureBtnScale: number = 0;
  videoState: string = 'beforeTakeVideo';
  mode: string = '';
  resourceUri: string = '';
  videoUri: string = ''
  thumbnail: Resource = $r('app.media.ic_camera_thumbnail_default_white');
  isThirdPartyCall: boolean = false;
  xComponentWidth: number = 0;
  xComponentHeight: number = 0;
}

class ShutterButtonDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public updateSmallVideoTimerVisible(visible: boolean): void {
    this.mDispatch(Action.updateSmallVideoTimerVisible(visible));
  }

  public updateShutterIcon(icon: Resource): void {
    this.mDispatch(Action.updateShutterIcon(icon));
  }

  public capture(): void {
    this.mDispatch(Action.updateShowFlashBlackFlag(true));
    this.mDispatch(Action.capture());
  }

  public startRecording(): void {
    this.mDispatch(Action.startRecording());
    this.mDispatch(Action.updateVideoState('startTakeVideo'));
    this.mDispatch(Action.updateBigVideoTimerVisible(true));
    this.mDispatch(Action.updateScreenStatus(true));
  }

  public pauseRecording(): void {
    this.mDispatch(Action.pauseRecording());
    this.mDispatch(Action.updateVideoState('pauseTakeVideo'));
  }

  public resumeRecording(): void {
    this.mDispatch(Action.resumeRecording());
    this.mDispatch(Action.updateVideoState('startTakeVideo'));
  }

  public stopRecording(): void {
    this.mDispatch(Action.stopRecording());
    this.mDispatch(Action.updateVideoState('beforeTakeVideo'));
    this.mDispatch(Action.updateBigVideoTimerVisible(false));
    this.mDispatch(Action.updateSmallVideoTimerVisible(false));
    this.mDispatch(Action.updateScreenStatus(false));
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }
}

class ScreenSizeType {
  width: number = 0;
  height: number = 0;
}

class ModeStruct {
  mode: string = '';
}

class UpdateThumbnailStruct {
  thumbnail: image.PixelMap | undefined = undefined;
  resourceUri: string = '';
}

@Component
export struct ShutterButtonLand {
  private TAG: string = '[ShutterButtonLand]:';
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private settingManager = SettingManager.getInstance();
  private lastTime = 0;
  @Link screenSize: ScreenSizeType;
  type: ButtonType = ButtonType.Capsule;
  stateEffect: boolean = false;
  @State state: StateStruct = new StateStruct();
  @State captureBtnScale: number = 1;
  private mAction: ShutterButtonDispatcher = new ShutterButtonDispatcher();

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`);
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        uiEnable: state.contextReducer.uiEnable,
        shutterIcon: state.cameraReducer.shutterIcon,
        captureBtnScale: state.captureReducer.captureBtnScale,
        videoState: state.recordReducer.videoState,
        mode: state.modeReducer.mode,
        resourceUri: state.cameraInitReducer.resourceUri,
        videoUri: state.cameraInitReducer.videoUri,
        thumbnail: state.cameraInitReducer.thumbnail,
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
        xComponentWidth: state.previewReducer.xComponentWidth,
        xComponentHeight: state.previewReducer.xComponentHeight
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.appEventBus.on(Action.ACTION_CHANGE_MODE, (data: ModeStruct) => this.changeShutterIcon(data));
    this.appEventBus.on(Action.ACTION_UPDATE_THUMBNAIL, (data: UpdateThumbnailStruct) => this.onThumbnailUpdate(data));
    this.appEventBus.on(Action.ACTION_INIT_MODE, (data: ModeStruct) => this.changeShutterIcon(data));
    this.refreshIcon(this.state.mode)
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`);
    this.appEventBus.off(Action.ACTION_CHANGE_MODE, (data: ModeStruct) => this.changeShutterIcon(data))
    this.appEventBus.off(Action.ACTION_UPDATE_THUMBNAIL, (data: UpdateThumbnailStruct) => this.onThumbnailUpdate(data))
    this.appEventBus.off(Action.ACTION_INIT_MODE, (data: ModeStruct) => this.changeShutterIcon(data));
    Log.info(`${this.TAG} aboutToDisappear X`);
  }

  private async onThumbnailUpdate(data: UpdateThumbnailStruct): Promise<void> {
    Log.info(`${this.TAG} onThumbnailUpdate data: ${JSON.stringify(data)} E`)
    Log.info(`${this.TAG} onThumbnailUpdate resourceUri= ${JSON.stringify(this.state.resourceUri)} E`);
    Log.info(`${this.TAG} onThumbnailUpdate isThirdPartyCall= ${this.state.isThirdPartyCall} E`)
    Log.info(`${this.TAG} onThumbnailUpdate videoUri= ${this.state.videoUri} E`);
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
          callBundleName: GlobalContext.get().getCameraAbilityWant()?.parameters?.callBundleName
        }
      })
    }
    Log.info(`${this.TAG} onThumbnailUpdate this.state.thumbnail: ${JSON.stringify(this.state.thumbnail)} X`)
  }

  private async changeShutterIcon(data: ModeStruct): Promise<void> {
    Log.info(`${this.TAG} resetShutterIcon E`);
    this.refreshIcon(data.mode)
    Log.info(`${this.TAG} resetShutterIcon X`);
  }

  private async refreshIcon(mode: string): Promise<void> {
    Log.info(`${this.TAG} refreshIcon E`);
    if (mode === 'PHOTO') {
      this.mAction.updateShutterIcon($r('app.media.ic_circled_filled'))
    } else if (mode === 'VIDEO') {
      this.mAction.updateShutterIcon($r('app.media.take_video_normal'))
    } else {
      this.mAction.updateShutterIcon($r('app.media.ic_circled_filled'))
    }
    Log.info(`${this.TAG} refreshIcon X`);
  }

  build() {
    if (this.state.videoState === 'beforeTakeVideo') {
      Stack({ alignContent: Alignment.Center }) {
        if (this.state.mode === 'VIDEO') {
          Image(this.state.shutterIcon)
            .width(76).aspectRatio(1).enabled(this.state.uiEnable)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Up) {
                let timerLapse = this.settingManager.getTimeLapse()
                Log.log(`${this.TAG} startRecording getValue= ${JSON.stringify(timerLapse)}`)
                if (timerLapse && timerLapse.id !== Timer.RESOURCE_OFF.id) {
                  this.mAction.changeTimeLapse(true)
                } else {
                  this.mAction.startRecording()
                }
              }
            })
        } else {
          Image($r("app.media.ic_circled")).fillColor(Color.White).width(76).aspectRatio(1)
          Image(this.state.shutterIcon)
            .width(54)
            .aspectRatio(1)
            .fillColor(Color.White)
            .scale({ x: this.captureBtnScale, y: this.captureBtnScale, z: this.captureBtnScale })
            .enabled(this.state.uiEnable)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                animateTo(
                  { duration: 125, curve: Curve.Sharp, delay: 0 },
                  () => {
                    this.captureBtnScale = 0.85
                  })
              } else if (event.type === TouchType.Up) {
                animateTo(
                  { duration: 125, curve: Curve.Sharp, delay: 0,
                    onFinish: () => {
                      this.captureBtnScale = 1
                    } },
                  () => {
                    this.captureBtnScale = 1
                  })
                let timerLapse = this.settingManager.getTimeLapse()
                Log.log(`${this.TAG} startCapture getValue= ${JSON.stringify(timerLapse)}`)
                if (timerLapse && timerLapse.id !== Timer.RESOURCE_OFF.id) {
                  this.mAction.changeTimeLapse(true)
                } else {
                  let waitTime = 450
                  let curTime = Date.now();
                  if (Math.abs(curTime - this.lastTime) >= waitTime) {
                    Log.log(`${this.TAG} throttle invoke time = ${JSON.stringify(curTime - this.lastTime)}`)
                    this.mAction.capture()
                    this.lastTime = curTime;
                  }
                }
              }
            })
        }
      }.width(76).aspectRatio(1).margin({
        top: ComponentPosition.getShutterButtonMargin(this.screenSize.width, this.screenSize.height, this.state.xComponentHeight),
        bottom: ComponentPosition.getShutterButtonMargin(this.screenSize.width, this.screenSize.height, this.state.xComponentHeight)
      })
    } else {
      Column() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          if (this.state.videoState === 'startTakeVideo') {
            Image($r('app.media.ic_video_recording'))
              .width(20)
              .aspectRatio(1)
              .fillColor(Color.White)
              .margin({ bottom: 16 })
              .enabled(this.state.uiEnable)
              .onClick(() => {
                this.mAction.pauseRecording()
              })
          } else if (this.state.videoState === 'pauseTakeVideo') {
            Image($r('app.media.ic_video_pause'))
              .width(20)
              .aspectRatio(1)
              .fillColor(Color.Red)
              .margin({ bottom: 16 })
              .enabled(this.state.uiEnable)
              .onClick(() => {
                this.mAction.resumeRecording()
              })
          }
          Image($r('app.media.ic_video_end'))
            .width(20)
            .aspectRatio(1)
            .fillColor(Color.White)
            .margin({ top: 16 })
            .enabled(this.state.uiEnable)
            .onClick(() => {
              this.mAction.stopRecording()
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