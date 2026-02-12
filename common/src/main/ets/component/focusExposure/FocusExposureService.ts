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

import camera from '@ohos.multimedia.camera';
import lazy { componentUtils, display } from '@kit.ArkUI';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FocusExposureAction } from './FocusExposureAction';
import lazy { MULTIPLE_OUTPUTS_MODES } from '../../function/outputswitcher/OutputSwitcher';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { getStates, reduxSubscribe, OhCombinedState, Dispatch, Unsubscribe } from '../../redux';
import lazy {
  AdaptiveLayoutService,
  TAB_BAR_HEIGHT,
  ZOOM_VIEW_HEIGHT,
  VDE_ZOOM_VIEW_HEIGHT,
  MODE_BAR_HEIGHT,
  FOOT_BAR_HEIGHT
} from '../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { SettingFuncDialogItemIndex } from '../settingview/SettingFuncDialogItemIndex';
import lazy { FocusExposureAreaDispatcher } from './FocusExposureAreaDispatcher';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { FocusData, ExposureData, RangeInfo } from '../../component/focusExposure/FocusExposureHelper';
import lazy {
  FocusConfig,
  ModeFocusConfig,
  CANVAS_WIDTH,
  CANVAS_HEIGHT,
  FOCUS_SIZE,
  EXPOSURE_RING_LENGTH_20,
  EventOffsetInfos,
  Event,
  Ranges,
  EventEffectiveInfo,
  FOCUS_EXPOSURE_GAP,
  PositionType,
  TipInfo,
  SUPER_ISO_THRESHOLD_VALUE,
  VLOG_FOCUS_DATA_LENGTH
} from './FocusExposureHelper';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { DurationType } from '../tip/TipService';
import lazy { ConflictParam } from '../../function/core/ConflictParam';
import lazy { ValueSet } from '../../function/core/ValueSet';
import lazy { ConflictManager } from '../../function/core/ConflictManager';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';

const TAG: string = 'FocusExposureService';

export class FocusExposureService {
  public static instance: FocusExposureService;
  private mAction: FocusExposureAreaDispatcher = new FocusExposureAreaDispatcher();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mode: ModeType = ModeType.NONE;
  private isHalfCollapsLEM: boolean = false;
  private isVdeLandscape: boolean = true;

  constructor() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  public static getInstance(): FocusExposureService {
    if (!FocusExposureService.instance) {
      FocusExposureService.instance = new FocusExposureService();
    }

    return FocusExposureService.instance;
  }

  /* instrument ignore next */
  public getExposureOffset(rotateAngle: number, event?: EventOffsetInfos): number {
    let exposureOffset: number | undefined = 0;
    const angle: number = (rotateAngle + 360) % 360;
    switch (angle) {
      case 0:
        exposureOffset = event?.offsetY;
        break;
      case 90:
        exposureOffset = event ? -event.offsetX : 0;
        break;
      case 180:
        exposureOffset = event ? -event.offsetY : 0;
        break;
      case 270:
        exposureOffset = event?.offsetX;
        break;
      default:
        exposureOffset = event?.offsetY;
        break;
    }
    HiLog.i(TAG, `getExposureOffset exposureOffset: ${exposureOffset}, angle: ${angle}.`);
    return exposureOffset ?? 0;
  }

  // 获取预览尺寸
  private getPreviewSize(): PositionType {
    let previewSize: PositionType = {
      x: getStates().get('previewReducer', 'xComponentWidth'),
      y: getStates().get('previewReducer', 'xComponentHeight')
    };
    return previewSize;
  }

  private getLocalX(event: Event): number {
    let localX: number = 0;
    if (event.fingerList) {
      localX = event.fingerList[0]?.globalX || event.fingerList[0]?.windowX || 0;
    } else if (event.changedTouches) {
      localX = event.changedTouches[0]?.globalX || event.changedTouches[0]?.windowX || 0;
    }

    HiLog.i(TAG, `getLocalX event: ${JSON.stringify(event)}.`);
    return localX;
  }

