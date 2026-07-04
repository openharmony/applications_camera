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
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { Dispatch } from '@ohos/common/src/main/ets/redux';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import lazy { getColorString } from '@ohos/common/src/main/ets/utils/ColorUtil';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { FocusModeEffectMode } from '@ohos/common/src/main/ets/function/enumbase/FocusModeEffectMode';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { ShutterEffectMode } from '@ohos/common/src/main/ets/function/enumbase/ShutterEffectMode';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { HdrBrightnessUtil } from '@ohos/common/src/main/ets/utils/HdrBrightnessUtil';

/* instrument ignore file */
const TAG: string = 'StandardSlider';

const MF_ARRAY_LENGTH = 27;

class StandardSliderDispatcher {
  private mDispatch: Dispatch = (data) => data;

  private mMode: ModeType = ModeType.NONE;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public setMode(mode: ModeType) {
    this.mMode = mode;
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    if (this.mMode === ModeType.TIME_LAPSE) {
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

class IdentifierValueStruct {
  public isBeautySkin: boolean = false;
  public beautySkinTitle: Resource | string = '';
  public isUpperCase: boolean = false; // StandardSlider上文字是否大写
}

const STANDARD_CANVAS_WIDTH: number = 340;
const STANDARD_SLIDER_PADDING: number = 20;

@Component
export struct StandardSlider {
  private timeLapse = -1;
  private initValue: number = 3;
  private unit: String = '';
  private showUnit: boolean = false;
  private segCount: number = 5; // segment数
  private gapNumInEachSeg: number = 6; // 每段的间隙数 = 每段的分割数,general: 1 longWhiteLine + N redLine
  private valueRange: string[] = []; //
  private changeFunctionValue: Function = () => {
  };
  private setTimeout: Function = () => {
  };
  private clearTimeout: Function = () => {
  };
  private sliderCanvasWidth: number = STANDARD_CANVAS_WIDTH; // canvas组件宽度,直板机一般360
  private sliderCanvasHeight: number = 80; // 一般用于控制底部
  private longWhiteLineHeight: number = 10; // 滑动条细长白线高
  private longWhiteLineWidth: number = 1.5; // 滑动条细长白线宽
  private shortWhiteLineHeight: number = 5; // 滑动条细短白线高
  private shortWhiteLineWidth: number = 1.5; // 滑动条细短白线宽
  private redLineHeight: number = 20; // 滑动条粗红线高,直线段为20-2-2,lineTo起点终点在直线段首尾端
  private redLineWidth: number = 4; // 滑动条粗红线宽
  private bottomPadding: number = 31;
  private bothSidesPadding: number = STANDARD_SLIDER_PADDING; // 左侧距首点左侧、右侧距尾点右侧 padding
  private segLength: number = (this.sliderCanvasWidth - this.bothSidesPadding * 2 - this.longWhiteLineWidth) /
  this.segCount; // 前一大点中间距后一大点中间,即28.85 两个长白线之间的距离
  private dotDistance: number = this.segLength / this.gapNumInEachSeg; // 前一点中间距后一点中间,即9.5
  private spotCount: number = this.segCount * this.gapNumInEachSeg + 1; // 总点数
  private mStoreManager: StoreManager = StoreManager.getInstance();
  @State isSliding: boolean = false; // 用于滑动过程中
  @State @Watch('canvasInit') screenX: number = this.bothSidesPadding + this.longWhiteLineWidth / 2 + this.initValue *
  this.dotDistance; // 粗红线中心位置
  private gestureStartX: number = 0; // 单次滑动起始位置缓存
  @State sliderValue: number = 0; // 用于显示值
  private lastFloatValue: number = 0;
  private isPanGesStartEndOrTap: boolean = false;
  private sliderSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private sliderCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.sliderSettings);
  private sliderOffCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.sliderCanvasWidth, this.sliderCanvasHeight, this.sliderSettings);
  private mAction: StandardSliderDispatcher = new StandardSliderDispatcher();
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State titlePosition: PositionType = this.getTitlePosition();
  @State rotateAngle: number = 0;
  private readonly ONE_RADIAN: number = Math.PI / 180;
  private mSubscriber: Unsubscribe | null = null;
  private bigTextTimer: number = setTimeout((): void => {}); // 大字体消失延时器
  @State bigTextOpacity: number = 0;
  private readonly BIG_TEXT_DISAPPEAR_DURATION: number = 350;
  private tips: String[] = [];
  @StorageLink('showFilmingTime') showFilmingTime: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @Prop isHdr: boolean = false;

  aboutToAppear() { // 组件复用,要重新计算值
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.mAction.setMode(state.get<ModeType>('modeReducer', 'mode'));
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.sliderCanvasWidth = Math.min(this.sliderCanvasWidth, getStates().get<number>('windowReducer', 'windowWidth'));
    this.bothSidesPadding = Math.min(this.bothSidesPadding, (this.sliderCanvasWidth - (this.sliderCanvasWidth -
      this.bothSidesPadding * 2)) / 2);
    this.segLength = (this.sliderCanvasWidth - this.bothSidesPadding * 2 - this.longWhiteLineWidth) / this.segCount;
    this.dotDistance = this.segLength / this.gapNumInEachSeg;
    this.spotCount = this.segCount * this.gapNumInEachSeg + 1;
    this.screenX = this.bothSidesPadding + this.longWhiteLineWidth / 2 + this.initValue * this.dotDistance; // 粗红线中心位置
    this.sliderValue = this.initValue;
    this.lastFloatValue = this.initValue;
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
  }

  private async directionChange() {
    HiLog.i(TAG, 'directionChange E');
    if (!this.isSliding) {
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
    //用来填充刻度的临界点
    let fillRectCenterX = this.getFillRectCenterX(this.screenX);
    let curFloatValue = (fillRectCenterX - this.bothSidesPadding - this.longWhiteLineWidth / 2) /
      (this.sliderCanvasWidth - 2 * this.bothSidesPadding - this.longWhiteLineWidth);
    let nextValue = Number(curFloatValue.toFixed(3));
    if (this.isPanGesStartEndOrTap && this.sliderValue !== nextValue) {
      this.sliderValue = nextValue; // 返回的是位置
      this.changeFunctionValue(0, Number(this.sliderValue));
      this.initValue = Number(this.sliderValue) * MF_ARRAY_LENGTH;
    }
    this.lastFloatValue = curFloatValue;
    HiLog.d(TAG, `canvasInit ${this.initValue}`);
    this.redrawCanvas(fillRectCenterX); // 离屏重绘制canvas
    this.sliderCanvasContext.transferFromImageBitmap(this.sliderOffCanvasCtx.transferToImageBitmap());
  }

  private getTitlePosition(): PositionType {

    return {
      x: 87,
      y: (this.mDirection === WindowDirection.LEFT || this.mDirection === WindowDirection.RIGHT) ? -120 : -91,
    }
  }

  private drawLongScale(commonLength: number): void {
    this.sliderOffCanvasCtx.globalAlpha = 1;
    this.sliderOffCanvasCtx.fillStyle = '#ffffff';
    this.sliderOffCanvasCtx.shadowColor = '#4d000000';
    this.sliderOffCanvasCtx.shadowBlur = 3;
    this.sliderOffCanvasCtx.fillRect(commonLength - this.longWhiteLineWidth / 2, this.sliderCanvasHeight -
    this.bottomPadding - this.longWhiteLineHeight, this.longWhiteLineWidth, this.longWhiteLineHeight);
  }

  private drawShortScale(commonLength: number): void {
    this.sliderOffCanvasCtx.globalAlpha = 0.6;
    this.sliderOffCanvasCtx.shadowColor = '#33000000';
    this.sliderOffCanvasCtx.shadowBlur = 3;
    this.sliderOffCanvasCtx.fillRect(commonLength - this.shortWhiteLineWidth / 2, this.sliderCanvasHeight -
    this.bottomPadding - this.shortWhiteLineHeight, this.shortWhiteLineWidth, this.shortWhiteLineHeight);
  }

  private redrawCanvas(fillRectCenterX: number): void {
    for (let i = 0; i < this.spotCount; i++) {
      let commonLength: number = this.bothSidesPadding + this.longWhiteLineWidth / 2 +
        Math.floor(i / this.gapNumInEachSeg) * this.segLength + (i % this.gapNumInEachSeg) * this.dotDistance;
      let fontText = `${this.valueRange[i].toString()} ${this.showUnit ? this.unit : ''}`;
      let fontPosYGap = this.isSliding ? 29 : 27;
      this.sliderOffCanvasCtx.rotate(0);
      if (this.mDirection === WindowDirection.LEFT || this.mDirection === WindowDirection.RIGHT) {
        fontPosYGap = this.isSliding ? 38 : 36;
      }
      let fontTextPos = this.getTextPosition({
        x: commonLength,
        y: this.sliderCanvasHeight - this.bottomPadding - fontPosYGap
      });
      this.sliderOffCanvasCtx.globalAlpha = 1;
      this.sliderOffCanvasCtx.font = `bold ${vp2px(11)}px`;
      this.sliderOffCanvasCtx.textAlign = 'center';
      this.sliderOffCanvasCtx.textBaseline = 'middle';
      this.sliderOffCanvasCtx.shadowColor = '#33000000';
      this.sliderOffCanvasCtx.shadowBlur = 3;
      if ((i % this.gapNumInEachSeg !== 0)) {
        this.sliderOffCanvasCtx.globalAlpha = 0;
        this.sliderOffCanvasCtx.shadowColor = '#00000000';
      }
      this.sliderOffCanvasCtx.font = 'bold 11';
      this.sliderOffCanvasCtx.rotate(DirectionToAngleUtil.geViewRotate(this.mDirection) * this.ONE_RADIAN);
      if (this.timeLapse !== FocusModeEffectMode.FOCUS_MODE_MANUAL) { // 存在图标则删除
        this.sliderOffCanvasCtx.fillText(fontText, fontTextPos.x, fontTextPos.y);
      }
      this.sliderOffCanvasCtx.rotate(-DirectionToAngleUtil.geViewRotate(this.mDirection) * this.ONE_RADIAN);
      if (i % this.gapNumInEachSeg === 0) {
        this.drawLongScale(commonLength);
      } else {
        this.drawShortScale(commonLength);
      }
    }
    if (this.sliderValue !== -1) {
      this.sliderOffCanvasCtx.beginPath();
      this.sliderOffCanvasCtx.globalAlpha = 1;
      this.sliderOffCanvasCtx.lineWidth = this.redLineWidth;
      this.sliderOffCanvasCtx.lineCap = 'round';
      this.sliderOffCanvasCtx.strokeStyle = getColorString();
      this.sliderOffCanvasCtx.moveTo(fillRectCenterX, this.sliderCanvasHeight - (this.bottomPadding - 1) -
        this.redLineWidth / 2);
      this.sliderOffCanvasCtx.lineTo(fillRectCenterX, this.sliderCanvasHeight - (this.bottomPadding - 1) -
      this.redLineHeight + this.redLineWidth / 2);
      this.sliderOffCanvasCtx.stroke();
    }
  }

  private getFillRectCenterX(mScreenX: number): number {
    let fillRectCenterX = mScreenX;
    if (fillRectCenterX < this.bothSidesPadding + this.longWhiteLineWidth / 2) {
      fillRectCenterX = this.bothSidesPadding + this.longWhiteLineWidth / 2;
    } else if (fillRectCenterX > this.sliderCanvasWidth - this.bothSidesPadding - this.longWhiteLineWidth / 2) {
      fillRectCenterX = this.sliderCanvasWidth - this.bothSidesPadding - this.longWhiteLineWidth / 2;
    }
    return fillRectCenterX;
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

  // 获取手势事件的localX
  private getFingerListLocalX(event: GestureEvent): number | null {
    let localX: number | null = null;
    event.fingerList.forEach((eventItem: FingerInfo) => {
      if (eventItem) {
        localX = eventItem?.localX;
        return;
      }
    });
    return localX;
  }

  private tapGestureResponse(event?: GestureEvent): void {
    if (event === undefined) {
      return;
    }
    this.clearTimeout();
    this.isPanGesStartEndOrTap = true;
    if (this.enableScreenReader) {
      const initValue = this.initValue / MF_ARRAY_LENGTH + 0.01 > 1 ? 0 :
        this.initValue / MF_ARRAY_LENGTH + 0.01;
      this.screenX = this.bothSidesPadding + this.longWhiteLineWidth / 2 +
        initValue * (this.sliderCanvasWidth - 2 * this.bothSidesPadding - this.longWhiteLineWidth);
      AccessibilityUtils.sendAnnounceAccessibilityEvent(`${this.initValue.toFixed(2)}`)
    } else {
      let localX = this.getFingerListLocalX(event);
      if (!localX) {
        return;
      }
      this.screenX = localX; // 双击文本的时候
    }
    this.isPanGesStartEndOrTap = false;
    this.setTimeout();
    this.setBigTextTimer();
  }

  private onPanGestureEnd(event?: GestureEvent): void {
    if (event === undefined) {
      return;
    }
    this.isPanGesStartEndOrTap = true;
    this.gestureStartX = this.screenX; // 手指抬起来的时候
    if (this.enableScreenReader) {
      AccessibilityUtils.sendAnnounceAccessibilityEvent(`${this.initValue.toFixed(2)}`)
    }
    this.isPanGesStartEndOrTap = false;
    this.isSliding = false;
    this.setBigTextTimer();
    this.setTimeout();
    this.mAction.isEnterImmersive(false);
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

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
      Column() {
        Row() {
          Image($r(null))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .margin({
              left: 3,
              right: SystemLanguageUtil.isRTL() ? 3 : 0
            })
            .draggable(false)
            .rotate({ angle: this.rotateAngle })
            .foregroundFilter(HdrBrightnessUtil.getHdrFilter(this.isHdr))
          Image($r(null))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .margin({
              right: 3,
              left: SystemLanguageUtil.isRTL() ? 3 : 0
            })
            .draggable(false)
            .rotate({ angle: this.rotateAngle })
            .foregroundFilter(HdrBrightnessUtil.getHdrFilter(this.isHdr))
        }
        .visibility(this.timeLapse !== FocusModeEffectMode.FOCUS_MODE_MANUAL ? Visibility.Hidden : Visibility.Visible)
        .width(STANDARD_CANVAS_WIDTH - 16)
        .justifyContent(
          FlexAlign.SpaceBetween
        ).position({
          x: 0,
          y: this.isSliding ? 4 : 6
        })

        Row() {
          Canvas(this.sliderCanvasContext)
            .width(this.sliderCanvasWidth)
            .height(this.sliderCanvasHeight)
            .onReady((): void => {
              this.canvasInit();
            })
            .gesture(
              GestureGroup(
                GestureMode.Exclusive,
                PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
                  .onActionStart((event?: GestureEvent) => {
                    if (event === undefined) {
                      return;
                    }
                    this.mAction.uiDisabled();
                    this.mAction.isEnterImmersive(true);
                    this.clearTimeout();
                    let localX = this.getFingerListLocalX(event);
                    if (!localX) {
                      return;
                    }
                    this.gestureStartX = localX;
                    this.isSliding = true;
                    this.isPanGesStartEndOrTap = true;
                    this.screenX = localX;
                    this.isPanGesStartEndOrTap = false;
                    this.clearBigTextTimer();

                  })
                  .onActionUpdate((event?: GestureEvent) => {
                    if (event === undefined) {
                      return;
                    }
                    this.isPanGesStartEndOrTap = true;
                    this.screenX = (this.gestureStartX + event.offsetX);
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
                    this.tapGestureResponse(event);
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
                  .onActionEnd((event?: GestureEvent) => {
                    this.tapGestureResponse(event);
                    this.onLongPressGestureEnd(event);
                  })
                  .onActionCancel((event?: GestureEvent) => this.onLongPressGestureEnd(event)),
              )
            )
            .key(ComponentIdKeys.getInstance().getKey('FocusModeView', FunctionId.FOCUS, ShutterEffectMode.AUTO))
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
      .height(80)
    }
  }


  private getABText(): string {
    return `${ResGetter.getStringSafe($r('app.string.accessibility_focus_mode_manual'))}
    ${this.initValue.toFixed(2)}`;
  }

  private getNextScreenX(mScreenX: number): number {
    let fillRectCenterX = this.getFillRectCenterX(mScreenX);
    // 将位置换成了刻度条位置
    let curFloatValue = (fillRectCenterX - this.bothSidesPadding - this.longWhiteLineWidth / 2) / (this.segCount *
    this.segLength) * (this.segCount * this.gapNumInEachSeg);
    let nextValue = Number(curFloatValue.toFixed(0));
    // 将刻度换成了位置
    let nextScreenX = nextValue / (this.segCount * this.gapNumInEachSeg) * (this.segCount * this.segLength) +
    this.bothSidesPadding + this.longWhiteLineWidth / 2;
    HiLog.i(TAG, `this.screenX: ${this.screenX}, this.sliderValue: ${this.sliderValue}, nextScreenX: ${nextScreenX}.`);
    return nextScreenX;
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