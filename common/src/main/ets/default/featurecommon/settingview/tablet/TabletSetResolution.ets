/**
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

import { Action } from '../../../redux/actions/Action'
import AspectRatio from '../../../setting/settingitem/AspectRatio'
import Resolution from '../../../setting/settingitem/Resolution'
import Timer from '../../../setting/settingitem/Timer'
import { CustomDialogView, CustomDialogDetails } from '../../customdialog/dialogComponent/CustomDialogView'
import { Log } from '../../../utils/Log'
import { getStore } from '../../../redux/store'
import { SettingManager } from '../../../setting/SettingManager'
import { BaseData }  from '../model/BaseData'
import { SettingData }  from '../model/SettingData'

let localState = (state) => {
  return {
    isCloseFlag: state.SettingReducer.isCloseFlag
  }
}

let localDispatcher = (dispatch) => {
  return {
    closeDialog: (isCloseFlag: boolean) => {
      dispatch(Action.closeDialog(isCloseFlag))
    }
  }
}

class StateStruct {
  isCloseFlag
  closeDialog: Function
}

@Component
export struct TabletSetResolution {
  private TAG: string = '[TabletSetResolution]:'
  @Link settingsList: any[]
  @Link @Watch('onCloseDialog') closeFlag: boolean
  private itemValue: SettingData
  private getCheckValue: Promise<string>
  private WH_100_100: string = "100%"
  private settingManager = SettingManager.getInstance()
  private setAlias: string= undefined
  @StorageLink("settingDialogFlag") settingDialogFlag: boolean = true

  @State curCheckName: Resource = $r("app.string.default_value")

  @State state: StateStruct = new StateStruct()

  @Provide customDialogDetails: CustomDialogDetails = {
    confirmCallback: null,
    confirmItem: true,
    height: 256,
    width: 256,
    setAlias: this.setAlias,
    childrenList: [],
    settingTitle: '',
//    dialogCloseFlag:false
  }
  CustomDialogView: CustomDialogController = new CustomDialogController({
    builder: CustomDialogView({ cancel: this.existView.bind(this) }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    cancel: this.existView,
    customStyle: true
  })

  existView() {
    Log.info(`${this.TAG} existView E`)
    if (this.settingManager.getSettingValue(this.itemValue.settingAlias) !== undefined) {
      this.curCheckName = JSON.parse(JSON.stringify(this.settingManager.getSettingValue(this.itemValue.settingAlias)))
      Log.info(`${this.TAG} existView curCheckName: ${this.curCheckName} X`)
    }
    this.state.closeDialog(false)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear settingsList: ${JSON.stringify(this.settingsList)} E`)
    getStore().connect(localState, localDispatcher)(this.state)
    Log.info(`${this.TAG} aboutToAppear this.closeFlag ${this.closeFlag}`)
    if (this.settingManager.getSettingValue(this.itemValue.settingAlias) !== undefined) {
      this.curCheckName = JSON.parse(JSON.stringify(this.settingManager.getSettingValue(this.itemValue.settingAlias)))
      Log.info(`${this.TAG} aboutToAppear curCheckName: ${this.curCheckName} X`)
    }
  }

  public onCloseDialog() {
    Log.info(`${this.TAG} onCloseDialog E`)
    if (this.customDialogDetails.setAlias !== undefined) {
      this.state.closeDialog(false)
      this.CustomDialogView.close()
    }
    Log.info(`${this.TAG} onCloseDialog X`)
  }

  public formatCurCheckName(name) {
    if (name.id === Timer.DEFAULT_VALUE.id) {
      name = Timer.RESOURCE_OFF_ALREADY
    }
    return name
  }

  build() {
    Row() {
      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween
      }) {
        Row() {
          Image(this.itemValue.imagePath)
            .width(24)
            .height(24)
            .fillColor("#FFFFFF")
          Text(this.itemValue.settingName)
            .margin({ left: $r("sys.float.ohos_id_elements_margin_horizontal_l") })
            .fontColor("#FFFFFF")
            .fontSize($r("sys.float.ohos_id_text_size_sub_title2"))
            .fontWeight(FontWeight.Regular)
        }

        Row() {
          Text(this.formatCurCheckName(this.curCheckName))
            .fontColor($r('app.color.font_color_FFFFFF'))
            .fontSize($r("sys.float.ohos_id_text_size_body2"))
            .opacity(0.6)
            .fontWeight(FontWeight.Regular)
            .opacity($r('app.float.opacity_6'))
          Image($r("app.media.ic_public_arrow_right"))
            .width(12)
            .height(24)
            .fillColor('#33FFFFFF')
            .opacity(0.4)
            .opacity($r('app.float.opacity_4'))
            .margin({ left: 4 })
        }
      }
      .height(64)
      .padding({ left: 12, right: 12 })
    }
    .width(this.WH_100_100)
    .height(56)
    .onClick(() => {
      if (this.settingDialogFlag) {
        this.settingDialogFlag = false
        setTimeout(() => {
          this.settingDialogFlag = true
        }, 200)
        this.openDetailsDialog(this.itemValue)
      }
    })
  }

  async openDetailsDialog(itemValue): Promise<void> {
    Log.info(`${this.TAG} openDetailsDialog start`)
    Log.info(`${this.TAG} openDetailsDialog dataInfo ${JSON.stringify(itemValue)}`)
    // 需要根据相机能力更新这个childrenList，目前是写死状态
    this.customDialogDetails.childrenList = itemValue.radio;
    this.customDialogDetails.settingTitle = itemValue.settingName;
    this.customDialogDetails.setAlias = itemValue.settingAlias;
//    this.customDialogDetails.dialogCloseFlag = this.closeFlag
    Log.info(`${this.TAG} childrenList: ${JSON.stringify(itemValue.radio)}`)
    this.state.closeDialog(true)
    this.CustomDialogView.open()
    Log.info(`${this.TAG} openDetailsDialog end`)
  }
}