  private getLocalY(event: Event): number {
    let localY: number = 0;
    if (event.fingerList) {
      localY = event.fingerList[0]?.globalY || event.fingerList[0]?.windowY || 0;
    } else if (event.changedTouches) {
      localY = event.changedTouches[0]?.globalY || event.changedTouches[0]?.windowY || 0;
    }
    HiLog.i(TAG, `getLocalY event: ${JSON.stringify(event)}.`);
    return localY;
  }

  // 获取事件坐标
  private getCoordinates(event: Event): PositionType {
    const localX = this.getLocalX(event);
    const localY = this.getLocalY(event);
    const coordinates = { x: localX, y: localY };
    return coordinates;
  }

  // =============================================== 元素位置 =======================================================
  // 根据手指位置计算元素位置
  /* instrument ignore next */
  private getPosition(local: number, componentSize: number, isFocusPosition = true): number {
    let offset = EXPOSURE_RING_LENGTH_20;
    if (isFocusPosition) {
      offset = FocusExposureAction.FOCUS_POSITION_40;
    }
    let position = local - offset;
    if (local < offset) {
      position = 0;
    } else if (local + offset > componentSize) {
      position = componentSize - offset * 2;
    }
    return position;
  }

  // 计算元素位置 -- 输出坐标
  /* instrument ignore next */
  private calcElementPosition(coordinates: PositionType, isFocusPosition: boolean): PositionType {
    const previewSize: PositionType = this.getPreviewSize();
    const position: PositionType = { x: coordinates.x, y: coordinates.y };
    position.x = this.getPosition(coordinates.x, previewSize.x, isFocusPosition);
    position.y = this.getPosition(coordinates.y, previewSize.y, isFocusPosition);
    HiLog.i(TAG, `calcElementPosition postion x: ${position.x}, y: ${position.y}.`);
    return position;
  }


  // 通过事件计算当前元素位置
  /* instrument ignore next */
  public calcElementPositionByEvent(event: Event, isFocusPosition: boolean): PositionType {
    let postion: PositionType = this.getCoordinates(event);
    if (!postion.x || !postion.y) {
      HiLog.i(TAG, `calcElementPositionByEvent localX: ${postion.x}, localY: ${postion.y}.`);
      return postion;
    }
    postion = this.calcElementPosition(postion, isFocusPosition);

    return postion;
  }

  // =============================================== 模式、位置下发 =======================================================
  // 坐标位置转换
  /* instrument ignore next */
  private handlePositionTransfer(coordinates: PositionType): PositionType {
    const dis: display.Display = DisplayService.getInstance().getDisplay();
    HiLog.i(TAG, `handlePositionTransfer orientation: ${dis.orientation}.`);
    let pointData: PositionType = coordinates;
    switch (dis.orientation) {
      case display.Orientation.PORTRAIT: // 上
        pointData = {
          x: coordinates.y,
          y: 1 - coordinates.x,
        };
        break;
      case display.Orientation.LANDSCAPE: //
        pointData = {
          x: 1 - coordinates.x,
          y: 1 - coordinates.y,
        };
        break;
      case display.Orientation.PORTRAIT_INVERTED: //下
        pointData = {
          x: 1 - coordinates.y,
          y: coordinates.x,
        };
        break;
      case display.Orientation.LANDSCAPE_INVERTED: // 右
      default:
    }
    return pointData;
  }

  /* instrument ignore next */
  private handlePositionTransferTriCollapsFullExpanded(coordinates: PositionType): PositionType {
    const dis: display.Display = DisplayService.getInstance().getDisplay();
    HiLog.i(TAG, `TriCollapsFullExpanded orientation: ${dis.orientation}, isLockOrientation: isLockOrientation.`);
    let pointData: PositionType = coordinates;
    switch (dis.orientation) {
      case display.Orientation.PORTRAIT: // 左
        pointData = {
          x: 1 - coordinates.x,
          y: 1 - coordinates.y,
        };
        break;
      case display.Orientation.LANDSCAPE: // 上
        pointData = {
          x: 1 - coordinates.y,
          y: coordinates.x,
        };
        break;
      case display.Orientation.PORTRAIT_INVERTED: // 右
        break;
      case display.Orientation.LANDSCAPE_INVERTED: // 下
        pointData = {
          x: coordinates.y,
          y: 1 - coordinates.x,
        };
      default:
    }
    return pointData;
  }

