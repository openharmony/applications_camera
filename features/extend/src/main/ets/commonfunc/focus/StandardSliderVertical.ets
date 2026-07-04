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

import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { Dispatch } from '@ohos/common/src/main/ets/redux';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import camera from '@ohos.multimedia.camera';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { FocusFunction } from './FocusFunction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { ShutterEffectMode } from '@ohos/common/src/main/ets/function/enumbase/ShutterEffectMode';
import lazy { getColorString } from '@ohos/common/src/main/ets/utils/ColorUtil';
import lazy { HdrBrightnessUtil } from '@ohos/common/src/main/ets/utils/HdrBrightnessUtil';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'StandardSliderVertical';
const EXTEND_BAR_HEIGHT: number = 380;
const MF_ARRAY_LENGTH = 27;

class IdentifierValueStruct {
  public isBeautySkin: boolean = false;
  public beautySkinTitle: Resource | string = '';
}

class StandardSliderDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public isEnterImmersive(isEnterImmersive: boolean, mode: ModeType): void {
    if (mode === ModeType.TIME_LAPSE) {
      this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.EXTEND_BAR));
      return;
    }
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.PRO_BAR));
  }

  public sliderValue(sliderVale: Number, timeLapse: string): void {
    this.mDispatch(Action.timeLapseSlider(sliderVale, timeLapse));
  }

  public uiDisabled(): void {
    this.mDispatch(Action.uiState(false));
  }

  public uiEnabled(): void {
    this.mDispatch(Action.uiState(true));
  }
}

