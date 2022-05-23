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
import Timer from '../../../../../../../../../../common/src/main/ets/default/setting/Timer';
import AspectRatio from '../../../../../../../../../../common/src/main/ets/default/setting/AspectRatio';
import Resolution from '../../../../../../../../../../common/src/main/ets/default/setting/Resolution';

@Component
export default struct EntryComponent {
  private TAG: string = '[EntryComponent]:'
  @Prop itemValue: string;
  @Prop checkedValue: string;
  @Prop settingAlias: string;
  private getValue: any
  private onChange: Function
  private settingsUtil = SettingsUtil.getInstance()

  async aboutToAppear(): Promise<void> {
    CLog.info(`${this.TAG} aboutToAppear calle1d = ${this.settingAlias}`)
    try {
      this.getValue = await this.settingsUtil.getSettingValue(this.settingAlias)
      CLog.log(`${this.TAG} EntryComponent.getValue=${this.getValue}`)
    } catch {
      CLog.log(`${this.TAG} catch this.settingAlias=${this.settingAlias}`)
      if (this.settingAlias === Resolution.ALIAS) {
        this.getValue = Resolution.DEFAULT_VALUE
      } else if (this.settingAlias === Timer.ALIAS) {
        this.getValue = Timer.DEFAULT_VALUE
      } else {
        this.getValue = AspectRatio.DEFAULT_VALUE
      }
      CLog.error(`${this.TAG} catch this.getValue=${this.getValue}`)
    }
  }

  build() {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Text(this.itemValue)
          .fontColor('#E6000000')
          .fontSize($r("sys.float.ohos_id_text_size_body1"))
          .fontWeight(FontWeight.Regular)

        Radio({ group: 'settingChildren', value: this.itemValue.toString() })
          .width(24)
          .height(24)
          .borderColor('#1095E8')
          .checked(JSON.stringify(this.itemValue) === JSON.stringify(this.getValue))
          .enabled(true)
          .onClick(() => {
            CLog.info(`${this.TAG} onChange settingAlias:${this.settingAlias}  itemValue:${this.itemValue}`)
            this.settingsUtil.setSettingValue(this.settingAlias, this.itemValue)
            this.onChange()
          });
      }
      .width('100%')
  }
}