  // 获取到位置 用于下发对焦/测光分离 位置
  private getPositionPoint(position: PositionType, isFocusPosition: boolean, hasFocusBoxed = true): PositionType {
    const previewAreaSize = this.getPreviewSize();
    const previewAreaSizeX = previewAreaSize.x;
    const previewAreaSizeY = previewAreaSize.y;
    if (previewAreaSizeX === 0 || previewAreaSizeY === 0) {
      return { x: 0, y: 0, };
    }

    const point: PositionType = hasFocusBoxed ? {
      x: position.x + (isFocusPosition ? FocusExposureAction.FOCUS_POSITION_40 : EXPOSURE_RING_LENGTH_20),
      y: position.y + (isFocusPosition ? FocusExposureAction.FOCUS_POSITION_40 : EXPOSURE_RING_LENGTH_20)
    } : { x: position.x, y: position.y };

    HiLog.i(TAG, `getPositionPoint previewAreaSizeX: ${previewAreaSizeX}, previewAreaSizeY: ${previewAreaSizeY}.`);
    const pointData: PositionType = this.handlePositionTransfer({
      x: point.x / previewAreaSizeX,
      y: point.y / previewAreaSizeY
    });
    HiLog.i(TAG, `getPositionPoint pointData: ${pointData.x}, localY: ${pointData.y}.`);
    return pointData;
  }

  // 下发对焦信息
  public setFocusValue(focusData: FocusData, hasFocusBoxed = true): void {
    HiLog.i(TAG, 'setFocusValue E');
    let focusPoint: PositionType = focusData.focusPoint;
    if (focusData.focusPoint && focusData.focusPoint.x !== undefined) {
      focusPoint = this.getPositionPoint(focusData.focusPoint, true, hasFocusBoxed);
    }
    this.mAction.changeFunctionValue(FunctionId.FOCUS, {
      ...focusData,
      focusPoint: focusPoint,
    });
  }

  // 下发曝光信息
  public setExposureValue(exposure: Partial<ExposureData>, isFocusPosition = false): void {
    HiLog.i(TAG, 'setExposureValue E');
    let exposurePoint: PositionType = exposure.exposurePoint;
    if (exposure.exposurePoint) { // 测光移动
      exposurePoint = this.getPositionPoint(exposure.exposurePoint, isFocusPosition);
    }
    const value: number = exposure.exposureValue ?? 0; // 后续考虑移除
    this.mAction.changeFunctionValue(FunctionId.EXPOSURE, {
      ...exposure,
      exposurePoint: exposurePoint,
      exposureValue: value,
    })
    HiLog.i(TAG, `setExposureValue mode: ${exposure.exposureMode}`);
  }

  // =============================================== 拖动 =======================================================
  // 获取 变焦条下边沿位置
  private getRouletteZoomPosition(): number {
    let rouletteZoomPosition = AdaptiveLayoutService.getInstance().rouletteZoomPosition;
    if (this.isVdeLandscape) {
      const aspectRatio = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue();
      if (aspectRatio !== SettingFuncDialogItemIndex.INDEX_SEC) {
        rouletteZoomPosition =
          rouletteZoomPosition + ZOOM_VIEW_HEIGHT - MODE_BAR_HEIGHT - FOOT_BAR_HEIGHT - 6; // 6是vde独有偏移量
      } else {
        rouletteZoomPosition = rouletteZoomPosition + VDE_ZOOM_VIEW_HEIGHT;
      }
    } else {
      rouletteZoomPosition = rouletteZoomPosition + ZOOM_VIEW_HEIGHT;
    }
    HiLog.i(TAG, `getRouletteZoomPosition rouletteZoomPosition: ${rouletteZoomPosition}`);
    return rouletteZoomPosition;
  }

