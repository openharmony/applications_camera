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
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { CaptureService } from '../capture/CaptureService';
import lazy { Action } from '../../redux/actions/Action';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { CaptureAction } from '../capture/CaptureAction';
import lazy { OhCombinedState, Dispatch, Unsubscribe, getStates } from '../../redux';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { RecordingState } from './RecordAction';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { LogStyleMode } from '../enumbase/LogStyleMode';
import lazy { reduxSubscribe } from '../../redux/Store';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';

/* instrument ignore file */
const TAG: string = 'RecordingShutterButton';
const RECORDING_CAPTURE_RADIUS: number = 24;

class ThumbnailViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public changeFunctionValue(id: FunctionId, value: number | string | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public proSonChangeState(): void {
    this.mDispatch(Action.proSonChangeState(-1));
  }
}

@Component
export struct RecordingCaptureButton {
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: ThumbnailViewDispatcher = new ThumbnailViewDispatcher();
  private uiEnable: boolean = true;
  @State captureBtnScale: ScaleOptions = { x: 1, y: 1 };
  @State recordThumOpcaity: number = 0;
  @State isShowSubScreenRadius: boolean = false;
  @State density: number = 1 //DisplayService.getInstance().getDisplay().densityPixels;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @Prop isPicker: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @Prop isHdr: boolean = false;
  @State isCaptureButtonShow: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.density = state.get<number>('collapsReducer', 'density');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.isCaptureButtonShow = this.getRecordCaptureVis();
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mSubscriber.destroy();
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  private videoStateOnChange(): void {
    HiLog.i(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    this.isCaptureButtonShow = this.getRecordCaptureVis();
    if (this.videoState === RecordingState.STARTING) {
      this.recordStartAnim();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
    }
  }

  private getRecordCaptureVis(): boolean {
    if (this.isPicker) {
      return false;
    }
    return this.videoState !== RecordingState.READY;
  }

  private recordStartAnim(): void {
    HiLog.i(TAG, 'recordStartAnim');
    this.recordThumOpcaity = 1;
    this.recordStartAnimOp();
  }

  private recordEndAnim(): void {
    HiLog.i(TAG, 'recordEndAnim');
    this.recordThumOpcaity = 1;
    this.captureBtnScale = { x: 1, y: 1 };
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
      }
    }, () => {
      this.captureBtnScale = { x: 0, y: 0 };
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp
    }, () => {
      this.recordThumOpcaity = 0;
    });
  }

  private onPhotoShutterDown(): void {
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
      }
    }, () => {
      this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_DOWN;
    });
  }

  private onPhotoShutterUp(): void {
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_DOWN;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
      }
    }, () => {
      this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    });
  }

  private getCircleBackgroundColor(): ResourceColor {
    return this.videoState === RecordingState.READY || this.videoState === RecordingState.STOPPING ?
      Color.Transparent : '#334d4d4d';
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.isVdeCollapsed ? 28 : 44)
        .aspectRatio(1)
        .border({
          width: 1.5,
          color: Color.White,
          radius: $r('app.float.thumbnail_radius'),
          style: BorderStyle.Solid
        })
        .backgroundColor(this.getCircleBackgroundColor())
        .opacity(this.recordThumOpcaity)
      Column()
        .width(this.isVdeCollapsed ? 18 : 32)
        .aspectRatio(1)
        .borderRadius(this.isShowSubScreenRadius ? RECORDING_CAPTURE_RADIUS : 16)
        .key(ComponentIdKeys.SHUTTER_PHOTO_ON_VIDEO_1)
        .backgroundColor(Color.White)
        .opacity(this.recordThumOpcaity)
        .scale(this.captureBtnScale)
    }
    .visibility(this.isCaptureButtonShow ? Visibility.Visible : Visibility.Hidden)
    .onTouch((event?: TouchEvent) => {
      if (!CaptureService.getInstance().isEnableCapture() || !event || !this.uiEnable ||
        this.videoState === RecordingState.READY) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.onPhotoShutterDown();
      } else if (event.type === TouchType.Up) {
        HiLog.i(TAG, 'capture called.');
        this.onPhotoShutterUp();
        AppStorage.setOrCreate('ShowFlashBlackOpacity', 1);
        this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
        this.mAction.capture();
        this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
      } else if (event.type === TouchType.Cancel) {
        this.onPhotoShutterUp();
      }
    })
    .accessibilityGroup(true)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    // 录像中拍照
    .accessibilityText(ResGetter.getStringSafe($r('app.string.video_mode')) +
      (ResGetter.getStringSafe($r('app.string.photo_mode'))))
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .onclickStyle();
  }

  @Styles
  private onclickStyle() {
    .onClick(((event) => {
      // 仅在无障碍服务开启时生效
      if (event && this.enableScreenReader && this.isOpenTouchGuide && this.uiEnable) {
        this.recordCapture();
      }
    }))
  }

  private recordCapture() {
    AppStorage.setOrCreate('ShowFlashBlackOpacity', 1);
    this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
    this.mAction.capture();
    this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
  }

  private recordStartAnimOp(): void {
    this.recordThumOpcaity = 0;
    this.captureBtnScale = { x: 0, y: 0 };
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
      }
    }, () => {
      this.captureBtnScale = { x: 1, y: 1 };
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp
    }, () => {
      this.recordThumOpcaity = 1;
    });
  }
}