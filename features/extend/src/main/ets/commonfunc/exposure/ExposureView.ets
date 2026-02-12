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
import lazy { OhCombinedState, Unsubscribe, Dispatch, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import camera from '@ohos.multimedia.camera';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import lazy { ChangeState } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ZoomActionType } from '@ohos/common/src/main/ets/redux/actions/ZoomActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { ExposureData, CANVAS_WIDTH, CANVAS_HEIGHT } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';

/* instrument ignore file */
const TAG: string = 'ExposureView';

class StateStruct {
  public xComponentWidth: number = 0;
  public xComponentHeight: number = 0;
  public isShowExposureRing: boolean = false;
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

  public changeTabBarSelector(id: FunctionId): void {
    this.mDispatch(TabBarAction.changeTabBarSelector(id, RenderLocation.NONE));
  }
}

const DOT_RADIUS: number = 2 / 2;// 滑动条圆点
const TOP_PADDING: number = 11; // canvas顶部距首个点顶侧gap
const ICON_SIZE: number = 24;// 滑动图标size
const SPOT_COUNT: number = 17; // 滑动条圆点总数
// 前一点下侧距后一点上侧gap
const DOT_GAP: number = (CANVAS_HEIGHT - TOP_PADDING * 2 - DOT_RADIUS * 2 * SPOT_COUNT) / (SPOT_COUNT - 1);