  // 个性风格x y 方向覆盖距离
  private handleCustomFilterBorder(): PositionType {
    let coverPreview: PositionType = { x: 0, y: 0 };
    return coverPreview;
    if (AppStorage.get<PositionType>('customFilterBorder')) {
      coverPreview = AppStorage.get<PositionType>('customFilterBorder');
    }
    HiLog.i(TAG, `handleCustomFilterBorder coverPreviewX: ${coverPreview?.x}, coverPreviewY: ${coverPreview?.y}`);
    return coverPreview;
  }

  // 半折态时 对焦框和测光分离出现范围
  /* instrument ignore next */
  private getHalfCollapsRanges(): Ranges {
    const width = getStates().get<number>('windowReducer', 'windowWidth');
    const height = getStates().get<number>('windowReducer', 'windowHeight');
    const previewSize: PositionType = this.getPreviewSize();
    let previewPositionY: number = 0;
    let previewPositionX: number = 0;
    previewPositionX = (width - previewSize.x) / 2;
    previewPositionY = height / 2 - previewSize.y;
    const distances: Ranges = {
      x: [previewPositionX, previewPositionX + previewSize.x, 0, 0],
      y: [previewPositionY, previewSize.y, 0, 0]
    };
    return distances;
  }

  // 直板机 对焦框和测光分离出现范围
  private getUncollapsRanges(fromWatchTouch?: boolean): Ranges {
    const tabBarPosition = AdaptiveLayoutService.getInstance().tabBarPosition;
    const rouletteZoomPosition = this.getRouletteZoomPosition();
    const componentInfo: componentUtils.ComponentInfo =
      WindowService.getInstance().getUiContext().getComponentUtils().getRectangleById('focusExposureArea');
    const previewPosition = px2vp(componentInfo.windowOffset.y);
    const previewSize: PositionType = this.getPreviewSize();

    const xOffset: number = (getStates().get<number>('windowReducer', 'windowWidth') - previewSize.x) / 2;
    HiLog.i(TAG, `getUncollapsBorderDistances xOffset: ${xOffset} - ${JSON.stringify(previewSize)}`);
    const customFilterBorder: PositionType = this.handleCustomFilterBorder();

    let yOffsetStart: number = customFilterBorder.y;
    if (previewPosition === 0) {
      yOffsetStart += tabBarPosition + TAB_BAR_HEIGHT;
    }
    let yOffsetEnd: number = Math.max(previewPosition + previewSize.y - rouletteZoomPosition + customFilterBorder.y, 0);

    if (fromWatchTouch) {
      yOffsetEnd = customFilterBorder.y;
    }

    const distances: Ranges = {
      x: [xOffset, previewSize.x + xOffset, customFilterBorder.x, customFilterBorder.x],
      y: [previewPosition, previewPosition + previewSize.y, yOffsetStart, yOffsetEnd]
    };

    HiLog.i(TAG, `getUncollapsBorderDistances distancesX: ${distances.x}，distancesY: ${distances.y}`);
    return distances;
  }

  // 对焦框和测光分离可拖动范围 -- 展开态和悬停态
  private getDefaultRanges(previewAnimatePosition: PositionType): Ranges {
    const previewSize: PositionType = this.getPreviewSize();
    const distances: Ranges = {
      x: [previewAnimatePosition.x, previewSize.x + previewAnimatePosition.x, 0, 0],
      y: [previewAnimatePosition.y, previewSize.y + previewAnimatePosition.y, 0, 0]
    };

    return distances;
  }

  // 获取对焦和测光分离的可拖动范围
  private getRanges(previewPosition: PositionType, fromWatchTouch?: boolean): Ranges {
    const isShowLandscape = getStates().get('collapsReducer', 'isShowLandscape');
    const isHalfCollapsLEM = getStates().get('collapsReducer', 'isHalfCollapsLEM');

    let ranges: Ranges = this.getDefaultRanges(previewPosition);
    if (isHalfCollapsLEM) {
      HiLog.i(TAG, 'getRanges isHalfCollapsLEM');
      ranges = this.getHalfCollapsRanges();
    } else if (!isShowLandscape && DeviceInfo.isPhone()) {
      ranges = this.getUncollapsRanges(fromWatchTouch);
      HiLog.i(TAG, 'getRanges !isShowLandscape');
    }

    HiLog.i(TAG, `getRanges rangesX:${ranges.x.toString()} rangesY:${ranges.y.toString()}`);
    return ranges;
  }

