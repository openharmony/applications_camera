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
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { Dispatch, OhCombinedState, reduxSubscribe, getStates } from '@ohos/common/src/main/ets/redux';
import lazy { PopupButton } from '@ohos/common/src/main/ets/component/tabbar/PopupButton';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy {
  RenderLocation,
  TabBarRenderLocations
} from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { RotateImageView } from '@ohos/common/src/main/ets/component/animate/RotateImageView';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy {
  CameraRunningState,
  CameraStartType,
  CameraStartTypeStruct
} from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import camera from '@ohos.multimedia.camera';
import lazy { TAB_BAR_HEIGHT } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy { Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ConflictParam } from '@ohos/common/src/main/ets/function/core/ConflictParam';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { ToggleButtonLottie } from '@ohos/common/src/main/ets/component/tabbar/ToggleButtonLottie';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy {
  TabBarUtils,
  TAB_BAR_STABILIZATION_ELEMENT_LENGTH
} from '@ohos/common/src/main/ets/component/tabbar/TabBarUtils';
import lazy {
  CUSTOM_FILTER_TABBAR_MARGIN_RIGHT,
  TAB_BAR_TOGGLE_ELEMENT_SIZE,
  TAB_BAR_ELEMENT_SIZE,
  CUSTOM_FILTER_TABBAR_WIDTH,
  TAB_BAR_ELEMENTS
} from '@ohos/common/src/main/ets/component/tabbar/TabBarConfig';
import lazy {
  LongPressDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/LongPressDialogView';
import curves from '@ohos.curves';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { TabBarAnimationType, TabBarPlayLottieType } from '@ohos/common/src/main/ets/camera/DataType';
import lazy { getPopupButtons, TabBarConfig } from '@ohos/common/src/main/ets/component/tabbar/TabBarConfig';
import Configuration from '@system.configuration';
import lazy { screenLock } from '@kit.BasicServicesKit';
import lazy { StringUtil } from '@ohos/common/src/main/ets/utils/StringUtil';
import lazy { getColorString } from '@ohos/common/src/main/ets/utils//ColorUtil';
import lazy { FunctionValueType, PositionType, LightPaintingType } from '@ohos/common/src/main/ets/utils/types';
import lazy { ValueType } from '@kit.ArkData';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { TabBarActionType } from '@ohos/common/src/main/ets/redux/actions/TabBarActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { CollaborateActionType } from '@ohos/common/src/main/ets/redux/actions/CollaborateActionType';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { SystemParamService } from '@ohos/common/src/main/ets/service/systemparameter/SystemParamService';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import { it } from '@ohos/hypium';

/* instrument ignore file */
const TAG: string = 'TabBar';
const SECOND_LIST_ELEMENT_ITEM_DELAY: number = 50;
const SECOND_LIST_ELEMENT_DELAY_BASIC: number = 150;
const DISABLED_OPACITY: number = 0.6;
const TEXT_MARGIN_26: number = 26;
const TIMER_DURATION: number = 750;
const FLASH_TYPE_FUNCTION: FunctionId[] = [FunctionId.FLASH];

class TabBarPopupButtonItem {
  public id: FunctionId = FunctionId.NONE;
  public renderType: RenderType = RenderType.NONE;
  public location: RenderLocation = RenderLocation.NONE;
}

class TranAnimationItem {
  public id: FunctionId = FunctionId.NONE;
  public renderType: RenderType = RenderType.NONE;
  public location: RenderLocation = RenderLocation.NONE;
  public icon: Resource | undefined = undefined;
}

class TypeListMap {
  public id: FunctionId = FunctionId.NONE;
  public map: Map<ValueType, UiElement> = new Map();
}

class FunctionStruct {
  public icon: Resource | undefined = undefined;
  public value: number = 0;
  public desc: Resource | string = '';
  public color: string = '';
  public title: Resource | string = '';
  public disabled: boolean = false;
  public tipText: Resource | string = ''; // 分辨率展开二级 弹出提示
  public accessibilityTitle: Resource | string = '';
  public accessibilityDescription: Resource | string = '';
}

interface FunctionData {
  id: FunctionId;
  value?: Object;
  conflictParam?: ConflictParam;
}

interface ProIsoValue {
  functionId: FunctionId,
  value: number
}


class TabBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: number | boolean | Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value, RenderLocation.TAB_BAR_RIGHT));
  }

  public changeTabBarSelector(id: FunctionId, renderLocation: RenderLocation): void {
    this.mDispatch(TabBarAction.changeTabBarSelector(id, renderLocation));
  }

  public changeTreasureBoxSelector(id: FunctionId): void {
    this.mDispatch(TreasureBoxAction.changeTreasureBoxSelector(id));
  }

  public changeTreasureBoxStatus(isOpen: boolean): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(isOpen))
  }

  public updateIsShowFilterView(isShow: boolean): void {
    if (isShow) {
      this.mDispatch(Action.updateIsShowExtendBar(false)); // 先触发ExtendBar里其它调节Bar下树,如PortraitEffectView
    }
    this.mDispatch(Action.updateIsShowParamBar(!isShow));
    this.mDispatch(Action.updateIsShowExtendBar(isShow));
  }

  public hideExtendBar(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
  }
}

