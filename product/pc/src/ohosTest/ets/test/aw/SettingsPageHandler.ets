/*
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
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

import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { TestUtils } from '../utils/TestUtils';
import { Driver, ON } from '@ohos.UiTest';
import { TestConstants } from '../TestConstants';

const TAG: string = TestConstants.TAG + '_' + 'SettingsPageHandler';

export class SettingsPageHandler {
  /**
   * 进入设置页
   * 1.点击设置
   */
  public static async SettingViewOpen(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'SettingViewOpen');
    HiLog.i(TAG, 'treasureBox open');
    let id = ComponentIdKeys.CAMERA_SETTING_1;
    HiLog.i(TAG, 'settingView click');
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
    HiLog.end(TAG, 'SettingViewOpen');
  }

  /**
   * 恢复默认值
   * 1.进入设置页
   * 2.上滑
   * 3.点击恢复默认值 确认
   * 4.点击允许
   */
  public static async RestoreDefaultValue(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'RestoreDefaultValue');
    HiLog.i(TAG, 'settingView enter');
    await SettingsPageHandler.SettingViewOpen(driver);
    await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
    if (!await driver.findComponent(ON.id('NAV_DESTINATION_TITLE_BACK_1'))) {
      return;
    }
    let id = ComponentIdKeys.SETTING_DEFAULT_BUTTON_1;
    while (!await driver.findComponent(ON.id(id))) {
      HiLog.i(TAG, 'slide up to find restore button');
      await TestUtils.slideUpHalfScreenQuick(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
    }
    HiLog.i(TAG, 'settingDefaultButton clicked.');
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
    HiLog.i(TAG, 'confirm');
    id = ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
    HiLog.i(TAG, 'settingDefaultConfirmGeo');
    id = ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
    const component = await driver.findComponent(ON.id(id));
    // 否允许“相机”获取您的精确位置 弹窗适配
    if (component) {
      id = ComponentIdKeys.SETTING_RESTORE_DEFAULT_CANCEL;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'location button cancel is clicked.');
    }
    HiLog.end(TAG, 'RestoreDefaultValue');
  }

  /**
   * 退出设置页
   * 1.设置页返回
   */
  public static async SettingViewClose(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'SettingViewClose');
    HiLog.i(TAG, 'slide left from screen');
    await TestUtils.slideLeftFromScreen(driver);
    await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
    HiLog.end(TAG, 'SettingViewClose');
  }
}