  // 获取当前展示的位置
  private getShowPosition(touchPosition: number, range: RangeInfo, isFocusPosition: boolean, isY: boolean): number {
    const scale: number = this.getFocusExposureVScale();
    let offset = EXPOSURE_RING_LENGTH_20;

    let borderDistance: number = EXPOSURE_RING_LENGTH_20 * scale;
    if (isFocusPosition) {
      offset = FocusExposureAction.FOCUS_POSITION_40;
      borderDistance = (scale - 1) * FocusExposureAction.FOCUS_POSITION_40;
    }

    let coordinatesPoint = touchPosition - range[0] - offset;
    if (touchPosition - range[0] - range[2] - offset < borderDistance) {
      coordinatesPoint = range[2] + borderDistance;
    } else if (touchPosition + offset + borderDistance > range[1] - range[3]) {
      coordinatesPoint = range[1] - range[3] - range[0] - 2 * offset - borderDistance;
    }

    HiLog.i(TAG,
      `getShowPosition touchPosition:${touchPosition} coordinatesPoint: ${coordinatesPoint}, range: ${range.toString()}`);
    return coordinatesPoint;
  }

  // 更新曝光图标位置 （包括 手机旋转）
  public getExposurePosition(focusPosition: PositionType): PositionType {
    const previewSize = this.getPreviewSize();
    const rotateAngle: number = getStates().get<number>('contextReducer', 'rotateAngle');
    HiLog.i(TAG, `changeExposureViewPosition w: ${previewSize.x} h: ${previewSize.y}, rotateAngle: ${rotateAngle}`);
    let focusPositionX = focusPosition.x;
    let focusPositionY = focusPosition.y;
    HiLog.i(TAG, `changeExposureViewPosition focusPositionX: ${focusPositionX},focusPositionY: ${focusPositionY}`);
    const scale: number = FocusExposureService.getInstance().getFocusExposureVScale();
    const offset = FOCUS_SIZE * (1 - scale) / 2 + CANVAS_WIDTH * (1 - scale) / 2;
    /* instrument ignore else*/
    if (rotateAngle % 180 === 0) {
      focusPositionY = focusPositionY - (CANVAS_HEIGHT - FOCUS_SIZE) / 2;
      let offsetX: number = FOCUS_SIZE - offset + FOCUS_EXPOSURE_GAP;
      /* instrument ignore if*/
      if (focusPosition.x >= previewSize.x / 2) {
        offsetX = -CANVAS_WIDTH + offset - FOCUS_EXPOSURE_GAP;
      }
      focusPositionX = focusPosition.x + offsetX;
    } else {
      focusPositionX = focusPosition.x + (FOCUS_SIZE - CANVAS_WIDTH) / 2;

      let offsetY: number = FOCUS_SIZE - CANVAS_HEIGHT / 2 + CANVAS_WIDTH / 2 + FOCUS_EXPOSURE_GAP - offset;
      if (focusPosition.y >= previewSize.y / 2) {
        offsetY = -(CANVAS_WIDTH + CANVAS_HEIGHT) / 2 - FOCUS_EXPOSURE_GAP + offset;
      }
      focusPositionY = focusPosition.y + offsetY;
    }
    HiLog.i(TAG, `changeExposureViewPosition x: ${focusPositionX},y: ${focusPositionY}`);
    return { x: focusPositionX, y: focusPositionY };
  }