@Component
export struct TabBar {
  private mBase: BaseComponent = new BaseComponent();
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mAction: TabBarDispatcher = new TabBarDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mFeatureManager: FeatureManager = FeatureManager.getInstance();
  private mTimerId: number = Number.MIN_VALUE;
  @State @Watch('clearTimerId') selector: FunctionId = FunctionId.NONE;
  @State @Watch('clearTimerId') selectorLocation: RenderLocation = RenderLocation.NONE;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State xComponentWidth: number = 0;
  @StorageLink('closeTabBar') closeTabBar: boolean = true;
  @StorageLink('treasureBoxSelector') treasureBoxSelector: FunctionId = FunctionId.NONE;
  @State leftFuncIds: Set<FunctionId> = new Set();
  @State middleFuncIds: Set<FunctionId> = new Set();
  @State rightFuncIds: Set<FunctionId> = new Set();
  @State textListMap: TypeListMap[] = [];
  @State mode: ModeType = ModeType.NONE;
  @State lastMode: ModeType = ModeType.NONE;
  @State mDirection: number = 0;
  @State rotateAngle: number = 0;
  @State @Watch('rotateAngleChanged') rotateAngleWatch: number = 0;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State @Watch('onLightPaintingFlashStateChange') isLightPaintingFlashShow: boolean = false;
  @State resetPopUpButton: Map<FunctionId, number> = new Map();
  @State resetLinkageButton: number = 0;
  @State @Watch('onToggleButtonTimerChange') isToggleButtonTimerStarted: boolean =
    false; //TOGGLE_BUTTON类型图标消失动画计时器是否开始标志
  @State @Watch('onFlashEnableStateChange') isFlashEnable: boolean = true;
  // lottie按钮
  @State isShowLottieCanvas: Map<FunctionId, boolean> = new Map();
  @State isShownByClick: Map<FunctionId, boolean> = new Map();
  @State isShowAudioZoomLottieCanvas: boolean = false;
  @StorageLink('isTabBarLottiePlaying') isTabBarLottiePlaying: boolean = false;
  // 动效参数
  private elementsRenderLocations: Map<FunctionId, RenderLocation> = new Map<FunctionId, RenderLocation>();
  @State allFunctionIds: FunctionId[] = [];
  @State prevAllFunctionIds: FunctionId[] = [];
  @State isShowButton: Map<FunctionId, boolean> = new Map<FunctionId, boolean>();
  @State functionPositions: Map<FunctionId, PositionType> = new Map<FunctionId, PositionType>();
  @State functionOpacity: Map<FunctionId, number> = new Map<FunctionId, number>();
  @State @Watch('isShowTextListChange') isShowTextList: boolean = false;
  @State @Watch('textListOpacityChange') textListOpacity: number = 0;
  @State isShowSecondLevel: boolean = false;
  @State isShowSecondLevelTextList: boolean = false;
  @State firstLevelOpacity: number = 1;
  @State secondLevelOpacity: number = 0;
  @State secondLevelElements: FunctionStruct[] = [];
  @StorageLink('isStaticImgShow') isStaticImgShow: boolean = true;
  private uiEnable: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  private customDialogViewController?: CustomDialogController;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State @Watch('onSuperIsoValueChange') superIsoValue: number = 0;
  @State clickLottieItem: TabBarPopupButtonItem | TranAnimationItem | null = null; // 用于
  @State isMicDeviceType: boolean = true;
  @StorageLink('isChangingModeOrSwitchingCamera') isChangingModeOrSwitchingCamera: boolean = false;
  private lottieTimer: number = -1;
  @State @Watch('onGlobalExposureValueChange') globalExposureValue: number = 0;
  @StorageLink('isGlobalExposureBarShow') @Watch('onGlobalExposureBarShow') isGlobalExposureBarShow: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @State cameraStartType: CameraStartType = CameraStartType.COLD_START;
  @State isCustomFilterOpen: boolean = false;
  @State currentHue: number = 0;
  @State currentSaturation: number = 0;
  @State currentTone: number = 0;
  @Prop isCustomFilterButtonShow: boolean = false;
  @Prop isCustomFilterImmersiveImmediately: boolean = false;
  @Prop isPicker: boolean = false;
  @State textOpacity: number = 0;
  @State curStyleIndex: number = 0;
  @State customFilterCardOpened: boolean = false;
  protected mStoreManager: StoreManager = StoreManager.getInstance();
  private isNeedUpdate: boolean = false;
  @StorageLink('onCustomFilterCardActionMenuShow') isShowActionMenu: boolean = false;
  @State isShowCustomFilterMenu: boolean = false;
  @State tabBarElements: FunctionId[] = TAB_BAR_ELEMENTS;
  @State isCustomFilterCloseLottieAnimDone: boolean = true;
  private mPreFunctionId: number = 0; // 记录上次点击的一级菜单
  @State refreshStabilizationIcon: boolean = false;
  @StorageLink('isAnimationPlaying') isAnimationPlaying: boolean = false;
  @StorageLink('isOpenAnimationShow') isOpenAnimationShow: boolean = false;
  @StorageLink('isCloseAnimationShow') isCloseAnimationShow: boolean = false;
  @StorageLink('xmageAnimationShow') isXmageAnimationShow: boolean = false;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.rotateAngle = getStates().get<number>('contextReducer', 'rotateAngle');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.selector = state.get<FunctionId>('tabBarReducer', 'tabBarSelector');
      this.selectorLocation = state.get<RenderLocation>('tabBarReducer', 'tabBarSelectorLocation');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      if (this.lastMode !== this.mode && this.mode !== state.get<ModeType>('modeReducer', 'mode')) {
        this.lastMode = this.mode;
      }
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngleWatch = state.get<number>('contextReducer', 'rotateAngle');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isLightPaintingFlashShow = state.get<boolean>('settingReducer', 'isLightPaintingFlashShow');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
      this.isMicDeviceType = state.get<boolean>('audioZoomReducer', 'isMicDeviceType');
      this.globalExposureValue = state.get<number>('globalExposureReducer', 'globalExposureValue');

      this.curStyleIndex = state.get<number>('customFilterStyleReducer', 'styleIndex');
      this.customFilterCardOpened = state.get<boolean>('customFilterStyleReducer', 'customFilterCardOpened');
      this.isCustomFilterOpen = state.get<boolean>('customFilterStyleReducer', 'customFilterEffectEnable');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.registerEventBus();
    this.initBasicAttributes();
    this.updateIsShowTextListState();
    HiLog.i(TAG, 'aboutToAppear getCameraRunningState.' +
    getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState'));
    // if (getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') === CameraRunningState.STARTED) {
    //   this.updateTabBar();
    // }
    this.updateTabBar();
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear invoke.');
    this.closeTabBar = true;
    this.mEventBus.clear(this.mBase.hashCode());
    this.subscriber.destroy();
    clearTimeout(this.lottieTimer);
  }

  private resetTabbarElements() {
    this.tabBarElements = TAB_BAR_ELEMENTS
  }