@Component
export struct ExposureView {
  @State state: StateStruct = new StateStruct();
  private mAction: ExposureDispatcher = new ExposureDispatcher();
  @Link isShowExposureSlider: boolean;
  @Link isShowExposureValue: boolean;
  private exposureSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private exposureCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.exposureSettings);
  private exposureOffCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    CANVAS_WIDTH, CANVAS_HEIGHT, this.exposureSettings);
  private exposureImg: ImageBitmap = new ImageBitmap('/res/ic_camera_public_focus_ev_bright_normal.svg'); // 仅支持ets下
  @Link isExposureChangedEnd: boolean; // 用于记录滑动的终止动作
  @Link @Watch('canvasInit') screenExposureY: number; // 实时更新Y,滑动图标中心Y
  @State exposureValue: number = 0; // 曝光值
  @State exposureValuePreview: number = 0; // 曝光值
  @State fillRectStartY: number = 48; // 用于滑动过程中字符动态position显示
  private mSubscriber: Unsubscribe | null = null;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State rotateAngle: number = 0;
  @Prop focusPosition: PositionType = { x: 0, y: 0 };
  @Prop exposurePosition: PositionType = { x: 0, y: 0 };
  @State videoState: RecordingState = RecordingState.READY;
  private mFocusExposureService: FocusExposureService = FocusExposureService.getInstance();
  @State mode: ModeType = ModeType.NONE;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        xComponentHeight: state.get<number>('previewReducer', 'xComponentHeight'),
        isShowExposureRing: state.get<boolean>('focusExposureReducer', 'isShowExposureRing'),
      });
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  aboutToDisappear() {
    this.hideExposureView();
    this.mSubscriber?.destroy();
  }

  private hideExposureView(): void {
    HiLog.i(TAG, 'hideExposureView invoke E.');
    this.isShowExposureSlider = false;
    this.screenExposureY = 60; // 立即触发移除滑动条
    this.isShowExposureValue = false;
    HiLog.i(TAG, 'hideExposureView invoke X.');
  }

  private canvasInit(): void {
    this.exposureCanvasContext.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    this.exposureOffCanvasCtx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    this.exposureOffCanvasCtx.strokeStyle = '#FFFFFF';
    this.exposureOffCanvasCtx.fillStyle = '#FFFFFF';
    this.exposureOffCanvasCtx.lineWidth = 1.5;
    this.fillRectStartY = this.screenExposureY - ICON_SIZE / 2;
    if (this.fillRectStartY < TOP_PADDING + DOT_RADIUS - ICON_SIZE / 2) {
      this.fillRectStartY = TOP_PADDING + DOT_RADIUS - ICON_SIZE / 2; // 图标上侧滑动的上限
    } else if (this.fillRectStartY > CANVAS_HEIGHT - TOP_PADDING - DOT_RADIUS - ICON_SIZE / 2) {
      // 图标上侧滑动的下限
      this.fillRectStartY = CANVAS_HEIGHT - TOP_PADDING - DOT_RADIUS - ICON_SIZE / 2;
    }

    if (this.isShowExposureSlider) {
      this.exposureOffCanvasCtx.shadowBlur = 3;
      this.exposureOffCanvasCtx.shadowOffsetX = 0;
      this.exposureOffCanvasCtx.shadowOffsetY = 0;
      this.exposureOffCanvasCtx.shadowColor = '#4d000000';
      for (let i = 0; i < SPOT_COUNT; i++) {
        let dotCenterY: number = TOP_PADDING + DOT_RADIUS + i * (DOT_GAP + DOT_RADIUS * 2);
        if ((dotCenterY - DOT_RADIUS > this.fillRectStartY &&
          dotCenterY - DOT_RADIUS < this.fillRectStartY + ICON_SIZE) ||
          (dotCenterY + DOT_RADIUS > this.fillRectStartY &&
            dotCenterY + DOT_RADIUS < this.fillRectStartY + ICON_SIZE)) {
          continue;
        }
        this.exposureOffCanvasCtx.beginPath();
        this.exposureOffCanvasCtx.arc(CANVAS_WIDTH / 2, dotCenterY, DOT_RADIUS, 0, 6.28);
        this.exposureOffCanvasCtx.fill();
      }
    }
    this.exposureOffCanvasCtx.globalAlpha = 1;
    this.exposureOffCanvasCtx.clearRect(CANVAS_WIDTH / 2 - ICON_SIZE / 2,
      this.fillRectStartY, ICON_SIZE, ICON_SIZE);
    this.exposureOffCanvasCtx.drawImage(this.exposureImg, CANVAS_WIDTH / 2 - ICON_SIZE / 2,
      this.fillRectStartY, ICON_SIZE, ICON_SIZE);
    this.exposureCanvasContext.transferFromImageBitmap(this.exposureOffCanvasCtx.transferToImageBitmap());

    let slidingDistance: number = this.fillRectStartY + ICON_SIZE / 2 - TOP_PADDING - DOT_RADIUS;
    let totalSlidingDistance: number = CANVAS_HEIGHT - (TOP_PADDING + DOT_RADIUS) * 2;
    this.exposureValue = - slidingDistance / totalSlidingDistance * 8 + 4; // 计算曝光值,[0, 1]映射为[-4, 4]
    let isNeedVibrator = (Math.abs(this.exposureValuePreview).toFixed(1) !== Math.abs(this.exposureValue)
      .toFixed(1)) && !this.isExposureChangedEnd;
    if (isNeedVibrator && this.videoState !== RecordingState.RECORDING) {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
    this.exposureValuePreview = this.exposureValue;
    HiLog.d(TAG, `canvasInit screenExposureY ${this.screenExposureY}, exposureValue: ${this.exposureValue}`);
    this.mFocusExposureService.setExposureValue({ exposureValue: parseFloat(this.exposureValue.toFixed(1)) });
  }

  private getExposureTextPosition(mDirection: number): Position {
    let positionX: number = 0;
    switch (mDirection) {
      case WindowDirection.TOP:
        positionX = this.focusPosition.x < this.state.xComponentWidth / 2 ? -80 : 44;
        break;
      case WindowDirection.BOTTOM:
        positionX = this.focusPosition.x < this.state.xComponentWidth / 2 ? 44 : -80;
        break;
      case WindowDirection.LEFT:
        positionX = this.focusPosition.y < this.state.xComponentHeight / 2 ? 44 : -80;
        break;
      case WindowDirection.RIGHT:
        positionX = this.focusPosition.y < this.state.xComponentHeight / 2 ? -80 : 44;
        break;
      default:
        positionX = 0;
        break;
    }
    return { x: positionX, y: this.fillRectStartY + ICON_SIZE / 2 - 40 };
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
      Column() {
        if (!this.state.isShowExposureRing) {
          Canvas(this.exposureCanvasContext)
            .width(CANVAS_WIDTH)
            .height(CANVAS_HEIGHT)
            .onReady((): void => this.canvasInit())
        } else {
          Stack() {
            Column()
              .width(40)
              .height(40)
              .border({ width: 1, color: Color.White, style: BorderStyle.Solid })
              .shadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
              .borderRadius(50)
            Image($r('app.media.ic_camera_exposure'))
              .width(24)
              .height(24)
          }
        }

      }.width(44)
      .height(this.state.isShowExposureRing ? 40 : 120)

      Row() {
        Column() {
          if (Number(this.exposureValue.toFixed(1)) !== 0.0) {
            Image(Number(this.exposureValue.toFixed(1)) > 0 ? $r('app.media.ic_camera_public_focus_ev_bright_add') :
            $r('app.media.ic_camera_public_focus_ev_bright_subtract'))
              .width(24)
              .height(24)
              .draggable(false)
              .objectFit(ImageFit.Contain)
          }
        }
        .width(24)
        .height(24)

        Text(Math.abs(this.exposureValue).toFixed(1))
          .width(56)
          .height(53)
          .fontSize(40)
          .maxFontScale(1)
          .fontColor(Color.White)
          .fontWeight(300)
          .textAlign(TextAlign.Center)
          .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
          .fontFeature('\"ss01\" on')
      }
      .width(80)
      .height(80)
      .alignItems(VerticalAlign.Center)
      .position(this.getExposureTextPosition(this.mDirection))
      .visibility(this.isShowExposureValue ? Visibility.Visible : Visibility.Hidden)
    }.width(44).height(this.state.isShowExposureRing ? 40 : 120)
  }
}