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

import lazy { HiLog } from '../../../utils/HiLog';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { Dispatch, getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { TreasureBoxAction } from '../reduce/TreasureBoxAction';
import lazy { CameraStartType, CameraStartTypeStruct } from '../../../camera/uithread/CameraAction';
import lazy { FunctionValueType, ValueType } from '../../../utils/types';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { SLEEP_TIME, TREASURE_BOX_ELEMENT_INNER_WIDTH } from '../common/DataType';
import lazy { ZIndex } from '../../../utils/ZIndex';
import lazy { LandscapeFirstLevelList } from './LandscapeFirstLevelList';
import landscapeTreasureBoxConfig from './LandscapeTreasureBoxConfig';
import lazy { LandscapeSecondLevelList } from './LandscapeSecondLevelList';
import lazy { UuidUtil } from '../../../utils/UuidUtil';
import lazy { PhotoFormatMode } from '../../../function/enumbase/PhotoFormatMode';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { CameraActionType } from '../../../redux/actions/CameraActionType';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { RecordActionType } from '../../../redux/actions/RecordActionType';
import lazy { TreasureBoxActionType } from '../../../redux/actions/TreasureBoxActionType';
import lazy { SettingViewActionType } from '../../../redux/actions/SettingViewActionType';
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { RecordingState } from '../../../function/recordcontrol/RecordAction';
import lazy { CollaborateActionType } from '../../../redux/actions/CollaborateActionType';
import lazy { GlobalContext } from '../../../utils/GlobalContext';

/* instrument ignore file */
const TAG: string = 'LandscapeTreasureBox';

const REFRESH_MINIMUM_TIME: number = 100;

const SLEEP: Function = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

export const LANDSCAPE_TREASURE_BOX_TAG: string = 'LandscapeTreasureBox';

// 默认显示的长度
export const LANDSCAPE_DEFAULT_SHOW_ELEMENT_LENGTH: number = 5;

interface ProIsoValue {
  functionId: FunctionId,
  value: number
}

@Component
export struct LandscapeTreasureBox {
  // 全局变量
  private mBase: BaseComponent = new BaseComponent();
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State uiEnable: boolean = true;
  // UX相关变量
  @Prop treasureBoxHeight: number = 0;
  @State isShowSemiCollapsed: boolean = false;
  // 百宝箱业务变量
  @StorageLink('treasureBoxSelector') @Watch('onSelectorChanged') selector: FunctionId = FunctionId.NONE;
  @State recordSelector: FunctionId = FunctionId.NONE;
  // List切换动效相关变量
  @State resetFirstListFlag: boolean = false;
  @State isFirstShow: boolean = true;
  @State isFirstToSecond: boolean = true;
  @State @Watch('onAnimationDone') transAnimationDone: boolean = false;
  @StorageLink('isDownSuperSlowBtnState') @Watch('watchSuperSlowDown') isDownSuperSlowBtn: boolean = false;
  @State @Watch('refreshTreasureBoxView') isLightPaintingFlashShow: boolean = false;
  @State @Watch('onCollapsStatusChange') isShowTricollaps: boolean = false;
  @State @Watch('onCollapsStatusChange') isShowLandscape: boolean = false;
  @State @Watch('refreshTreasureBoxView') isNightStarPortraitFlashShow: boolean = false;
  @State superIsoValue: number = 0;
  private lastRefreshTime: number = 0;
  private mDispatch: Dispatch = (data) => data;
  private recordZoomRatio: number = 1;
  @State mode: ModeType = ModeType.NONE;
  @Prop isHdr: boolean = false;
  @StorageLink('changeCustomFilterImmersiveImmediately') @Watch('toggleCustomFilter') isCustomFilterImmersiveImmediately: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isLightPaintingFlashShow = state.get<boolean>('settingReducer', 'isLightPaintingFlashShow');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isNightStarPortraitFlashShow = state.get<boolean>('settingReducer', 'isNightStarPortraitFlashShow');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
    }, (dispatch: Dispatch): void => {
      this.mDispatch = dispatch;
    });

    this.mEventBus.on(CameraActionType.STARTED, (data: CameraStartTypeStruct) => {
      const isReset: boolean = data.type === CameraStartType.CHANGE_MODE ||
        data.type === CameraStartType.CHANGE_OUTPUT_TYPE ||
        data.type === CameraStartType.SWITCH_CAMERA ||
        data.type === CameraStartType.SWITCH_CAMERA_CHANGE_MODE ||
        data.type === CameraStartType.WARM_START_WITH_MODE_AND_POS;
      if (isReset) {
        this.refreshTreasureBoxView();
      }
    }, this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, (data: FunctionValueType) =>
    this.refreshingInterface(data), this.mBase.hashCode());
    this.mEventBus.on([
      RecordActionType.START,
      RecordActionType.STOP
    ], () => { // 录像触发列表刷新场景
      if (this.isDownSuperSlowBtn) { // 超慢按下触发列表更新后续录制video不再触发
        return;
      }
      this.refreshTreasureBoxView();
    }, this.mBase.hashCode());
    this.mEventBus.on([
      TreasureBoxActionType.ACTION_REFRESH_TREASURE_BOX_VIEW,
      CollaborateActionType.SHOW_OR_HIDE_COLLABORATE_ICON], () => {
      this.refreshTreasureBoxView()
    }, this.mBase.hashCode());
    this.mEventBus.on([
      TreasureBoxActionType.ACTION_CHANGE_TREASURE_BOX_SELECTOR, //目前大屏调用CHANGE_TREASURE_BOX_SELECTOR事件均为关闭二级界面
      SettingViewActionType.ACTION_SHOW_SETTING_VIEW,
      TreasureBoxActionType.ACTION_CHANGE_WITH_ZOOM,
      ContextActionType.ABILITY_ON_BACKGROUND,
      ActionType.ACTION_PREVIEW_CLICKED,
      TreasureBoxActionType.ACTION_CLOSE_SECOND_TREASURE,
    ], (data: Object, event: string) => this.changeSelectorNone(true, true, event), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this),
      this.mBase.hashCode());
    landscapeTreasureBoxConfig.initMargins(this.isShowSemiCollapsed, this.treasureBoxHeight);
    this.refreshTreasureBoxView();
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
    this.mEventBus.on(ActionType.ACTION_UPDATE_PRO_PARAMETERS_VALUE, (data: ProIsoValue) =>
    this.updateSuperIsoValue(data), this.mBase.hashCode());
    this.toggleCustomFilter();
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  aboutToDisappear() {
    if (this.selector !== FunctionId.NONE) {
      this.selector = FunctionId.NONE;
      landscapeTreasureBoxConfig.setListOffset(0);
    }
    this.mEventBus.clear(this.mBase.hashCode());
    this.subscriber.destroy();
  }

  private updateSuperIsoValue(data: ProIsoValue): void {
  }

  private refreshingInterface(data: FunctionValueType): void {
    if (AppStorage.get('restoreFlag')) {
      return;
    }
    if (data.id === FunctionId.PHOTO_FORMAT) {
      this.refreshTreasureBoxView();
      return;
    }
  }

  private watchSuperSlowDown(): void {
    this.refreshTreasureBoxView();
  }

  private onCollapsStatusChange(): void {
    HiLog.i(TAG, `refreshTreasureBoxView onCollapsStatusChange isFirstShow:${this.isShowTricollaps}`);
    this.refreshTreasureBoxView();
  }

  // 公共方法，刷新百宝箱显示
  private async refreshTreasureBoxView(): Promise<void> {
    let currentTime: number = Date.now();
    let refreshInterval: number = currentTime - this.lastRefreshTime;
    HiLog.i(TAG, `refreshInterval:${refreshInterval}`);
    let pauseTime: number = 0;
    if (refreshInterval < REFRESH_MINIMUM_TIME) {
      pauseTime = REFRESH_MINIMUM_TIME - refreshInterval;
      HiLog.i(TAG, `pause :${refreshInterval}`);
      await SLEEP(pauseTime);
    }
    this.lastRefreshTime = currentTime + pauseTime;
    HiLog.i(TAG, `refreshTreasureBoxView begin, selector: ${this.selector}.`);
    landscapeTreasureBoxConfig.setListOffset(0);
    landscapeTreasureBoxConfig.setListOffsetError(0);
    landscapeTreasureBoxConfig.setIsFirstTimeInitCompleted(false);
    this.resetFirstListFlag = !this.resetFirstListFlag;
    if (this.selector !== FunctionId.NONE) {
      this.changeSelectorNone(false, true);
    }
  }

  private onSelectorChanged(): void {
    HiLog.i(TAG, `onSelectorChanged, treasureBox selector change to: ${this.selector}.`);
    if (this.selector !== FunctionId.NONE) {
      this.recordSelector = this.selector;
    }
  }

  private onAnimationDone(): void {
    if (this.transAnimationDone) {
      HiLog.i(TAG, 'trans animation done.');
      if (this.selector === FunctionId.NONE) {
        this.recordSelector = FunctionId.NONE;
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.selector === FunctionId.NONE) {
        LandscapeFirstLevelList({
          isFirstShow: $isFirstShow,
          resetListFlag: this.resetFirstListFlag,
          recordSelector: this.recordSelector,
          changeSelector: (functionId: FunctionId) => this.changeSelector(functionId),
          treasureBoxHeight: this.treasureBoxHeight
        })
          .transition(getListReleaseAnimation())
      } else {
        LandscapeSecondLevelList({
          changeSelectorNone: () => this.changeSelectorNone(true, true)
        })
          .transition(getListReleaseAnimation())
      }
    }
    .clip(true)
    .width(TREASURE_BOX_ELEMENT_INNER_WIDTH)
    .height(this.treasureBoxHeight)
  }

  private async changeSelector(functionId: FunctionId): Promise<void> {
    HiLog.i(TAG, `changeSelector functionId: ${functionId}, selector: ${this.selector}.`);
    if (functionId === this.selector || functionId === FunctionId.NONE) {
      return;
    }

    const functionImpl = FeatureManager.getInstance().getFunction(functionId);
    if (!!functionImpl) {
      const length: number = Array.from<[ValueType, UiElement]>(functionImpl.getUiElements(RenderLocation.TREASURE_BOX))
        .filter(value => value[0] !== UiElement.DEFAULT).length;
      landscapeTreasureBoxConfig.setSecondListLength(length);
    }

    if (this.selector !== FunctionId.NONE) {
      this.selector = functionId;
      return;
    }

    this.selector = functionId;
    const list: FunctionId[] = landscapeTreasureBoxConfig.getFirstList();
    const index: number = list.indexOf(this.selector);
    if (index === -1) {
      return;
    }
    // 一二级切换为滑动动效调整时序
    await UuidUtil.sleep(SLEEP_TIME);
    this.isFirstToSecond = true;
  }

  private onForeground(): void {
    this.toggleCustomFilter();
  }

  /*
   * 二级界面退出，返回一级界面
   * @param transAnimateShow：退出时是否显示滑动动效
   */
  private async changeSelectorNone(transAnimateShow: boolean, sendFromTreasureBox: boolean, event?: string): Promise<void> {
    if (this.selector === FunctionId.NONE) {
      return;
    }
    if (this.isCustomFilterImmersiveImmediately && sendFromTreasureBox && !GlobalContext.get().getIsPicker()) {
      HiLog.i(TAG, 'block for isCustomFilterImmersive');
      return;
    }
    HiLog.i(TAG, `changeSelectorNone, second level to first level, selector: ${this.selector}, event: ${event}.`);
    const selector: FunctionId = this.selector;
    this.selector = FunctionId.NONE;
    const list: FunctionId[] = landscapeTreasureBoxConfig.getFirstList();
    const index: number = list.indexOf(selector);
    if (index === -1 || !transAnimateShow) {
      landscapeTreasureBoxConfig.setListOffset(0);
      return;
    }
    // 一二级切换为滑动动效调整时序
    await UuidUtil.sleep(SLEEP_TIME);
    this.isFirstToSecond = false;
  }

  private toggleCustomFilter() {
    if (GlobalContext.get().getIsPicker()) {
      return;
    }
    HiLog.i(TAG, `toggleCustomFilter isCustomFilterImmersive: ${this.isCustomFilterImmersiveImmediately}`);
    if (this.isCustomFilterImmersiveImmediately) {
      this.changeSelectorNone(true, false);
    } else {
      this.changeSelectorNone(true, false);
    }
  }
}

function getListReleaseAnimation(): TransitionEffect {
  return TransitionEffect.asymmetric(
    TransitionEffect
      .OPACITY
      .animation({ duration: 100, curve: Curve.Friction, delay: 100 }),
    TransitionEffect
      .OPACITY
      .animation({ duration: 100, curve: Curve.Friction }))
}