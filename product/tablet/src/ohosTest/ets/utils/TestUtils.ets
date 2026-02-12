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

import { Driver, ON } from '@ohos.UiTest';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { TestConstants } from '../TestConstants';
import { KeyCode } from '@kit.InputKit';

const TAG: string = TestConstants.TAG + '_' + 'TestUtils';
const DELAY_TIME: number = 1000;
// 速率
const SPEED_SLOW = 200;
const SPEED = 1500;
const SPEED_QUICKLY = 5000;
const SPEED_QUICKLY_8K = 8000;

// 百宝箱内向左滑动
const START_RIGHT_X = 1000;
const END_RIGHT_X = 500;
const CONSTANT_RIGHT_Y = 2650;

// 百宝箱内向右滑动
const START_RIGHT_BOX_X = 500;
const END_RIGHT_BOX_X = 1000;
const CONSTANT_RIGHT_BOX_Y = 2650;

// 上滑
const CONSTANT_UP_X = 625;
const START_UP_Y = 1400;
const END_UP_Y = 0;
// 底部上滑
const SWIPE_UP_X = 600;
const SWIPE_START_Y = 2750;
const SWIPE_END_Y = 500;

//左右滑动
const SWIPE_LEFT_RIGHT_Y = 1000;
const SWIPE_LEFT_X = 500;
const SWIPE_RIGHT_X = 1000;

// 测试通用工具类
export class TestUtils {
  /**
   * 判断组件是否存在 并点击
   */
  static async ClickComponentIfExist(driver: Driver, key: string, time: number, isRetry?: boolean): Promise<void> {
    let component = await driver.findComponent(ON.id(key));
    if (component) {
      HiLog.i(TAG, `click the component ${key} success.`);
      await component.click();
      await driver.delayMs(time);
      return;
    }
    if (isRetry) {
      HiLog.e(TAG, `the key ${key} not exist and retry failed.`);
      return;
    }
    await TestUtils.ClickComponentIfExist(driver, key, time, true);
    HiLog.w(TAG, `the key ${key} not exist and retry.`);
    await driver.delayMs(time);
  }

  static async testClickByIdWithCatch(driver: Driver, id: string, time: number): Promise<boolean> {
    try {
      await TestUtils.ClickComponentIfExist(driver, id, time);
      return true;
    } catch (err) {
      HiLog.i(TAG, 'id not find or click error');
      return false;
    }
  }

  static async testDoubleClickById(driver: Driver, id: string, time: number, timeAgain: number): Promise<void> {
    await driver.assertComponentExist(ON.id(id));
    const component = await driver.findComponent(ON.id(id));
    await component.click();
    await driver.delayMs(time);
    await component.click();
    await driver.delayMs(timeAgain);
  }

  /**
   * 适用于不确定是否存在的组件，若存在则对其进行点击操作
   */
  public static async testIsExist(driver: Driver, id: string, time: number = DELAY_TIME): Promise<boolean> {
    if (await driver.findComponent(ON.id(id))) {
      await TestUtils.ClickComponentIfExist(driver, id, time);
      return true;
    } else {
      return false;
    }
  }

  // 长按
  static async testLongClickById(driver: Driver, id: string, time: number): Promise<void> {
    await driver.assertComponentExist(ON.id(id));
    const component = await driver.findComponent(ON.id(id));
    await component.longClick();
    await driver.delayMs(time);
  }

  // 双指捏合放大
  static async testPinchOutById(driver: Driver, id: string, time: number): Promise<void> {
    await driver.assertComponentExist(ON.id(id));
    const component = await driver.findComponent(ON.id(id));
    await component.pinchOut(2);
    await driver.delayMs(time);
  }

  // 双指捏合缩小
  static async testPinchInById(driver: Driver, id: string, time: number): Promise<void> {
    await driver.assertComponentExist(ON.id(id));
    const component = await driver.findComponent(ON.id(id));
    await component.pinchIn(0.5);
    await driver.delayMs(time);
  }

  // 百宝箱内向左滑动
  static async slideTreasureBox(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'swipe right to left');
    return driver.swipe(START_RIGHT_X, CONSTANT_RIGHT_Y, END_RIGHT_X, CONSTANT_RIGHT_Y, SPEED);
  }

  // 百宝箱内向右滑动
  static async slideTreasureBoxRight(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'swipe left to right');
    return driver.swipe(START_RIGHT_BOX_X, CONSTANT_RIGHT_BOX_Y, END_RIGHT_BOX_X, CONSTANT_RIGHT_BOX_Y, SPEED);
  }

  // 从左边屏幕侧滑
  static async slideLeftFromScreen(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide left from screen');
    await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
    await driver.triggerKey(KeyCode.KEYCODE_BACK);
  }

  // 从中下部屏幕上滑
  static async slideUpHalfScreen(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide up');
    return driver.swipe(CONSTANT_UP_X, START_UP_Y, CONSTANT_UP_X, END_UP_Y, SPEED);
  }

  // 从中下部屏幕上滑
  static async slideUpHalfScreenQuick(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide up');
    return driver.swipe(CONSTANT_UP_X, START_UP_Y, CONSTANT_UP_X, END_UP_Y, SPEED_QUICKLY_8K);
  }

  //从中上部屏幕下滑
  static async slideDownHalfScreenQuick(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide down');
    return driver.swipe(CONSTANT_UP_X, END_UP_Y, CONSTANT_UP_X, START_UP_Y, SPEED_QUICKLY_8K);
  }

  // 从底部屏幕上滑
  static async slideUpFromBottom(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide up from screen');
    return driver.swipe(SWIPE_UP_X, SWIPE_START_Y, SWIPE_UP_X, SWIPE_END_Y, SPEED_QUICKLY);
  }

  //预览右滑
  static async slideLeftFromRight(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide right from preview');
    return driver.swipe(SWIPE_RIGHT_X, SWIPE_LEFT_RIGHT_Y, SWIPE_LEFT_X, SWIPE_LEFT_RIGHT_Y, SPEED_QUICKLY);
  }

  //左滑连拍
  static async slideForBurst(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide right burst');
    return driver.swipe(650, 2400, 150, 2400, SPEED_SLOW);
  }

  //预览左滑
  static async slideRightFromLeft(driver: Driver): Promise<void> {
    HiLog.i(TAG, 'slide left from preview');
    return driver.swipe(SWIPE_LEFT_X, SWIPE_LEFT_RIGHT_Y, SWIPE_RIGHT_X, SWIPE_LEFT_RIGHT_Y, SPEED_QUICKLY);
  }

  /**
   * 延时
   * hypium 框架挂掉的时候替代 driver.delayMs
   */
  public static async sleep(duration: number) {
    return new Promise<void>((resolve: Function, reject: Function) => {
      setTimeout((): void => {
        resolve();
      }, duration)
    })
  }
}