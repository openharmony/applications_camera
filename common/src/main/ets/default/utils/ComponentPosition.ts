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

import DisplayCalculator from '../setting/DisplayCalculator';
import { Log } from './Log';

export class ComponentPosition {
  private static TAG: string = '[ComponentPosition]:'
  private static shutterButtonWidth: number = 76
  private static shutterButtonWidthVideo: number = 56
  private static footBarComponentWidth: number = 98
  private static footBarInPreviewMaxMargin: number = 98
  private static tarBarHeight: number = 360
  private static tarBarWidth: number = 48
  private static tabBarInPreviewMaxMargin: number = 48
  private static tabBarLeftDistance: number = 10
  private static tabBarBottomDistance: number = 40
  private static zoomViewComponentWidth: number = 82
  private static zoomViewToPreview: number = 75
  private static zoomViewWidthVideo: number = 60
  private static zoomViewRightDistance: number = 4
  private static foldControlHeight: number = 650
  private static controlItemHeight: number = 32

  public static previewPosition(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number) {
    Log.info(`${this.TAG} previewPosition `)
    let position = (Math.abs(screenWidth - previewWidth)  < 1) ? { x: 0, y: (screenHeight - previewHeight) / 2}
                                                       : { x: (screenWidth - previewWidth) / 2, y: 0 }
    return position
  }

  public static previewTabletPosition(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number) {
    Log.info(`${this.TAG} previewTabletPosition ` + previewHeight + previewWidth)
    if ((screenHeight == previewHeight &&  previewWidth > previewHeight)) {
      return {x: 0, y: 0}
    }
    let position = (Math.abs(screenWidth - previewWidth)  < 1) ? { x: 0, y: (screenHeight - previewHeight) / 2}
                                                               : { x: (screenWidth - previewWidth) / 2, y: 0 }
    return position
  }

  public static footBarPosition(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number) {
    Log.info(`${this.TAG} footBarPosition `)
    if (screenWidth == previewWidth && (3 * previewWidth > 4 * previewHeight)) {
      let previewSize = DisplayCalculator.calcSurfaceDisplaySize(screenWidth, screenHeight, 4, 3)
      previewWidth = previewSize.width
      previewHeight = previewSize.height
    }
    let position = screenWidth <= previewWidth + this.footBarInPreviewMaxMargin * 2 ?
      { x: (screenWidth / 2 + previewWidth / 2 - this.footBarComponentWidth), y: 0 } :
      { x: (screenWidth * 3 / 4 + previewWidth / 4 - this.footBarComponentWidth / 2), y: 0}
    return position
  }

  public static tabBarPosition(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number) {
    Log.info(`${this.TAG} tabBarPosition `)
    if (screenWidth == previewWidth && (3 * previewWidth > 4 * previewHeight)) {
      let previewSize = DisplayCalculator.calcSurfaceDisplaySize(screenWidth, screenHeight, 4, 3)
      previewWidth = previewSize.width
      previewHeight = previewSize.height
    }
    let xPosition: number = (screenWidth == previewWidth) ? this.tabBarLeftDistance :
      ((screenWidth >= previewWidth + this.tabBarInPreviewMaxMargin * 2) ?
      ((screenWidth - previewWidth) / 4) - this.tarBarWidth / 2  :
      ((screenWidth - previewWidth) / 2) + this.tabBarLeftDistance)
    let yPosition: number = (screenWidth * 9 <= screenHeight * 16) ?
      (screenHeight / 2 + screenWidth * 9 / 32 - this.tarBarHeight) :
      (screenHeight - this.tarBarHeight - this.tabBarBottomDistance)
    let position = { x: xPosition, y: 44}
    return position
  }

  public static zoomViewPosition(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number,
                                 videoState: string) {
    Log.info(`${this.TAG} zoomViewPosition `)
    let zoomViewWidth: number
    let shutterButtonWidth: number
    if (screenWidth == previewWidth && (3 * previewWidth > 4 * previewHeight)) {
      let previewSize = DisplayCalculator.calcSurfaceDisplaySize(screenWidth, screenHeight, 4, 3)
      previewWidth = previewSize.width
      previewHeight = previewSize.height
    }
    if (videoState === "beforeTakeVideo") {
      zoomViewWidth = this.zoomViewComponentWidth
      shutterButtonWidth = this.shutterButtonWidth
    } else {
      zoomViewWidth = this.zoomViewWidthVideo
      shutterButtonWidth = this.shutterButtonWidthVideo
    }
    let xPosition: number = 0;
    if (screenWidth < previewWidth + this.footBarInPreviewMaxMargin * 2) {
      xPosition = (screenWidth / 2 + previewWidth / 2 - ((this.footBarComponentWidth + this.zoomViewComponentWidth
      + zoomViewWidth + shutterButtonWidth) / 2 + this.zoomViewRightDistance))
    } else if (screenWidth < previewWidth + zoomViewWidth * 4 + shutterButtonWidth * 2) {
      xPosition = screenWidth / 2 + previewWidth / 2 - this.zoomViewToPreview
    } else {
      xPosition = screenWidth * 5 / 8 + previewWidth * 3 / 8 - shutterButtonWidth / 4 - this.zoomViewComponentWidth / 2
    }
    let position = { x: xPosition, y: 0 }
    return position
  }

  public static getControlHeight(width: number, height: number) {
    let position = this.isUnfoldControl(width, height) ? this.controlItemHeight * 5 : this.controlItemHeight * 3
    return position
  }

  public static isUnfoldControl(width: number, height: number) {
    Log.info(`${this.TAG} isUnfoldControl `)
    let previewSize = DisplayCalculator.calcSurfaceDisplaySize(width, height, 4, 3)
    return (previewSize.height > this.foldControlHeight)
  }

  public static getShutterButtonMargin(screenWidth: number, screenHeight: number, previewHeight: number) {
    Log.info(`${this.TAG} getShutterButtonMargin `)
    if (previewHeight < 400) {
      return 24
    }
    let previewSize = DisplayCalculator.calcSurfaceDisplaySize(screenWidth, screenHeight, 4, 3)
    let x = previewSize.height * 3 / 100 + 24
    return x
  }

  public static getFootBarHeight(screenWidth: number, screenHeight: number, previewHeight: number) {
    let x =  this.getShutterButtonMargin(screenWidth, screenHeight, previewHeight) * 2 + 164
    return x
  }

  public static getFootBarMargin(screenWidth: number, screenHeight: number, previewHeight: number) {
    Log.info(`${this.TAG} getFootBarMargin `)
    if (previewHeight < 400) {
      return 0
    }
    let previewSize = DisplayCalculator.calcSurfaceDisplaySize(screenWidth, screenHeight, 4, 3)
    let x =  previewSize.height * 12 / 100 - 48
    return x
  }

  public static getFootBarPosition(previewHeight: number) {
    return (previewHeight < 400) ? { x: 0, y: -30 } : { x: 0, y: 0 }
  }

  public static getControlPosition(previewHeight: number) {
    return (previewHeight < 400) ? { x: 0, y: -40 } : { x: 0, y: 0 }
  }
}