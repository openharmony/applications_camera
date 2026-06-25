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

import lazy {
  AdaptiveLayoutService,
  ARROW_HEIGHT,
  BOTTOM_MARGIN,
  TREASURE_BOX_ELEMENT_HEIGHT
} from '../../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { Dispatch, getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { TreasureBoxAction } from '../reduce/TreasureBoxAction';
import lazy { CameraStartType } from '../../../camera/uithread/CameraAction';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { CameraStartTypeData, SelectorData, SLEEP_TIME, TREASURE_BOX_IMAGE_ELEMENT } from '../common/DataType';
import lazy { ArrowButton } from './button/ArrowButton';
import lazy { BackButton } from './button/BackButton';
import lazy { FirstLevelList } from './FirstLevelList';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import treasureBoxConfig from './TreasureBoxConfig';
import lazy { SecondLevelList } from './SecondLevelList';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { apsSetScene } from '../../../utils/FrameLockSceneUtil';
import lazy { FrameLockScene } from '../../../utils/FrameLockScene';
import lazy { UuidUtil } from '../../../utils/UuidUtil';
import lazy { FunctionValueType, PositionType, ValueType } from '../../../utils/types';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { PhotoFormatMode } from '../../../function/enumbase/PhotoFormatMode';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { RecordingState } from '../../../function/recordcontrol/RecordAction';
import lazy { PickerUtils } from '../../../utils/PickerUtils';
import lazy { PersistType, PreferencesService } from '../../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../../service/preferences/PropTag';
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { TreasureBoxActionType } from '../../../redux/actions/TreasureBoxActionType';
import lazy { SettingViewActionType } from '../../../redux/actions/SettingViewActionType';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { WindowActionType } from '../../../redux/actions/WindowActionType';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { CameraActionType } from '../../../redux/actions/CameraActionType';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';

/* instrument ignore file */

const TAG: string = 'TreasureBox';

const ELEMENT_TOP_MAX_MARGIN: number = 12;

const SECOND_LEVEL_LIST_LENGTH_SUPPLEMENT: number = 0.5;

const INCREASE_HEIGHT: number = 8;

export const BACK_BUTTON_SIDE_LENGTH: number = 42;

export const BACK_BUTTON_LEFT_MARGIN: number = 15;

export const SECOND_LIST_PADDING_LEM_HALF: number = 8; //Lem半折下item之间的距离

export const BACK_BUTTON_MIN_RIGHT_MARGIN: number = 3;

export const TREASURE_BOX_TAG: string = 'TreasureBox';

enum TreasureBoxRefreshTriggerType {
  START_CAMERA = 0,
  CHANGE_FUNCTION_VALUE = 1
}

interface ProIsoValue {
  functionId: FunctionId,
  value: number
}

@Component
export struct TreasureBox {
  // 全局数据
  private mBase: BaseComponent = new BaseComponent();
  @State mode: ModeType = ModeType.NONE;
  private subscriber: Unsubscribe = { destroy: () => {} };
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private dispatch: Dispatch = (data) => data;
  // 百宝箱ux相关变量
  @State elementTopMargin: number = BOTTOM_MARGIN;
  @State @Watch('changeMargins') displayWidth: number = 0;
  // 百宝箱打开与关闭动效
  private uncollaps: (isShow: boolean) => void = () => {
  };
  @State isOpen: boolean = false;
  @State isShowTreasureBox: boolean = false;
  @State treasureBoxOpacity: number = 0;
  @State arrowTransDistance: number = 0;
  private arrowUpDistance: number = AdaptiveLayoutService.getInstance().arrowUpDistance;
  // List入场出场动效相关变量
  @State @Watch('onAnimationDone') transAnimationDone: boolean = false;
  @State isFirstToSecond: boolean = true;
  @State resetTransEffect: boolean = false;
  // 一级页面数据
  @StorageLink('treasureBoxSelector') @Watch('onSelectorChanged') selector: FunctionId = FunctionId.NONE;
  @State recordSelector: FunctionId = FunctionId.NONE;
  @State resetFirstListFlag: boolean = false;
  // 二级页面数据
  @State isShowListAnimate: boolean = true;
  @State isHalfCollapsLEM: boolean = false;
  @State @Watch('refreshTreasureBoxView') isLightPaintingFlashShow: boolean = false;
  // 环形补光
  @State isShowRingLightView: boolean = false;
  private isSuperIsoValue: boolean = false;
  private treasureBoxRefreshTriggerType: TreasureBoxRefreshTriggerType = TreasureBoxRefreshTriggerType.START_CAMERA;
  private renderLocation: RenderLocation | undefined = RenderLocation.NONE;
  @State videoState: RecordingState = RecordingState.READY;
  @State isVdeLandscape: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  private treasureBoxTimerId: number = Number.MIN_VALUE;
  /** STARTED 时 FeatureManager 用 setTimeout(0) 更新 functionRenderMap；此处同延后一级列表刷新，避免闪光灯等项仍按旧镜头渲染 */
  private cameraStartedListRefreshTimerId: number = -1;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  private recordZoomRatio: number = 1;
  @Prop isHdr: boolean = false;
  @Prop treasureBoxAnimationState: number = -1;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;

