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

import AbilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { TestUtils } from '../utils/TestUtils';
import { Driver, ON } from '@ohos.UiTest';
import { TestConstants } from '../TestConstants';
import { BusinessError } from '@ohos.base';

const TAG: string = TestConstants.TAG + '_' + 'CommonHandler';

export class CommonHandler {
  /**
   * 启动相机
   */
  public static async abilityStart(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'start ability');
    await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
    let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    try {
      await abilityDelegator.startAbility({
        bundleName: 'com.ohos.camera',
        abilityName: 'com.ohos.camera.MainAbility',
        parameters: {
          isRunningDT: true
        }
      });
    } catch (error) {
      let err = error as BusinessError;
      HiLog.e(TAG, `Failed to startAbility. Code: ${err?.code}`);
    }
    await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
    HiLog.end(TAG, 'start ability');
  }

  /**
   * 启动相机
   *  快捷列表
   */
  public static async abilityStartByShortCut(driver: Driver, mode:string): Promise<void> {
    HiLog.begin(TAG, `start ability by short cut , visit mode:${mode}`);
    await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
    let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    try {
      await abilityDelegator.startAbility({
        bundleName: 'com.ohos.camera',
        abilityName: 'com.ohos.camera.MainAbility',
        parameters: {
          isRunningDT: true,
          startByShortCut: true,
          mode:mode
        }
      });
    } catch (error) {
      let err = error as BusinessError;
      HiLog.e(TAG, `Failed to startAbility. Code: ${err?.code}`);
    }
    await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
    HiLog.end(TAG, 'start ability');
  }

  /**
   * 退出相机
   */
  public static async abilityEnd(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'end ability');
    await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
    await TestUtils.slideLeftFromScreen(driver);
    await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
    HiLog.end(TAG, 'end ability');
  }

  /**
   * 后置拍照 若非后置切换镜头
   * 1.切换照模式
   * 2.根据切换按钮是否是前置摄像头判断
   */
  public static async PhotoBack(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'PhotoBack');
    HiLog.i(TAG, 'photo mode');
    let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    if (await driver.findComponent(ON.id(ComponentIdKeys.IS_BACK_CAMERA))) {
      HiLog.i(TAG, 'position is back');
      return;
    }
    HiLog.i(TAG, 'switch camera');
    id = ComponentIdKeys.SWITCH_CAMERA_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'switch to back camera and photo mode');
  }

  /**
   * 普通拍照
   * 1.点击拍照
   * 2.查看缩略图
   * 3.滑动返回
   */
  public static async PhotoCommon(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'PhotoCommon');
    HiLog.i(TAG, 'click to take a photo.');
    let id = ComponentIdKeys.SHUTTER_PHOTO_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'click on the thumbnail.');
    id = ComponentIdKeys.THUMBNAIL_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
    HiLog.i(TAG, 'slide left from screen.');
    await TestUtils.slideLeftFromScreen(driver);
    await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
    HiLog.end(TAG, 'PhotoCommon');
  }

  /**
   * 基础录像
   * 1.开始录像
   * 2.结束录像
   */
  public static async VideoBasic(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'VideoBasic');
    HiLog.i(TAG, 'start recording');
    let id = ComponentIdKeys.SHUTTER_VIDEO_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'end recording');
    id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.end(TAG, 'VideoBasic');
  }

  /**
   * 普通录像
   * 1.点击开始录像
   * 2.点击暂停录像
   * 3.点击继续录像
   * 4.点击暂停录像
   * 5.点击继续录像
   * 6.点击结束录像
   */
  public static async VideoCommon(driver: Driver): Promise<void> {
    HiLog.begin(TAG, 'VideoCommon');
    HiLog.i(TAG, 'start recording');
    let id = ComponentIdKeys.SHUTTER_VIDEO_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'pause recording');
    id = ComponentIdKeys.VIDEO_RECORDING_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'continue recording');
    id = ComponentIdKeys.VIDEO_PAUSE_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'pause recording, second');
    id = ComponentIdKeys.VIDEO_RECORDING_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'continue recording, second');
    id = ComponentIdKeys.VIDEO_PAUSE_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.i(TAG, 'end recording.');
    id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
    await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
    HiLog.end(TAG, 'VideoCommon');
  }
}
