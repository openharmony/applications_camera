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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { OhCombinedState, Dispatch, reduxSubscribe } from '../../redux';
import lazy { RecordingState } from '../recordcontrol/RecordAction';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import camera from '@ohos.multimedia.camera';
import lazy { ChangeState, Unsubscribe } from '../../redux/Store';
import lazy { ZoomAction } from './ZoomAction';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { ZoomFuncValueStruct } from './ZoomStruct';
import lazy { Configuration, curves } from '@kit.ArkUI';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import ResGetter from '../../utils/ResGetter';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public uiEnable: boolean = false;
  public videoState: RecordingState = RecordingState.READY;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public zoomRatio: number = 0;
  public isShowZoomView: boolean = false;
  public isShowZoomText: boolean = false;
  public minZoomRatio: number = 0;
  public maxZoomRatio: number = 0;
  public xComponentWidth: number = 0;
}

class ZoomViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  // autoTriggered true-则代表是手动触发变焦了  false、默认为自动变焦场景
  public changeFunctionValue(id: FunctionId, value: ZoomFuncValueStruct, autoTriggered?: boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
    if (id === FunctionId.ZOOM && !autoTriggered && value?.zoomRatio) {
      this.mDispatch(ZoomAction.changedZoomByGesture());
    }
  }
}

/* instrument ignore file */
const TAG: string = 'ZoomViewVde';
const ICON_OUTER_HEIGHT = 44;
const ICON_HEIGHT = 24;
const QUICK_VIDEO_ZOOM_VALUE_RANGE: number[] = [0.53, 1, 2];
const QUICK_PHOTO_ZOOM_VALUE_RANGE: number[] = [0.55, 1, 2];

