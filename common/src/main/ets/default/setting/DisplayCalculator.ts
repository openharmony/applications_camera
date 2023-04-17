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

import { Log } from '../utils/Log'
import deviceInfo from '@ohos.deviceInfo';

export default class DisplayCalculator {
  private static TAG = '[DisplayCalculator]:'

  public static calcSurfaceDisplaySize(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number) {
    const displaySize = {
      width: 1920, height: 1080
    }
    const ratio = previewWidth / previewHeight
    if (deviceInfo.deviceType == 'tablet' || screenWidth > screenHeight) {
      if (screenWidth / screenHeight > ratio) {
        displaySize.width = Math.floor(screenHeight * ratio)
        displaySize.height = Math.floor(screenHeight)
      } else {
        displaySize.width = Math.floor(screenWidth)
        displaySize.height = Math.floor(screenWidth / ratio)
      }
    } else {
      if (screenWidth / screenHeight > ratio) {
        displaySize.width = Math.floor(screenHeight / ratio)
        displaySize.height = Math.floor(screenHeight)
      } else {
        displaySize.width = Math.floor(screenWidth)
        displaySize.height = Math.floor(screenWidth * ratio)
      }
    }
    Log.info(`${this.TAG} calcSurfaceDisplaySize screenWidth=${screenWidth} screenHeight=${screenHeight} `)
    Log.info(`${this.TAG} calcSurfaceDisplaySize previewWidth=${previewWidth} previewHeight=${previewHeight} displaySize= ${JSON.stringify(displaySize)}`)
    return displaySize
  }
}