  private registerEventBus(): void {
    const code = this.mBase.hashCode();
    this.mEventBus.on(CameraActionType.STARTED, this.tabBarOnCreateSessionDone.bind(this), code);
    this.mEventBus.on([FunctionActionType.ACTION_CHANGE_FUNCTION_VAL], this.onFunctionValueChange.bind(this), code);
    this.mEventBus.on(TabBarActionType.ACTION_UPDATE_TAB_BAR_ARR, () => {
      this.resetFunctionIdArr();
      this.updateIsShowTextListState();
    }, code);
    this.mEventBus.on(TabBarActionType.ACTION_UPDATE_TAB_BAR_POS_N_OPA,
      (data: TabBarAnimationType) => this.updateElementPositionNOpacity(data), code);
    this.mEventBus.on(TabBarActionType.ACTION_PLAY_LOTTIE_ANIMATION,
      (data: TabBarPlayLottieType) => this.playButtonLottieAnimation(data), code);
    this.mEventBus.on(TabBarActionType.ACTION_UPDATE_LINKAGE_BUTTON, this.updateLinkageButton.bind(this), code);
    this.mEventBus.on(TabBarActionType.ACTION_UPDATE_POPUP_BUTTON, this.updatePopUpButton.bind(this), code);
    this.mEventBus.on(TabBarActionType.ACTION_UPDATE_TEXT_LIST, this.resetTextList.bind(this), code);
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, this.updateTabBar.bind(this), code);
    this.mEventBus.on(ActionType.ACTION_UPDATE_PRO_PARAMETERS_VALUE, (data: ProIsoValue) => {
    }, code);
    this.mEventBus.on([CollaborateActionType.START, CollaborateActionType.STOP], () => this.refreshTabBarView(), code);
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE], () => {
      if (this.mode === ModeType.VIDEO) {
        this.refreshStabilizationIcon = !this.refreshStabilizationIcon;
      }
      if (this.isShowSecondLevel || this.isShowSecondLevelTextList) {
        this.isShowSecondLevel = false; // 切模式时关闭二级页面
        this.isShowSecondLevelTextList = false;
      }
    }, code);
  }

  private tabBarOnCreateSessionDone(data: CameraStartTypeStruct): void {
    HiLog.i(TAG, 'onCreateSessionDone, reset tabBar funcIds array.');
    this.cameraStartType = data?.type;
    if (data && data.type !== CameraStartType.RECORD) {
      this.updateTabBar();
      HiLog.i(TAG, `onCreateSessionDone functionOpacity:${StringUtil.map2String(this.functionOpacity)}`);
      HiLog.i(TAG, `onCreateSessionDone isShowButton:${StringUtil.map2String(this.isShowButton)}`);
    }
    if (data && (data.type === CameraStartType.CHANGE_MODE || data.type === CameraStartType.SWITCH_CAMERA_CHANGE_MODE ||
      data.type === CameraStartType.WARM_START_WITH_MODE_AND_POS || data.type === CameraStartType.SWITCH_CAMERA ||
      data.type === CameraStartType.CHANGE_OUTPUT_TYPE)) {
      setTimeout((): void => {
        this.isToggleButtonTimerStarted = false;
        if (this.selector != FunctionId.NONE) {
          this.clearTimerId();
          this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
        }
      }, 300);
    }
    this.onSuperIsoValueChange();
  }

  private onFunctionValueChange(data: FunctionValueType): void {
    if (AppStorage.get('restoreFlag')) {
      return;
    }
  }

  private rotateAngleChanged(): void {
    if (this.rotateAngle === this.rotateAngleWatch) {
      return;
    }
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.rotateAngle = this.rotateAngleWatch
    });
  }

  private resetFunctionIdArr(): void {
    HiLog.d(TAG, `resetFunctionIdArr mode ${this.mode}`);
    this.resetTabbarElements();
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput(this.mode);
    let modeType: string = this.mode;
    if (outputType !== OutputType.NONE) {
      modeType = modeType + outputType;
    }
    this.prevAllFunctionIds = JSON.parse(JSON.stringify(this.allFunctionIds));
    let allFunctions: FunctionId[] = TabBarConfig.get(modeType) ?? [];
    this.allFunctionIds = allFunctions.filter((item: FunctionId) => {
      const value: number = this.mFeatureManager.getFunction(item)?.getValue();
      return this.mFeatureManager.getFunction(item)?.isAvailable() && value >= 0 &&
      this.mFeatureManager.getFunction(item).isTabBarShow();
    });
    HiLog.i(TAG, `resetFunctionIdArr: ${this.allFunctionIds}`)
  }

  private isCustomFilterSupport(): boolean {
    return this.isCustomFilterOpen && !this.isPicker &&
      (this.mode === ModeType.PHOTO);
  }

  private resetTextList(): void {
    HiLog.i(TAG, 'resetTextList.');
    const renderMap: Map<RenderLocation, Set<FunctionId>> = getStates()
      .get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap');
    this.getTextList(renderMap.get(RenderLocation.TAB_BAR_LIST));
  }

  private getTextList(funcIds: Set<FunctionId> | undefined): void {
    if (!funcIds || funcIds.size === 0) {
      this.textListMap = [];
      return;
    }
    this.textListMap = Array.from(funcIds).map((id: FunctionId) => {
      const map: Map<ValueType, UiElement> =
        this.mFeatureManager.getFunction(id).getUiElements(RenderLocation.TAB_BAR_LIST);
      let res: TypeListMap = { id: id, map: map };
      return res;
    }).sort((a: TypeListMap, b: TypeListMap) => a.id - b.id);
  }

  /**
   *  帧率，分辨率点击事件处理
   */
  private onTextListClick(item: TypeListMap, index: number, event?: ClickEvent): void {
    if (!event || !this.uiEnable) {
      return;
    }
    if (item.id === FunctionId.VIDEO_RESOLUTION) {
      this.onPopupButtonClicked(item.id, RenderLocation.TAB_BAR_LIST);
      return;
    }
    const arr: Map<ValueType, UiElement> = this.textListMap[index]?.map;
    if (!arr) {
      return;
    }
    let unSupportedQuantity = 0;
    arr.forEach((item, key) => {
      if (item.disabled) {
        unSupportedQuantity++
      }
    })
    if (arr.size - unSupportedQuantity === 1) {
      return;
    }
    const functionImpl: BaseFunction = this.mFeatureManager.getFunction(item.id);
    const currentValue: number = functionImpl.getValue();
    let nextValue: number = currentValue + 1;
    nextValue = nextValue > arr.size ? 1 : nextValue;
    while (!functionImpl?.getUiElements(RenderLocation.TAB_BAR_LIST).get(nextValue) ||
      functionImpl?.getUiElements(RenderLocation.TAB_BAR_LIST).get(nextValue)?.disabled) {
      nextValue++;
      nextValue = nextValue > arr.size ? 1 : nextValue;
    }
    HiLog.i(TAG, `currentValue: ${currentValue}.nextValue: ${nextValue}`);
    if (currentValue === nextValue) {
      return;
    }
    this.resetTextList();
    this.mAction.changeFunctionValue(item.id, nextValue);
    TipService.getInstance().showTip(functionImpl.getUiElements(RenderLocation.TAB_BAR_LIST)
      .get(nextValue)?.desc, 3000);
    this.mAction.hideExtendBar();
  }

  private isAudioViewShow(): boolean | undefined {
    if (this.videoState === RecordingState.READY || !this.isMicDeviceType) {
      return false;
    }
    if (OutputOperation.isPanPhotoOutput(this.mode, OutputSwitcher.getInstance().getOutput(this.mode))) {
      return false;
    }
    if (getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') !==
    camera.CameraPosition.CAMERA_POSITION_BACK) {
      return false;
    }
    return false;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.closeTabBar) {
        Row() {
          if (this.isShowTextList) {
            // 分辨率及帧率
            this.textList();
          } else if (this.isAudioViewShow()) {
          }

          // 新增TabBar按钮请前往TabBarUtils.ts文件中配置
          ForEach(this.tabBarElements, (item: FunctionId) => {
            this.popupButtonWrap(this.getPopupButtonItem(item,
              this.elementsRenderLocations.get(item) ?? RenderLocation.TAB_BAR_RIGHT));
          });
        }
        .direction(Direction.Ltr)
        .width('100%')
        .height(TAB_BAR_HEIGHT)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .zIndex(ZIndex.MIDDLE_TOP)
        .opacity(this.firstLevelOpacity)
        .renderGroup(true)
      }
      if (this.isShowSecondLevelTextList) {
        this.SecondListTextBuilder();
      }
      if (this.isShowSecondLevel) {
        this.SecondListPopupBuilder();
      }
    }
    .width('100%')
    .height(TAB_BAR_HEIGHT)
    .key(ComponentIdKeys.TABBAR_VIEW)
  }

  private getTabBarDirection(): Direction {
    return Direction.Auto;
  }

  @Builder
  textListItemBuilder(item: TypeListMap, index: number) {
    ListItem() {
      Column() {
        this.textItemBuilder(item, index)
      }
      .accessibilityText(`${ResGetter.getStringSafe(this.textListMap[index]?.map?.get(
        this.mFeatureManager.getFunction(item.id)?.getValue())?.accessibilityTitle)} ${
      ResGetter.getStringSafe(this.textListMap[index]?.map?.get(
        this.mFeatureManager.getFunction(item.id)?.getValue())?.accessibilityDescription)}`)
      .accessibilityDescription($r('app.string.accessibility_clickable'))
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .accessibilityGroup(true)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .key(ComponentIdKeys.getInstance().getKey(TAG, item.id))
      .gesture(
        LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
          .onAction((event) => {
            if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
              this.createLongPressDialog('', `${ResGetter.getStringSafe(this.textListMap[index]?.map?.get(
                this.mFeatureManager.getFunction(item.id)?.getValue())?.title)}`, true);
              this.customDialogViewController?.open();
            }
          })
      )
      .onTouch((event) => {
        this.onTextListTouch(event, item);
      })
      .onClick((event?: ClickEvent) => {
        this.onTextListClick(item, index, event);
      })
    }
  }

  @Builder
  textList() {
    if (this.isShowTextList) {
      List({ space: 13 }) {
        ForEach(this.textListMap, (item: TypeListMap, index: number = 0) => {
          this.textListItemBuilder(item, index);
        })
      }
      .margin({
        left: TEXT_MARGIN_26,
        right: TEXT_MARGIN_26
      })
      .direction(Direction.Ltr)
      .listDirection(Axis.Horizontal)
      .divider({
        color: '#33FFFFFF',
        strokeWidth: 1,
        startMargin: 10,
        endMargin: 10
      })
      .opacity(this.textListOpacity)
    }
  }

  private onTextListTouch(event: TouchEvent, item: TypeListMap) {
    if (event.type === TouchType.Down &&
      (item.id === FunctionId.FRAME_RATE)) {
      BlurAnimateUtil.generatePixelMapFromSurface();
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.customDialogViewController?.close();
    }
  }

  @Builder
  textItemBuilder(item: TypeListMap, index: number) {
    Text(this.textListMap[index]?.map?.get(this.mFeatureManager.getFunction(item.id)?.getValue())?.title)
      .fontColor(Color.White)// 录像分辨率和帧数 适老化字体
      .fontSize($r('sys.float.Body_M'))
      .maxFontScale(1)
      .textShadow({
        radius: 3,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .fontFeature('\"ss01\" on')
      .rotate({
        angle: DirectionToAngleUtil.getTwoDirectionTextRotate(this.mDirection),
      })
  }

  @Builder
  SecondListPopupBuilder() {
    Row() {
      ForEach(this.secondLevelElements, (item: FunctionStruct, index: number = 0) => {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          if (item.color === getColorString()) {
            RotateImageView({
              imgFit: ImageFit.Contain,
              defaultImgSrc: item.icon,
              fillColor: item.color,
              selector: this.selector,
              value: item.value,
              rotateImageWidth: 0
            })
              .accessibilityGroup(true)
              .key(`${ComponentIdKeys.getInstance()
                .getKey(ComponentIdKeys.getInstance().getKey('TabBar', this.selector), item.value)}-choose`)
              .onAppear(() => {
                if (this.enableScreenReader) {
                  AccessibilityUtils.sendFocusAccessibilityEvent(`${ComponentIdKeys.getInstance()
                    .getKey(ComponentIdKeys.getInstance().getKey('TabBar', this.selector), item.value)}`)
                }
              })
              .onDisAppear(() => {
                if (this.enableScreenReader) {
                  AccessibilityUtils.sendFocusAccessibilityEvent(`${ComponentIdKeys.getInstance()
                    .getKey('TabBar', this.mPreFunctionId)}`);
                }
              })
          } else {
            RotateImageView({
              imgFit: ImageFit.Contain,
              defaultImgSrc: item.icon,
              fillColor: item.color,
              selector: this.selector,
              value: item.value,
              rotateImageWidth: 0
            })
              .accessibilityGroup(true)
          }
        }
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
        .accessibilityGroup(true)
        .accessibilitySelected(item.color === getColorString())
        .accessibilityText(`${ResGetter.getStringSafe(item.accessibilityTitle)} ${
        ResGetter.getStringSafe(item.accessibilityDescription)}`)
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .onAccessibilityActionIntercept((action: AccessibilityAction) => {
          if (action == AccessibilityAction.ACCESSIBILITY_CLICK) {
            this.onSecondListPopupClick(item);
            return AccessibilityActionInterceptResult.ACTION_INTERCEPT;
          } else {
            return AccessibilityActionInterceptResult.ACTION_CONTINUE;
          }
        })
        .width(30)
        .height('100%')
        .margin({ right: 20, left: 20 })
        .key(ComponentIdKeys.getInstance()
          .getKey(ComponentIdKeys.getInstance().getKey('TabBar', this.selector), item.value))
        .onTouch((event) => {
          if (event.type === TouchType.Down &&
            (this.selector === FunctionId.PHOTO_FORMAT)) {
            BlurAnimateUtil.generatePixelMapFromSurface();
          }
        })
        .onClick((): void => {
          this.onSecondListPopupClick(item);
        })
      })
    }
    .direction(Direction.Ltr)
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .opacity(this.secondLevelOpacity)
  }

  private onSecondListPopupClick(item: FunctionStruct) {
    const tempSelector = this.selector;
    if (item.color === getColorString()) {
      this.clearTimerId();
      this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
      this.closeTabBar = true;
      if (this.isShowSecondLevel || this.isShowSecondLevelTextList) {
        this.isShowSecondLevel = false; // 切模式时关闭二级页面
        this.isShowSecondLevelTextList = false;
      }
      if (this.enableScreenReader) {
        // 二级回到一级，重新选中焦点
        setTimeout(() => {
          AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance().getKey(TAG, tempSelector));
        }, AnimSpecifications.ANIM_DURATION_200);
      }
      return;
    }
    HiLog.i(TAG, `Clicke tabBarSelector ${this.selector}, treasureBoxSelector ${this.treasureBoxSelector}.`);
    const selector: FunctionId = this.selector;
    this.mAction.changeFunctionValue(selector, item.value);
    TipService.getInstance().showTip(item.desc, 3000);
    if (Number.MIN_VALUE !== this.mTimerId) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }
    if (this.enableScreenReader) {
      // 二级回到一级，重新选中焦点
      setTimeout(() => {
        AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance().getKey(TAG, tempSelector));
      }, AnimSpecifications.ANIM_DURATION_200);
    }
    this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
  }

  @Builder
  SecondListTextBuilder() {
    Row({ space: 2 }) {
      ForEach(this.secondLevelElements, (item: FunctionStruct, index: number = 0) => {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween,
        }) {
          Text(item.desc)
            .fontColor(item.color === getColorString() ? item.color :
              Color.White)// 录像左上方 fps帧数 适老化字体
            .fontSize(SystemLanguageUtil.isTibetan() && item.value === SettingFuncDialogItemIndex.INDEX_SEC ||
            SystemLanguageUtil.isSpanish() ?
              '10vp' : '11vp')
            .margin({
              top: SystemLanguageUtil.isTibetan() && item.value === SettingFuncDialogItemIndex.INDEX_SEC ||
              SystemLanguageUtil.isSpanish() ? -2 : 0
            })
            .height('50%')
            .textShadow({
              radius: 5,
              color: '#4d000000',
              offsetX: 0,
              offsetY: 0
            })
          Text(item.title)
            .fontColor(item.color === getColorString() ? item.color : Color.White)
            .fontSize(11)
            .maxFontScale(1)
            .height('50%')
            .key(`TabBar_FPS_${index}`)
            .textAlign(TextAlign.Center)
            .textShadow({
              radius: 5,
              color: '#4d000000',
              offsetX: 0,
              offsetY: 0
            })
        }
        // 为下标提供一个屏幕朗读聚焦的id
        .id('tabBar_resolution_id' + (index === 0 ? 0 : ''))
        .rotate({ angle: this.rotateAngle })
        .accessibilityGroup(true)
        .accessibilityText(`${item.color === getColorString() ?
          ResGetter.getStringSafe($r('app.string.accessibility_checked')) : ''} ${
        ResGetter.getStringSafe(item.accessibilityTitle)}`)
        .accessibilityDescription(`${ResGetter.getStringSafe(item.accessibilityDescription)}`)
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .onAppear(() => {
          if (this.enableScreenReader && index === 0) {
            AccessibilityUtils.sendFocusAccessibilityEvent('tabBar_resolution_id' + index)
          }
        })
        .layoutWeight(1)
        .height('100%')
        .gesture(
          LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
            .onAction((event) => {
              if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
                this.createLongPressDialog('', `${ResGetter.getStringSafe(item.desc)} ${
                ResGetter.getStringSafe(item.title)}`, true);
                this.customDialogViewController?.open();
              }
            })
        )
        .onTouch((event) => {
          if (event.type === TouchType.Down && this.selector === FunctionId.VIDEO_RESOLUTION) {
            BlurAnimateUtil.generatePixelMapFromSurface();
          }
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.customDialogViewController?.close();
          }
        })
        .onClick((): void => {
          const tempSelector = this.selector;
          if (item.color === getColorString()) {
            this.clearTimerId();
            this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
            if (this.enableScreenReader) {
              // 二级回到一级，重新选中焦点
              setTimeout(() => {
                AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance().getKey(TAG, tempSelector));
              }, AnimSpecifications.ANIM_DURATION_200);
            }
            return;
          }
          HiLog.i(TAG, `Clicke tabBarSelector ${this.selector}, treasureBoxSelector ${this.treasureBoxSelector}.`);
          const selector: FunctionId = this.selector;
          this.mAction.changeFunctionValue(selector, item.value);
          TipService.getInstance().showTip(item.tipText, 3000);
          if (Number.MIN_VALUE !== this.mTimerId) {
            clearTimeout(this.mTimerId);
            this.mTimerId = Number.MIN_VALUE;
          }
          if (this.enableScreenReader) {
            // 二级回到一级，重新选中焦点
            setTimeout(() => {
              AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance().getKey(TAG, tempSelector));
            }, AnimSpecifications.ANIM_DURATION_200);
          }
          this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
        })
      })
    }
    .direction(Direction.Ltr)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .opacity(this.secondLevelOpacity)
  }

  @Builder
  popupButtonWrap(item: TabBarPopupButtonItem) {
    // 火龙果图标加载耗时规避方案，只冷启动时上树一次。正向修改中。
    if (item && (this.isShowButton.get(item.id))) {
      Row() {
        if (item.renderType === RenderType.POPUP_BUTTON) {
          this.popupButtonBuilder(item);
        } else if (item.renderType === RenderType.LINKAGE_TABBAR_BUTTON) {
          this.linkageTabBarButtonBuilder(item);
        } else if (item.renderType === RenderType.TOGGLE_BUTTON) {
          this.toggleButtonLottieBuilder(item);
        }
      }
      .width(this.getIconWidth(item.id))
      .height(TAB_BAR_HEIGHT)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .draggable(false)
      .visibility(this.functionOpacity.get(item.id) === 0 ? Visibility.None : Visibility.Visible)
      .position(this.getPopUpButtonPosition(item))
      .opacity(this.functionOpacity.get(item.id))
      .zIndex(this.functionOpacity.get(item.id))
      .enabled(this.isFlashDisable(item.id) ?
        false : true)
    }
  }

  private getIconWidth(itemId: FunctionId): number {
    return TAB_BAR_ELEMENT_SIZE;
  }

  private getPopUpButtonPosition(item: TabBarPopupButtonItem): (PositionType | undefined) {
    return this.functionPositions.get(item.id)
  }

  @Builder
  popupButtonWrapAudio(item: TabBarPopupButtonItem) {
    if (item) {
      Row() {
        this.toggleButtonLottieBuilder(item);
      }
      .width(TAB_BAR_HEIGHT)
      .height(TAB_BAR_HEIGHT)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .draggable(false)
      .position({ x: 26, y: 0 })
    }
  }

  private isFlashDisable(itemId: FunctionId): boolean {
    return FLASH_TYPE_FUNCTION.includes(itemId) && !this.isFlashEnable;
  }

  @Builder
  private popupButtonBuilder(item: TabBarPopupButtonItem): void {
    PopupButton({
      mFunctionId: item.id,
      renderLocation: item.location,
      functionOpacity: this.functionOpacity,
      keyName: ComponentIdKeys.getInstance().getKey(TAG, item.id),
      onPopupButtonClicked: (): void => this.onPopupButtonClicked(item.id, item.location),
      resetIcon: this.resetPopUpButton.get(item.id)
    })
      .rotate({ angle: this.rotateAngle })
  }

  @Builder
  private linkageTabBarButtonBuilder(item: TabBarPopupButtonItem): void {
    PopupButton({
      mFunctionId: item.id,
      functionOpacity: this.functionOpacity,
      renderLocation: item.location,
      onPopupButtonClicked: () => {
        if (this.videoState === RecordingState.READY) {
          return this.onLinkageTabBarButtonClicked(item.id);
        }
        return;
      },
      resetIcon: this.resetLinkageButton
    })
      .key(ComponentIdKeys.getInstance().getKey(TAG, item.id))
      .rotate({ angle: this.rotateAngle })
  }

  private getAccessibilityText(item: TabBarPopupButtonItem | TranAnimationItem): string {
    if (!this.isOpenTouchGuide) {
      return ' ';
    }
    // 这个分支用于刷新屏幕朗读的值，勿删
    if (this.isShowLottieCanvas.get(item.id) || this.resetLinkageButton > 0) {
      HiLog.i(TAG, `to refresh the screen reader text, isShowLottieCanvas: ${this.isShowLottieCanvas.get(item.id)}.`);
    }
    let mFunctionImpl = FeatureManager.getInstance().getFunction(item.id || this.clickLottieItem?.id);
    let abTitle = mFunctionImpl?.getUiElements(item.location).get(mFunctionImpl.getValue())?.accessibilityTitle;
    let abDescription =
      mFunctionImpl?.getUiElements(item.location).get(mFunctionImpl.getValue())?.accessibilityDescription;
    return `${ResGetter.getStringSafe(abTitle)}${ResGetter.getStringSafe(abDescription)}`;
  }

  @Builder
  private toggleButtonLottieBuilder(item: TabBarPopupButtonItem | TranAnimationItem): void {
    if (this.enableScreenReader) {
      this.screenReaderBuilder(item);
    } else {
      this.commonBuilder(item);
    }
  }

  @Builder
  commonBuilder(item: TabBarPopupButtonItem | TranAnimationItem) {
    Stack() {
      ToggleButtonLottie({
        mFunctionId: item.id,
        isToggleButtonTimerStarted: this.isToggleButtonTimerStarted,
        isShowLottieCanvas: this.isShowLottieCanvas,
        isShowLottieCanvasLeft: this.isShowAudioZoomLottieCanvas,
        isShownByClick: this.isShownByClick,
      })
        .width(TabBarUtils.getImageWidth(item.id))
        .height(TAB_BAR_TOGGLE_ELEMENT_SIZE)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Center)
    .onTouch((event) => {
    })
    .onClick((): void => {
      if (this.videoState === RecordingState.READY) {
        return this.onToggleButtonClicked(item.id, item.location);
      }
    })
    .key(ComponentIdKeys.getInstance().getKey(TAG, item.id))
    .rotate(this.getIconRotation(item.id))
    .opacity((this.videoState != RecordingState.READY && this.videoState !== RecordingState.STOPPING) ?
      AnimSpecifications.ALPHA_HALF : AnimSpecifications.ALPHA_OPAQUE)
  }

  private getShowNumber(text: number): string {
    if (text < 10) {
      return '0' + text;
    }
    return text + '';
  }

  private getIconRotation(itemId: number): RotateOptions | null {
    return { angle: this.rotateAngle };
  }

  @Builder
  screenReaderBuilder(item: TabBarPopupButtonItem | TranAnimationItem) {
    Stack() {
      ToggleButtonLottie({
        mFunctionId: item.id,
        isToggleButtonTimerStarted: this.isToggleButtonTimerStarted,
        isShowLottieCanvas: this.isShowLottieCanvas,
        isShowLottieCanvasLeft: this.isShowAudioZoomLottieCanvas,
        isShownByClick: this.isShownByClick,
      });
    }
    .width(30)
    .height('100%')
    .align(Alignment.Center)
    .onTouch((event) => {
    })
    .onAppear(() => {
      this.clickLottieItem = item;
    })
    .accessibilityGroup(true)
    .accessibilityText(this.getAccessibilityText(item))
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .onClick((): void => {
      if (this.videoState === RecordingState.READY) {
        this.onToggleButtonClicked(item.id, item.location);
        if (this.clickLottieItem === item) {
          this.clickLottieItem = null;
        } else {
          this.clickLottieItem = item;
        }
      }
    })
    .key(ComponentIdKeys.getInstance().getKey(TAG, item.id))
    .rotate(this.getIconRotation(item.id))
    .opacity((this.videoState !== RecordingState.READY && this.videoState !== RecordingState.STOPPING) ?
      AnimSpecifications.ALPHA_HALF : AnimSpecifications.ALPHA_OPAQUE)
    .accessibilityLevel(
      this.videoState !== RecordingState.READY && this.videoState !== RecordingState.STOPPING ?
        CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
        CommonConstants.ACCESSIBILITY_LEVEL_YES)
  }

  /**
   * 弹出条类点击事件
   */
  private onPopupButtonClicked(funcId: FunctionId, location: RenderLocation) {
    if (!this.uiEnable) {
      return;
    }
    HiLog.i(TAG, `onPopupButtonClicked funcId:${funcId}`);
    this.mPreFunctionId = funcId;
    this.mAction.changeTabBarSelector(funcId, location);
    this.updatePopUpButton();
    this.mTimerId = setTimeout((): void => {
      this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
    }, this.enableScreenReader ? 5 * 5000 : 5000); // 开启屏幕朗读延长5倍时间自动关闭
  }

  /**
   * 唤起百宝箱类点击事件
   */
  private onLinkageTabBarButtonClicked(funcId: FunctionId): void {
    if (!this.uiEnable) {
      return;
    }
    this.mAction.changeTreasureBoxSelector(funcId);
  }

  /**
   * 开关类点击事件
   */
  private onToggleButtonClicked(funcId: FunctionId, renderLoc: RenderLocation): void {
    if (!this.uiEnable || this.isTabBarLottiePlaying) {
      return;
    }
    const functionImpl: BaseFunction = this.mFeatureManager.getFunction(funcId);
    if (!functionImpl) {
      return;
    }
    this.isToggleButtonTimerStarted = true;
    let value: ValueType = functionImpl.getValue();
    value = !value;
    this.mAction.changeFunctionValue(funcId, value);
    this.resetFunctionIdArr();
    this.updateElementPositionNOpacity({ isActivelyDoTransAnim: true });
    this.playButtonLottieAnimation({ isClicked: true, functionId: funcId });
    HiLog.i(TAG, 'onToggleButtonClicked');
    this.isShowActionMenu = false;
    this.updateLinkageButton();
    let abTitle = functionImpl?.getUiElements(renderLoc).get(functionImpl.getValue())?.accessibilityTitle;
    let abDescription =
      functionImpl?.getUiElements(renderLoc).get(functionImpl.getValue())?.accessibilityDescription;
    AccessibilityUtils.sendAnnounceAccessibilityEvent(
      `${ResGetter.getStringSafe(abTitle)}${ResGetter.getStringSafe(abDescription)}`);
  }

  /**
   * 开关类点击事件
   */
  private onAudioToggleButtonClicked(funcId: FunctionId, renderLoc: RenderLocation): void {
    if (!this.uiEnable || this.isTabBarLottiePlaying) {
      return;
    }
    const functionImpl: BaseFunction = this.mFeatureManager.getFunction(funcId);
    if (!functionImpl) {
      return;
    }

    const value = functionImpl.getValue() ? false : true;
    this.mAction.changeFunctionValue(funcId, value);
    this.playAudioButtonLottieAnimation({ isClicked: true, functionId: funcId });
  }

  private playAudioButtonLottieAnimation(data: TabBarPlayLottieType): void {
    HiLog.i(TAG, `Play AudioButton lottie animation functionId: ${data.functionId}, ${this.allFunctionIds},` +
      ` ${this.prevAllFunctionIds}`);
    if (data.functionId && !this.isShowButton.get(data.functionId) && this.allFunctionIds.includes(data.functionId)) {
      HiLog.i(TAG, `function ${data.functionId} is nonexistent`);
      return;
    }
    if (data.functionId !== FunctionId.NONE) {
      this.isTabBarLottiePlaying = true;
      this.isShowAudioZoomLottieCanvas = true;
      this.setTimerForLottie(data.functionId);
      return;
    }
  }

  private getPopupButtonItem(item: FunctionId, location: RenderLocation): TabBarPopupButtonItem {
    const functionImpl = this.mFeatureManager.getFunction(item);
    if (!functionImpl) {
      return new TabBarPopupButtonItem();
    }
    let res: TabBarPopupButtonItem = {
      id: item,
      renderType: functionImpl.getRenderType(location),
      location: location
    };
    return res;
  }

  /**
   * TabBar 二级和一级切换动效时长控制
   */
  private clearTimerId() {
    HiLog.d(TAG, 'clearTimerId invoke.');
    this.isShowActionMenu = false;
    if (this.selector === FunctionId.NONE && Number.MIN_VALUE !== this.mTimerId) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }
    HiLog.i(TAG, 'tabBar change started.');
    if (this.selector !== FunctionId.NONE) {
      this.secondLevelElements = this.getFunctions();
      this.showSecondLevel();
    } else {
      this.showFirstLevel();
    }
  }

  private showSecondLevel(): void {
    animateToImmediately({
      curve: Curve.Sharp, duration: 150, onFinish: () => {
        this.closeTabBar = false;
        if (this.selector === FunctionId.VIDEO_RESOLUTION) {
          this.isShowSecondLevelTextList = true;
        } else {
          this.isShowSecondLevel = true;
        }
        animateToImmediately({ curve: Curve.Sharp, duration: 150 }, () => {
          this.secondLevelOpacity = 1;
        })
      }
    }, () => {
      this.firstLevelOpacity = 0;
    });
  }

  private showFirstLevel(): void {
    animateToImmediately({
      curve: Curve.Sharp, duration: 150, onFinish: () => {
        this.isShowSecondLevel = false;
        this.isShowSecondLevelTextList = false;
        this.closeTabBar = true;
        animateToImmediately({ curve: Curve.Sharp, duration: 150 }, () => {
          this.firstLevelOpacity = 1;
        })
      }
    }, () => {
      this.secondLevelOpacity = 0;
    });
  }

  private getFunctions(): FunctionStruct[] {
    let array = this.mFeatureManager.getFunction(this.selector)?.getUiElements(this.selectorLocation).values();
    if (this.selector === FunctionId.NONE) {
      return [];
    } else {
      if (array === undefined) {
        return [];
      } else {
        let resultArray = Array.from(array).map((item: UiElement, index: number) => {
          let functionValue: number = this.mFeatureManager.getFunction(this.selector).getValue();
          let functionColor = '#FFFFFF';
          if (functionValue === item.functionValue) {
            functionColor = getColorString();
          }
          let res: FunctionStruct = {
            icon: item.icon,
            value: item.functionValue,
            desc: item.desc,
            color: functionColor,
            title: item.title,
            disabled: item.disabled,
            tipText: item.textItemSec || '',
            accessibilityTitle: item.accessibilityTitle,
            accessibilityDescription: item.accessibilityDescription
          };
          return res;
        });
        if (this.selector === FunctionId.VIDEO_RESOLUTION) {
          resultArray = resultArray.filter(item => !item.disabled);
        }
        return resultArray;
      }
    }
  }

  private videoStateOnChange(): void {
    HiLog.d(TAG, `videoStateOnChange videoState: ${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      this.videoStateOnStarting();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.videoStateOnStopping();
    }
  }

  private videoStateOnStarting(): void {
    this.isNeedUpdate = this.isGlobalExposureBarShow &&
      getStates().get<number>('globalExposureReducer', 'globalExposureValue') === 0;
    this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
    this.resetFunctionIdArr();
    this.updateElementPositionNOpacity({ isActivelyDoTransAnim: true });
    animateToImmediately({ curve: Curve.Sharp, duration: 150 }, () => {
      this.isShowTextList = false;
      this.textListOpacity = 0;
    });
  }

  private videoStateOnStopping(): void {
    this.resetFunctionIdArr();
    this.updateElementPositionNOpacity({ isActivelyDoTransAnim: true });
    let showText: boolean = true;
    animateToImmediately({ curve: Curve.Sharp, duration: 150 }, () => {
      this.isShowTextList = showText;
      this.textListOpacity = 1;
      this.isNeedUpdate = false;
    });
  }

  private createLongPressDialog(iconRes: ResourceStr, label?: ResourceStr, isOnlyShowText: boolean = false): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm: () => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true,
          label: label
        },
        textRes: label,
        isOnlyShowText: isOnlyShowText
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }

  private initBasicAttributes(): void {
    TAB_BAR_ELEMENTS.forEach((item: FunctionId) => {
      let renderLoc: RenderLocation =
        // this.mFeatureManager.getFunction(item).getRenderLocations().find(loc => TabBarRenderLocations.includes(loc)) ??
        RenderLocation.TAB_BAR_RIGHT;
      this.elementsRenderLocations.set(item, renderLoc);
      this.isShownByClick.set(item, false);
    });
  }

  private hideAndShowAnim(functionId: FunctionId, newPosition: PositionType): void {
    animateToImmediately({
      curve: Curve.Sharp, duration: 150, onFinish: () => {
        this.functionPositions.set(functionId, newPosition);
        this.resetPopUpButton.set(functionId, ((this.resetPopUpButton.get(functionId) ?? 0) + 1) % 50);
      }
    }, () => {
      this.functionOpacity.set(functionId, 0);
    });
    animateToImmediately({
      curve: Curve.Sharp, duration: 150, delay: 150
    }, () => {
      this.functionOpacity.set(functionId, this.isFlashDisable(functionId) ? DISABLED_OPACITY : 1);
    });
  }

  private isPlayPositionTransAnim(functionId: FunctionId, data: TabBarAnimationType): boolean {
    let isFunctionPositionsEmpty: boolean = false;
    let isPrevFunctionPositionsEmpty: boolean = false;
    if (!this.functionPositions.size) {
      isFunctionPositionsEmpty = true;
    }
    if (!this.prevAllFunctionIds.length) {
      isPrevFunctionPositionsEmpty = true;
    }
    if (!this.functionPositions.has(functionId)) {
      return false;
    }
    if (data.isActivelyDoTransAnim) {
      return true;
    }
    if (!this.prevAllFunctionIds.includes(functionId)) {
      return false;
    }
    if (isFunctionPositionsEmpty || isPrevFunctionPositionsEmpty) {
      return false;
    }
    return true;
  }

  private updateElementPositionNOpacity(data: TabBarAnimationType = { isActivelyDoTransAnim: false }): void {
    HiLog.i(TAG, 'updateElementPositionNOpacity');
    for (let i: number = 0; i < TAB_BAR_ELEMENTS.length; i++) {
      const item: FunctionId = TAB_BAR_ELEMENTS[i];
      const isShow: boolean = this.allFunctionIds.includes(item);
      if (isShow) {
        this.isShowButton.set(item, isShow);
        const isPlayedHideAndShowAnim: boolean = this.updateButtonPosition(item, data);
        if (isPlayedHideAndShowAnim) {
          continue;
        }
        animateToImmediately({
          curve: Curve.Sharp,
          duration: 150,
          delay: 150,
          onFinish: () => {
            this.updatePopupButtonByFunctionId(item);
          }
        }, () => {
          this.functionOpacity.set(item, this.getFlashOpacity(item));
        });
      } else {
        animateToImmediately({
          curve: Curve.Sharp, duration: 150, onFinish: () => {
            if (this.isToggleButtonTimerStarted || this.functionOpacity.get(item) === 1) {
              return;
            }
            this.isShowButton.set(item, isShow);
            this.updatePopupButtonByFunctionId(item);
          }
        }, () => {
          this.functionOpacity.set(item, 0);
        });
      }
    }
    this.cameraStartType = CameraStartType.COLD_START;
  }

  private getFlashOpacity(item: FunctionId): number {
    return this.isFlashDisable(item) ?
      DISABLED_OPACITY : 1;
  }

  private updateButtonPosition(functionId: FunctionId, data: TabBarAnimationType): boolean {
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput(this.mode);
    const isPanPhotoOutput: boolean = OutputOperation.isPanPhotoOutput(this.mode, outputType);
    const originalPosition: PositionType = this.functionPositions.get(functionId) ?? { x: 0, y: 0 };
    const newPosition: PositionType =
      TabBarUtils.calcElementPosition(functionId, this.allFunctionIds, isPanPhotoOutput);
    const windowWidth: number = getStates().get<number>('windowReducer', 'windowWidth');
    HiLog.d(TAG,
      `updateButtonPosition functionId:${functionId}--newPosition:${JSON.stringify(newPosition)} ${this.isPlayPositionTransAnim(functionId,
        data)}`);
    if (this.isPlayPositionTransAnim(functionId, data)) {
      if (Math.abs(newPosition.x - originalPosition.x) > windowWidth / 2) {
        this.hideAndShowAnim(functionId, newPosition);
        return true;
      }
      animateToImmediately({
        curve: curves.interpolatingSpring(0, 1, 228, 30),
      },
        () => {
          this.functionPositions.set(functionId, newPosition);
        });
    } else {
      this.functionPositions.set(functionId, newPosition);
    }
    return false;
  }

  private setTimerForLottie(functionId: FunctionId): void {
    clearTimeout(this.lottieTimer);
    this.lottieTimer = setTimeout(() => {
      this.isTabBarLottiePlaying = false;
      this.isShowLottieCanvas.set(functionId, false);
      HiLog.i(TAG, 'reset isTabBarLottiePlaying done');
    }, TIMER_DURATION);
  }

  private playButtonLottieAnimation(data: TabBarPlayLottieType): void {
    HiLog.i(TAG, `Play button lottie animation functionId: ${data.functionId}, ${this.allFunctionIds},` +
      ` ${this.prevAllFunctionIds}`);
    // 如果当前function不在tabBar上就不更新
    if (data.functionId && !this.isShowButton.get(data.functionId) && this.allFunctionIds.includes(data.functionId)) {
      HiLog.i(TAG, `function ${data.functionId} is nonexistent`);
      return;
    }
    if (data.functionId !== FunctionId.NONE) {
      let isOpen: boolean = !!this.mFeatureManager.getFunction(data.functionId).getValue();
      if (data.isClicked && isOpen) {
        this.isShownByClick.set(data.functionId, true);
      }
      this.isTabBarLottiePlaying = true;
      this.isShowLottieCanvas.set(data.functionId, true);
      this.setTimerForLottie(data.functionId);
      return;
    } else {
      this.isTabBarLottiePlaying = false;
    }
  }

  private updateLinkageButton(): void {
    HiLog.i(TAG, 'Update linkage button.');
    this.resetLinkageButton = (this.resetLinkageButton + 1) % 50;
  }

  private updatePopUpButton(): void {
    if (this.isChangingModeOrSwitchingCamera) {
      return;
    }
    HiLog.i(TAG, 'Update popup button.');
    getPopupButtons().forEach((item: FunctionId) => {
      this.updatePopupButtonByFunctionId(item);
    });
  }

  private updatePopupButtonByFunctionId(functionId: FunctionId): void {
    if (this.allFunctionIds.includes(functionId)) {
      this.resetPopUpButton.set(functionId, ((this.resetPopUpButton.get(functionId) ?? 0) + 1) % 50);
    }
  }

  private updateIsShowTextListState(): void {
    HiLog.i(TAG, 'Update text list state.');
    const functionIds: Set<FunctionId> = getStates()
      .get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap')
      .get(RenderLocation.TAB_BAR_LIST) ?? new Set();
    if (functionIds.size > 0 && this.mode !== ModeType.PHOTO && this.videoState !== RecordingState.PAUSED) {
      this.getTextList(functionIds);
      this.isShowTextList = true;
      animateToImmediately({ curve: Curve.Sharp, duration: 150, delay: 150 }, () => {
        this.textListOpacity = 1;
      });
    } else {
      animateToImmediately({
        curve: Curve.Sharp, duration: 150, onFinish: () => {
          if (this.textListOpacity === 1) {
            return;
          }
          this.getTextList(functionIds);
          this.isShowTextList = false;
          //添加显示动画
        }
      }, () => {
        this.textListOpacity = 0;
      });
    }
  }

  private refreshTabBarView(): void {
    if (this.mode === ModeType.PHOTO || this.mode === ModeType.VIDEO) {
      this.updateTabBar();
    }
  }

  private updateTabBar(): void {
    HiLog.i(TAG, `UPDATE TABBAR`);
    this.resetFunctionIdArr();
    this.updateElementPositionNOpacity();
    if (this.videoState !== RecordingState.RECORDING &&
      (this.videoState === RecordingState.READY || this.videoState === RecordingState.STOPPING ||
        !CameraAppCapability.getInstance().getIsSupportRecordingFlowing() ||
        (this.mode !== ModeType.VIDEO))) {
      this.updateIsShowTextListState();
    }
    this.playButtonLottieAnimation({ isClicked: false, functionId: FunctionId.NONE });
    this.updateLinkageButton();
  }

  private onToggleButtonTimerChange(): void {
    if (!this.isToggleButtonTimerStarted) {
      this.resetFunctionIdArr();
      this.updateElementPositionNOpacity({ isActivelyDoTransAnim: true });
    }
  }

  private onFlashEnableStateChange(): void {
    if (this.isFlashEnable) {
      if (this.functionOpacity.get(FunctionId.FLASH) === DISABLED_OPACITY) {
        FLASH_TYPE_FUNCTION.forEach((item: FunctionId) => {
          this.functionOpacity.set(item, 1);
        })
      }
      return;
    }
    FLASH_TYPE_FUNCTION.forEach((item: FunctionId) => {
      this.functionOpacity.set(item, DISABLED_OPACITY);
    })
  }

  private onSuperIsoValueChange(): void {
    if (this.videoState !== RecordingState.READY) {
      return
    }
    this.allFunctionIds.forEach((item: FunctionId) => {
    })
  }

  private onGlobalExposureValueChange(): void {
    this.updateLinkageButton();
  }

  private onGlobalExposureBarShow(): void {
    this.resetFunctionIdArr();
    this.updateElementPositionNOpacity({ isActivelyDoTransAnim: true });
  }

  private onLightPaintingFlashStateChange(): void {
    this.resetFunctionIdArr();
    this.updateElementPositionNOpacity();
  }

  private isShowTextListChange(changedPropertyName: string): void {
    HiLog.d(TAG, `isShowTextListChange isShowTextList: ${this.isShowTextList}`);
  }

  private textListOpacityChange(changedPropertyName: string): void {
    HiLog.d(TAG, `textListOpacityChange textListOpacity: ${this.textListOpacity}`);
  }
}