@Component
export struct ZoomViewVde {
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State curZoomValue: number = 1;
  @State curZoomValueIndex: number = 1;
  @State zoomRatio: number = 1;
  private mAction: ZoomViewDispatcher = new ZoomViewDispatcher();
  @State circleScale: number = AnimSpecifications.SCALE_ORIGINAL;
  @Prop @Watch('onRotateAngle') iconAngleRotate: number = 0;
  @State angleRotateShow: number = 0;
  // 环形补光
  @State isShowRingLightView: boolean = false;
  @State isShowBigText: boolean = false; // 是否显示变焦大字体
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  private bigTextTimerId: number = Number.MIN_VALUE; // 变焦大字体定时器Id
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        zoomRatio: state.get<number>('zoomReducer', 'zoomRatio'),
        isShowZoomView: state.get<boolean>('zoomReducer', 'isShowZoomView'),
        isShowZoomText: state.get<boolean>('zoomReducer', 'isShowZoomText'),
        minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
        maxZoomRatio: state.get<number>('zoomReducer', 'maxZoomRatio'),
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
      });
      this.zoomRatio = state.get<number>('zoomReducer', 'zoomRatio');
      this.iconAngleRotate = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.angleRotateShow = this.iconAngleRotate;
    // 响应捏合变焦处理
    this.mEventBus.on(ZoomActionType.ACTION_SWITCH_ZOOM_RATIO, this.onSwitchZoomRatio.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      this.updateZoomRatio.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.checkAndResetZoomRatio();
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  onForeground(): void {
    this.checkAndResetZoomRatio();
  }

  build() {
    RelativeContainer() {
      this.SwitcherButtonBuilder();
      if (this.isShowBigText) {
        this.bigTextView();
      }
    }
    .accessibilityText(`${this.getQuickZoomABText(this.curZoomValue)}} ${
    ResGetter.getStringSafe($r('app.string.accessibility_button'))}`)
    .onClick((event?: ClickEvent) => {
      this.changeQuickZoomValue();
    })
    .key(ComponentIdKeys.QUICK_ZOOM_BAR)
    .width(PickerUtils.getIsPicker() ? 28 : ICON_OUTER_HEIGHT)
    .aspectRatio(1)
  }

  @Builder
  SwitcherButtonBuilder() {
    Column()
      .id('Circle')
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .width(28)
      .height(28)
      .border({
        width: 1.5,
        color: Color.White,
        radius: 22,
        style: BorderStyle.Solid
      })
      .backgroundColor('#334d4d4d')
      .scale({
        x: this.circleScale,
        y: this.circleScale
      })

    Text(this.getZoomValueText())
      .width(ICON_HEIGHT)
      .height(ICON_HEIGHT)
      .aspectRatio(1)
      // 关怀模式-大字体中字体大小不随系统变化
      .fontSize('10vp')
      .fontColor(Color.White)
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Center)
      .draggable(false)
      .id('RotateImageView')
      .rotate({ angle: this.angleRotateShow })
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
  }

  changeQuickZoomValue(): void {
    let tmpIndex: number = this.curZoomValueIndex;
    tmpIndex = (tmpIndex + 1) % QUICK_VIDEO_ZOOM_VALUE_RANGE.length;
    // 人像模式不支持广角
    if (tmpIndex === 0) {
      tmpIndex++;
    }
    this.curZoomValueIndex = tmpIndex;
    if (this.state.mode === ModeType.PHOTO) {
      this.curZoomValue = QUICK_PHOTO_ZOOM_VALUE_RANGE[this.curZoomValueIndex];
    } else {
      this.curZoomValue = QUICK_VIDEO_ZOOM_VALUE_RANGE[this.curZoomValueIndex];
    }
    AccessibilityUtils.sendAnnounceAccessibilityEvent(
      ResGetter.getStringSafe(`${ResGetter.getStringSafe($r('app.string.accessibility_checked'))} ${
      this.getQuickZoomABText(this.curZoomValue)}`));
    this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue, isPrepareZoom: true, isUnprepareZoom: true }, true);
    this.clearAndSetBigTextTimer();
    this.isShowBigText = true;
  }

  getZoomValueText(): string {
    if (this.curZoomValue < 1) {
      return 'W';
    }
    return this.curZoomValue + 'x';
  }

  private changeZoomFunctionValue(zoomData: ZoomFuncValueStruct, autoTriggered?: boolean): void {
    this.mAction.changeFunctionValue(FunctionId.ZOOM, zoomData, autoTriggered);
  }

  /**
   * 前置捏合变焦场景
   */
  private onSwitchZoomRatio(data: Record<'toNext', boolean>): void {
    if (data.toNext && this.curZoomValueIndex < QUICK_PHOTO_ZOOM_VALUE_RANGE.length - 1) {
      if (this.state.mode === ModeType.PHOTO) {
        this.curZoomValue = QUICK_PHOTO_ZOOM_VALUE_RANGE[this.curZoomValueIndex + 1];
      } else {
        this.curZoomValue = QUICK_VIDEO_ZOOM_VALUE_RANGE[this.curZoomValueIndex + 1];
      }
      this.curZoomValueIndex++;
      HiLog.i(TAG, `pinch to switch Zoom value : ${this.curZoomValue}.`);
      this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
      return;
    }
    if (!data.toNext && this.curZoomValueIndex > 0) {
      // 人像模式不支持广角
      if (this.state.mode === ModeType.PHOTO) {
        this.curZoomValue = QUICK_PHOTO_ZOOM_VALUE_RANGE[this.curZoomValueIndex - 1];
      } else {
        this.curZoomValue = QUICK_VIDEO_ZOOM_VALUE_RANGE[this.curZoomValueIndex - 1];
      }
      this.curZoomValueIndex--;
      HiLog.i(TAG,
        `pinch to switch Zoom value: ${this.curZoomValue}, index: ${this.curZoomValueIndex}, mode: ${this.state.mode}.`);
      this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
      return;
    }
  }

  private updateZoomRatio(): void {
    // 模式切换复位变焦值
    this.curZoomValue = 1;
    this.curZoomValueIndex = 1;
    this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
  }

  private onRotateAngle() {
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.angleRotateShow = this.iconAngleRotate;
    });
  }

  @Builder
  bigTextView(): void {
    Text(this.getZoomValueText())
      .fontSize(vp2px(px2fp(24)))
      .fontWeight(FontWeight.Medium)
      .width(40)
      .height(40)
      .textAlign(TextAlign.Center)
      .textShadow({
        radius: 2,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .fontColor(Color.White)
      .rotate({
        centerX: '50%',
        centerY: '50%',
        angle: this.iconAngleRotate,
      })
      .position(this.getBigTextPosition())
      .transition(this.getBigTextAppearDisappearAnim())
      .onAppear((): void => {
        this.clearAndSetBigTextTimer(); // 设置定时器
      })
      .onDisAppear((): void => {
      })
      .hitTestBehavior(HitTestMode.Transparent)
      .key(ComponentIdKeys.ZOOM_BIG_TEXT)
  }

  private clearAndSetBigTextTimer(): void {
    this.clearBigTextTimer();
    this.bigTextTimerId = setTimeout((): void => {
      this.isShowBigText = false;
    }, 1500);
  }

  private clearBigTextTimer(): void {
    if (this.bigTextTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.bigTextTimerId);
      this.bigTextTimerId = Number.MIN_VALUE;
    }
  }


  private getBigTextPosition(): Position {
    return {
      x: SystemLanguageUtil.isRTL() ? 76 : -66,
      y: -118
    };
  }

  private getBigTextAppearDisappearAnim(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect // 大字体进场动效
        .scale({ x: 0.9, y: 0.9 })
        .animation({
          duration: 500,
          curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
        })
        .combine(TransitionEffect.OPACITY
          .animation({
            duration: 100,
            curve: Curve.Sharp
          })),
      TransitionEffect // 大字体退场动效
        .scale({ x: 0.9, y: 0.9 })
        .animation({
          duration: 250,
          curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
        })
        .combine(TransitionEffect.OPACITY
          .animation({
            duration: 250,
            curve: curves.cubicBezierCurve(0, 0, 0, 1)
          }))
    );
  }

  private checkAndResetZoomRatio() {
    if (this.zoomRatio > QUICK_PHOTO_ZOOM_VALUE_RANGE[2] || this.zoomRatio < QUICK_PHOTO_ZOOM_VALUE_RANGE[0]) {
      HiLog.i(TAG, 'zoomRatio out of range, resetZoomRatio to default value');
      this.updateZoomRatio();
    }
  }

  private getQuickZoomABText(zoomVal: number): string {
    if (zoomVal < 1) {
       return ResGetter.getStringSafe($r('app.string.wide_angle'));
    }
    return getContext(this)
      .resourceManager
      .getPluralStringValueSync($r('app.plural.accessibility_tips_zoom_scale_new').id, zoomVal);
  }
}