  // 验证当前触摸事件是否在有效范围，并计算当前位置
  public getEventEffectiveInfo = (event: Event, previewPosition: PositionType, isLongPress = false):
    EventEffectiveInfo => {

    const coordinates: PositionType = this.getCoordinates(event);
    HiLog.i(TAG, `getEventEffectiveInfo x: ${coordinates.x},y: ${coordinates.y}`);
    const ranges: Ranges = this.getRanges(previewPosition, event?.fromWatchTouch);
    const isEffective: boolean = (coordinates.y < ranges.y[1] - ranges.y[3]) &&
      (coordinates.y > ranges.y[0] + ranges.y[2]) && (coordinates.x < ranges.x[1] - ranges.x[3]) &&
      (coordinates.x > ranges.x[0] + ranges.x[2]);

    let focusPosition: PositionType = { x: 0, y: 0 };
    let exposurePosition: PositionType = { x: 0, y: 0 };
    if (isEffective) {
      focusPosition = this.getEffectiveCoordinates(event, previewPosition, true);

      const isFocusExposureRingSupported: boolean = this.getFocusSupportedInfo('isFocusExposureRingSupported');
      const isOnlyFocusLockSupported: boolean = this.getFocusSupportedInfo('isOnlyFocusLockSupported');
      const isOnlyFocusSupported: boolean = this.getFocusSupportedInfo('isOnlyFocusSupported');
      if (isLongPress && isFocusExposureRingSupported) { // 测光分离
        exposurePosition = this.getEffectiveCoordinates(event, previewPosition, false);
      } else if (!isOnlyFocusLockSupported && !isOnlyFocusSupported) {
        exposurePosition = this.getExposurePosition(focusPosition);
      }
    }

    return { isEffective, focusPosition, exposurePosition };
  };

  // 获取有效坐标 适用于滑动
  public getEffectiveCoordinates(event: Event, previewPosition: PositionType, isFocusPosition: boolean): PositionType {
    const coordinates: PositionType = this.getCoordinates(event);
    const range: Ranges = this.getRanges(previewPosition, event?.fromWatchTouch);
    coordinates.x = this.getShowPosition(coordinates.x, range.x, isFocusPosition, false);
    coordinates.y = this.getShowPosition(coordinates.y, range.y, isFocusPosition, true);
    HiLog.i(TAG, `getEffectiveCoordinates, isFocusPosition: ${isFocusPosition}`);
    return coordinates;
  }

  // 对焦/测光支持能力的判断  start=======================================
  // 获取对焦信息:  是否支持长按、 是否支持对焦锁定、 是否是仅支持对焦
  private getFocusSupportedInfo(field: keyof FocusConfig): boolean {
    const isMultipleMode: boolean = MULTIPLE_OUTPUTS_MODES.includes(this.mode);
    const isPanVideoOutput: boolean = OutputOperation.isPanVideoOutput(this.mode);
    HiLog.i(TAG, `getFocusSupportedInfo mode: ${this.mode}.`);
    const existInfo: boolean = ModeFocusConfig.has(this.mode);
    let mode: ModeType = this.mode;
    if (!existInfo) {
      mode = isPanVideoOutput ? ModeType.VIDEO : ModeType.PHOTO;
    }
    const data: boolean[] = ModeFocusConfig.get(mode)[field];

    let isSupport: boolean = data[0];
    const cameraPosition: camera.CameraPosition =
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    if (isMultipleMode && isPanVideoOutput || cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      isSupport = data[1];
    }
    HiLog.i(TAG, `getFocusSupportedInfo ${field}: ${isSupport}.`);

    return isSupport;
  }

  //是否支持长按
  public isSupportLongPress(): boolean {
    const isFocusExposureRingSupported = this.getFocusSupportedInfo('isFocusExposureRingSupported');
    const isFocusLockExposureSupported = this.getFocusSupportedInfo('isFocusLockExposureSupported');
    const isOnlyFocusLockSupported = this.getFocusSupportedInfo('isOnlyFocusLockSupported');

    return isFocusExposureRingSupported || isFocusLockExposureSupported || isOnlyFocusLockSupported;
  }

