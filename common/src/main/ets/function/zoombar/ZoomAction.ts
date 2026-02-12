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
import type { ActionData } from '../../redux/actions/Action';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';

export class ZoomAction {

  public static initZoomRatio(min: number, max: number): ActionData {
    return {
      type: ZoomActionType.ACTION_INIT_ZOOM_RATIO,
      data: { minZoomRatio: min, maxZoomRatio: max }
    };
  }

  public static updateStateZoomRatio(zoomRatio: number): ActionData {
    if (zoomRatio) {
      return {
        isEvent: true,
        type: ZoomActionType.ACTION_CHANGE_ZOOM_RATIO,
        data: { zoomRatio: zoomRatio }
      };
    }
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_CHANGE_ZOOM_RATIO,
      data: { zoomRatio: 1 }
    };
  }

  /* instrument ignore next */
  public static updateShowZoomViewFlag(isShowZoomView: boolean): ActionData {
    return {
      type: ZoomActionType.ACTION_UPDATE_SHOW_ZOOM_VIEW_FLAG,
      data: { isShowZoomView: isShowZoomView }
    };
  }

  /* instrument ignore next */
  public static updateShowZoomTextFlag(isShowZoomText: boolean): ActionData {
    return {
      type: ZoomActionType.ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG,
      data: { isShowZoomText: isShowZoomText }
    };
  }

  /* instrument ignore next */
  public static updateZoomBigTextVisible(isShowZoomBigText: boolean): ActionData {
    return {
      type: ZoomActionType.ACTION_UPDATE_ZOOM_BIG_TEXT_VISIBLE,
      data: { isShowZoomBigText: isShowZoomBigText }
    };
  }

  /* instrument ignore next */
  public static updatePhotoZoomDetailsFlag(isPhotoZoomDetails: boolean): ActionData {
    return {
      type: ZoomActionType.ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG,
      data: { isPhotoZoomDetails: isPhotoZoomDetails }
    };
  }

  /* instrument ignore next */
  public static updateBaseZoom(baseZoom: number): ActionData {
    return {
      type: ZoomActionType.ACTION_UPDATE_BASE_ZOOM,
      data: { baseZoom: baseZoom }
    };
  }

  public static updateShowPinch(isShowPinch: boolean): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_UPDATE_SHOW_PINCH,
      data: { isShowPinch: isShowPinch }
    };
  }

  public static zoomSlide2QuickZoom(zoomValue: number): ActionData { // 通知环形变焦条滑动至快捷变焦点刻度
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_ZOOM_SLIDE_QUICK_ZOOM,
      data: { zoomValue: zoomValue }
    };
  }

  public static changeZoomState(zoomState: string): ActionData { // 通知Zoom三种状态之间的切换
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_CHANGE_ZOOM_STATE,
      data: { zoomState: zoomState }
    };
  }

  public static resetZoomRatio(): ActionData { // zoom恢复默认值,回复默认显示状态
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_RESET_ZOOM_RATIO,
      data: { zoomRatio: 1 }
    };
  }

  public static switchZoomRatio(toNext: boolean): ActionData { // 前置变焦时，切换至下一个可选变焦点 toNext为false 为切换上一个
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_SWITCH_ZOOM_RATIO,
      data: { toNext: toNext }
    };
  }

  /* instrument ignore next */
  public static smartControlZoomRatio(toNext: boolean): ActionData { // 智拍键滑动变焦
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_SMART_CONTROL_ZOOM_RATIO,
      data: { toNext: toNext }
    };
  }

  public static onClickZoomSmoothAnimDuration(duration: number): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_ON_CLICK_ZOOM_SMOOTH_ANIM_DURATION,
      data: { duration: duration }
    };
  }

  public static updateZoomBuilderOffsetY(offsetY: number): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.UPDATE_ZOOM_BUILDER_OFFSETY,
      data: { offsetY: offsetY }
    };
  }

  /* instrument ignore next */
  public static onLemDoubleClick(index: number): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_LEM_DOUBLE_CLICK,
      data: { index: index }
    };
  }

  /* instrument ignore next */
  public static changedZoomByGesture(): ActionData {
    return {
      type: ZoomActionType.ACTION_CHANGED_ZOOM_BY_GESTURE,
      data: {}
    };
  }

  // 单向传递给变焦组件，其他组件请勿监听 传递参数是切换到0.8 不传时切换到w
  /* instrument ignore next */
  public static switchZoomToWideAngle(zoomRatio?: number): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_CHANGE_ZOOM_TO_WIDE_ANGLE,
      data: { zoomRatio: zoomRatio }
    };
  }

  // 单向传递给变焦组件，其他组件请勿监听
  /* instrument ignore next */
  public static switchZoomToDefault(): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_CHANGE_ZOOM_TO_DEFAULT,
      data: {}
    };
  }

  /* instrument ignore next */
  public static showColorfulZoomRing(isShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.SHOW_COLORFUL_ZOOM_RING,
      data: { isShow: isShow }
    };
  }

  /* instrument ignore next */
  public static handleAutoCloseFlash(isAutoCloseFlash: boolean): ActionData {
    return {
      isEvent: true,
      type: ZoomActionType.ACTION_AUTO_CLOSE_FLASH,
      data: { isAutoCloseFlash: isAutoCloseFlash }
    };
  }
}