  aboutToAppear(): void {
    HiLog.i(TREASURE_BOX_TAG, 'aboutToAppear begin.');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isOpen = state.get<boolean>('treasureBoxReducer', 'isOpen');
      this.displayWidth = state.get<number>('windowReducer', 'windowWidth');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isLightPaintingFlashShow = state.get<boolean>('settingReducer', 'isLightPaintingFlashShow');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
    }, (dispatch: Dispatch): void => {
      this.dispatch = dispatch;
    });

    this.initDistance();

    this.eventBus.on(CameraActionType.STARTED, this.onCameraStarted, this.mBase.hashCode());
    this.eventBus.on(TreasureBoxActionType.ACTION_CHANGE_TREASURE_BOX_SELECTOR,
      (data: SelectorData) => this.onSelectorChangedByAnotherComponent(data), this.mBase.hashCode());
    this.changeSelectToNone();
    this.eventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, (data: FunctionValueType, event: string) => {
      if (AppStorage.get('restoreFlag')) {
        return;
      }
      this.refreshingInterface(data);
      this.treasureBoxRefreshTriggerType = TreasureBoxRefreshTriggerType.CHANGE_FUNCTION_VALUE;
      this.renderLocation = data.renderLocation;
      if (this.selector === FunctionId.VIDEO_RESOLUTION) {
        this.refreshTreasureBoxView();
        return;
      }
      if (data.id !== this.selector || (data.renderLocation !== RenderLocation.TAB_BAR_RIGHT &&
        data.renderLocation !== RenderLocation.TAB_BAR_LEFT && data.renderLocation !== RenderLocation.TAB_BAR_LIST &&
        data.renderLocation !== RenderLocation.TAB_BAR_MIDDLE)) {
        return;
      }
      this.changeSelectorNone(true, event);
    }, this.mBase.hashCode());
    this.eventBus.on(
      [TreasureBoxActionType.ACTION_REFRESH_TREASURE_BOX_VIEW,
        ActionType.ACTION_IS_SHOW_WATERMARK_PAGE],
      () => this.refreshTreasureBoxView(), this.mBase.hashCode());
    this.eventBus.on([WindowActionType.WINDOW_STATUS], () => this.onRefreshTreasureBoxView(),
      this.mBase.hashCode());
    this.onLandscapeChanged(); // 要刷新一下 后置当前置 百宝箱组件需要移除后置当前置功能
    this.eventBus.on(TreasureBoxActionType.ACTION_PRO_UPDATE_TREASURE_BOX,
      this.proUpdateTreasureBox.bind(this), this.mBase.hashCode());
    HiLog.i(TREASURE_BOX_TAG, 'aboutToAppear end.');
  }

  private refreshTBTipPreference(): void {
    HiLog.i(TREASURE_BOX_TAG, 'refreshTBTipPreference E.');
    PreferencesService.getInstance()
      .putPropValue(PersistType.FOREVER, PropTag.LAST_SHOW_TREASURE_BOX_TIP_TIMESTAMP, -1);
  }

  private proUpdateTreasureBox(): void {
    if (this.selector === FunctionId.FLASH) {
      this.changeSelectorNone(false);
    }
  }

  private refreshingInterface(data: FunctionValueType): void {
    if (data.id === FunctionId.ZOOM) {
      let zoomRatio: number = FeatureManager.getInstance().getFunction(FunctionId.ZOOM).getValue();
      if ((zoomRatio === 1 && this.recordZoomRatio !== 1) || (zoomRatio !== 1 && this.recordZoomRatio === 1)) {
        this.refreshTreasureBoxView();
      }
      this.recordZoomRatio = zoomRatio;
      return;
    }
  }

  private changeSelectToNone() {
    this.eventBus.on([
      SettingViewActionType.ACTION_SHOW_SETTING_VIEW,
      TreasureBoxActionType.ACTION_CHANGE_WITH_ZOOM,
      ContextActionType.UPDATE_SAVE_POWER_MODE_STATE,
      TreasureBoxActionType.ACTION_CLOSE_SECOND_TREASURE
    ],
      (data: Object, event: string) => this.changeSelectorNone(false, event), this.mBase.hashCode());
  }

  private onLandscapeChanged(): void {
    HiLog.i(TREASURE_BOX_TAG, 'onLandscapeChanged');
    if (PickerUtils.getIsExpandedSplitScreen()) {
      return;
    }
    this.resetFirstListFlag = !this.resetFirstListFlag;
  }

  aboutToDisappear() {
    if (this.cameraStartedListRefreshTimerId !== -1) {
      clearTimeout(this.cameraStartedListRefreshTimerId);
      this.cameraStartedListRefreshTimerId = -1;
    }
    this.renderLocation = RenderLocation.NONE;
    this.eventBus.clear(this.mBase.hashCode());
    this.subscriber.destroy();
    // 百宝箱展开态时杀死相机，ArrowButton动画走不到onFinish, isOpening为true, 导致点击tabBar区域xMage无法展开百宝箱
    // 当百宝箱被销毁时将isOpening置成false, 解决上述问题
    treasureBoxConfig.setIsOpening(false);
  }

  private onSelectorChanged(): void {
    HiLog.i(TREASURE_BOX_TAG, `onSelectorChanged, treasureBox selector change to: ${this.selector}.`);
    if (this.selector === FunctionId.NONE) {
      return;
    }
    this.recordSelector = this.selector;
  }

  private changeMargins(): void {
    HiLog.i(TREASURE_BOX_TAG, 'displayWidth changed, changeMargins begin.');
    treasureBoxConfig.initMargins(this.displayWidth);
  }

  private onSelectorChangedByAnotherComponent(data: SelectorData): void {
    if (treasureBoxConfig.getIsOpening()) {
      return;
    }
    if (this.isOpen && this.selector === data.functionId) {
      this.dispatch(TreasureBoxAction.setTreasureBoxStatus(false));
      return;
    }
    if (!this.isOpen && data.functionId !== FunctionId.NONE) {
      this.dispatch(TreasureBoxAction.setTreasureBoxStatus(true));
    }
    if (data.functionId === FunctionId.NONE) {
      this.changeSelectorNone(true);
    } else {
      this.changeSelector(data.functionId);
    }
  }

  // 百宝箱展开与收起动效执行前准备
  private beforeUncollapsAnimation(isOpen: boolean): void {
    HiLog.i(TREASURE_BOX_TAG, `uncollapsTreasureBox open: ${isOpen}, treasureBoxOpacity: ${this.treasureBoxOpacity}.`);
    treasureBoxConfig.setIsOpening(true);
    this.uncollaps(isOpen);
    if (isOpen) {
      apsSetScene(TREASURE_BOX_TAG, true); // 进入页面开始锁帧
      FrameLockScene.getInstance().apsSetScene(TREASURE_BOX_TAG, true); // 进入页面解除锁帧
      treasureBoxConfig.setListOffset(0);
      this.isShowTreasureBox = true;
      this.refreshTBTipPreference();
      this.resetFirstListFlag = !this.resetFirstListFlag;
      HiLog.i(TREASURE_BOX_TAG, 'uncollapsTreasureBox open treasureBox starting.');
    }
    HiLog.i(TREASURE_BOX_TAG, `uncollapsTreasureBox isOpen: ${isOpen}.`);
  }

  // 百宝箱展开与收起动效执行后设置
  private afterUncollapsAnimation(isOpen: boolean): void {
    if (isOpen !== this.isOpen) {
      return;
    }
    treasureBoxConfig.setIsOpening(false);
    if (isOpen) {
      HiLog.i(TREASURE_BOX_TAG, 'uncollapsTreasureBox open treasureBox finished.');
      return;
    }
    HiLog.i(TREASURE_BOX_TAG, 'uncollapsTreasureBox close treasureBox finished.');
    this.selector = FunctionId.NONE;
    this.isShowTreasureBox = false;
    apsSetScene(TREASURE_BOX_TAG, false); // 退出页面结束锁帧
    FrameLockScene.getInstance().apsSetScene(TREASURE_BOX_TAG, false); // 退出页面开始锁帧
  }

  private onCameraStarted = (data: CameraStartTypeData): void => {
    HiLog.i(TREASURE_BOX_TAG, `onCameraStarted this.isOpen: ${this.isOpen}.`);
    if (!this.isOpen) {
      return;
    }
    const type: CameraStartType = data.type;
    const isReset: boolean =
      type === CameraStartType.CHANGE_OUTPUT_TYPE ||
        type === CameraStartType.CHANGE_MODE ||
        type === CameraStartType.SWITCH_CAMERA ||
        type === CameraStartType.SWITCH_CAMERA_CHANGE_MODE ||
        type === CameraStartType.WARM_START_WITH_MODE_AND_POS;
    HiLog.i(TREASURE_BOX_TAG, `onCameraStarted begin, camera start type: ${type}, isReset: ${isReset}.`);
    if (!isReset) {
      return;
    }
    this.treasureBoxRefreshTriggerType = TreasureBoxRefreshTriggerType.START_CAMERA;
    if (this.cameraStartedListRefreshTimerId !== -1) {
      clearTimeout(this.cameraStartedListRefreshTimerId);
    }
    this.cameraStartedListRefreshTimerId = setTimeout((): void => {
      this.cameraStartedListRefreshTimerId = -1;
      this.refreshTreasureBoxView();
    }, 0);
  }

  private onRefreshTreasureBoxView(): void {
    this.refreshTreasureBoxView();
  }

  // 公共方法，刷新百宝箱显示
  private refreshTreasureBoxView(): void {
    treasureBoxConfig.setListOffset(0);
    // 是否是设置页恢复默认值导致的百宝箱刷新
    let triggeredByRestore: boolean | undefined = AppStorage.get('refreshTreasureBoxTriggeredByRestore');
    // 是否是CameraActionType.STARTED回调导致的百宝箱刷新
    let startCamera: boolean = this.treasureBoxRefreshTriggerType === TreasureBoxRefreshTriggerType.START_CAMERA;
    // 设置页恢复默认值时会同时触发changeFunctionValue、startCamera, 导致百宝箱闪烁
    // 恢复默认值场景只在startCamera时才刷新百宝箱，防止百宝箱闪烁
    let needResetFirstListFlag: boolean = (triggeredByRestore && startCamera) || !triggeredByRestore;
    if (needResetFirstListFlag) {
      this.resetFirstListFlag = !this.resetFirstListFlag;
      AppStorage.setOrCreate('refreshTreasureBoxTriggeredByRestore', false);
    }
    if (this.selector !== FunctionId.NONE) {
      this.changeSelectorNone(false);
    }
  }

  // 自适应布局设置百宝箱内部ux
  private initDistance(): void {
    HiLog.i(TREASURE_BOX_TAG, 'initDistance begin.');
    const spaceGained: number = this.arrowUpDistance - TREASURE_BOX_ELEMENT_HEIGHT;
    this.elementTopMargin = Math.max(Math.min(spaceGained, ELEMENT_TOP_MAX_MARGIN), 0) + ARROW_HEIGHT;
    HiLog.i(TREASURE_BOX_TAG, `elementTopMargin is ${this.elementTopMargin}.`);
    this.changeMargins();
  }

  // lem内外屏联动涉及arrowUpDistance变化
  private changeDistance(): void {
    HiLog.i(TREASURE_BOX_TAG, 'changeDistance begin.');
    this.arrowUpDistance = AdaptiveLayoutService.getInstance().arrowUpDistance;
    if (this.arrowUpDistance === 0) {
      return;
    }
    this.elementTopMargin = Math.max(Math.min(this.arrowUpDistance - TREASURE_BOX_ELEMENT_HEIGHT,
          ELEMENT_TOP_MAX_MARGIN), 0) + ARROW_HEIGHT;
    HiLog.i(TREASURE_BOX_TAG, `changeDistance ElementTopMargin is ${this.elementTopMargin}.`);
    this.changeMargins();
  }

  // 一级界面进入二级界面
  private async changeSelector(functionId: FunctionId): Promise<void> {
    HiLog.i(TREASURE_BOX_TAG, `changeSelector functionId: ${functionId}, selector: ${this.selector}, ` +
      `isHalfCollapsLEM: ${this.isHalfCollapsLEM}.`);
    if (functionId === this.selector || functionId === FunctionId.NONE) {
      return;
    }
    if (!this.isOpen) {
      this.selector = functionId;
      return;
    }

    const functionImpl = FeatureManager.getInstance().getFunction(functionId);
    if (!!functionImpl) {
      const length: number = Array.from<[ValueType, UiElement]>(functionImpl.getUiElements(RenderLocation.TREASURE_BOX))
        .filter(value => value[0] !== UiElement.DEFAULT).length;
      treasureBoxConfig.setSecondListLength(length);
    }

    if (this.selector !== FunctionId.NONE) {
      this.selector = functionId;
      return;
    }

    this.selector = functionId;
    const list: FunctionId[] = treasureBoxConfig.getFirstList();
    const index: number = list.indexOf(this.selector);
    if (index === -1 || TREASURE_BOX_IMAGE_ELEMENT.has(this.selector) || SystemLanguageUtil.isRTL()) {
      return;
    }
    // 一二级切换为滑动动效调整时序
    await UuidUtil.sleep(SLEEP_TIME);
    this.isFirstToSecond = true;
  }

  // 二级界面退出一级界面
  private async changeSelectorNone(transAnimateShow: boolean, event?: string): Promise<void> {
    if (this.selector === FunctionId.NONE) {
      return;
    }
    HiLog.i(TREASURE_BOX_TAG, `changeSelectorNone, second level to first level, selector: ${this.selector}, event: ${event}.`);
    const recordSelector: FunctionId = this.selector;
    this.selector = FunctionId.NONE;
    if (!this.isOpen) {
      return;
    }
    const list: FunctionId[] = treasureBoxConfig.getFirstList();
    const index: number = list.indexOf(recordSelector);
    if (index === -1 || !transAnimateShow || SystemLanguageUtil.isRTL()) {
      treasureBoxConfig.setListOffset(0);
      return;
    }
    // 一二级切换为滑动动效调整时序
    await UuidUtil.sleep(SLEEP_TIME);
    this.isFirstToSecond = false;
  }

  build() {
    Stack() {
      ArrowButton({
        uncollapsBegin: (data: boolean) => this.beforeUncollapsAnimation(data),
        uncollapsEnd: (data: boolean) => this.afterUncollapsAnimation(data),
        transDistance: $arrowTransDistance,
        treasureBoxOpacity: $treasureBoxOpacity,
        functionId: this.selector
      })

      if (this.isShowTreasureBox) {
        Stack() {
          if (this.selector === FunctionId.NONE) {
            FirstLevelList({
              recordSelector: this.recordSelector,
              changeSelector: (functionId: FunctionId) => this.changeSelector(functionId),
              resetListFlag: this.resetFirstListFlag
            })
              .onDisAppear(() => {
                HiLog.i(TREASURE_BOX_TAG, 'FirstLevelList disAppear');
              })
              .width('100%')
              .margin(this.getMarginValue())
              .transition(treasureBoxConfig.getListReleaseAnimation(this.treasureBoxAnimationState))
          }
          if (this.selector !== FunctionId.NONE) {
            if (!this.isHalfCollapsLEM) {
              BackButton({
                topMargin: this.elementTopMargin,
                goBack: () => this.changeSelectorNone(true),
                functionId: this.selector,
                isHideAnimation: true,
              }).transition(treasureBoxConfig.getListReleaseAnimation())
            }
            SecondLevelList({
              setTimeout: () => this.setTimeoutForTreasureBox(),
              clearTimeout: () => this.clearTimeoutForTreasureBox()
            })
              .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
              .width(this.isVdeSemiCollapsed ? this.displayWidth :
                this.displayWidth - BACK_BUTTON_LEFT_MARGIN - BACK_BUTTON_SIDE_LENGTH +
                  SECOND_LEVEL_LIST_LENGTH_SUPPLEMENT)
              .margin(this.getSecondListMargin())
              .transition(treasureBoxConfig.getListReleaseAnimation())
              .position(this.getPositionSecondBox())

          }

          if (this.isHalfCollapsLEM && !this.isVdeSemiCollapsed) {
            Column() {
            }
            .width(BACK_BUTTON_LEFT_MARGIN + BACK_BUTTON_SIDE_LENGTH)
            .height(50)
            .margin({ top: 30 })
            .shadow({ radius: 30, color: this.isShowRingLightView ? Color.White : Color.Black, offsetX: 48 })
            .position({ x: -57 })
            .hitTestBehavior(HitTestMode.Transparent)

            Column() {
            }
            .width(BACK_BUTTON_LEFT_MARGIN + BACK_BUTTON_SIDE_LENGTH)
            .height(50)
            .margin({ left: 364, top: 30 })
            .shadow({ radius: 30, color: this.isShowRingLightView ? Color.White : Color.Black, offsetX: -48 })
            .hitTestBehavior(HitTestMode.Transparent)
          }
        }
        .alignContent(Alignment.TopStart)
        .backgroundColor(this.isHalfCollapsLEM ? '' : '#191B1D')
        .borderRadius(this.isHalfCollapsLEM ? {} : {
          topLeft: $r('sys.float.ohos_id_corner_radius_dialog'),
          topRight: $r('sys.float.ohos_id_corner_radius_dialog'),
          bottomLeft: 0,
          bottomRight: 0
        })
        .opacity(this.treasureBoxOpacity)
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      }
    }
    .height(this.getTreasureBoxHeight())
    .width(DeviceInfo.isPhone() ? '100%' : this.displayWidth)
    .alignContent(Alignment.Top)
    .clip(this.isHalfCollapsLEM ? false : true)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .translate({ x: 0, y: this.isHalfCollapsLEM ? 0 : this.arrowTransDistance + 8, z: 0 })
    .visibility(this.videoState !== RecordingState.READY && this.videoState !== RecordingState.STOPPING ?
      Visibility.None : Visibility.Visible)
  }

  private getMarginValue(): Margin {
    HiLog.i(TREASURE_BOX_TAG, `getMaginValue: ${this.elementTopMargin}`);
    return { top: Math.max(this.elementTopMargin, ARROW_HEIGHT)};
  }

  private onAnimationDone(): void {
    if (!this.transAnimationDone) {
      return;
    }
    HiLog.i(TREASURE_BOX_TAG, 'trans animation done.');
    this.renderLocation = RenderLocation.NONE;
    if (this.selector === FunctionId.NONE) {
      this.recordSelector = FunctionId.NONE;
    }
  }

  private getSecondListMargin(): Margin {
    if (this.isVdeSemiCollapsed) {
      return { top: this.elementTopMargin, left: 0, right: 0 };
    }
    return {
      top: this.elementTopMargin,
      left: SystemLanguageUtil.isRTL() ? 0 : BACK_BUTTON_LEFT_MARGIN + BACK_BUTTON_SIDE_LENGTH,
      right: SystemLanguageUtil.isRTL() ? BACK_BUTTON_SIDE_LENGTH + BACK_BUTTON_SIDE_LENGTH : 0
    };
  }

  private getPositionSecondBox(): PositionType {
    if (this.isVdeSemiCollapsed) {
      return { x: 0, y: 0 };
    } else if (this.isHalfCollapsLEM) {
      return { x: -(BACK_BUTTON_LEFT_MARGIN + BACK_BUTTON_SIDE_LENGTH) / 2, y: 0 };
    } else {
      return { x: 0, y: 0 };
    }
  }

  private getTreasureBoxHeight(): number {
    if (this.isVdeSemiCollapsed) {
      return 120;
    }
    return this.isHalfCollapsLEM && this.selector === FunctionId.NONE ? 80 :
      Math.ceil(this.arrowUpDistance) + BOTTOM_MARGIN + ARROW_HEIGHT;
  }

  private setTimeoutForTreasureBox(): void {
    this.clearTimeoutForTreasureBox();
    this.treasureBoxTimerId = setTimeout(() => {
      this.selector = FunctionId.NONE;
    }, this.enableScreenReader ? 3 * 5000 : 5000); // 开启屏幕朗读延长3倍时间自动关闭
    HiLog.d(TREASURE_BOX_TAG, `setTimeoutForTreasureBox Id: ${this.treasureBoxTimerId}`);
  }

  private clearTimeoutForTreasureBox(): void {
    HiLog.d(TREASURE_BOX_TAG, `clearTimeoutForTreasureBox: Id: ${this.treasureBoxTimerId}`);
    if (Number.MIN_VALUE !== this.treasureBoxTimerId) {
      clearTimeout(this.treasureBoxTimerId);
      this.treasureBoxTimerId = Number.MIN_VALUE;
    }
  }
}