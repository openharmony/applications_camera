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
import lazy { componentUtils, display, FrameNode, Position, Size, UIContext } from '@kit.ArkUI';
import lazy { getStates } from '../redux';
import { DisplayService } from '../service/UIAdaptive/DisplayService';
import lazy { HiLog } from './HiLog';
import { simpleStringify } from './SimpleStringify';
import { SystemLanguageUtil } from './SystemLanguageUtil';
import lazy { WindowDirection } from './WindowDirection';

const TAG = 'ComponentAttrUtils';

export class ComponentAttrUtils {
  private static frameNode: FrameNode;

  /**
   * 根据组件的id获取组件的位置信息
   * @returns
   */
  public static getRectInfoByIdWithTransform(context: UIContext, id: string): RectInfoInPx {
    /* instrument ignore if */
    if (!context || !id || !context.getAttachedFrameNodeById(id)) {
      HiLog.e(TAG, 'context or id doesnt exist.');
      return {
        positionX: 0,
        positionY: 0,
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        width: 0,
        height: 0
      };
    }
    try {
      ComponentAttrUtils.frameNode = context.getAttachedFrameNodeById(id);
      let size: Size = ComponentAttrUtils.frameNode.getMeasuredSize();
      let position: Position = ComponentAttrUtils.frameNode.getPositionToWindowWithTransform();
      let nodeId = context.getAttachedFrameNodeById(id)?.getUniqueId();
      let rstRect: RectInfoInPx = new RectInfoInPx();
      let mDirection = this.convertDirection();
      switch (mDirection) {
        case WindowDirection.RIGHT:
          rstRect.left = position.x - px2vp(size.width);
          rstRect.top = position.y;
          rstRect.right = position.x;
          rstRect.bottom = position.y + px2vp(size.height);
          rstRect.width = px2vp(size.width);
          rstRect.height = px2vp(size.height);
          rstRect.positionX = position.x - px2vp(size.width) / 2;
          rstRect.positionY = position.y + px2vp(size.height) / 2;
          break;
        case WindowDirection.LEFT:
          rstRect.left = position.x;
          rstRect.top = position.y - px2vp(size.height);
          rstRect.right = position.x + px2vp(size.width);
          rstRect.bottom = position.y;
          rstRect.width = px2vp(size.width);
          rstRect.height = px2vp(size.height);
          rstRect.positionX = position.x - px2vp(size.width) / 2;
          rstRect.positionY = position.y + px2vp(size.height) / 2;
          break;
        case WindowDirection.BOTTOM:
          rstRect.left = position.x - px2vp(size.width);
          rstRect.top = position.y - px2vp(size.height);
          rstRect.right = position.x;
          rstRect.bottom = position.y;
          rstRect.width = px2vp(size.width);
          rstRect.height = px2vp(size.height);
          rstRect.positionX = position.x - px2vp(size.width) / 2;
          rstRect.positionY = position.y - px2vp(size.height) / 2;
          break;
        case WindowDirection.TOP:
        default:
          rstRect.left = position.x;
          rstRect.top = position.y;
          rstRect.right = position.x + px2vp(size.width);
          rstRect.bottom = position.y + px2vp(size.height);
          rstRect.width = px2vp(size.width);
          rstRect.height = px2vp(size.height);
          rstRect.positionX = position.x + px2vp(size.width) / 2;
          rstRect.positionY = position.y + px2vp(size.height) / 2;
      }
      if (SystemLanguageUtil.isRTL()) {
        this.convertPositionRTL(rstRect);
      }
      HiLog.i(TAG, `getRectInfoByIdWithTransform: ${rstRect.toString()}, ${vp2px(1)}, ${nodeId}`);
      return rstRect;
    } catch (error) {
      HiLog.e(TAG, `getRectInfoByIdWithTransform error: ${simpleStringify(error)}`);
      return {
        positionX: 0,
        positionY: 0,
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        width: 0,
        height: 0
      };
    }
  }

  private static convertPositionRTL(rstRect: RectInfoInPx): void {
    const screenWidth = getStates().get<number>('windowReducer', 'windowWidth');
    rstRect.positionX = screenWidth - rstRect.positionX;
    let tmpLeft = rstRect.left;
    let tmpRight = rstRect.right;
    rstRect.left = screenWidth - tmpRight;
    rstRect.right = screenWidth - tmpLeft;
    HiLog.i(TAG, `convertPositionRTL: ${rstRect.toString()}`);
  }

