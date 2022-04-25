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

//import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'

@Component
export default struct EntryComponentForMulti {
  private TAG: string = '[EntryComponentForMulti]:'
  @Prop item: string
  @Link cameraPosition: string
  @Link xComponentChangeFlag: boolean
  private onChange: Function
//  private cameraService = CameraService.getInstance()
  private curCameraName

  private aboutToAppear() {
//    this.curCameraName = this.cameraService.getCameraName()
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Text(this.item)
        .fontColor('#E6000000')
        .fontSize($r("sys.float.ohos_id_text_size_body1"))
        .fontWeight(FontWeight.Regular)

      Radio({ group: 'settingChildren', value: this.item.toString() })
        .width(24)
        .height(24)
        .checked(this.item.toString() === globalThis.curCameraName)
        .enabled(true)
        .onClick(() => {
          CLog.info(this.TAG + ' onChange: ' + this.item)
          globalThis.curCameraName = this.item
//          this.cameraService.setCameraName(this.item)
          if (this.item == '本地（前置）') {
            this.cameraPosition = 'FRONT'
          } else if (this.item == '本地（后置）') {
            this.cameraPosition = 'BACK'
          } else {
            this.cameraPosition = this.item
          }
          this.xComponentChangeFlag = !this.xComponentChangeFlag
//          console.info(`EntryComponent onChange itemValue${this.itemValue}`)
//          this.settingsUtil.setSettingValue(this.settingAlias, this.itemValue)
          //            console.info("EntryComponent onChange end ")
          this.onChange()
        })
    }
    .height(48)
    .width('100%')
  }
}