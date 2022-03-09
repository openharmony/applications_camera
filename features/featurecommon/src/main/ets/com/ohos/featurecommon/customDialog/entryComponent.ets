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

import SettingListModel from '../../../../../../../../../common/src/main/ets/default/model/SettingListImpl/SettingListModel.ets';
import settings from '@ohos.settings';
import {SettingsUtil} from '../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil.ets';

@Component
export default struct EntryComponent {
  @Prop itemValue: string;
  @Prop checkedValue: string;
  @Prop settingAlias: string;
  @State getValue: string = ''
  private onChange: Function
  private settingsUtil = SettingsUtil.getInstance()

  async aboutToAppear(): Promise<void> {
    console.info(`EntryComponent aboutToAppear calle1d = ${this.settingAlias}`)
    try {
      this.getValue = await this.settingsUtil.getSettingValue(this.settingAlias)
      console.log(`EntryComponent.getValue=${this.getValue}`)
    } catch {
      console.log(`catch this.settingAlias=${this.settingAlias}`)
      if (this.settingAlias === 'Video resolution' || this.settingAlias === 'videoResolution') {
        this.getValue = '[16:9] 720p'
      } else {
        this.getValue = '4:3'
      }
      console.log(`catch this.getValue=${this.getValue}`)
    }
  }

  private logger(): boolean {
    console.info('EntryComponent build')
    return true
  }

  build() {
    if (this.logger()) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Text(this.itemValue)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Radio({ group: 'settingChildren', value: this.itemValue.toString() })
          .width(24)
          .height(24)
          .checked(this.itemValue.toString() === this.getValue.toString())
          .enabled(true)
          .onChange(() => {
            console.info(`EntryComponent onChange settingAlias${this.settingAlias}`)
            console.info(`EntryComponent onChange itemValue${this.itemValue}`)
            this.settingsUtil.setSettingValue(this.settingAlias, this.itemValue).then(() => {
              this.onChange()
            })
          })
      }
      .height(48)
      .width('100%')
    }
  }
}