  private static convertDirectionLandscapeInverted(mDirection: number): number {
    if (mDirection === WindowDirection.RIGHT) {
      return WindowDirection.TOP;
    } else if (mDirection === WindowDirection.TOP) {
      return WindowDirection.LEFT;
    } else if (mDirection === WindowDirection.BOTTOM) {
      return WindowDirection.RIGHT;
    } else {
      return WindowDirection.BOTTOM;
    }
  }

  private static convertDirectionLandscape(mDirection: number): number {
    if (mDirection === WindowDirection.RIGHT) {
      return WindowDirection.BOTTOM;
    } else if (mDirection === WindowDirection.TOP) {
      return WindowDirection.RIGHT;
    } else if (mDirection === WindowDirection.BOTTOM) {
      return WindowDirection.LEFT;
    } else {
      return WindowDirection.TOP;
    }
  }

  private static convertDirectionPortraitInverted(mDirection: number): number {
    if (mDirection === WindowDirection.RIGHT) {
      return WindowDirection.LEFT;
    } else if (mDirection === WindowDirection.TOP) {
      return WindowDirection.BOTTOM;
    } else if (mDirection === WindowDirection.BOTTOM) {
      return WindowDirection.TOP;
    } else {
      return WindowDirection.RIGHT;
    }
  }

  private static convertDirectionPortrait(mDirection: number): number {
    if (mDirection === WindowDirection.RIGHT) {
      return WindowDirection.RIGHT;
    } else if (mDirection === WindowDirection.TOP) {
      return WindowDirection.TOP;
    } else if (mDirection === WindowDirection.BOTTOM) {
      return WindowDirection.BOTTOM;
    } else {
      return WindowDirection.LEFT;
    }
  }

  private static convertDirection(): number {
    let mDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
    return mDirection;
  }

  /**
   * 根据组件的id获取组件的位置信息
   * @returns
   */
  public static getRectInfoById(context: UIContext, id: string): RectInfoInPx {
    /* instrument ignore if */
    if (!context || !id) {
      HiLog.e(TAG, 'context or id doesnt exist.');
      return {
        positionX: 0,
        positionY: 0,
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        width: 0,
        height: 0
      };
    }

    try {
      let componentInfo: componentUtils.ComponentInfo = context.getComponentUtils().getRectangleById(id);

      /* instrument ignore if */
      if (!componentInfo) {
        HiLog.e(TAG, 'componentInfo doesnt exist, return default Info.');
        return {
          positionX: 0,
          positionY: 0,
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          width: 0,
          height: 0
        };
      }

      let rstRect: RectInfoInPx = new RectInfoInPx();
      const widthScaleGap = componentInfo.size.width * (1 - componentInfo.scale.x) / 2;
      const heightScaleGap = componentInfo.size.height * (1 - componentInfo.scale.y) / 2;
      rstRect.left = componentInfo.translate.x + componentInfo.windowOffset.x + widthScaleGap;
      rstRect.top = componentInfo.translate.y + componentInfo.windowOffset.y + heightScaleGap;
      rstRect.right =
        componentInfo.translate.x + componentInfo.windowOffset.x + componentInfo.size.width - widthScaleGap;
      rstRect.bottom =
        componentInfo.translate.y + componentInfo.windowOffset.y + componentInfo.size.height - heightScaleGap;
      rstRect.width = rstRect.right - rstRect.left;
      rstRect.height = rstRect.bottom - rstRect.top;
      rstRect.positionX = Math.abs(rstRect.right + rstRect.left) / 2
      rstRect.positionY = Math.abs(rstRect.bottom + rstRect.top) / 2
      HiLog.i(TAG, `getRectInfoById: ${rstRect.toString()}`);
      return {
        positionX: rstRect.positionX,
        positionY: rstRect.positionY,
        left: rstRect.left,
        right: rstRect.right,
        top: rstRect.top,
        bottom: rstRect.bottom,
        width: rstRect.width,
        height: rstRect.height
      }
    } catch (error) {
      HiLog.e(TAG, `getRectInfoById error: ${simpleStringify(error)}`);
      return {
        positionX: 0,
        positionY: 0,
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        width: 0,
        height: 0
      };
    }
  }
}

export class RectInfoInPx {
  positionX: number = 0;
  positionY: number = 0;
  left: number = 0;
  top: number = 0;
  right: number = 0;
  bottom: number = 0;
  width: number = 0;
  height: number = 0;

  public toString(): string {
    return `positionX: ${this.positionX}, positionY: ${this.positionY}, left: ${this.left}, right: ${this.right},
     top: ${this.top}, bottom: ${this.bottom}, width: ${this.width}, heght: ${this.height}`;
  }
}

export class RectJson {
  $rect: Array<number> = [];
}