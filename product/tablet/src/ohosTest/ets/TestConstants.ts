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

export class TestConstants {
  // TAG
  static readonly TAG = 'DTTest';
  // 测试用例级别 0
  static readonly TEST_LEVEL_ZERO: number = 0;
  // 测试用例级别 1
  static readonly TEST_LEVEL_ONE: number = 1;
  // 测试用例级别 2
  static readonly TEST_LEVEL_TWO: number = 2;

  // 延迟 50ms
  static readonly DELAY_MIN_TIME: number = 50;
  static readonly DELAY_TWO_HUNDRED_MILLISECOND: number = 200;
  // 延迟 500ms
  static readonly DELAY_500_MS: number = 500;
  // 延迟 1s
  static readonly DELAY_ONE_SECOND: number = 1000;
  // 延迟 2s
  static readonly DELAY_TWO_SECOND: number = 2000;
  // 延迟 3s
  static readonly DELAY_THREE_SECOND: number = 3000;
  // 延迟 4s
  static readonly DELAY_FOUR_SECOND: number = 4000;
  // 延迟 5s
  static readonly DELAY_FIVE_SECOND: number = 5000;
  // 延迟 7s
  static readonly DELAY_SEVEN_SECOND: number = 7000;
  // 延迟 9s
  static readonly DELAY_NINE_SECOND: number = 9000;
  // 延迟 11s
  static readonly DELAY_ELEVEN_SECOND: number = 11000;
  // 延迟 12s
  static readonly DELAY_TWELVE_SECOND: number = 12000;
  // 进入省电模式延迟
  static readonly DELAY_INTO_SAVE_POWER_MODE: number = 61000;
  // 锁屏
  static readonly KEY_UNLOCK: string = 'uinput -T -m 300 2700 280 200';
  // 开关键
  static readonly KEY_POWER: string = 'uinput -K -d 18 -u 18';
  // 截图 音量键+开关键
  static readonly KEY_SNIP: string = 'uinput -K -d 18  -d 17 -u 17 -u 18';
  // 截图
  static readonly SNAPSHOT: string = 'snapshot_display';
  // 拉起应用
  static readonly START_UP: string = 'aa start -a com.ohos.camera.MainAbility -b com.ohos.camera';
  // 杀进程
  static readonly KILL_PID: string = 'pidof com.ohos.camera |xargs kill -9';
  // 拉起Picker测试工具
  static readonly START_UP_PICKER_DEMO: string = 'aa start -a EntryAbility -b com.example.PerfectDemo';
  // 以camerashell指令测试
  static readonly START_UP_CAMERA_SHELL: string = 'hdc shell aa start -a com.ohos.camera.MainAbility -b com.ohos.camera --ps camerashell';
}
