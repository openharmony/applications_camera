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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy {
  OhCombinedState,
  Unsubscribe,
  Dispatch,
  reduxSubscribe,
  getStates
} from '@ohos/common/src/main/ets/redux';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import camera from '@ohos.multimedia.camera';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { ExposureFunction } from './ExposureFunction';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy {
  DirectionCorrectionService
} from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'LandscapeExposureBarView';
const EXTEND_BAR_HEIGHT: number = 380;
const IMAGE_ELEMENT_LENGTH: number = 72;

class StateStruct {
  public isShowExtendBar: boolean = false;
  public xComponentWidth?: number = 0;
  public mode: ModeType = ModeType.NONE;
}

class PositionData {
  public x: number = 0;
  public y: number = 0;
}

class FunctionValueStruct {
  public exposureMode: camera.ExposureMode = camera.ExposureMode.EXPOSURE_MODE_LOCKED;
  public exposureValue: number = 0;
}


class ExposureDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: FunctionValueStruct): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public hideExposureView(iconId: number): void {
    this.mDispatch(Action.proSonChangeState(iconId));
  }

  public isEnterImmersive(isEnterImmersive: boolean, mode: ModeType): void {
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
export struct LandscapeExposureBarView {
  @State state: StateStruct = new StateStruct();
  private mAction: ExposureDispatcher = new ExposureDispatcher();
  private timerId: number = Number.MIN_VALUE;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @State exposureFunValue: number = 0;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State rotateAngle: number = 0;
  private exposureModeTimerId: number = Number.MIN_VALUE;
  private mExposureFunction: ExposureFunction = FeatureManager.getInstance()
    .getFunction(FunctionId.EXPOSURE) as ExposureFunction;
  private initValue: number = this.mExposureFunction?.getModeValue();
  private segCount: number = 4; // segment数
  private gapNumInEachSeg: number = 6; // 每段的间隙数 = 每段的分割数,general: 1 longWhiteLine + N redLine
  private valuesRange: string[] =
    ['-4', '-3.7', '-3.3', '-3', '-2.7', '-2.3', '-2', '-1.7', '-1.3', '-1', '-0.7', '-0.3',
      '0', '+0.3', '+0.7', '+1', '+1.3', '+1.7', '+2', '+2.3', '+2.7', '+3', '+3.3', '+3.7', '+4'];
  private sliderCanvasWidth: number = 80; // canvas组件宽度
  private sliderCanvasHeight: number = 340; // 一般用于控制底部
  private longWhiteLineHeight: number = 1.5; // 滑动条细长白线高
  private longWhiteLineWidth: number = 10; // 滑动条细长白线宽
  private shortWhiteLineHeight: number = 1.5; // 滑动条细短白线高
  private shortWhiteLineWidth: number = 5; // 滑动条细短白线宽
  private redLineHeight: number = 4; // 滑动条粗红线高,直线段为20-2-2,lineTo起点终点在直线段首尾端
  private redLineWidth: number = 16; // 滑动条粗红线宽
  private bottomPadding: number = 21;
  private bothSidesPadding: number = 20; // 左侧距首点左侧、右侧距尾点右侧 padding
  private segLength: number = (this.sliderCanvasWidth - this.bothSidesPadding * 2 - this.longWhiteLineWidth) /
  this.segCount; // 前一大点中间距后一大点中间,即28.85
  private dotDistance: number = this.segLength / this.gapNumInEachSeg; // 前一点中间距后一点中间,即9.5
  private spotCount: number = this.segCount * this.gapNumInEachSeg + 1; // 总点数
  @State isSliding: boolean = false; // 用于滑动过程中,临时变量
  @State exposureTextOpacity: number = 0;
  @State isCanvasClicked: boolean = false; // 用于滑动过程中,临时变量
  @State sliderValue: number = 0; // 用于显示值
  private lastFloatValue: number = 0;
  private isPanGesStartEndOrTap: boolean = false;
  private sliderSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private sliderCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.sliderSettings);
  private sliderOffCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.sliderCanvasWidth, this.sliderCanvasHeight, this.sliderSettings);
  private readonly ONE_RADIAN: number = Math.PI / 180;
  private mSubscriber: Unsubscribe | null = null;
  @State isEXPOSUREAutoState: boolean = true;
  private bigTextTimer: number = setTimeout((): void => {
  }); // 大字体消失延时器
  private readonly BIG_TEXT_DISAPPEAR_DURATION: number = 350;
  private title = '';
  private tips: String[] = [];
  @State isShowSemiCollapsed: boolean = true;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State @Watch('canvasInit') screenY: number =
    this.bothSidesPadding + this.longWhiteLineHeight / 2 + this.initValue * this.segLength;
  private timeLapse = -1;
  private unit: String = '';
  private showUnit: boolean = false;
  private mRightPadding: number = 20;
  private gestureStartY: number = 0; // 单次滑动起始位置缓存
  @State bigTextOpacity: number = 0;
  @StorageLink('showFilmingTime') showFilmingTime: boolean = false;
  private globalAutoChangeFlag: boolean = false;
  private setTimeoutForLapse: Function = () => {
  };
  private clearTimerForLapse: Function = () => {
  };
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State exposureOpacity: number = 0;
  private initialLoading: boolean = true;
  @Link showEvLocked: boolean;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.state.mode = state.get<ModeType>('modeReducer', 'mode');
      this.mDirection =
        DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
          state.get<boolean>('windowReducer', 'isLockRotation'));
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.initialLoading = false;
    this.segLength = (this.sliderCanvasHeight - this.bothSidesPadding * 2 - this.longWhiteLineHeight) / this.segCount;
    this.dotDistance = this.segLength / this.gapNumInEachSeg;
    this.spotCount = this.segCount * this.gapNumInEachSeg + 1;
    this.initValue = Number(this.initValue?.toFixed(1));
    if (!this.listDisplayJudgment()) {
      this.valuesRange = [...this.valuesRange].reverse();
    }
    let initIndex = this.valuesRange.findIndex(index => {
      return Number(index) === this.initValue;
    });
    this.sliderValue = initIndex;
    if (!this.isShowSemiCollapsed) {
      initIndex = this.valuesRange.length - 1 - initIndex;
    }
    this.setTimeout();
    this.lastFloatValue = initIndex;
    this.screenY = this.bothSidesPadding + this.longWhiteLineHeight / 2 + initIndex * this.dotDistance; // 粗红线中心位置
    this.mEventBus.on(ActionType.ACTION_LAPSE_AUTO, (data: ActionData) => this.changeExposureToState(data['autoType']),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LUMATION_CHANGE_STATE, () => this.refreshingBar(),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  private semiCollapsedBlackAreaClicked(): void {
    this.clearTimer();
    this.mAction.hideExposureView(-1);
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear invoke E.');
    this.clearTimer();
    this.mSubscriber?.destroy();
    HiLog.i(TAG, 'aboutToDisappear invoke X.');
  }

  private listDisplayJudgment(): boolean {
    if (SystemLanguageUtil.isRTL()) {
      return this.isShowSemiCollapsed;
    }
    return !this.isShowSemiCollapsed;
  }

  private refreshingBar(): void {
    this.initValue = this.mExposureFunction?.getModeValue();
    this.initValue = Number(this.initValue?.toFixed(1));
    let initIndex = this.valuesRange.findIndex(index => {
      return Number(index) === this.initValue;
    });
    this.sliderValue = initIndex;
    this.lastFloatValue = initIndex;
    this.screenY = this.bothSidesPadding + this.longWhiteLineHeight / 2 + initIndex * this.dotDistance;
  }

  private changeExposureModeFunctionValue(value: number): void {
    if (this.globalAutoChangeFlag) {
      this.sliderValue = 0;
      return;
    }
    this.showEvLocked = false;
    HiLog.i(TAG, `changeExposureModeFunctionValue value --- ${value}`);
    FocusExposureService.getInstance().setExposureValue({
      exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
      exposureValue: value,
      isParamSetting: true,
    });
    VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
  }

  private clearExposureModeTimeout(): void {
    HiLog.d(TAG, 'clearPortraitBeautyModeTimeout.');
    if (Number.MIN_VALUE !== this.exposureModeTimerId) {
      clearTimeout(this.exposureModeTimerId);
    }
    this.clearTimer();
  }

  private async directionChange() {
    HiLog.i(TAG, 'directionChange E');
    if (!this.isSliding && !this.initialLoading) {
      this.canvasInit();
    }
    HiLog.i(TAG, 'directionChange X');
  }

  private clearTimer(): void {
    if (Number.MIN_VALUE !== this.timerId) {
      clearTimeout(this.timerId);
    }
    this.clearTimerForLapse();
  }

  private setTimeout(): void {
    this.clearTimer();
    this.timerId = setTimeout((): void => {
      this.mAction.hideExposureView(-1);
    }, this.enableScreenReader ? 3 * 5000 : 5000); // 开启屏幕朗读延长3倍时间自动关闭

  }

  private canvasInit(): void {
    this.sliderCanvasContext.clearRect(0, 0, this.sliderCanvasWidth, this.sliderCanvasHeight);
    this.sliderOffCanvasCtx.clearRect(0, 0, this.sliderCanvasWidth, this.sliderCanvasHeight);
    this.sliderOffCanvasCtx.strokeStyle = '#FFFFFF';
    this.sliderOffCanvasCtx.fillStyle = '#FFFFFF';
    this.sliderOffCanvasCtx.lineWidth = 1.5;

    const fillRectCenterY = this.getFillRectCenterY(this.screenY);
    let curFloatValue = this.valuesRange.length - 1 - (fillRectCenterY - this.bothSidesPadding -
      this.longWhiteLineHeight / 2) / (this.segCount * this.segLength) * (this.segCount * this.gapNumInEachSeg);
    if (this.isShowSemiCollapsed) {
      curFloatValue = (fillRectCenterY - this.bothSidesPadding - this.longWhiteLineHeight / 2) /
        (this.segCount * this.segLength) * (this.segCount * this.gapNumInEachSeg);
    }
    const rightSlideThroughFlag = Number(curFloatValue?.toFixed(3)) >= Number(this.lastFloatValue?.toFixed(0));
    const leftSlideThroughFlag = Number(curFloatValue?.toFixed(3)) <= Number(this.lastFloatValue?.toFixed(0));
    let nextValue = Number(curFloatValue?.toFixed(0));
    if ((rightSlideThroughFlag || leftSlideThroughFlag || this.isPanGesStartEndOrTap) && this.sliderValue !==
      nextValue) {
      this.sliderValue = nextValue;
      this.changeExposureModeFunctionValue(Number(this.valuesRange[this.sliderValue]));
    }
    this.lastFloatValue = curFloatValue;
    this.redrawCanvas(fillRectCenterY); // 离屏重绘制canvas
    this.sliderCanvasContext.transferFromImageBitmap(this.sliderOffCanvasCtx.transferToImageBitmap());
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

  private redrawCanvasText(i: number, initIndex: number, commonPosition: number): void {
    const fontText = `${this.valuesRange[this.valuesRange.length - i - 1]}${this.showUnit ? this.unit : ''}`;
    const fontPosYGap = this.isSliding ? 36 : 34;
    const fontPosXGap = 0;
    let fontTextPos = this.getTextPosition({
      x: this.sliderCanvasWidth - this.mRightPadding - fontPosYGap + fontPosXGap,
      y: commonPosition,
    });
    this.sliderOffCanvasCtx.globalAlpha = 1;
    this.sliderOffCanvasCtx.shadowColor = '#33000000';
    this.sliderOffCanvasCtx.shadowBlur = 3;
    if (Math.abs(initIndex - i) < 2 && i !== initIndex && !this.isSliding) {
      this.sliderOffCanvasCtx.globalAlpha = 0;
      this.sliderOffCanvasCtx.shadowColor = '#00000000';
    } else if (this.isSliding && i === initIndex && (i % this.gapNumInEachSeg !== 0)) {
      this.sliderOffCanvasCtx.globalAlpha = 0;
      this.sliderOffCanvasCtx.shadowColor = '#00000000';
    }
    this.redrawFont(fontText, fontTextPos.x, fontTextPos.y, this.sliderOffCanvasCtx.globalAlpha);
  }

  private redrawCanvas(fillRectCenterY: number): void {
    if (this.isShowSemiCollapsed) {
      this.redrawCanvasSemiCollapsed();
    } else {
      for (let i = 0; i < this.spotCount; i++) {
        const commonPosition: number = this.bothSidesPadding + this.longWhiteLineHeight / 2 + Math.floor(i /
        this.gapNumInEachSeg) * this.segLength + (i % this.gapNumInEachSeg) * this.dotDistance;
        const curRedLineInNum = this.valuesRange.findIndex(index => {
          return Number(index) === this.sliderValue;
        }) * this.gapNumInEachSeg;
        const initIndex = this.valuesRange.length - 1 - this.valuesRange.findIndex((item, index) => {
          return index === this.sliderValue;
        })
        if (i === 0 || i === this.spotCount - 1 || (!this.isSliding && i === curRedLineInNum) || i %
        this.gapNumInEachSeg === 0 || i === initIndex) {
          this.redrawCanvasText(i, initIndex, commonPosition);
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
    this.sliderOffCanvasCtx.strokeStyle = DeviceInfo.isTablet() ? '#0A59F7' : '#FF0000';
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
      this.gapNumInEachSeg) * this.segLength + (i % this.gapNumInEachSeg) * this.dotDistance;
      const curRedLineInNum = this.valuesRange.findIndex(index => {
        return Number(index) === this.sliderValue;
      }) * this.gapNumInEachSeg;

      let fontPosYGap = this.isSliding ? 23 : 25;
      let fontTextPos = this.getTextPosition({
        x: this.sliderCanvasWidth - this.bottomPadding - fontPosYGap + 20,
        y: commonLength,
      });
      const initIndex = this.valuesRange.findIndex((item, index) => {
        return index === this.sliderValue;
      })
      if (i === 0 || i === this.spotCount - 1 || (!this.isSliding && i === curRedLineInNum) || i %
      this.gapNumInEachSeg === 0 || i === initIndex) {
        const fontText = i === 0 ? this.valuesRange[0].toString() : i === this.spotCount - 1 ?
          this.valuesRange[this.spotCount - 1].toString() :
          this.valuesRange[i].toString();
        let globalAlpha = 1;
        if (Math.abs(initIndex - i) < 2 && i !== initIndex && !this.isSliding) {
          globalAlpha = 0;
          this.sliderOffCanvasCtx.shadowColor = '#00000000';
        } else if (this.isSliding && i === initIndex && (i % this.gapNumInEachSeg !== 0)) {
          globalAlpha = 0;
          this.sliderOffCanvasCtx.shadowColor = '#00000000';
        }
        this.redrawFont(fontText, fontTextPos.x, fontTextPos.y, globalAlpha);
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

  private redrawFont(text: string, x: number, y: number, globalAlpha: number): void {
    this.sliderOffCanvasCtx.rotate(0);
    this.sliderOffCanvasCtx.globalAlpha = globalAlpha;
    this.sliderOffCanvasCtx.font = `bold ${vp2px(11)}px`;
    this.sliderOffCanvasCtx.textAlign = 'center';
    this.sliderOffCanvasCtx.textBaseline = 'middle';
    this.sliderOffCanvasCtx.rotate(this.geViewRotate(this.mDirection) * this.ONE_RADIAN);
    this.sliderOffCanvasCtx.fillText(text, x, y);
    this.sliderOffCanvasCtx.rotate(-this.geViewRotate(this.mDirection) * this.ONE_RADIAN);
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

  private getTextPosition(textPos: PositionData): PositionData {
    let paddingTop = this.isShowSemiCollapsed ? 5 : 0;
    let paddingLeft = this.isShowSemiCollapsed ? 0 : 5;
    switch (this.mDirection) {
      case WindowDirection.TOP:
        textPos.x = textPos.x + paddingTop;
        textPos.y = textPos.y;
        break;
      case WindowDirection.BOTTOM:
        textPos.x = -textPos.x - paddingTop;
        textPos.y = -textPos.y;
        break;
      case WindowDirection.LEFT:
        let tempX = textPos.x;
        textPos.x = -textPos.y;
        textPos.y = tempX + paddingLeft;
        break;
      case WindowDirection.RIGHT:
        let tempY = textPos.y;
        textPos.y = -textPos.x - paddingLeft;
        textPos.x = tempY;
        break;
      default:
        break;
    }
    return textPos;
  }

  private getSliderValuePosition(): PositionType {
    if (this.isShowSemiCollapsed) {
      const width = getStates().get<number>('windowReducer', 'windowWidth');
      const height = getStates().get<number>('windowReducer', 'windowHeight');
      return this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK
        ? {
          x: ((width - 270) * 3 / 4 + 52) - 84,
          y: (height - EXTEND_BAR_HEIGHT - 130) / 2
        } : {
          x: (width - 300) * 3 / 4 - 3,
          y: (height - EXTEND_BAR_HEIGHT - 136) / 2 - 1
        }
    }
    return {
      x: -134,
      y: 144,
    }
  }

  private getNextScreenY(mScreenY: number): number {
    const fillRectCenterY = this.getFillRectCenterY(mScreenY);
    const curFloatValue = (fillRectCenterY - this.bothSidesPadding - this.longWhiteLineHeight / 2) / (this.segCount *
    this.segLength) * (this.segCount * this.gapNumInEachSeg);
    const nextValue = Number(curFloatValue?.toFixed(0));

    const nextScreenY = nextValue / (this.segCount * this.gapNumInEachSeg) * (this.segCount * this.segLength) +
    this.bothSidesPadding + this.longWhiteLineHeight / 2;
    HiLog.i(TAG, `this.screenY: ${this.screenY}, this.sliderValue: ${this.sliderValue}.`);
    return nextScreenY;
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

  private tapGestureResponse(event?: GestureEvent): void {
    if (event === undefined) {
      return;
    }
    if (!this.enableScreenReader && event.fingerList[0]?.localX === undefined) {
      return;
    }
    this.clearTimer();
    this.isPanGesStartEndOrTap = true;
    if (this.enableScreenReader) {
      let initIndex: number;
      if (this.isShowSemiCollapsed) {
        initIndex = (this.sliderValue + 1 > this.valuesRange.length - 1) ? 0 : this.sliderValue + 1;
      } else {
        initIndex = (this.valuesRange.length - 1 - (this.sliderValue + 1) < 0) ?
          this.valuesRange.length - 1 : this.valuesRange.length - 1 - (this.sliderValue + 1);
      }
      this.screenY = this.bothSidesPadding + this.longWhiteLineHeight / 2 + initIndex * this.dotDistance;
      setTimeout(() => {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(
          ResGetter.getStringSafe($r('app.string.accessibility_exposure_compensation_tile')) +
          this.valuesRange[this.sliderValue]);
      }, 10);
    } else {
      let localY = this.getFingerListLocalY(event);
      if (!localY) {
        return;
      }
      this.screenY = this.getNextScreenY(localY);
    }
    this.setTimeout();
    this.isPanGesStartEndOrTap = false;
    this.setBigTextTimer();
  }

  private getOffset(): Position {
    if (!DeviceInfo.isTablet()) {
      return { x: 0, y: 0 };
    }
    const width = getStates().get<number>('windowReducer', 'windowWidth');
    const height = getStates().get<number>('windowReducer', 'windowHeight');
    if (width > height) {
      return { x: 0, y: 0 };
    }
    return { x: 0, y: 2 };
  }

  private onPanGestureEnd(event?: GestureEvent): void {
    if (event === undefined) {
      return;
    }
    this.gestureStartY = this.screenY;
    this.isSliding = false;
    this.isPanGesStartEndOrTap = true;
    this.screenY = this.getNextScreenY(this.screenY);
    this.isPanGesStartEndOrTap = false;
    this.setBigTextTimer();
    this.setTimeout();
    this.mAction.isEnterImmersive(false, this.state.mode);
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
    return `${ResGetter.getStringSafe($r('app.string.accessibility_exposure_compensation_tile'))} ${this.valuesRange[this.sliderValue]}`
  }

  build() {
    Row() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        // 滑动时字体显示
        Column() {
          Text(`${this.valuesRange[this.sliderValue]}${this.unit}`)
            .fontSize(vp2px(px2fp(40)))
            .fontColor(Color.White)
            .fontWeight(300) // .height(53)
            .textShadow({
              radius: 3,
              color: '#33000000',
              offsetX: 0,
              offsetY: 0
            })
            .textAlign(TextAlign.Center)
            .fontFeature('\"ss01\" on')
            .touchable(false)
          if (this.tips && this.tips.length > 0) {
            Text(`${this.tips[this.sliderValue]}`)
              .fontSize(12)
              .maxFontScale(1)
              .fontColor(Color.White)
              .height(16)
              .textShadow({
                radius: 3,
                color: '#33000000',
                offsetX: 0,
                offsetY: 0
              })
              .textAlign(TextAlign.Center)
              .fontFeature('\"ss01\" on')
              .touchable(false)
          }
        }
        .width(150)
        .position(this.getSliderValuePosition())
        .rotate({
          angle: (this.isShowSemiCollapsed) ?
            this.rotateAngle : 0
        }) // EV 大的数值
        .opacity(this.bigTextOpacity)

        Row() {
          Canvas(this.sliderCanvasContext)
            .width(this.sliderCanvasWidth)
            .height(this.sliderCanvasHeight)
            .offset(this.getOffset())
            .onReady((): void => {
              this.canvasInit();
            })
            .gesture(
              GestureGroup(
                GestureMode.Exclusive,
                PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical })
                  .onActionStart((event?: GestureEvent) => {
                    if (event === undefined || event.fingerList.length === 0) {
                      return;
                    }
                    this.mAction.uiDisabled();
                    this.mAction.isEnterImmersive(true, this.state.mode);
                    this.clearTimer();
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
                    this.screenY = (this.gestureStartY + event.offsetY);
                    if (this.timeLapse !== -1) {
                      this.mAction.sliderValue(this.timeLapse, this.valuesRange[this.sliderValue]);
                    }
                    this.clearTimer();
                  })
                  .onActionEnd((event?: GestureEvent) => {
                    this.onPanGestureEnd(event);
                    if (this.enableScreenReader) {
                      AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe($r('app.string.accessibility_exposure_compensation_tile')) +
                      this.valuesRange[this.sliderValue])
                    }
                  })
                  .onActionCancel((event?: GestureEvent) => this.onPanGestureEnd(event)),
                TapGesture({ count: 1 })
                  .onAction((event?: GestureEvent) => {
                    this.tapGestureResponse(event);
                  }),
                LongPressGesture({ repeat: false, duration: 300 })
                  .onAction((event?: GestureEvent) => {
                    if (event === undefined) {
                      return;
                    }
                    this.mAction.uiDisabled();
                    this.clearTimer();
                    if (this.bigTextTimer) {
                      clearTimeout(this.bigTextTimer);
                    }
                  })
                  .onActionEnd((event?: GestureEvent) => {
                    this.tapGestureResponse(event);
                    this.onLongPressGestureEnd(event);
                  })
                  .onActionCancel((event?: GestureEvent) => this.onLongPressGestureEnd(event)),
              )
            )
            .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
            .accessibilityText(this.getABText())
            .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_slider_description')))
            .id(ComponentIdKeys.EXPOSURE_BAR_VIEW)
        }
      }
      .offset(this.isShowSemiCollapsed ? { x: -7, y: 3 } : { x: -6, y: 0 })
      .width(IMAGE_ELEMENT_LENGTH)
      .height(this.sliderCanvasHeight)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)

    .opacity(this.exposureOpacity)
    .onAppear(() => {
      if (this.enableScreenReader) {
        AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.EXPOSURE_BAR_VIEW)
      }
      this.exposureOpacity = 0;
      animateToImmediately({
        delay: 100,
        duration: 200,
        curve: Curve.Sharp
      }, () => {
        this.exposureOpacity = 1;
      });
    })
    .width(72)
    .height(DeviceInfo.isTablet() ? 340 : 320)
    .justifyContent(FlexAlign.Center)
    .onDisAppear(() => {
      this.exposureOpacity = 1;
      animateToImmediately({
        delay: 0,
        duration: 200,
        curve: Curve.Sharp
      }, () => {
        this.exposureOpacity = 0;
      });
    })
  }

  private changeExposureToState(newLapseAutoState: number): void {
    this.globalAutoChangeFlag = true;
    if (newLapseAutoState === 0) {
      let initIndex = this.valuesRange.findIndex(index => {
        return Number(index) === 0;
      });
      this.screenY = this.getScreenYByIndex(initIndex);
      this.changeExposureModeFunctionValue(0);
      this.canvasInit();
    }
    this.setTimeout();
    this.globalAutoChangeFlag = false;
  }

  private getScreenYByIndex(initIndex: number): number {
    return this.bothSidesPadding + this.longWhiteLineHeight / 2 + initIndex * (this.segLength / this.gapNumInEachSeg);
  }
}