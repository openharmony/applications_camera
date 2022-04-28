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

import { CLog } from '../Utils/CLog'

export default class DisplayUtil {
  private static TAG: string = '[DisplayUtil]:'
  /**
   prepare to replace the real method
   */
  private static getDisplaySize(){
    let displaySize = {
      width: 1920, height: 1080
    }
    return displaySize
  }

  public static calcSurfaceDisplaySize(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number) {
    let displaySize = getDisplaySize()
    if(previewWidth == 0 || previewHeight == 0){
      CLog.error(`${this.TAG} previewWidth or previewHeight is 0 `)
      return displaySize
    }
    let ratio = previewWidth / previewHeight
    if (screenWidth > screenHeight) {
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
    CLog.info(`${this.TAG} calcSurfaceDisplaySize screenWidth=${screenWidth} screenHeight=${screenHeight} `)
    CLog.info(`${this.TAG} calcSurfaceDisplaySize previewWidth=${previewWidth} previewHeight=${previewHeight} displaySize= ${JSON.stringify(displaySize)}`)
    CLog.info(`${this.TAG} calcSurfaceDisplaySize displaySize= ${JSON.stringify(displaySize)}`)
    return displaySize
  }
}