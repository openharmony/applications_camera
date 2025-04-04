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

import { CameraService } from '../../camera/CameraService';
import { Dispatch, getStore, OhCombinedState } from '../../redux/store';
import { Log } from '../../utils/Log';

class StateStruct {
  uiEnable: boolean = true;
}

class ComponentForMultiDispatcher {
  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  private mDispatch: Dispatch = (data) => data;
}


@Component
export default struct EntryComponentForMulti {
  @State state: StateStruct = new StateStruct();
  @State isLocalDevice: boolean = false;
  @State switchCameraState: boolean = false;
  @State recCameraState: boolean = true;
  @State defaultChecked: boolean = false;
  @State curCameraName: string = '';
  private TAG: string = '[EntryComponentForMulti]:';
  private localList: string = '';
  private item: string = '';
  private cameraService: CameraService = CameraService.getInstance();
  private deviceName: string = '';
  private cameraPositionRes: string | Resource = '';
  private cameraPositionName: string = '';
  private mAction: ComponentForMultiDispatcher = new ComponentForMultiDispatcher();

  aboutToAppear() {
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        uiEnable: state.contextReducer.uiEnable
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });


    this.getShowName(this.item)
    this.curCameraName = this.cameraService.getCameraName()
    if (this.localList.split(',').length === 1 && this.curCameraName === 'BACK') {
      this.curCameraName = 'FRONT'
    }
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Row() {
        if (this.isLocalDevice) {
          Text($r('app.string.local'))
            .fontColor('#E6000000')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Medium)
        } else {
          Text(this.deviceName)
            .fontColor('#E6000000')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Medium)
        }
        Text(this.cameraPositionRes)
          .fontColor('#E6000000')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Medium)
      }

      Radio({ group: 'settingChildren', value: this.item.toString() })
        .width(24)
        .height(24)
        .borderColor('#1095E8')
        .checked(this.defaultChecked ? true : this.item === this.curCameraName)
        .enabled(this.state.uiEnable)
        .onClick(() => {
          Log.info(`${this.TAG} onChange item: ${this.item}`)
          if (this.item === this.curCameraName) {
            Log.info(`${this.TAG} no Change curCameraName: ${this.curCameraName}`)
          } else {
            this.onChange(this.item)
          }
        })
    }
    .height(48)
    .width('100%')
  }

  private onChange: Function = () => {
  };

  private getShowName(item: string): void {
    this.cameraPositionName = item.split('_').pop() as string;
    switch (this.cameraPositionName) {
      case 'FRONT':
        this.cameraPositionRes = $r('app.string.front')
        break
      case 'BACK':
        this.cameraPositionRes = $r('app.string.back')
        break
      default:
        break
    }
    if (item.split('_').length == 1) {
      this.isLocalDevice = true
    } else {
      const cameraItem = this.cameraService.getCameraMap().get(item)
      if (cameraItem) {
        this.deviceName = cameraItem.deviceName as string;
        this.isLocalDevice = false
      }
    }
  }
}