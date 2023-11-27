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

import { Action } from '../../redux/actions/Action';
import { CameraSwitchController } from './CameraSwitchController';
import { Dispatch, OhCombinedState } from '../../redux/store';
import { getStore } from '../../redux/store';
import { Log } from '../../utils/Log';
import MultiCameraDialog from '../customdialog/MultiCameraDialog';
import deviceInfo from '@ohos.deviceInfo';
import { GlobalContext } from '../../utils/GlobalContext';
import { CameraId } from '../../setting/settingitem/CameraId';

let storageCameraId: string = AppStorage.Link('storageCameraId') as string;

class StateStruct {
  mode: string = 'PHOTO';
  uiEnable: boolean = true;
  cameraPosition: CameraId = CameraId.BACK;
  videoState: string = 'beforeTakeVideo';
}


class CameraSwitchDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeCameraPosition(cameraPosition: string): void {
    this.mDispatch(Action.uiState(false));
    this.mDispatch(Action.switchCamera(cameraPosition));
    this.mDispatch(Action.resetZoomRatio(1));
  }
}


@Component
export struct CameraSwitchButton {
  private TAG: string = '[CameraSwitchButton]:'
  @State state: StateStruct = new StateStruct()
  @State deviceType: string = deviceInfo.deviceType
  @StorageLink('storageCameraId') storageCameraId: string = ''
  icon: Resource = $r('app.media.small_switch_camera')
  mWidth: number = 0;
  mHeight: number = 0;
  mMargin: number = 0;
  type: ButtonType = ButtonType.Capsule;
  stateEffect: boolean = false;
  private mAction: CameraSwitchDispatcher = new CameraSwitchDispatcher();
  cameraSwitchController: CameraSwitchController = new CameraSwitchController()
  multiDialogController: CustomDialogController = new CustomDialogController({
    builder: MultiCameraDialog({
      cancel: () => this.existView(),
      deviceType: $deviceType
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
    cancel: this.existView
  })

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`);
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        mode: state.modeReducer.mode,
        uiEnable: state.contextReducer.uiEnable,
        cameraPosition: state.cameraReducer.cameraPosition,
        videoState: state.recordReducer.videoState
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.cameraSwitchController.getParam()
    this.icon = this.cameraSwitchController.icon
    this.mWidth = this.cameraSwitchController.width
    this.mHeight = this.cameraSwitchController.height
    this.mMargin = this.cameraSwitchController.margin
    this.type = this.cameraSwitchController.type
    this.stateEffect = this.cameraSwitchController.stateEffect
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  private openMultiDialog() {
    Log.info(`${this.TAG} openMultiDialog E`)
    this.multiDialogController.open()
    Log.info(`${this.TAG} openMultiDialog X`)
  }

  private existView(): void {}

  build() {
    Column() {
      Stack() {
        Image($r('app.media.small_switch_camera'))
          .width('67.5%').aspectRatio(1)
          .clip(new Circle({ width: '100%', height: '100%' }))
        Column() {}.width(44).height(44)
        .border({ width: 1, color: Color.White, radius: 22, style: BorderStyle.Solid })
      }
      .width('100%').height('100%').enabled(this.state.uiEnable)
      .onClick(() => {
        Log.info(`${this.TAG} onClick invoke E`)
        Log.info(`${this.TAG} this.state.videoState: ${this.state.videoState}, this.state.mode: ${this.state.mode}`)
        Log.info(`${this.TAG} this.state.cameraPosition: ${this.state.cameraPosition}`)
        if (this.state.videoState === 'beforeTakeVideo') {
          if (this.state.mode === 'MULTI') {
            this.openMultiDialog()
          } else {
            GlobalContext.get().setObject('switchCameraTime',new Date().getTime())
            if (this.state.cameraPosition !== 'BACK') {
              this.mAction.changeCameraPosition('BACK')
              this.storageCameraId = 'BACK'
            } else {
              this.mAction.changeCameraPosition('FRONT')
              this.storageCameraId = 'FRONT'
            }
          }
        }
        Log.info(`${this.TAG} onClick invoke X`)
      })
    }.width(44).aspectRatio(1)
  }
}