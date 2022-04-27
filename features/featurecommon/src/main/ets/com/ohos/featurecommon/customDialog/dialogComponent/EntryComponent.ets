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

import settings from '@ohos.settings';

import {CLog} from '../../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import SettingListModel from '../../../../../../../../../../common/src/main/ets/default/model/SettingListImpl/SettingListModel';
import {SettingsUtil} from '../../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil';

@Component
export default struct EntryComponent {
  private TAG: string = '[EntryComponent]:'
  @Prop itemValue: string;
  @Prop checkedValue: string;
  @Prop settingAlias: string;
  @State getValue: string = ''
  private onChange: Function
  private settingsUtil = SettingsUtil.getInstance()

  async aboutToAppear(): Promise<void> {
    CLog.info(`${this.TAG} aboutToAppear calle1d = ${this.settingAlias}`)
    try {
      this.getValue = await this.settingsUtil.getSettingValue(this.settingAlias)
      CLog.log(`${this.TAG} EntryComponent.getValue=${this.getValue}`)
    } catch {
      CLog.log(`${this.TAG} catch this.settingAlias=${this.settingAlias}`)
      if (this.settingAlias === 'VideoResolution') {
        this.getValue = '[16:9] 720p'
      } else {
        this.getValue = '4:3'
      }
      CLog.log(`${this.TAG} catch this.getValue=${this.getValue}`)
    }
  }

  private logger(): boolean {
    CLog.info(`${this.TAG} build`)
    return true
  }

  build() {
    if (this.logger()) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Text(this.itemValue)
          .fontColor('#E6000000')
          .fontSize($r("sys.float.ohos_id_text_size_body1"))
          .fontWeight(FontWeight.Regular)

        Radio({ group: 'settingChildren', value: this.itemValue.toString() })
          .width(24)
          .height(24)
          .borderColor('#1095E8')
          .checked(this.itemValue.toString() === this.getValue.toString())
          .enabled(true)
          .onClick(() => {
            CLog.info(`${this.TAG} onChange settingAlias${this.settingAlias}`)
            CLog.info(`${this.TAG} onChange itemValue${this.itemValue}`)
            this.settingsUtil.setSettingValue(this.settingAlias, this.itemValue)
            this.onChange()
          });
      }
      //      .height(48)
      .width('100%')
    }
  }
}