  // 是否支持对焦锁定 + 测光分离
  public isSupportFocusExposureRing(): boolean {
    const isFocusExposureRingSupported: boolean = this.getFocusSupportedInfo('isFocusExposureRingSupported');

    return isFocusExposureRingSupported;
  }

  // 是否支持对焦锁定 + 曝光可调
  public isSupportFocusLockExposure(): boolean {
    const isSupport: boolean = this.getFocusSupportedInfo('isFocusLockExposureSupported');

    return isSupport;
  }

  // 是否仅支持对焦锁定
  public isSupportOnlyFocusLock(): boolean {
    const isSupport: boolean = this.getFocusSupportedInfo('isOnlyFocusLockSupported');

    return isSupport;
  }

  // 是否是仅支持对焦
  public isOnlyFocusSupported(): boolean {
    const isSupport: boolean = this.getFocusSupportedInfo('isOnlyFocusSupported');
    return isSupport;
  }

  public isParamSetFocusSupported(): boolean {
    return false;
  }

  public isParamSetExposureSupported(): boolean {
    return false;
  }

  // 计算对焦和曝光图标的缩放比例
  /* instrument ignore next */
  public getFocusExposureVScale(): number {
    let scale: number = 1;
    if (this.isHalfCollapsLEM) {
      const mAspectRatio: SettingFuncDialogItemIndex =
        FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue();
      if (this.mode === ModeType.VIDEO) {
        const shutterValue: number = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION).getValue();
        scale = shutterValue === SettingFuncDialogItemIndex.INDEX_SEC ? 0.6 : 0.75;
      } else if (mAspectRatio === SettingFuncDialogItemIndex.INDEX_THR) {
        scale = 0.6;
      } else {
        scale = 0.9;
      }
    }

    return scale;
  }

  public getLongPressTip(): TipInfo {
    const isSupportFocusLockExposure: boolean = this.isSupportFocusLockExposure();
    const isSupportOnlyFocusLock: boolean = this.isSupportOnlyFocusLock();
    let longPressTip: Resource = $r('app.string.part_change_exposure_focus');
    let tipDuring: DurationType = DurationType.Duration_Normal;
    /* instrument ignore if*/
    if (isSupportFocusLockExposure) {
      longPressTip = $r('app.string.exposure_focus_locked');
      tipDuring = DurationType.Duration_ALWAYS;
    } else if (isSupportOnlyFocusLock) {
      longPressTip = $r('app.string.exposure_focus_locked');
      tipDuring = DurationType.Duration_ALWAYS;
    }

    return { tipText: longPressTip, tipDuring: tipDuring };
  }

  // 对焦/测光 冲突处理  start=======================================
  public isConflictDisabled(id: FunctionId): boolean {
    const conflicts: ConflictParam = ConflictManager.getInstance().getFunctionConflicts(id);

    return conflicts?.disabled ?? false;
  }

  // 对焦互斥
  /* instrument ignore next */
  public focusConflictManage(): void {
    HiLog.i(TAG, `focusConflictManage E`);
    let focusConflictParam: ConflictParam = new ConflictParam();
    if (getStates().get<boolean>('focusExposureReducer', 'smartControlLocked')) {
      const focusConflictValue: string = camera.FocusMode.FOCUS_MODE_LOCKED.toString();
      focusConflictParam.setLimitedValueSet(new ValueSet().setValues([focusConflictValue]));
    }
    ConflictManager.getInstance().setConflictParam(FunctionId.FOCUS, focusConflictParam);
  }

  // 曝光互斥
  public exposureConflictManage(): void {
    HiLog.i(TAG, `exposureConflictManage E`);
    let exposureConflictParam: ConflictParam = new ConflictParam();
    if (getStates().get<boolean>('focusExposureReducer', 'smartControlLocked')) {
      const exposureConflictValue: string = camera.ExposureMode.EXPOSURE_MODE_LOCKED.toString();
      exposureConflictParam.setLimitedValueSet(new ValueSet().setValues([exposureConflictValue]));
    }
    ConflictManager.getInstance().setConflictParam(FunctionId.EXPOSURE, exposureConflictParam);
  }
}