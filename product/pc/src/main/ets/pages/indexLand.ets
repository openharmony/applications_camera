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
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { OhCombinedState, getStates, execDispatch, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import {
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { TabBarLand } from '@ohos/common/src/main/ets/component/tabbar/TabBarLand';
import { Tip } from '@ohos/common/src/main/ets/component/tip/Tip';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import { FootBarLand } from './FootBarLand';
import { ControlLand } from '@ohos/common/src/main/ets/component/ModeBar/pcLand/ControlLand';
import { PreviewAreaLand } from './PreviewAreaLand';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ThirdPreviewView } from './ThirdPreviewView';
import { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import {
  ThumbnailUpdateScene
} from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailAction';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { BigText } from '@ohos/common/src/main/ets/component/bigtext/BigText';
import {
  CameraStartType,
  CameraStartTypeStruct
} from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
// import { PafUiWidget } from '@ohos-paf/ui-widget-base';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import {
  CameraErrorDialogView,
  CameraErrorDialogViewParams,
  CameraErrorData
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/CameraErrorDialogView'
import { ThumbnailStruct } from '@ohos/common/src/main/ets/utils/types';
import power from '@ohos.power';
import screenLock from '@ohos.screenLock';
import { VideoTimerLand } from '@ohos/common/src/main/ets/component/videoTimer/VideoTimerLand';
import { simpleStringify } from '@ohos/common/src/main/ets/utils/SimpleStringify';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { PcInfo } from '@ohos/common/src/main/ets/component/deviceinfo/PcInfo';
import { MediaLibraryUiService } from '@ohos/common/src/main/ets/utils/LazyImportUtil';
import { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';

const TAG: string = 'IndexLand';

class NavPathInfoData {
  public width: number = 0;
  public height: number = 0;
  public mode: ModeType = ModeType.NONE;
  public uri: string = '';
  public videoUri: string = '';
  public callBundleName: string = '';
}

class EnterImmersiveData {
  public isShowtimeLapse?: boolean = false;
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
}

const PERMISSION_LIST: Permissions[] = [
  'ohos.permission.CAMERA',
  'ohos.permission.MICROPHONE',
  'ohos.permission.READ_IMAGEVIDEO',
  'ohos.permission.WRITE_IMAGEVIDEO',
];

@Entry(LocalStorage.getShared())
@Component
struct Index {
  // 大图组件延迟加载
  @Builder
  photoBrowserMapLand() {
    this.photoBrowserLoader();
  }
  @Builder
  photoBrowserMapLandTemp() {
  }
  @BuilderParam photoBrowserLoader: () => void = this.photoBrowserMapLandTemp;
  // 通用事件监听触发
  private mBase: BaseComponent = new BaseComponent();
  private subscriber: Unsubscribe = { destroy: () => {} };
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  // 布局
  private readonly tabBarHeight: number = 40;
  private readonly tabBarMarginTop: number = 50;
  private readonly zoomBarHeight: number = 82;
  private readonly controlHeight: number = 58;
  private readonly footBarHeight: number = 76;
  private readonly footBarMarginBottom: number = 15;
  private readonly settingOffsetX: number = 130;
  @State previewPosition: number = 0;
  @State xComponentRotate: number = 0;
  @State isShowtimeLapse: boolean = false;
  @State isShowBigText: boolean = false;
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
  @State isStarted: boolean = false;
  // 相机异常弹窗
  private cameraErrorDialogController: CustomDialogController | null = null;
  private isShowCameraError: boolean = false;
  // 录像时间
  @State videoState: RecordingState = RecordingState.READY;
  @State @Watch('timerStateOnChange') videoTimerState: boolean = false;
  @State showTimer: boolean = false;
  @State timerOpacity: number = 0;
  @StorageLink('isShowPhotoBrowser') isShowPhotoBrowser: boolean = false;
  // Navigation
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @Builder
  PageMap(navigationName: string) {
    if (navigationName === 'ThirdPreviewView') {
      ThirdPreviewView({ navigationName: navigationName })
    }
  }

  aboutToAppear(): void {
    HiLog.begin(TAG, 'aboutToAppear');
    // Paf UiWidget 初始化
    // PafUiWidget.init(GlobalContext.get().getWindowStage(), ContextManager.getInstance().getAbilityContext());
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
    this.requestPermissions();
    this.isIntroLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    this.isRequestedPermission = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.IS_REQUESTED_PERMISSION, false) as boolean;

    const code = this.mBase.hashCode(); 
    this.eventBus.on(CameraActionType.ERROR, (data: CameraErrorData) => this.cameraErrorDialogShow(data.code), code);
    this.eventBus.on(CameraActionType.STARTED, this.indexOnStarted.bind(this), code);
    this.eventBus.on(ThumbnailActionType.RECEIVED, this.onThumbnailUpdate.bind(this), code);
    this.eventBus.on(RecordActionType.STOPPED, this.onThumbnailUpdate.bind(this), code);
    this.eventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE,
      ActionType.ACTION_IS_ENTER_IMMERSIVE], this.isEnterImmersive.bind(this), code);
    this.eventBus.on(CameraActionType.PREEMPTION_WITH_ERROR, this.preemptCameraEnterSavePowerState.bind(this), code);
    this.eventBus.on([ActionType.ACTION_CHANGE_TIMED_SHOT,
      ActionType.ACTION_IS_ENTER_IMMERSIVE], this.isEnterImmersive.bind(this), code);
    HiLog.end(TAG, 'aboutToAppear');
  }

  private async requestPermissions(): Promise<void> {
    if (GlobalContext.get().getT<boolean>('permissionFlag')) {
      return;
    }
    HiLog.i(TAG, `Permissions need to require from user: ${simpleStringify(PERMISSION_LIST)}.`);
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const context = ContextManager.getInstance().getContextWithToken();
      const data = await atManager.requestPermissionsFromUser(context, PERMISSION_LIST);
      HiLog.i(TAG, `requestPermissionsFromUser data: ${simpleStringify(data)}.`);
      let sum = 0;
      for (let i = 0; i < data.authResults.length; i++) {
        sum += data.authResults[i];
      }
      if (sum >= 0) {
        GlobalContext.get().setObject('permissionFlag', true);
      } else {
        GlobalContext.get().setObject('permissionFlag', false);
      }
      HiLog.i(TAG, `Request permissions result: ${GlobalContext.get().getObject('permissionFlag')}.`);
    } catch (error) {
      HiLog.e(TAG, `requestPermissionsFromUser Catch error: ${error?.code}.`);
    }
  }

  onPageShow(): void {
    HiLog.i(TAG, 'onPageShow');
    MediaLibraryUiService.getInstance().onPageChange(true);
  }

  onPageHide(): void {
    HiLog.i(TAG, 'onPageHide E.');
    MediaLibraryUiService.getInstance().onPageChange(false);
    HiLog.i(TAG, 'onPageHide X.');
  }

  aboutToDisappear(): void {
    this.eventBus.clear(this.mBase.hashCode());
    this.subscriber.destroy();
    HiLog.i(TAG, 'aboutToDisappear E.');
  }

  onBackPress(): boolean {
    HiLog.i(TAG, 'onBackPress begin.');
    if (this.isShowPhotoBrowser) {
      HiLog.i(TAG, `onBackPress isShowPhotoBrowser: ${this.isShowPhotoBrowser}.`);
      execDispatch(Action.photoBrowserOnBackPress());
      return true;
    }
    if (this.isShowtimeLapse) {
      execDispatch(Action.changeTimeLapse(false, true));
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

  private async indexOnStarted(data: CameraStartTypeStruct): Promise<void> {
    if (data.type !== CameraStartType.COLD_START) {
      if (!(data.type === CameraStartType.WARM_START && !this.isStarted)) { // 热启动且之前冷启动未加载so时，需加载so
        return;
      }
    }
    HiLog.begin(TAG, 'delayImportBrowser');
    const photoBrowserTimer = setTimeout(async () => {
      let photoBrowserLoader = await import('./PhotoBrowserLand');
      this.photoBrowserLoader = photoBrowserLoader.PhotoBrowserLoader;
      this.isStarted = true;
      clearTimeout(photoBrowserTimer);
    }, 100);
    HiLog.end(TAG, 'delayImportBrowser');
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

  private preemptCameraEnterSavePowerState(): void {
    AppStorage.setOrCreate<boolean>('isPreemption', true);
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
          /*预授权启动页*/
          if (!this.isIntroLoaded) {
          } else {
            this.DefaultIndexLand();
          }
        }.width('100%').height('100%').backgroundColor(Color.Black)
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .navDestination(this.PageMap)
    }
  }

  @Builder
  BigTextBuilder(): void {
    Row() {
      BigText()
    }
    .position({ x: 0, y: 0 })
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
  TipBuilder(): void {
    Tip()
      .offset({
        x: 0,
        y: -(this.windowHeight / 2 - this.tabBarHeight - this.tabBarMarginTop - fp2px(28))
      })
  }

  @Builder
  VideoTimerLandBuilder(): void {
    VideoTimerLand()
      .width('100%')
      .height('100%')
      .opacity(this.timerOpacity)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  DefaultIndexLand(): void {
    Stack({ alignContent: Alignment.Center }) {
      PreviewAreaLand({
        xComponentRotate: $xComponentRotate
      }).key(ComponentIdKeys.PREVIEW_WINDOW_1);
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
      if (this.isStarted) {
        this.photoBrowserMapLand();
      }
    }
    .width('100%').height('100%')
    .visibility(this.isIntroLoaded ? Visibility.Visible : Visibility.Hidden)
  }


  private async onThumbnailUpdate(data: ThumbnailStruct): Promise<void> {
    const isThirdPartyCall = getStates().get<boolean>('contextReducer', 'isThirdPartyCall');
    HiLog.i(TAG, `onThumbnailUpdate, scene: ${data.scene}, isThirdPartyCall: ${isThirdPartyCall}.`);
    if (data.scene === ThumbnailUpdateScene.REFRESH || !isThirdPartyCall) {
      return;
    }
    const resourceUri = getStates().get<string>('captureReducer', 'resourceUri');
    const videoUri = getStates().get<string>('recordReducer', 'videoUri');
    HiLog.i(TAG, `onThumbnailUpdate data: ${JSON.stringify(data)} E.`);
    HiLog.i(TAG, `onThumbnailUpdate resourceUri: ${resourceUri}.`);
    HiLog.i(TAG, `onThumbnailUpdate videoUri: ${videoUri}.`);
    HiLog.i(TAG, 'onThumbnailUpdate start router to ThirdPreviewView.');
    let callBundleName: string | undefined = GlobalContext.get()
      .getCameraAbilityWant()?.parameters?.callBundleName as string;
    if (!callBundleName) {
      callBundleName = GlobalContext.get().getCameraNewWant()?.parameters?.callBundleName as string;
    }

    PickerUiService.getInstance().saveUriAndThumbnail(data?.thumbnail);
    this.pageInfos.pushPath(new NavPathInfo('ThirdPreviewView', {
      width: this.xComponentWidth,
      height: this.xComponentHeight,
      mode: this.mode,
      uri: resourceUri,
      videoUri: videoUri,
      callBundleName: callBundleName,
    } as NavPathInfoData));
    HiLog.i(TAG, 'onThumbnailUpdate X.');
  }

  private createCameraErrorDialog(errorCode: number): void {
    HiLog.i(TAG, `pass errorCode: ${errorCode}`);
    let params: CameraErrorDialogViewParams = CameraErrorDialogView.getDefaultParams(errorCode);
    this.cameraErrorDialogController = new CustomDialogController({
      builder: CameraErrorDialogView({
        confirm: () => {
          params.confirm();
          this.isShowCameraError = false;
        },
        title: params.title,
        description: params.description,
        confirmText: params.confirmText,
      }),
      autoCancel: false,
      maskColor: '#66000000',
      alignment: DialogAlignment.Center,
      customStyle: true
    });
  }

  private cameraErrorDialogShow(errorCode: number): void {
    let isBackground: boolean | undefined = AppStorage.get<boolean>('isBackground');
    let isActive: boolean = power.isActive();
    let isLocked: boolean = screenLock.isLocked();
    HiLog.i(TAG, `isBackground: ${isBackground}, isActive: ${isActive}, isLocked: ${isLocked}`);
    if (isBackground || !isActive || isLocked) {
      HiLog.i(TAG, 'Ignore the errorCode.');
      return;
    }
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    HiLog.i(TAG, `errorCode == ${errorCode}`);
    this.createCameraErrorDialog(errorCode);
    this.cameraErrorDialogController?.open();
    this.isShowCameraError = true;
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