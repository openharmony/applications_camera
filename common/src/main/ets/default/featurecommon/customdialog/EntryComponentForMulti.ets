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

import { CameraService } from '../../camera/CameraService'
import { EventBus } from '../../worker/eventbus/EventBus'
import EventBusManager from '../../worker/eventbus/EventBusManager'
import { Log } from '../../utils/Log'

@Component
export default struct EntryComponentForMulti {
  private TAG: string = '[EntryComponentForMulti]:'
  @Prop item: string
  @Link cameraPosition: string
  @Link xComponentChangeFlag: boolean
  @State isLocalDevice: boolean = false
  @State switchCameraState: boolean = false
  @State recCameraState: boolean = true
  private onChange: Function
  private cameraService = CameraService.getInstance()
  private appEventBus = EventBusManager.getMainInstance().getEventBus()
  private deviceName: string
  private cameraPositionRes: Resource
  private curCameraName: string
  private cameraPositionName: string

  private aboutToAppear() {
    this.getShowName(this.item)
    this.curCameraName = this.cameraService.getCameraName()
    this.appEventBus.on('switchCameraState', (state) => {
      Log.info(`${this.TAG} switchCameraState= ${state}`)
      this.switchCameraState = state
    })
    this.appEventBus.on('recCameraState', (state) => {
      Log.info(`${this.TAG} recCameraState= ${state}`)
      this.recCameraState = state
    })
  }

  private getShowName(item) {
    let cameraMap
    this.cameraPositionName = item.split('_').pop()
    switch (this.cameraPositionName) {
      case 'FRONT':
        this.cameraPositionRes = $r("app.string.front")
        break
      case 'BACK':
        this.cameraPositionRes = $r("app.string.back")
        break
      default:
        break
    }
    if (item.split('_').length == 1) {
      this.isLocalDevice = true
    } else {
      cameraMap = this.cameraService.getCameraMap()
      this.deviceName = cameraMap.get(item).deviceName
      this.isLocalDevice = false
    }
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Row() {
        if (this.isLocalDevice) {
          Text($r("app.string.local"))
            .fontColor('#E6000000')
            .fontSize($r("sys.float.ohos_id_text_size_body1"))
            .fontWeight(FontWeight.Medium)
        } else {
          Text(this.deviceName)
            .fontColor('#E6000000')
            .fontSize($r("sys.float.ohos_id_text_size_body1"))
            .fontWeight(FontWeight.Medium)
        }
        Text(this.cameraPositionRes)
          .fontColor('#E6000000')
          .fontSize($r("sys.float.ohos_id_text_size_body1"))
          .fontWeight(FontWeight.Medium)
      }

      Radio({ group: 'settingChildren', value: this.item.toString() })
        .width(24)
        .height(24)
        .borderColor('#1095E8')
        .checked(this.item === this.curCameraName)
        .enabled(!this.switchCameraState || this.recCameraState)
        .onClick(() => {
          Log.info(`${this.TAG} onChange: ${this.item}`)
          this.cameraService.setCameraId(this.item)
          this.cameraPosition = this.item
          this.xComponentChangeFlag = !this.xComponentChangeFlag
          this.onChange()
        })
    }
    .height(48)
    .width('100%')
  }
}