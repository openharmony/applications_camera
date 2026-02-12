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

import lazy { BaseFunction } from '../../../function/core/BaseFunction';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { FunctionAction } from '../../../function/core/FunctionAction';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { Dispatch, getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { ZIndex } from '../../../utils/ZIndex';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { TipService } from '../../tip/TipService';
import lazy { OnModeData } from '../../../utils/types';
import lazy { LogStyleMode } from '../../../function/enumbase/LogStyleMode';
import treasureBoxConfig from './TreasureBoxConfig';
import lazy { ImageElement } from './button/icon/ImageElement';
import lazy { SecondListButton } from './button/SecondListButton';
import lazy { BACK_BUTTON_MIN_RIGHT_MARGIN, TREASURE_BOX_TAG } from './TreasureBox';
import lazy { FunctionConflictParamData, FunctionType, TREASURE_BOX_IMAGE_ELEMENT } from '../common/DataType';
import lazy { FunctionValueType, ValueType } from '../../../utils/types';
import camera from '@ohos.multimedia.camera';
import lazy { BlurAnimateUtil } from '../../../utils/BlurAnimateUtil';
import lazy { AccessibilityUtils } from '../../../utils/AccessibilityUtils';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import ResGetter from '../../../utils/ResGetter';
import lazy { TabBarAction } from '../../tabbar/TabBarAction';
import lazy { OutputOperation } from '../../../function/outputswitcher/OutputOperation';
import Configuration from '@system.configuration';
import lazy { StoreManager } from '../../../worker/StoreManager';
import lazy { MirrorData } from '../../../function/enumbase/MirrorData';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { execAction } from '../../../redux/ActionRegistry';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';
import lazy { LengthMetrics } from '@kit.ArkUI';
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';

/* instrument ignore file */
const TAG: string = 'SecondLevelList';

export const FILTER_LIST_SPACE = 4;

export const EFFECT_SELECTED_DELAY: number = 200;

const TYPE_CLASSIC = 4; // 经典
const TYPE_MODERN = 5; // 现代

class MirrorSelfieMenuDataStruct {
  public mirrorSelfieItemDataList: MirrorData[] = [];
}

@Component
export struct SecondLevelList {
  // 全局数据
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  protected mStoreManager: StoreManager = StoreManager.getInstance();
  private mDispatch: Dispatch = (data) => data;
  private isFrontCamera: boolean = false;
  private isFilterListStart: boolean = false;
  @State uiEnable: boolean = true;
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @State @Watch('onListChanged') mainList: FunctionType[] = [];
  private scrollerMap: Map<boolean, Scroller> = new Map([
    [true, new Scroller()],
    [false, new Scroller()]
  ]);
  @StorageLink('treasureBoxSelector') @Watch('resetSecondList') selector: FunctionId = FunctionId.NONE;
  @State selectModeIndex: number = 0;
  @State listSpace: number = 0;
  @State secondIconShowTime: number = 0;
  @State mode: ModeType = ModeType.NONE
  // 更新二级界面动效
  @State isReloadSecondAnimation: boolean = false;
  @State customFilterEffectEnable: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  private setTimeout: Function = () => {
  };
  private clearTimeout: Function = () => {
  };
  private realFilterTime: number = 0;
  private selectBorderTime: number = 0; // 除去实时滤镜之外的框选中元素：如XMage
  private selectBorderThrottleDur: number = 250; // ux要对比双，一定时间范围可点击，时间频率可调
  private windowWidth: number = 0;
  @State mirrorSelfieItemDataList: MirrorData[] = [];
  @State realTimeFilterType: number = -1;
  // 魔镜外屏的index，不是二级菜单的（跟二级菜单index相差 1）
  @State @Watch('changeSelectedMirrorSelfieIndex') currentMirrorSelfieItemIndex: number = -1;
  @State refreshMirrorSelfieFlag: boolean = false;
  @State tabSelector: FunctionId = FunctionId.NONE;

  aboutToAppear(): void {
    HiLog.i(TAG, `aboutToAppear begin, selector: ${this.selector}.`);
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.customFilterEffectEnable = state.get<boolean>('customFilterStyleReducer', 'customFilterEffectEnable');
      this.currentMirrorSelfieItemIndex = state.get<number>('mirrorSelfieReducer', 'currentItemIndex');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.tabSelector = state.get<FunctionId>('tabBarReducer', 'tabBarSelector');
    }, (dispatch: Dispatch): void => {
      this.mDispatch = dispatch;
    });
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      (data: FunctionConflictParamData) => this.handleConflict(data), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      (data: FunctionValueType) => this.filterResetList(data), this.mBase.hashCode());
    this.resetSecondList();
    this.mEventBus.on(ActionType.ACTION_PREVIEW_CLICKED, () => this.backToFirstLevelList(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LOG_MODE_CHANGE, (data: OnModeData) => this.updateOnModeValue(data),
      this.mBase.hashCode());
    if (this.isVdeCollapsed) {
      this.setTimeout();
    }
    this.getMirrorSelfieMenuData();
    HiLog.i(TAG, `aboutToAppear end, secondList length: ${this.mainList.length}.`);
  }

  aboutToDisappear() {
    this.mEventBus.clear(this.mBase.hashCode());
    if (this.isFilterListStart) {
      HiLog.i(TAG, 'RealTimeFilter.filterListStop');
      this.isFilterListStart = false;
    }
    this.mSubscriber.destroy();
  }

  private updateOnModeValue(data: OnModeData): void {
    HiLog.i(TAG, `updateOnModeValue: ${data.isOn}.`)
  }

  private filterListStart(): void {
    this.isFrontCamera =
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
      camera.CameraPosition.CAMERA_POSITION_FRONT;
    this.isFilterListStart = true;
    HiLog.i(TAG, 'RealTimeFilter.filterListStart');
  }

  private filterResetList(data: FunctionValueType): void {
    const videoResolution = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION);
    // 切换拍照格式 百宝箱二级照片比例要返回
    if (this.selector === FunctionId.ASPECT_RATIO && data.id === FunctionId.PHOTO_FORMAT) {
      this.selector = FunctionId.NONE;
    }
  }

  private onListChanged(): void {
    treasureBoxConfig.setSecondListLength(this.mainList.length);
  }

  // 从设置页返回相机，需要重新获取魔镜数据
  private refreshMirrorMenuData(data?: MirrorSelfieMenuDataStruct): void {
    if (data && data.mirrorSelfieItemDataList) {
      HiLog.i(TAG,
        `back from MirrorSelfieMenuSettingView, old data length: ${this.mirrorSelfieItemDataList.length},
          new data length: ${data?.mirrorSelfieItemDataList.length}`);
      this.mirrorSelfieItemDataList = data?.mirrorSelfieItemDataList;
      if (this.currentMirrorSelfieItemIndex > data.mirrorSelfieItemDataList.length - 3) {
        HiLog.i(TAG, `change currentMirrorSelfieItemIndex, index: ${this.currentMirrorSelfieItemIndex}`);
        this.currentMirrorSelfieItemIndex = data.mirrorSelfieItemDataList.length - 3;
        this.mDispatch(execAction('MirrorSelfieAction', 'setMirrorItemIndex', this.currentMirrorSelfieItemIndex));
      }
    }
    this.resetSecondList();
  }

  private async getMirrorSelfieMenuData(): Promise<void> {
    HiLog.i(TAG, 'second level list getMirrorSelfieMenuData');
    if (this.mirrorSelfieItemDataList.length > 0) {
      this.refreshMirrorSelfieFlag = !this.refreshMirrorSelfieFlag;
    }
  }

  private changeSelectedMirrorSelfieIndex(): void {
    HiLog.i(TAG, `selectedMirrorSelfie Item changed, currentItemIndex: ${this.currentMirrorSelfieItemIndex}`);
    this.selectModeIndex = this.currentMirrorSelfieItemIndex + 1;
  }

  // 显示二级界面中正在被使用的模式
  private getSelectedMode(value: ValueType): number {
    if (this.customFilterEffectEnable &&
      (this.mode === ModeType.PHOTO && OutputOperation.isPanPhotoOutput(this.mode))) {
      return -1;
    }
    if (!value || value === -1) {
      value = 0;
    }
    for (let i = 0; i < this.mainList.length; i++) {
      if (this.mainList[i].value === value) {
        return i;
      }
    }
    return -1;
  }

  private handleConflict(data: FunctionConflictParamData): void {
    HiLog.i(TAG, `handleConflict id: ${data.id}, conflictParam: ${data.conflictParam}, selector: ${this.selector}.`);
    if (data.id !== this.selector || this.selector !== FunctionId.FRAME_RATE) {
      return;
    }
    this.resetSecondList();
  }

  /**
   * 从其他页面切换到EFFECT页面
   * 超级微距和视频帧率60有冲突(打开超级微距,视频帧率60置灰且不可点击)
   */
  private resetSecondList(): void {
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(this.selector);
    if (!functionImpl) {
      return;
    }
    this.mainList = Array.from<Object[]>(functionImpl.getUiElements(RenderLocation.TREASURE_BOX))
      .filter(value => value[0] != UiElement.DEFAULT)
      .map((item: Object[]) => {
        let res: FunctionType = { uiElement: item[1] as UiElement, value: item[0] as ValueType };
        return res;
      });
    this.selectModeIndex = this.getSelectedMode(functionImpl.getValue());
    this.listSpace = treasureBoxConfig.getListSpace();
    HiLog.i(TAG, 'reset second level list');
    this.isReloadSecondAnimation = !this.isReloadSecondAnimation;
  }

  build() {
    Column() {
      if (this.isReloadSecondAnimation) {
        this.listBuilder(this.scrollerMap.get(true) || new Scroller());
      } else {
        this.listBuilder(this.scrollerMap.get(false) || new Scroller());
      }
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  listBuilder(scroller: Scroller) {
    List({
      initialIndex: TREASURE_BOX_IMAGE_ELEMENT.has(this.selector) ? this.selectModeIndex : 0,
      space: TREASURE_BOX_IMAGE_ELEMENT.has(this.selector) ? FILTER_LIST_SPACE : this.listSpace,
      scroller: scroller
    }) {
      this.listBuilderCommon();
    }
    .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(20) })
    .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
      if (scrollState === ScrollState.Idle) {
        return;
      }
    })
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .zIndex(ZIndex.MIDDLE_BOTTOM)
    // 无障碍开启会导致聚焦过慢
    .enabled(this.enableScreenReader ? true : this.uiEnable)
    .listDirection(Axis.Horizontal)
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .key(ComponentIdKeys.TREASURE_BOX_SECOND_LIST)
    .onAppear(() => {
      HiLog.i(TAG, `second level list show index: ${this.selectModeIndex}.`);
      this.onAppearChangeOffset(scroller);
    })
  }

  @Builder
  listBuilderMirrorSelfie() {
    if (this.refreshMirrorSelfieFlag) {
      this.mirrorSelfieItemBuilder();
    } else {
      this.mirrorSelfieItemBuilder();
    }
  }

  @Builder
  mirrorSelfieItemBuilder() {
    ForEach(this.mirrorSelfieItemDataList, (item: MirrorData, index: number = 0) => {
      ListItem() {
      }
      .enabled(true)
      .margin(this.getMargin(index))
      .key(ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.selector, index))
      .id(ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.selector, index))
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_button')))
      .onAppear(() => {
        if (index === this.selectModeIndex && this.enableScreenReader) {
          AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance()
            .getKey(TREASURE_BOX_TAG, this.selector, index));
        }
      })
      .onTouch((event: TouchEvent) => {
        this.onListBuilderCommonTouch(event);
      })
      .onClick((event) => {
        HiLog.i(TAG, `onListBuilderMirrorSelfieClick, selectModeIndex: ${this.selectModeIndex}, index: ${index}`);
        if (index === this.selectModeIndex && index !== this.mirrorSelfieItemDataList.length - 1) {
          return;
        }
        let curTime: number = Date.now();
        if (TREASURE_BOX_IMAGE_ELEMENT.has(this.selector) &&
          curTime - this.selectBorderTime <= this.selectBorderThrottleDur) {
          return;
        }
        this.selectBorderTime = curTime;
        this.onListBuilderMirrorSelfieClick(index, item);
      });
    })
  }

  @Builder
  listBuilderCommon() {
    ForEach(this.mainList, (item: FunctionType, index: number = 0) => {
      ListItem() {
        this.itemBuilder(item, index)
      }
      .enabled(item.uiElement.disabled ? false : true)
      .key(ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.selector, item.value))
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilitySelected(index === this.selectModeIndex)
      .accessibilityText(this.getAbText(item, index))
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .id(ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.selector, item.value))
      .margin(this.getMargin(index))
      .onTouch((event: TouchEvent) => {
        this.onListBuilderCommonTouch(event, index);
      })
      .onClick((event) => {
        this.onListItemClick(index, item);
      })
      .onAppear(() => {
        HiLog.i(TAG, `ListLength: ${this.mainList.length}, title: ${item.uiElement.title}, index: ${index}`);
        if (index === this.selectModeIndex && this.enableScreenReader) {
          AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance()
            .getKey(TREASURE_BOX_TAG, this.selector, item.value));
        }
      })
    })
  }

  private onListItemClick(index: number, item: FunctionType) {
    if (index === this.selectModeIndex) {
      return;
    }
    if (AppStorage.get('collaborate_status')) {
      this.mStoreManager.postMessage(execAction('CollaborateAction', 'loadExternalScreenBlur'));
    }
    let curTime: number = Date.now();
    if (TREASURE_BOX_IMAGE_ELEMENT.has(this.selector) &&
      curTime - this.selectBorderTime <= this.selectBorderThrottleDur) {
      return;
    }
    this.selectBorderTime = curTime;
    if (this.enableScreenReader) {
      AccessibilityUtils.sendAnnounceAccessibilityEvent(
        `${ResGetter.getStringSafe($r('app.string.accessibility_checked'))} ${this.getAbText(item,
          index)}`);
    }
    if (this.isVdeCollapsed) {
      this.onButtonClickVde(index, item);
      this.clearTimeout();
    } else {
      this.onListBuilderCommonClick(index, item);
    }
  }

  private getMargin(index: number = 0): Margin {
    let listLength: number = this.mainList.length;
    if (this.isVdeCollapsed) {
      return treasureBoxConfig.getVdeCollapsedMargin(index, listLength);
    }
    if (this.isVdeSemiCollapsed) {
      return treasureBoxConfig.getVdeSemiCollapsMargin(index, this.selector, listLength);
    }
    if (this.isHalfCollapsLEM) {
      return treasureBoxConfig.getHalfCollapsLemMargin(index, this.selector, listLength);
    }
    return {
      left: this.getCommonSecondListLeftMargin(index, this.selector, listLength),
      right: this.getCommonSecondListRightMargin(index, this.selector, listLength),
    }
  }

  private getCommonSecondListLeftMargin(index: number, selector: FunctionId, length: number): string | number {
    if (SystemLanguageUtil.isRTL()) {
      return treasureBoxConfig.getSecondListRightMargin(index, selector, length);
    }
    return treasureBoxConfig.getSecondListLeftMargin(index, selector, length);
  }

  private getCommonSecondListRightMargin(index: number, selector: FunctionId, length: number): string | number {
    if (SystemLanguageUtil.isRTL()) {
      return treasureBoxConfig.getSecondListLeftMargin(index, selector, length);
    }
    return treasureBoxConfig.getSecondListRightMargin(index, selector, length);
  }

  private getAbText(item: FunctionType, index: number): string {
    HiLog.i(TAG, 'getABText item = ' + item, 'index = ' + item);
    if (this.enableScreenReader && !this.isOpenTouchGuide) {
      return '';
    }
    return `${ResGetter.getStringSafe(item.uiElement.accessibilityDescription)}`;
  }

  private onListBuilderCommonTouch(event: TouchEvent, index?: number) {
    if (index === this.selectModeIndex) {
      return;
    }
    if (event.type === TouchType.Down) {
      if (BlurAnimateUtil.checkIfNeedBlur(this.selector)) {
        BlurAnimateUtil.generatePixelMapFromSurface();
      }
    }
  }

  @Builder
  itemBuilder(item: FunctionType, index: number) {
    if (TREASURE_BOX_IMAGE_ELEMENT.has(this.selector)) {
      ImageElement({
        functionId: this.selector,
        mUiElement: item.uiElement,
        isSelected: index === this.selectModeIndex,
        curItemValue: item.value,
      })
        .transition(treasureBoxConfig.getSecondListItemDisappearAnimation())
        .onAppear(() => {
          HiLog.i(TAG, `ImageElement Appear: ${item.uiElement.title}, ${index}`);
        })
        .key(index === this.selectModeIndex ?
          `${ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.selector, item.value)}-choose` : '')
    } else {
      SecondListButton({
        uiElement: item.uiElement, isSelected: index === this.selectModeIndex,
        functionId: item.id
      })
        .key(index === this.selectModeIndex ?
          `${ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.selector, item.value)}-choose` : '')
    }
  }

  private onListBuilderMirrorSelfieClick(index: number, item: MirrorData): void {
    HiLog.i(TAG, `onClick the listItem, mirrorDataListLength: ${this.mirrorSelfieItemDataList.length}`);
    if (this.selectModeIndex === index || !this.uiEnable) {
      return;
    }
    this.selectModeIndex = index;
    if (index === 0) { // 关闭双屏同显
      HiLog.i(TAG, 'Close collaboration');
      this.mDispatch(execAction('MirrorSelfieAction', 'setMirrorItemIndex', -1));
      this.mDispatch(FunctionAction.changeFunctionValue(this.selector, false, RenderLocation.TREASURE_BOX));
    } else if (index === this.mirrorSelfieItemDataList.length - 1 &&
      !getStates().get<boolean>('securityCameraReducer', 'isSecurityCamera')) { // 跳转到系统设置页
      HiLog.i(TAG, 'jump to setting mirror Selfie pattern');
      this.mDispatch(execAction('MirrorSelfieAction', 'showMirrorSelfieSettingView', true));
    } else { // 开启双屏同显，自动切换至内屏选择的图案
      HiLog.i(TAG, 'open collaboration and switch to the pattern');
      AppStorage.setOrCreate('reloadMirrorSwiperItemToIndex', true);
      this.mDispatch(execAction('MirrorSelfieAction', 'setMirrorItemIndex', index - 1));
      this.mDispatch(FunctionAction.changeFunctionValue(this.selector, true, RenderLocation.TREASURE_BOX));
    }
  }

  private onListBuilderCommonClick(index: number, item: FunctionType) {
    if (this.selectModeIndex === index || !this.uiEnable) {
      return;
    }
    if (this.tabSelector !== FunctionId.NONE) {
      this.mDispatch(TabBarAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE));
    }
    if (item.uiElement.desc) {
      TipService.getInstance().showTip(item.uiElement.desc, 3000);
    }
    this.mDispatch(FunctionAction.changeFunctionValue(this.selector, item.value, RenderLocation.TREASURE_BOX));
    this.broadcastTabBarEvents();
    this.selectModeIndex = index;
    if (this.isHalfCollapsLEM) {
      this.selector = FunctionId.NONE;
    }
  }

  onButtonClickVde(index: number, item: FunctionType): void {
    if (this.selectModeIndex === index) {
      this.selector = FunctionId.NONE;
      return;
    }
    if (!this.uiEnable) {
      return;
    }
    if (item.uiElement.desc) {
      TipService.getInstance().showTip(item.uiElement.desc, 3000);
    }
    this.mDispatch(FunctionAction.changeFunctionValue(this.selector, item.value, RenderLocation.TREASURE_BOX));
    this.broadcastTabBarEvents();
    this.selectModeIndex = index;
    this.selector = FunctionId.NONE;
    return;
  }

  private onAppearChangeOffset(scroller: Scroller): void {
    const offset = scroller.currentOffset()?.xOffset;
    if (!offset || offset === null) {
      return;
    }
    scroller.scrollTo({ xOffset: Math.max(offset - BACK_BUTTON_MIN_RIGHT_MARGIN, 0), yOffset: 0 });
  }

  private broadcastTabBarEvents(): void {
    this.mDispatch(TabBarAction.updateTabBarArr());
    this.mDispatch(TabBarAction.updatePositionAndOpacity(true));
    this.mDispatch(TabBarAction.updatePopUpButton());
    this.mDispatch(TabBarAction.updateLinkageButton());
    this.mDispatch(TabBarAction.updateTextList());
  }

  backToFirstLevelList() {
    if (this.isVdeCollapsed && this.selector !== FunctionId.NONE) {
      this.clearTimeout;
      this.selector = FunctionId.NONE;
    }
  }
}