@Component
export struct StandardSliderVertical { // 滑动条组件封装 - 光滑、瘦脸、美肤 Standard
  private timeLapse = -1;
  private mFocusModeFunction: FocusFunction = FeatureManager.getInstance().getFunction(FunctionId.FOCUS) as
  FocusFunction;
  private initValue: number = this.mFocusModeFunction?.getModeMfValue() === 0 ?
    27 : this.mFocusModeFunction?.getModeMfValue();
  private unit: String = '';
  private showUnit: boolean = false;
  private title = '';
  private segCount: number = 1; // segment数
  private gapNumInEachSeg: number = 6; // 每段的间隙数 = 每段的分割数,general: 1 longWhiteLine + N redLine
  private valueRange: string[] = []; //
  private changeFunctionValue: Function = () => {
  };
  private setTimeout: Function = () => {
  };
  private clearTimeout: Function = () => {
  };
  private identifierValue: IdentifierValueStruct = new IdentifierValueStruct();
  private tips: String[] = [];
  private mRightPadding: number = 20;
  private sliderCanvasWidth: number = 72; // canvas组件宽度,直板机一般360
  private sliderCanvasHeight: number = 360; // 一般用于控制底部
  private longWhiteLineHeight: number = 1.5; // 滑动条细长白线高
  private longWhiteLineWidth: number = 10; // 滑动条细长白线宽
  private shortWhiteLineHeight: number = 1.5; // 滑动条细短白线高
  private shortWhiteLineWidth: number = 5; // 滑动条细短白线宽
  private redLineHeight: number = 4; // 滑动条粗红线高,直线段为20-2-2,lineTo起点终点在直线段首尾端
  private redLineWidth: number = 16; // 滑动条粗红线宽、、
  @State isShowSemiCollapsed: boolean = true;
  private bothSidesPadding: number = 35; // 左侧距首点左侧、右侧距尾点右侧 padding
  // 前一大点中间距后一大点中间,即28.85
  private segLength: number = (this.sliderCanvasHeight - this.bothSidesPadding * 2 - this.longWhiteLineHeight) /
  this.segCount;
  private dotDistance: number = this.segLength / this.gapNumInEachSeg; // 前一点中间距后一点中间,即9.5
  private spotCount: number = this.segCount * this.gapNumInEachSeg + 1; // 总点数
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  private mode: ModeType = ModeType.NONE;
  @State isSliding: boolean = false; // 用于滑动过程中,临时变量
  // 粗红线中心位置
  @State @Watch('canvasInit') screenY: number = this.bothSidesPadding + this.longWhiteLineHeight / 2 + this.initValue *
  this.segLength;
  private gestureStartY: number = 0; // 单次滑动起始位置缓存
  @State sliderValue: number = 0; // 用于显示值
  private lastFloatValue: number = 0;
  private isPanGesStartEndOrTap: boolean = false;
  private sliderSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private sliderCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.sliderSettings);
  private sliderOffCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.sliderCanvasWidth, this.sliderCanvasHeight, this.sliderSettings);
  private mAction: StandardSliderDispatcher = new StandardSliderDispatcher();
  private readonly ONE_RADIAN: number = Math.PI / 180;
  private mSubscriber: Unsubscribe | null = null;
  @State rotateAngle: number = 0;
  private bigTextTimer: number = setTimeout((): void => {}); // 大字体消失延时器
  @State bigTextOpacity: number = 0;
  private readonly BIG_TEXT_DISAPPEAR_DURATION: number = 350;
  @StorageLink('showFilmingTime') showFilmingTime: boolean = false;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.RIGHT;
  private bottomPadding: number = 21;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @Prop isHdr: boolean = false;

  aboutToAppear() { // 组件复用,要重新计算值
    HiLog.i(TAG, 'aboutToAppear E');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.sliderCanvasHeight = Math.min(this.sliderCanvasHeight, getStates().get<number>('windowReducer', 'windowHeight'));
    this.bothSidesPadding = Math.min(this.bothSidesPadding, (this.sliderCanvasHeight - (this.sliderCanvasHeight -
      this.bothSidesPadding * 2)) / 2);
    this.segLength = (this.sliderCanvasHeight - this.bothSidesPadding * 2 - this.longWhiteLineHeight) / this.segCount;
    this.dotDistance = this.segLength / this.gapNumInEachSeg;
    this.spotCount = this.segCount * this.gapNumInEachSeg + 1;
    this.screenY = this.bothSidesPadding + this.longWhiteLineHeight / 2 + this.initValue * this.dotDistance; // 粗红线中心位置
    this.sliderValue = this.initValue;
    this.lastFloatValue = this.initValue;
    HiLog.i(TAG, 'aboutToAppear X');
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
  }

  private async directionChange() {
    HiLog.i(TAG, 'directionChange E');
    if (!this.isSliding && this.isShowSemiCollapsed) {
      this.canvasInit();
    }
    HiLog.i(TAG, 'directionChange X');
  }

  private canvasInit(): void {
    this.sliderCanvasContext.clearRect(0, 0, this.sliderCanvasWidth, this.sliderCanvasHeight);
    this.sliderOffCanvasCtx.clearRect(0, 0, this.sliderCanvasWidth, this.sliderCanvasHeight);
    this.sliderOffCanvasCtx.strokeStyle = '#FFFFFF';
    this.sliderOffCanvasCtx.fillStyle = '#FFFFFF';
    this.sliderOffCanvasCtx.lineWidth = 1.5;

    const fillRectCenterY = Number(this.getFillRectCenterY(this.screenY).toFixed(3));
    const curFloatValue = (fillRectCenterY - (this.bothSidesPadding + this.longWhiteLineHeight / 2)) /
      (this.sliderCanvasHeight - 2 * this.bothSidesPadding - this.longWhiteLineHeight);
    let nextValue = Number(curFloatValue.toFixed(3));
    if (this.sliderValue !== nextValue && this.isPanGesStartEndOrTap) {
      this.sliderValue = this.focusValue(nextValue);
      this.changeFunctionValue(0, Number(this.sliderValue));
      HiLog.d(TAG, `canvasInit changeFunctionValue  value ${Number(this.sliderValue)}`);
      this.initValue = Number(nextValue) * MF_ARRAY_LENGTH;
    }
    this.lastFloatValue = curFloatValue;

    this.redrawCanvas(fillRectCenterY); // 离屏重绘制canvas
    this.sliderCanvasContext.transferFromImageBitmap(this.sliderOffCanvasCtx.transferToImageBitmap());
  }

  private focusValue(nextValue: number): number {
    if (this.listDisplayJudgment()) {
      return 1 - nextValue;
    }
    return nextValue;
  }

  private getSliderValuePosition(): PositionType {
    if (this.isShowSemiCollapsed) {
      return {
        x: this.isSliding ? 56 : 54,
        y: 32
      }
    }
    return {
      x: this.isSliding ? 30 : 32,
      y: 30
    }
  }

  private redrawCanvas(fillRectCenterY: number): void {
    if (this.isShowSemiCollapsed) {
      this.redrawCanvasSemiCollapsed();
    } else {
      for (let i = 0; i < this.spotCount; i++) {
        const commonPosition: number = this.bothSidesPadding + this.longWhiteLineHeight / 2 + Math.floor(i /
        this.gapNumInEachSeg) * this.segLength + (i % this.gapNumInEachSeg) * this.dotDistance;
        const fontText = `${this.valueRange[i]}${this.showUnit ? this.unit : ''}`;
        const fontPosYGap = this.isSliding ? 36 : 34;
        this.sliderOffCanvasCtx.globalAlpha = 1;
        this.sliderOffCanvasCtx.rotate(0);
        this.sliderOffCanvasCtx.font = `bold ${vp2px(11)}px`;
        this.sliderOffCanvasCtx.textAlign = 'center';
        this.sliderOffCanvasCtx.textBaseline = 'middle';
        this.sliderOffCanvasCtx.shadowColor = '#33000000';
        this.sliderOffCanvasCtx.shadowBlur = 3;
        if (i % this.gapNumInEachSeg !== 0) {
          this.sliderOffCanvasCtx.globalAlpha = 0;
          this.sliderOffCanvasCtx.shadowColor = '#00000000';
        }
        if (i % this.gapNumInEachSeg === 0) {
          this.sliderOffCanvasCtx.globalAlpha = 1;
          this.sliderOffCanvasCtx.fillStyle = '#ffffff';
          this.sliderOffCanvasCtx.shadowColor = '#4d000000';
          this.sliderOffCanvasCtx.shadowBlur = 3;
          this.sliderOffCanvasCtx.fillRect(this.sliderCanvasWidth - this.mRightPadding - this.longWhiteLineWidth,
            commonPosition - this.longWhiteLineHeight / 2, this.longWhiteLineWidth, this.longWhiteLineHeight);
        } else {
          this.sliderOffCanvasCtx.globalAlpha = 0.6;
          this.sliderOffCanvasCtx.shadowColor = '#33000000';
          this.sliderOffCanvasCtx.shadowBlur = 3;
          this.sliderOffCanvasCtx.fillRect(this.sliderCanvasWidth - this.mRightPadding - this.shortWhiteLineWidth,
            commonPosition - this.shortWhiteLineHeight / 2, this.shortWhiteLineWidth, this.shortWhiteLineHeight);
        }
      }
    }
    this.sliderOffCanvasCtx.beginPath();
    this.sliderOffCanvasCtx.globalAlpha = 1;
    this.sliderOffCanvasCtx.lineWidth = this.redLineHeight;
    this.sliderOffCanvasCtx.lineCap = 'round';
    this.sliderOffCanvasCtx.strokeStyle = getColorString();
    if (this.isShowSemiCollapsed) {
      this.sliderOffCanvasCtx.moveTo(this.sliderCanvasWidth - this.mRightPadding - this.redLineWidth - 15,
        fillRectCenterY);
      this.sliderOffCanvasCtx.lineTo(this.sliderCanvasWidth - this.mRightPadding - 15, fillRectCenterY);
    } else {
      this.sliderOffCanvasCtx.moveTo(this.sliderCanvasWidth - this.mRightPadding - this.redLineWidth, fillRectCenterY);
      this.sliderOffCanvasCtx.lineTo(this.sliderCanvasWidth - this.mRightPadding, fillRectCenterY);
    }
    this.sliderOffCanvasCtx.stroke();
  }

  private redrawCanvasSemiCollapsed(): void {
    for (let i = 0; i < this.spotCount; i++) {
      let commonLength: number = this.bothSidesPadding + this.longWhiteLineHeight / 2 + Math.floor(i /
      this.gapNumInEachSeg) *
      this.segLength + (i % this.gapNumInEachSeg) * this.dotDistance;
      const curRedLineInNum = this.valueRange.findIndex(index => {
        return Number(index) === this.sliderValue;
      }) * this.gapNumInEachSeg;

      let fontPosYGap = this.isSliding ? 23 : 25;
      let fontTextPos = this.getTextPosition({
        x: this.sliderCanvasWidth - this.bottomPadding - fontPosYGap + 20,
        y: commonLength,
      });

      if (i === 0 || i === this.spotCount - 1 || (!this.isSliding && i === curRedLineInNum)) {
        const fontText = i === 0 ? this.valueRange[0].toString() : i === this.spotCount - 1 ? this.valueRange[1]
          .toString() :
        this.sliderValue.toString();
        this.redrawFont(fontText, fontTextPos.x, fontTextPos.y);
      }
      if (i % this.gapNumInEachSeg === 0) {
        this.sliderOffCanvasCtx.globalAlpha = 1;
        this.sliderOffCanvasCtx.fillStyle = '#FFF';
        this.sliderOffCanvasCtx.shadowColor = '#4d000000';
        this.sliderOffCanvasCtx.shadowBlur = 3;
        this.sliderOffCanvasCtx.fillRect((this.sliderCanvasWidth - this.mRightPadding - this.longWhiteLineWidth - 20),
          (commonLength - this.longWhiteLineHeight / 2), this.longWhiteLineWidth, this.longWhiteLineHeight);
      } else {
        this.sliderOffCanvasCtx.globalAlpha = 0.3;
        this.sliderOffCanvasCtx.shadowColor = '#33000000';
        this.sliderOffCanvasCtx.shadowBlur = 3;
        this.sliderOffCanvasCtx.fillRect(this.sliderCanvasWidth - this.mRightPadding - this.shortWhiteLineWidth - 20,
          commonLength - this.shortWhiteLineHeight / 2, -this.shortWhiteLineWidth, this.shortWhiteLineHeight);
      }
    }
  }

  private getTextPosition(textPos: PositionType): PositionType {
    switch (this.mDirection) {
      case WindowDirection.TOP:
        break;
      case WindowDirection.BOTTOM:
        textPos.x = -textPos.x;
        textPos.y = -textPos.y;
        break;
      case WindowDirection.LEFT:
        let tempX = textPos.x;
        textPos.x = -textPos.y;
        textPos.y = tempX;
        break;
      case WindowDirection.RIGHT:
        let tempY = textPos.y;
        textPos.y = -textPos.x;
        textPos.x = tempY;
        break;
      default:
        break;
    }
    return textPos;
  }

  private redrawFont(text: string, x: number, y: number): void {
    this.sliderOffCanvasCtx.rotate(0);
    this.sliderOffCanvasCtx.globalAlpha = 1;
    this.sliderOffCanvasCtx.font = `bold ${vp2px(11)}px`;
    this.sliderOffCanvasCtx.textAlign = 'center';
    this.sliderOffCanvasCtx.textBaseline = 'middle';
    this.isShowSemiCollapsed && this.sliderOffCanvasCtx.rotate(this.geViewRotate(this.mDirection) * this.ONE_RADIAN);
    this.isShowSemiCollapsed && this.sliderOffCanvasCtx.rotate(-this.geViewRotate(this.mDirection) * this.ONE_RADIAN);
  }

  private geViewRotate(currentDirection: WindowDirection, isSettingView: boolean = false): number {
    switch (currentDirection) {
      case WindowDirection.TOP:
        return 0;
      case WindowDirection.BOTTOM:
        return isSettingView ? 0 : AnimSpecifications.ANIM_ROTATE_180;
      case WindowDirection.RIGHT:
        return AnimSpecifications.ANIM_ROTATE_90;
      case WindowDirection.LEFT:
        return AnimSpecifications.ANIM_ROTATE_270;
      default:
        return 0;
    }
  }

  private getFillRectCenterY(mScreenY: number): number {
    let fillRectCenterY = mScreenY;
    if (fillRectCenterY < this.bothSidesPadding + this.longWhiteLineHeight / 2) {
      fillRectCenterY = this.bothSidesPadding + this.longWhiteLineHeight / 2;
    } else if (fillRectCenterY > this.sliderCanvasHeight - this.bothSidesPadding - this.longWhiteLineHeight / 2) {
      fillRectCenterY = this.sliderCanvasHeight - this.bothSidesPadding - this.longWhiteLineHeight / 2;
    }
    return fillRectCenterY;
  }

  private getFingerListLocalY(event: GestureEvent): number | null {
    let localY: number | null = null;
    event.fingerList.forEach((eventItem: FingerInfo) => {
      if (eventItem) {
        localY = eventItem?.localY;
        return;
      }
    });
    return localY;
  }

  private onPanGestureEnd(event?: GestureEvent): void {
    if (event === undefined) {
      return;
    }
    this.isPanGesStartEndOrTap = true;
    this.gestureStartY = this.screenY;
    this.isPanGesStartEndOrTap = false;
    this.isSliding = false;
    if (this.enableScreenReader) {
      AccessibilityUtils.sendAnnounceAccessibilityEvent(`${this.initValue.toFixed(2)}`)
    }
    this.setBigTextTimer();
    this.setTimeout();
    this.mAction.isEnterImmersive(false, this.mode);
    this.mAction.uiEnabled();
  }

  private onLongPressGestureEnd(event?: GestureEvent): void {
    if (event === undefined) {
      return;
    }
    this.setTimeout();
    this.setBigTextTimer();
    this.mAction.uiEnabled();
  }

  private getABText(): string {
    return `${ResGetter.getStringSafe($r('app.string.accessibility_focus_mode_manual'))}
    ${this.initValue.toFixed(2)}`;
  }

  private listDisplayJudgment(): boolean {
    if (SystemLanguageUtil.isRTL()) {
      return this.isShowSemiCollapsed;
    }
    return !this.isShowSemiCollapsed;
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.End, justifyContent: FlexAlign.Center }) {
      Column() {
        Image(this.listDisplayJudgment() ? $r(null):
          $r(null))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .margin({ left: -6, top: -19 })
          .draggable(false)
          .rotate({ angle: this.rotateAngle })
          .offset({ x: DeviceInfo.isTablet() ? -1 : 0, y: DeviceInfo.isTablet() ? -4 : 0 })
          .foregroundFilter(HdrBrightnessUtil.getHdrFilter(this.isHdr))
        Image(!this.listDisplayJudgment() ? $r(null) :
          $r(null))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .margin({ left: -6, bottom: 41 })
          .draggable(false)
          .rotate({ angle: this.rotateAngle })
          .offset({ x: DeviceInfo.isTablet() ? -1 : 0, y: DeviceInfo.isTablet() ? -4 : 0 })
          .foregroundFilter(HdrBrightnessUtil.getHdrFilter(this.isHdr))
      }

      .height(this.sliderCanvasHeight)
      .justifyContent(
        FlexAlign.SpaceBetween
      ).position(this.getSliderValuePosition())

      Row() {
        Canvas(this.sliderCanvasContext)
          .width(this.sliderCanvasWidth)
          .height(this.sliderCanvasHeight)
          .offset({ x: this.isShowSemiCollapsed ? 0 : 10, y: DeviceInfo.isTablet() ? -5 : 0 })
          .onReady((): void => {
            this.canvasInit();
          })
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical })
                .onActionStart((event?: GestureEvent) => {
                  if (event === undefined || event.fingerList.length === 0) {
                    return;
                  }
                  this.mAction.uiDisabled();
                  this.mAction.isEnterImmersive(true, this.mode);
                  this.clearTimeout();
                  let localY = this.getFingerListLocalY(event);
                  if (!localY) {
                    return;
                  }
                  this.gestureStartY = localY;
                  this.isSliding = true;
                  this.isPanGesStartEndOrTap = true;
                  this.screenY = localY;
                  this.isPanGesStartEndOrTap = false;
                  this.clearBigTextTimer();
                })
                .onActionUpdate((event?: GestureEvent) => {
                  if (event === undefined) {
                    return;
                  }
                  this.isPanGesStartEndOrTap = true;
                  this.screenY = (this.gestureStartY + event.offsetY);
                  this.isPanGesStartEndOrTap = false;
                  if (this.timeLapse !== -1) {
                    this.mAction.sliderValue(this.timeLapse, this.sliderValue.toString(3));
                  }
                  this.clearTimeout();
                })
                .onActionEnd((event?: GestureEvent) => this.onPanGestureEnd(event))
                .onActionCancel((event?: GestureEvent) => this.onPanGestureEnd(event)),
              TapGesture({ count: 1 })
                .onAction((event?: GestureEvent) => {
                  if (event === undefined) {
                    return;
                  }
                  if (!this.enableScreenReader && event.fingerList[0]?.localX === undefined) {
                    return;
                  }
                  this.clearTimeout();
                  this.isPanGesStartEndOrTap = true;
                  if (this.enableScreenReader) {
                    let initValue: number;
                    if (this.isShowSemiCollapsed) {
                      initValue = this.initValue / MF_ARRAY_LENGTH + 0.01 > 1 ? 0 :
                        this.initValue / MF_ARRAY_LENGTH + 0.01;
                    } else {
                      initValue = this.initValue / MF_ARRAY_LENGTH + 0.01 > 1 ? 0 :
                        this.initValue / MF_ARRAY_LENGTH + 0.01;
                    }
                    this.screenY = this.getNextScreenY(this.bothSidesPadding + this.longWhiteLineHeight / 2 +
                      initValue * MF_ARRAY_LENGTH * this.dotDistance);
                    AccessibilityUtils.sendAnnounceAccessibilityEvent(`${this.initValue.toFixed(2)}`);
                  } else {
                    let localY = this.getFingerListLocalY(event);
                    if (!localY) {
                      return;
                    }
                    this.screenY = this.getNextScreenY(localY);
                  }
                  this.isPanGesStartEndOrTap = false;
                  this.setTimeout();
                  this.setBigTextTimer();
                }),
              LongPressGesture({ repeat: false, duration: 300 })
                .onAction((event?: GestureEvent) => {
                  if (event === undefined) {
                    return;
                  }
                  this.mAction.uiDisabled();
                  this.clearTimeout();
                  if (this.bigTextTimer) {
                    clearTimeout(this.bigTextTimer);
                  }
                })
                .onActionEnd((event?: GestureEvent) => this.onLongPressGestureEnd(event))
                .onActionCancel((event?: GestureEvent) => this.onLongPressGestureEnd(event)),
            )
          )
          .key(ComponentIdKeys.getInstance().getKey('LandscapeFocusModeView', FunctionId.FOCUS, 'slider'))
          .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
          .accessibilityText(this.getABText())
          .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_slider_description')))
          .key(ComponentIdKeys.getInstance().getKey(TAG, FunctionId.WHITE_BALANCE) + '_ADJUST_BAR')
          .onAppear(()=>{
            if (this.enableScreenReader) {
              AccessibilityUtils.
              sendFocusAccessibilityEvent(`${ComponentIdKeys.getInstance().getKey('FocusModeView',
                FunctionId.FOCUS, ShutterEffectMode.AUTO)}`);
            }
          })
      }
      .foregroundFilter(HdrBrightnessUtil.getHdrFilter(this.isHdr))
    }
    .offset(this.isShowSemiCollapsed ? { x: -21, y: -5 } : { x: -6, y: -10 })
    .width(this.sliderCanvasWidth)
    .height(this.sliderCanvasHeight)
  }

  private getNextScreenY(mScreenY: number): number {
    const fillRectCenterY = this.getFillRectCenterY(mScreenY);
    const curFloatValue = (fillRectCenterY - this.bothSidesPadding - this.longWhiteLineHeight / 2) / (this.segCount *
    this.segLength) * (this.segCount * this.gapNumInEachSeg);
    const nextValue = Number(curFloatValue.toFixed(0));

    const nextScreenY = nextValue / (this.segCount * this.gapNumInEachSeg) * (this.segCount * this.segLength) +
    this.bothSidesPadding + this.longWhiteLineHeight / 2;
    HiLog.i(TAG, `this.screenY: ${this.screenY}, this.sliderValue: ${this.sliderValue}, nextScreenX: ${nextScreenY}.`);
    return nextScreenY;
  }

  private setBigTextTimer() {
    this.clearBigTextTimer();
    this.bigTextTimer = setTimeout((): void => {
      this.bigTextOpacity = 0;
    }, this.BIG_TEXT_DISAPPEAR_DURATION);
  }

  private clearBigTextTimer() {
    if (this.bigTextTimer) {
      clearTimeout(this.bigTextTimer);
      this.bigTextOpacity = 1;
    }
  }
}