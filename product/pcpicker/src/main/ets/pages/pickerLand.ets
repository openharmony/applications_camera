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
import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { OhCombinedState, execDispatch, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import {
  PersistType,
  PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { TabBarLand } from '@ohos/common/src/main/ets/component/tabbar/TabBarLand';
import { Tip } from '@ohos/common/src/main/ets/component/tip/Tip';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import { FootBarLand } from '../../../../../pc/src/main/ets/pages/FootBarLand';
import { ControlLand } from '@ohos/common/src/main/ets/component/ModeBar/pcLand/ControlLand';
import { PreviewAreaLand } from '../../../../../pc/src/main/ets/pages/PreviewAreaLand';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ThirdPreviewView } from './ThirdPreviewView';
import { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import { Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { ThumbnailStruct } from '@ohos/common/src/main/ets/utils/types';
import { DIALOG_OFFSET, PrivacyBanner } from '@ohos/common/src/main/ets/component/picker/PrivacyBanner';
import { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
// import { PickerSheet, PickerType } from '@ohos/pickersheet';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { VideoTimerLand } from '@ohos/common/src/main/ets/component/videoTimer/VideoTimerLand';
import { BigText } from '@ohos/common/src/main/ets/component/bigtext/BigText';
import { PickerActionType } from '@ohos/common/src/main/ets/redux/actions/PickerActionType';
import { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import { PcInfo } from '@ohos/common/src/main/ets/component/deviceinfo/PcInfo';
import { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import { image } from '@kit.ImageKit';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';

const TAG: string = 'pickerLand';

const PC_TIP_MARGIN_TOP: number = 98;
const TIP_IMG_SIZE: number = 14;
const PC_ROTATION_0: number = 0

class EnterImmersiveData {
  public isShowtimeLapse?: boolean = false;
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
}

interface pcPickerPhotoMap {
  pcPickerPhotoMap: Map<string, image.PixelMap>
}

@Entry
@Component
struct PickerLand {
  // 通用事件监听触发
  private mBase: BaseComponent = new BaseComponent();
  private subscriber: Unsubscribe = { destroy: () => {} };
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  // 布局
  private readonly tabBarHeight: number = 40;
  private readonly tabBarMarginTop: number = 32;
  private readonly controlHeight: number = 58;
  private readonly footBarHeight: number = 76;
  private readonly footBarMarginBottom: number = 15;
  private readonly settingOffsetX: number = 130;
  @State previewPosition: number = 0;
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @State isShowBigText: boolean = false;
  @State xComponentRotate: number = 0;
  @State isHideSettingBtn: boolean = false;
  @StorageLink('isHideWindowBar') @Watch('getWindowStatusBar') isHideWindowBar: boolean = false;
  // 通用数据
  @State mode: ModeType = ModeType.NONE;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  // 沉浸式
  @State immersiveOpacity: number = 1;
  private immersiveUIType: UIOperationType = UIOperationType.NULL;
  //预授权启动页是否显示过
  @StorageLink('isIntroLoaded') isIntroLoaded: boolean = false;
  @StorageLink('isRequestedPermission') isRequestedPermission: boolean = false;
  // 录像时间
  @State videoState: RecordingState = RecordingState.READY;
  @State @Watch('timerStateOnChange') videoTimerState: boolean = false;
  @State showTimer: boolean = false;
  @State timerOpacity: number = 0;

  @State isShowtimeLapse: boolean = false;
  @State isLearnMore: boolean = false;
  @State isBannerVisible: boolean = true;
  //Picker首次点开弹窗
  @State isDialogLoaded: boolean = false;
  @State isDialogOpen: boolean = false;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PrivacyBanner({ isBannerLoaded: this.isDialogLoaded, isBannerOpen: this.isDialogOpen,
      isBannerVisible: this.isBannerVisible }),
    autoCancel: false,
    alignment: DialogAlignment.Top,
    maskColor: Color.Transparent,
    customStyle: true,
    offset: { dx: 0, dy: DIALOG_OFFSET },
    isModal: false
  })

  @Builder
  PageMap(navigationName: string) {
    if (navigationName === 'ThirdPreviewView') {
      ThirdPreviewView()
    }
  }

  aboutToAppear(): void {
    HiLog.begin(TAG, 'aboutToAppear');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.videoTimerState = state.get<boolean>('recordReducer', 'videoTimerState');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isShowBigText = state.get<boolean>('modeReducer', 'isShowBigText');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
    });
    this.initializeIsDialogLoaded();
    this.eventBus.on([PickerActionType.SHOW_PICKER_VIEW, ThumbnailActionType.RECEIVED],
      this.showThirdPickerView.bind(this), this.mBase.hashCode());
    this.eventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), this.mBase.hashCode());
    this.eventBus.on(PickerActionType.LEARN_MORE_SECURITY_CAMERA,
      this.learnMoreSecurityCamera.bind(this), this.mBase.hashCode());
    this.eventBus.on(ThumbnailActionType.PC_PICKER_RECEIVED, (data: pcPickerPhotoMap) =>
    this.showRotatablePcThirdPickerView(data), this.mBase.hashCode());
    HiLog.end(TAG, 'aboutToAppear');
  }

  onPageShow(): void {
    HiLog.i(TAG, 'onPageShow.');
  }

  aboutToDisappear(): void {
    this.eventBus.clear(this.mBase.hashCode());
    this.subscriber.destroy();
    HiLog.i(TAG, 'aboutToDisappear E.');
  }

  onBackPress(): boolean {
    HiLog.i(TAG, 'onBackPress begin.');
    if (this.isShowtimeLapse) {
      execDispatch(Action.changeTimeLapse(false, true));
      return true;
    }
    if (getStates().get<boolean>('contextReducer', 'isThirdPartyCall')) {
      PickerUiService.getInstance().terminateSelfWithResult();
      return true;
    }
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSED) {
      execDispatch(RecordAction.stop());
      execDispatch(FunctionAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP));
      return true;
    }
    HiLog.i(TAG, 'onBackPress end.');
    return false;
  }

  private isEnterImmersive(data: EnterImmersiveData): void {
    let mIsImmersive: boolean = false;
    let mImmersiveUIType: UIOperationType = UIOperationType.NULL;
    let json: EnterImmersiveData = JSON.parse(JSON.stringify(data));
    HiLog.i(TAG, `isEnterImmersive json: ${JSON.stringify(data)}.`);
    if (json.isShowtimeLapse !== undefined) { // 定时拍摄需要状态变量渲染组件,就不再重复发Action了直接复用
      mIsImmersive = json.isShowtimeLapse;
      mImmersiveUIType = mIsImmersive ? UIOperationType.TIMELAPSE : UIOperationType.NULL;
    } else {
      if (json.isImmersive !== undefined) {
        mIsImmersive = json.isImmersive;
      }
      if (json.mainTrigCompo !== undefined && mIsImmersive) {
        mImmersiveUIType = json.mainTrigCompo;
      }
    }

    if (mIsImmersive) {
      this.immersiveUIType = mImmersiveUIType;
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
        curve: Curve.Sharp,
        onFinish: () => {
          this.immersiveUIType = mImmersiveUIType; // 保证退出沉浸式时self不受opacity影响
        }
      }, () => {
        this.immersiveOpacity = 1;
      });
    }
  }

  private learnMoreSecurityCamera(): void {
    this.isLearnMore = true;
  }

  onPageHide(): void {
    HiLog.i(TAG, 'onPageHide E.');
    this.stopCameraRecording();
    HiLog.i(TAG, 'onPageHide X.');
  }

  public stopCameraRecording(): void {
    HiLog.i(TAG, 'stopCameraRecording E.');
    if (this.isShowtimeLapse) {
      execDispatch(Action.changeTimeLapse(false));
    }
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSED) {
      execDispatch(RecordAction.stop());
      execDispatch(FunctionAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP));
    }
    HiLog.i(TAG, 'stopCameraRecording X.');
  }

  private isShowDialog(): boolean {
    return !this.isDialogLoaded;
  }

  private initializeIsDialogLoaded(): void {
    this.isDialogLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.PICKER_IS_BANNER_LOADED, false) as boolean;
    HiLog.i(TAG, `isDialogLoaded was initialized as: ${this.isDialogLoaded}`);
    if (this.isShowDialog()) {
      this.dialogController.open();
      this.isDialogOpen = true;
    }
    if (this.isDialogLoaded) {
      this.showPrivacyTip();
    }
  }

  private showPrivacyTip(): void {
    setTimeout((): void => {
      TipService.getInstance().showTip('', 3500, false, undefined, false, false, true);
    }, 200);
  }

  private setSettingOffsetX(): number {
    if (SystemLanguageUtil.isRTL()) {
      return this.settingOffsetX;
    }
    return 0;
  }

  private getWindowStatusBar(): void {
    this.isHideSettingBtn = this.isHideWindowBar;
  }

  build() {
    Stack() {
      Navigation(this.pageInfos) {
          Stack({ alignContent: Alignment.Center }) {
            PreviewAreaLand({
              xComponentRotate: $xComponentRotate
            }).key(ComponentIdKeys.PREVIEW_WINDOW_1)

            if (this.isShowBigText) {
              this.BigTextBuilder();
            }
            this.TabBarLandBuilder();
            this.ControlLandBuilder();
            this.FootBarLandBuilder();
            this.TipBuilder();
            if (this.showTimer) {
              this.VideoTimerLandBuilder();
            }

            if (this.isLearnMore) {
              // PickerSheet({
              //   appIcon: $r('app.media.icon'),
              //   curPickerKey: PickerType.CAMERA_PICKER,
              //   onClose: () => {
              //     this.isLearnMore = false;
              //   },
              //   windowProxy: PickerUiService.getInstance().getPickerWindowProxy()
              // })
            }
          }.width('100%').height('100%').visibility(Visibility.Visible)
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .navDestination(this.PageMap)
      .backgroundColor(Color.Black)
    }
  }

  @Builder
  BigTextBuilder(): void {
    Row() {
      BigText()
    }
    .position({ x: 0, y: -20 })
  }

  @Builder
  TabBarLandBuilder(): void {
    Column() {
      TabBarLand()
    }
    .width('100%')
    .height(this.tabBarHeight)
    .position({ y: 15, x: this.setSettingOffsetX() })
    .visibility(this.immersiveOpacity !== 0 && !this.isHideSettingBtn ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  ControlLandBuilder(): void {
    Column() {
      if (this.videoState === RecordingState.READY) {
        ControlLand()
      }
    }
    .width(360)
    .height(this.controlHeight)
    .hitTestBehavior(HitTestMode.Transparent)
    .offset({
      y: PcInfo.isRotatablePc() ?
        this.windowHeight / 2 - this.controlHeight / 2 - this.footBarHeight - this.footBarMarginBottom :
        this.xComponentHeight / 2 - this.controlHeight / 2 - this.footBarHeight - this.footBarMarginBottom
    })
    .visibility((this.immersiveUIType === UIOperationType.MODE_BAR || this.immersiveOpacity !== 0) ?
    Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  TipBuilder(): void {
    Tip()
      .offset({ x: 0, y: -(this.windowHeight / 2 - PC_TIP_MARGIN_TOP - TIP_IMG_SIZE / 2) })
  }

  @Builder
  FootBarLandBuilder(): void {
    Column() {
      FootBarLand()
    }
    .width(360)
    .height(this.footBarHeight)
    .offset({
      y: PcInfo.isRotatablePc() ?
        this.windowHeight / 2 - this.footBarHeight / 2 - this.footBarMarginBottom :
        this.xComponentHeight / 2 - this.footBarHeight / 2 - this.footBarMarginBottom
    })
    .visibility(this.immersiveUIType === UIOperationType.FOOT_BAR || this.immersiveOpacity !== 0 ?
    Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  VideoTimerLandBuilder(): void {
    VideoTimerLand()
      .width('100%')
      .height('100%')
      .opacity(this.timerOpacity)
      .hitTestBehavior(HitTestMode.None)
  }

  private async showThirdPickerView(data: ThumbnailStruct) {
    HiLog.i(TAG, 'showThirdPickerView E.');
    PickerUiService.getInstance().saveUriAndThumbnail(data?.thumbnail);
    this.pageInfos.pushPath(new NavPathInfo('ThirdPreviewView', null));
    execDispatch(Action.updateShowPickerView(true));
    HiLog.i(TAG, 'showThirdPickerView X.');
  }

  private async showRotatablePcThirdPickerView(data: pcPickerPhotoMap) {
    if (!PcInfo.isRotatablePc()) {
      return;
    }
    const pcPixMap: Map<string, image.PixelMap> = data.pcPickerPhotoMap;
    if (PcInfo.isRotatablePc() && DisplayService.getInstance().getDisplay().rotation === PC_ROTATION_0) {
      PickerUiService.getInstance().saveUriAndThumbnail(pcPixMap.get('portrait'));
    } else {
      PickerUiService.getInstance().saveUriAndThumbnail(pcPixMap.get('landscape'));
    }
    this.pageInfos.pushPath(new NavPathInfo('ThirdPreviewView', null));
    execDispatch(Action.updateShowPickerView(true));
    HiLog.i(TAG, 'showThirdPickerView X.');
  }


  private timerStateOnChange() {
    HiLog.i(TAG, `timerStateOnChange videoTimerState:${this.videoTimerState}`)
    if (this.videoTimerState) {
      HiLog.i(TAG, 'recordStartAnim');
      this.timerOpacity = 0;
      this.showTimer = true;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
        curve: Curve.Sharp
      }, () => {
        this.timerOpacity = 1;
      });
    } else {
      HiLog.d(TAG, 'recordEndAnim');
      this.timerOpacity = 1;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
        curve: Curve.Sharp,
        onFinish: () => {
          this.showTimer = false;
        }
      }, () => {
        this.timerOpacity = 0;
      });
    }
  }
}