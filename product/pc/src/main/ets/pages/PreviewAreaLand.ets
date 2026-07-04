/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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
import { ShowFlashBlack } from '@ohos/common/src/main/ets/component/animate/ShowFlashBlack';
import { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import { Action, ActionData, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { Dispatch, OhCombinedState, execDispatch, getStates } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { AssistiveGridView } from '@ohos/extend/src/main/ets/settingcommonfunc/assistivegrid/AssistiveGridView';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { Size, XComponentSize } from '@ohos/common/src/main/ets/utils/types';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { CameraAction, CameraStartType,
  CameraStartTypeStruct } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { Unsubscribe, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { XComponentService } from '@ohos/common/src/main/ets/component/xcomponent/XComponentService';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import { window } from '@kit.ArkUI';
import display from '@ohos.display';
import { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import { JSON } from '@kit.ArkTS';
import { simpleStringify } from '@ohos/common/src/main/ets/utils/SimpleStringify';
import { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import { DurationType, TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import { PcInfo } from '@ohos/common/src/main/ets/component/deviceinfo/PcInfo';
import { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { image } from '@kit.ImageKit';
import { screenLock } from '@kit.BasicServicesKit';
import { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';

const TAG: string = 'PreviewAreaLand';
const RATIO_ACCURACY: number = 2;
const RATIO_16_TO_9 = 16 / 9;
const DELAY_SHOW_PREVIEW_TIME: number = 500;
const WIN_DECOR_HEIGHT: number = 50;

interface PreviewFrameStartData {
  isPreviewFrameStart: boolean;
}

interface WindowSizeData {
  windowSize: Size;
}

class EnterImmersiveStruct {
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
}

class Dispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public startPreview(): void {
    this.mDispatch(CameraAction.start(false));
  }

  public warmStartup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public close(): void {
    this.mDispatch(CameraAction.close({ isNeedSaveRestore: true , isPcEnterSleep: true}));
  }

  public stopRecording(): void {
    this.mDispatch(RecordAction.stop());
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public startRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.start());
  }

  public assistiveGridView(isViewShow: boolean): void {
    this.mDispatch(Action.assistiveGridView(isViewShow));
  }

  public thirdPartyCall(isThirdPartyCall: boolean, action?: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, action));
  }

  public swipeChangeMode(swipe: number): void {
    this.mDispatch(Action.swipeChangeMode(swipe));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.PINCH_ZOOM));
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public previewClicked(): void {
    this.mDispatch(Action.previewClicked());
  }

  public changeTabBarSelector(id: FunctionId): void {
    this.mDispatch(TabBarAction.changeTabBarSelector(id, RenderLocation.NONE));
  }

  public changeIsLockedState(): void {
    this.mDispatch(ContextAction.screenLockedState(false));
  }
}

XComponentService.getInstance().init(new XComponentController());

@Component
export struct PreviewAreaLand {
  private mBase: BaseComponent = new BaseComponent();
  private subscriber: Unsubscribe = { destroy: () => {} };
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State mode: ModeType = ModeType.NONE;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State videoState: RecordingState = RecordingState.READY;
  @State isShowBigText: boolean = false;
  @State isAssGridViewShow: boolean = false;
  @State isLocked: boolean = false;
  @State scaleX: number = 1;
  @State scaleXSec: number = 0.8;
  @State rotateAngle: number = 0;
  @State rotateAngleSec: number = 80;
  @State btnOpacityFirst: number = 1;
  @State btnOpacitySec: number = 0;
  @State switchBackgroundOpacity: number = 1;
  @State screenSize: Size = { width: 0, height: 0 };
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State immersiveOpacity: number = 1;
  private xComponentSizeForAnim: Size = {width : 0, height: 0}
  private isReportDrawnCompleted: boolean = false;
  private mAction: Dispatcher = new Dispatcher();
  @StorageLink('isInBlurAnim') isInBlurAnim: boolean = false;
  @StorageLink('showPhotoBrowserAction') showPhotoBrowserAction: boolean = false;
  @StorageLink('savePowerModeNeedRestartPreview') savePowerModeNeedRestartPreview: boolean = false;
  @Link xComponentRotate: number;
  @State isHideMinimize: boolean = false;
  private isXcomponentLoaded: boolean = false;
  @State isHorizontalLevelShow: boolean = false;
  @State isShowBlackMask: boolean = true;
  @State curWindowStatus:window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @State pcAspectRatio: number = 0;
  @State isUpdateAspectRatio: boolean = false;
  @State lastWindowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  // 模糊
  @State isPreviewFrameStart: boolean = false;
  @State previewBlurOpacity: number = 1;
  @State previewBlur: number = 0;
  @State isShowPreviewBlur: boolean = false;
  @State mScreenshotPixelMap: image.PixelMap | null = null;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.screenSize = { width: 1135, height: 672 };
    this.updateXComponentVariables();
    this.xComponentSizeForAnim = {
      width: getStates().get<number>('previewReducer', 'xComponentWidth'),
      height: getStates().get<number>('previewReducer', 'xComponentHeight')
    };
    this.lastWindowStatus = getStates().get<number>('windowReducer', 'windowStatus');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.isShowBigText = state.get<boolean>('modeReducer', 'isShowBigText');
      this.isAssGridViewShow = state.get<boolean>('settingReducer', 'isAssGridViewShow');
      this.isLocked = state.get<boolean>('contextReducer', 'isLocked');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.curWindowStatus = state.get<number>('windowReducer', 'windowStatus')
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.windowSizeChange();
    this.refreshXComponentRotation();

    const code: string = this.mBase.hashCode();
    this.eventBus.on(WindowActionType.ON_CLASS_READY, this.onWindowClassReady.bind(this), code);
    this.eventBus.on(CameraActionType.STARTED, this.onSessionCreated.bind(this), code);
    // 确保模糊动效开始前一定准备好新模式对应的size，或者size在模糊期间更新会失败，或者后续去更新又有明显的延迟
    this.eventBus.on(ActionType.ACTION_PREVIEW_SHOT_COMPONENT, this.onSessionCreated.bind(this), code);
    this.eventBus.on(WindowActionType.ON_SIZE_CHANGE, this.windowSizeChange.bind(this), code);
    this.eventBus.on(WindowActionType.REFRESH_UX, this.onRotationChange.bind(this), code);
    this.eventBus.on(ContextActionType.ABILITY_ON_NEW_WANT, this.onNewWant.bind(this), code);
    this.eventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), code);
    this.eventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START, this.onPreviewFrameStart.bind(this), code);
    this.eventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.pcBackgroundCloseCamera.bind(this), code);
    this.eventBus.on(ContextActionType.ABILITY_ACTIVE, this.pcOnForegroundWarmStart.bind(this), code);
    this.eventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      (data: XComponentSize) => this.onChangeXComponentSize(data), code);
    this.eventBus.on(CameraActionType.ON_LENS_DIRTY, this.onLensDirty.bind(this), code);
    this.eventBus.on([ActionType.ACTION_IS_UPDATE_ASPECT_RATIO, CameraActionType.CHANGE_MODE],
      this.getIsUpdateAspectRatio.bind(this), code);
    this.afterShowPreview();
    HiLog.i(TAG, 'aboutToAppear X.');
    //PC这里必须需要刷新一下宽高比，否则会黑屏
    setTimeout(() => {
      let featureManager = FeatureManager.getInstance();
      this.mAction.changeFunctionValue(FunctionId.ASPECT_RATIO, featureManager.getFunction(FunctionId.ASPECT_RATIO)
        .getDefaultValue() as number);
    }, 200)
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.eventBus.clear(this.mBase.hashCode());
    this.subscriber.destroy();
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  onPageHide(): void {
    HiLog.i(TAG, 'onPageHide E.');
    HiLog.i(TAG, 'onPageHide X.');
  }

  private updateXComponentVariables(): void {
    this.xComponentWidth = getStates().get<number>('previewReducer', 'xComponentWidth');
    this.xComponentHeight = getStates().get<number>('previewReducer', 'xComponentHeight');
  }

  //黑遮罩持续500ms遮盖冷起时的雪花状噪点
  private afterShowPreview(): void {
    HiLog.i(TAG, 'afterShowPreview');
    setTimeout(() => {
      this.isShowBlackMask = false;
    }, DELAY_SHOW_PREVIEW_TIME)
  }

  private getIsUpdateAspectRatio(): void {
    this.isUpdateAspectRatio = true;
    this.lastWindowStatus = this.curWindowStatus;
  }


  private stopRecordingBeforeClose(): void {
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSING ||
      this.videoState === RecordingState.PAUSED || this.videoState === RecordingState.RESUMING) {
      HiLog.i(TAG, `stopRecordingBeforeClose E.`);
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      HiLog.i(TAG, `stopRecordingBeforeClose X.`);
    }
  }

  //PC最小化后关闭相机
  private pcBackgroundCloseCamera(data: ActionData): void {
    if (data['windowStageEventType'] === window.WindowStageEventType.HIDDEN && !screenLock.isLocked()) {
      AppStorage.setOrCreate('isOnHiddenCamera', true);
      this.stopRecordingBeforeClose();
      HiLog.i(TAG, `pcBackgroundCloseCamera E.`);
      this.isHideMinimize = true;
      this.mAction.close();
      HiLog.i(TAG, `pcBackgroundCloseCamera X.`);
    }
  }
  //PC最小化后拉起相机热起
  private pcOnForegroundWarmStart(): void {
    if (this.isHideMinimize) {
      HiLog.i(TAG, `pcOnForegroundWarmStart E.`);
      AppStorage.setOrCreate('isOnHiddenCamera', false);
      this.mAction.warmStartup();
      this.isHideMinimize = false;
      HiLog.i(TAG, `pcOnForegroundWarmStart X.`);
    }
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    HiLog.i(TAG, `onPreviewFrameStart ${JSON.stringify(data)}.`);
    if (data.isPreviewFrameStart && !this.isReportDrawnCompleted) {
      ContextManager.getInstance().getUiContext().reportDrawnCompleted(async () => {
        HiLog.i(TAG, 'reportDrawnCompleted_previewAreaLand');
      })
      this.isReportDrawnCompleted = true;
    }
    if (data.isPreviewFrameStart) {
      this.hideBlurAnim();
    } else {
      this.showBlurAnim();
    }
    this.isPreviewFrameStart = data.isPreviewFrameStart;
  }

  private hideBlurAnim(): void {
    HiLog.i(TAG, 'hideBlurAnim begin, previewBlur change.');
    animateToImmediately({
      duration: BlurAnimateUtil.HIDE_BLUR_DURATION,
      curve: Curve.FastOutSlowIn,
    }, () => {
      this.previewBlurOpacity = 0;
      this.previewBlur = 0;
      setTimeout(() => {
        this.isShowPreviewBlur = false;
        this.changePreviewSizeAnim(this.xComponentSizeForAnim);
        HiLog.i(TAG, `hideBlurAnim finish, previewBlur: ${this.previewBlur}.`);
      }, BlurAnimateUtil.HIDE_BLUR_DURATION)
    });
  }

  private showBlurAnim(): void {
    HiLog.i(TAG, 'showBlurAnim begin, previewBlur change.');
    this.previewBlur = 0;
    this.previewBlurOpacity = 1;
    this.isShowPreviewBlur = true;
    this.mScreenshotPixelMap = BlurAnimateUtil.getBlurPixelMap();
    animateToImmediately({
      duration: BlurAnimateUtil.SHOW_BLUR_DURATION,
      curve: Curve.Friction,
      onFinish: async () => {
        try {
          FeatureManager.getInstance().setIsInResolution(false);
          this.mScreenshotPixelMap =
            await BlurAnimateUtil.generateBlurByEffectKit(BlurAnimateUtil.getBlurPixelMap(), false);
          this.changePreviewSizeAnim(this.xComponentSizeForAnim);
        } catch (e) {
          HiLog.e(TAG, `showBlurAnim err:${JSON.stringify(e)}`);
        }
        HiLog.i(TAG, `showBlurAnim finish, previewBlur: ${this.previewBlur}.`);
      }
    }, () => {
      this.previewBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
      HiLog.i(TAG, `previewBlur: ${this.previewBlur}.`);
    });
  }

  private onChangeXComponentSize(data: XComponentSize): void {
    HiLog.i(TAG, `onChangeXComponentSize, data: ${JSON.stringify(data)}.`);
    this.xComponentSizeForAnim = { width: data.xComponentWidth, height: data.xComponentHeight };
  }

  private changePreviewSizeAnim(newSize: Size) {
    HiLog.begin(TAG, 'changePreviewSizeAnim');
    HiLog.i(TAG, `changePreviewSizeAnim, xComponentWidth: ${this.xComponentWidth}, new width: ${newSize.width
    }, xComponentHeight: ${this.xComponentHeight}, new height: ${newSize.height}.`);
    animateToImmediately({
      duration: BlurAnimateUtil.CHANGE_PREVIEW_DURATION,
      curve: Curve.Friction,
      onFinish: () => {
        HiLog.end(TAG, 'changePreviewSizeAnim')
      }
    }, () => {
      this.xComponentWidth = newSize.width;
      this.xComponentHeight = newSize.height;
    });
  }

  private isEnterImmersive(data: EnterImmersiveStruct): void {
    let json: EnterImmersiveStruct = JSON.parse(JSON.stringify(data)) as Object as EnterImmersiveStruct;
    HiLog.i(TAG, `isEnterImmersive json: ${JSON.stringify(data)}.`)
    const isImmersive = json.isImmersive !== undefined ? json.isImmersive : false;
    if (isImmersive) {
      this.immersiveOpacity = 1;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
      }, () => {
        this.immersiveOpacity = 0;
      });
    } else {
      this.immersiveOpacity = 0;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp
      }, () => {
        this.immersiveOpacity = 1;
      });
    }
  }

  private refreshXComponentRotation(): void {
    if (!PcInfo.isRotatablePc()) {
      this.xComponentRotate = 0;
      return;
    }
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    switch (rotation) {
      case 0:
        this.xComponentRotate = 0;
        break;
      case 1:
        this.xComponentRotate = 90;
        break;
      case 2:
        this.xComponentRotate = 180;
        break;
      case 3:
        this.xComponentRotate = 270;
        break;
      default:
        this.xComponentRotate = 90;
    }
    HiLog.i(TAG, `refreshXComponentRotation rotation: ${rotation}, xComponentRotate: ${this.xComponentRotate}.`);
  }

  private getXComponentSideLength(length: number): number | string {
    let isWindowStatusFloat: boolean = this.curWindowStatus === window.WindowStatusType.FLOATING;
    return PcInfo.isRotatablePc() || (!PcInfo.isRotatablePc() && !isWindowStatusFloat) ? length : '100%';
  }

  build() {
    // pc预览旋转依赖rotate
    Stack({ alignContent: Alignment.Center }) {
      Stack({ alignContent: Alignment.Center }) {
        XComponent({
          id: 'HDC_PREVIEW', // Hardware Direct Connect Preview,禁止变更
          type: 'surface',
          libraryname: '',
          controller: XComponentService.getInstance().getController()
        } as ESObject)
          .onLoad((): void => {
            HiLog.begin(TAG, 'XComponent_onLoad');
            const surface = XComponentService.getInstance().createSurface();
            HiLog.i(TAG, `startPreview, surface: ${surface}.`);
            this.mAction.startPreview();
            HiLog.end(TAG, 'XComponent_onLoad');
          })
          .onDestroy((): void => {
            const surface = XComponentService.getInstance().deleteSurface();
            HiLog.i(TAG, `XComponent_onDestroy, delete surface: ${surface}.`);
          })
          .onClick((): void => {
            this.mAction.changeTabBarSelector(FunctionId.NONE);
            this.mAction.previewClicked();
          })
          .focusable(false)

        if (this.isShowPreviewBlur) {
          Column(){
            Image(this.mScreenshotPixelMap)
              .width('100%')
              .height('100%')
              .blur(this.previewBlur)
              .syncLoad(true)
              .opacity(this.previewBlurOpacity)
          }.rotate({ y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 })
        }

        if (this.isShowBlackMask) {
          Column() {
          }
          .backgroundColor(Color.Black)
        }

        ShowFlashBlack({ xComponentWidth: this.xComponentWidth, xComponentHeight: this.xComponentHeight })
          .hitTestBehavior(HitTestMode.None)

        if (this.isAssGridViewShow && (!this.isShowBigText || this.videoState !== RecordingState.READY)) {
          AssistiveGridView()
            .hitTestBehavior(HitTestMode.Transparent)
            .visibility(this.immersiveOpacity !== 0 ? Visibility.Visible : Visibility.Hidden)
            .key(ComponentIdKeys.ASSISTIVE_GRID_VIEW)
        }
      }
      .width(this.getXComponentSideLength(this.xComponentWidth))
      .height(this.getXComponentSideLength(this.xComponentHeight))
      .rotate({ angle: this.xComponentRotate })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .onTouch((event: TouchEvent) => {
      if (TouchType.Down === event.type) {
        BlurAnimateUtil.generatePixelMapFromSurface();
        return;
      }
    })
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        TapGesture({ fingers: 1, count: 1 })
          .onAction(() => this.onPreviewClicked()),
        PanGesture({
          fingers: 1,
          direction: SystemLanguageUtil.isRTL() ? PanDirection.Right : PanDirection.Left,
          distance: 10
        })
          .onActionStart((): void => {
            const uiEnable = getStates().get<boolean>('contextReducer', 'uiEnable');
          }),
        PanGesture({
          fingers: 1,
          direction:SystemLanguageUtil.isRTL() ? PanDirection.Left : PanDirection.Right,
          distance: 10
        })
          .onActionStart((): void => {
            const uiEnable = getStates().get<boolean>('contextReducer', 'uiEnable');
          })
      )
    )
  }

  private async onWindowClassReady() {
    HiLog.i(TAG, 'EventBus onWindowClassReady E.');
    this.updateXComponentVariables();
    let isAssGridViewShow: boolean = FeatureManager.getInstance().getFunction(FunctionId.ASSISTIVE_GRID).getValue();
    this.mAction.assistiveGridView(isAssGridViewShow);
    this.pcAspectRatio = Number((this.xComponentWidth / (this.xComponentHeight -
      WIN_DECOR_HEIGHT)).toFixed(RATIO_ACCURACY));
    WindowService.getInstance().setAspectRatio(this.pcAspectRatio);
    this.resetScreenSize(this.screenSize);
    HiLog.i(TAG, 'onWindowClassReady X.');
  }

  private onSessionCreated(data: CameraStartTypeStruct): void {
    if (data.type === CameraStartType.RECORD) {
      return;
    }
    HiLog.i(TAG, 'onSessionCreated E.');
    this.resetScreenSize(this.screenSize, false);
    HiLog.i(TAG, 'onSessionCreated X.');
  }

  private async onNewWant() {
    let newWantAction = GlobalContext.get().getCameraNewWant().action;
    let newWant = GlobalContext.get().getCameraNewWant();
    HiLog.i(TAG, `globalThis.cameraNewWant is ${JSON.stringify(GlobalContext.get().getCameraNewWant())}.`);
    HiLog.i(TAG, `newWantAction is ${JSON.stringify(newWantAction)}.`);
    if (newWantAction === 'action.system.home' || !(!!newWant.parameters?.callBundleName)) {
      this.mAction.thirdPartyCall(false, newWantAction);
    } else {
      this.mAction.thirdPartyCall(true, newWantAction);
    }
  }

  private async onPreviewClicked() {
    if (OutputOperation.isPanPhotoOutput(this.mode, OutputType.NONE)) {
      this.mAction.changeTimeLapse(false);
      this.eventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      this.mAction.capture();
      this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
    } else if (OutputOperation.isPanVideoOutput(this.mode, OutputType.NONE)) {
      this.mAction.changeTimeLapse(false);
      this.mAction.startRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, 0);
    }
    HiLog.i(TAG, 'onPreviewClicked end.');
  }

  private windowSizeChange(data?: WindowSizeData): void {
    HiLog.i(TAG, `windowSizeChange data: ${JSON.stringify(data)}.`);
    if ((this.curWindowStatus === window.WindowStatusType.FLOATING &&
      this.lastWindowStatus === window.WindowStatusType.MAXIMIZE) || !data?.windowSize) {
      this.isUpdateAspectRatio = true;
      this.lastWindowStatus = this.curWindowStatus;
    }
    this.lastWindowStatus = window.WindowStatusType.UNDEFINED
    if (!data?.windowSize) {
      this.screenSize = { width: this.windowWidth, height: this.windowHeight };
    } else {
      this.screenSize = data?.windowSize;
    }
    this.isXcomponentLoaded = true;
    this.resetScreenSize(this.screenSize);
    this.updateXComponentVariables();
  }

  private resetScreenSize(size: Size, isChange: boolean = true): void {
    const xComponentSize = CameraBasicService.getInstance().getPreviewDisplaySize();
    HiLog.i(TAG, `resetScreenSize screenSize: ${simpleStringify(size)}, xComponentSize: ${
      simpleStringify(xComponentSize)}.`);
    try {
      const isRotatablePc: boolean = PcInfo.isRotatablePc();
      const rotation = DisplayService.getInstance().getDisplay().rotation;
      // 竖屏相机则需要将宽高调换
      if (isRotatablePc && (rotation === 0 || rotation === 2)) {
        HiLog.i(TAG, `isRotatablePc: ${isRotatablePc}, rotation: ${rotation}, windowHeight: ${this.windowHeight}.`);
        if (xComponentSize.width > xComponentSize.height) {
          this.changeXComponentSize(this.windowHeight * (xComponentSize.height / xComponentSize.width),
            this.windowHeight, this.isXcomponentLoaded, isChange);
        } else {
          this.changeXComponentSize(xComponentSize.width, xComponentSize.height, false, isChange);
        }
        return;
      }
      if (!isRotatablePc) {
        HiLog.i(TAG, `isRotatablePc: ${isRotatablePc}, xComponentSize: ${simpleStringify(xComponentSize)}.`);
        this.changeXComponentSize(xComponentSize.width, xComponentSize.height, true, isChange);
        return;
      }
      if (xComponentSize.width > xComponentSize.height) {
        HiLog.i(TAG, `windowHeight: ${this.windowHeight}, xComponentSize: ${simpleStringify(xComponentSize)}.`);
        this.changeXComponentSize(xComponentSize.height + 8, xComponentSize.width, false, isChange);
        return;
      }
      HiLog.i(TAG, `xComponentSize: ${simpleStringify(xComponentSize)}.`);
      this.changeXComponentSize(xComponentSize.height, xComponentSize.width, true, isChange);
    } catch (err) {
      HiLog.e(TAG, `resetScreenSize fail, error: ${simpleStringify(err)}.`);
    }
  }

  private changeXComponentSize(width: number, height: number, isRefreshWindow: boolean, isChange: boolean): void {
    HiLog.i(TAG, `changeXComponentSize width: ${width}, height: ${height}, isRefreshWindow: ${isRefreshWindow
    }, isChange: ${isChange}.`);
    // isRefresh : 需要刷新窗口大小，竖屏相机竖屏仅更改预览宽高无需更新窗口大小
    let isRefresh: boolean =
      (this.pcAspectRatio - Math.abs(Number((width / (height - WIN_DECOR_HEIGHT)).toFixed(RATIO_ACCURACY)))) <= 0.01 &&
        (this.pcAspectRatio - Math.abs(Number((width / (height - WIN_DECOR_HEIGHT)).toFixed(RATIO_ACCURACY)))) > 0
    if (isRefreshWindow && isRefresh || this.isUpdateAspectRatio) {
      WindowService.getInstance().setAspectRatio(Number((PcInfo.isRotatablePc() ?
        RATIO_16_TO_9 : (width / (height - WIN_DECOR_HEIGHT))).toFixed(RATIO_ACCURACY)));
      this.isUpdateAspectRatio = false;
    }
    execDispatch(Action.changeXComponentSize(width, height));
  }

  private onRotationChange(): void { // 横竖屏切换
    this.resetScreenSize(this.screenSize);
    this.updateXComponentVariables();
  }

  //脏镜头提示
  private onLensDirty(data: Record<string, boolean>): void {
    if (this.showPhotoBrowserAction) {
      if (TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().hideAlwaysShowTip($r('app.string.is_dirty_lens'));
      }
      return;
    }
    HiLog.i(TAG, `onLensDirty: ${data.isCameraLensDirty}`);
    if (data.isCameraLensDirty) {
      if (!TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().showTip($r('app.string.is_dirty_lens'), DurationType.Duration_LENS_DIRTY, true);
      }
    } else {
      if (TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().hideAlwaysShowTip($r('app.string.is_dirty_lens'));
      }
    }
  }
}