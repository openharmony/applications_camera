/**
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

import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'

@Component
export default struct EntryComponentForMulti {
  @Prop item: string
  @Link cameraPosition: string
  @Link xComponentChangeFlag: boolean
  private onChange: Function
  private cameraService = CameraService.getInstance()
  private curCameraName

  private aboutToAppear() {
    this.curCameraName = this.cameraService.getCameraName()
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Text(this.item)
        .fontColor('#000000')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: '12vp', left: '12vp', bottom: '12vp', right: '24vp' })
      Radio({ group: 'settingChildren', value: this.item.toString() })
        .width(24)
        .height(24)
        .checked(this.item.toString() === this.curCameraName)
        .enabled(true)
        .onChange(() => {
          console.info('EntryComponentForMulti onChange: ' + this.item)
          this.cameraService.setCameraName(this.item)
          if (this.item == '本地（前置）') {
            this.cameraPosition = 'FRONT'
          } else if (this.item == '本地（后置）') {
            this.cameraPosition = 'BACK'
          } else {
            this.cameraPosition = this.item
          }
          this.xComponentChangeFlag = !this.xComponentChangeFlag
          this.onChange()
        })
    }
    .height(48)
    .width('100%')
  }
}