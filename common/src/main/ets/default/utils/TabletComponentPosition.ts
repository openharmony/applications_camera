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

import DisplayCalculator from '../setting/DisplayCalculator';
import { Log } from './Log';

export default class TabletComponentPosition {
  private static TAG: string = '[ComponentPosition]:'
  private static shutterButtonWidth: number = 76
  private static shutterButtonWidthVideo: number = 56
  private static footBarComponentWidth: number = 98
  private static footBarInPreviewMaxMargin: number = 98
  private static zoomViewComponentWidth: number = 82
  private static zoomViewToPreview: number = 75
  private static zoomViewWidthVideo: number = 60
  private static zoomViewRightDistance: number = 4

  public static previewPosition(screenWidth: number, screenHeight: number, previewWidth: number, previewHeight: number) {
    Log.info(`${this.TAG} previewPosition ` + previewHeight + previewWidth)
    if ((screenHeight == previewHeight &&  previewWidth > previewHeight)) {
      return {x: 0, y: 0}
    }
    let position = (Math.abs(screenWidth - previewWidth)  < 1) ? { x: 0, y: (screenHeight - previewHeight) / 2}
                                                       : { x: (screenWidth - previewWidth) / 2, y: 0 }
    return position
  }

}