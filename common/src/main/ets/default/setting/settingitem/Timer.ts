/*
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

export default class Timer {
  private static TAG = '[Timer]:'
  public static readonly ALIAS = 'Timer'
  public static readonly TIMER_OFF = 'off'
  public static readonly TIMER_TWO_SECONDS = '2'
  public static readonly TIMER_FIVE_SECONDS = '5'
  public static readonly TIMER_TEN_SECONDS = '10'
  public static readonly DEFAULT_VALUE = $r('app.string.off')
  public static readonly RESOURCE_OFF = Timer.DEFAULT_VALUE
  public static readonly RESOURCE_TWO_SECONDS = $r('app.string.timer_2_seconds')
  public static readonly RESOURCE_FIVE_SECONDS = $r('app.string.timer_5_seconds')
  public static readonly RESOURCE_TEN_SECONDS = $r('app.string.timer_10_seconds')
  public static readonly RESOURCE_OFF_ALREADY = $r('app.string.already_off')

  public static convertToResource(timer: string): Resource {
    switch (timer) {
    case Timer.TIMER_OFF:
      return Timer.RESOURCE_OFF
    case Timer.TIMER_TWO_SECONDS:
      return Timer.RESOURCE_TWO_SECONDS
    case Timer.TIMER_FIVE_SECONDS:
      return Timer.RESOURCE_FIVE_SECONDS
    case Timer.TIMER_TEN_SECONDS:
      return Timer.RESOURCE_TEN_SECONDS
    default:
      return Timer.RESOURCE_OFF
    }
  }

  public static convertToString(res: Resource): string {
    if (res.id === Timer.RESOURCE_OFF.id) {
      return Timer.TIMER_OFF
    } else if(res.id === Timer.RESOURCE_TWO_SECONDS.id) {
      return Timer.TIMER_TWO_SECONDS
    } else if(res.id === Timer.RESOURCE_FIVE_SECONDS.id) {
      return Timer.TIMER_FIVE_SECONDS
    } else if(res.id === Timer.RESOURCE_TEN_SECONDS.id) {
      return Timer.TIMER_TEN_SECONDS
    }
  }
}