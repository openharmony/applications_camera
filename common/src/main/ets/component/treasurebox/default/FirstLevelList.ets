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

import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import treasureBoxConfig from './TreasureBoxConfig';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { PhotoFormatMode } from '../../../function/enumbase/PhotoFormatMode';
import lazy { FirstListButton } from './button/FirstListButton';
import lazy {
  TREASURE_BOX_ELEMENT_HEIGHT,
  TREASURE_BOX_ELEMENT_WIDTH,
  TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH,
  TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH,
  TREASURE_BOX_ELEMENT_VDE_COLLAPS_HEIGHT
} from '../../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { TREASURE_BOX_TAG } from './TreasureBox';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { FunctionValueType } from '../../../utils/types';
import Configuration from '@system.configuration';
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { camera } from '@kit.CameraKit';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';

/* instrument ignore file */
const MAIN_CAMERA_ZOOM = 1;
const D_VALUE = 0.1;
const DEFAULT_LOAD_COUNT: number = 5
const LIST_SCROLL_THRESHOLD = 1.5;
const MARGIN_COUNT = 2;

const TAG: string = 'FirstLevelList';

interface ProIsoValue {
  functionId: FunctionId,
  value: number
}

@Component
export struct FirstLevelList {
  // 全局数据
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State uiEnable: boolean = true;
  @State displayWidth: number = 0;
  @State isLightPaintingFlashShow: boolean = false;
  @State isNightStarPortraitFlashShow: boolean = false;
  // 一二级界面切换相关
  private changeSelector: (functionId: FunctionId) => void = () => {
  };
  @State selectorAnimateIndex: number = -1;
  @Prop @Watch('resetAnimateIndex') recordSelector: FunctionId;
  // 一级列表基础数据
  @State mainList: FunctionId[] = [];
  @State listSpace: number = 0;
  @State listLeftMargin: number = 0;
  @State refreshListElement: boolean = false;
  // 刷新一级页面
  @Prop @Watch('resetList') resetListFlag: boolean;
  @State refreshMainList: boolean = false;
  private scrollerMap: Map<boolean, Scroller> = new Map([
    [true, new Scroller()],
    [false, new Scroller()]
  ]);
  @State listIsAppeared: boolean = false;
  private firstIconShowTime: number = 0;
  private firstIconIndex: number = 0;
  // LEM半折状态
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  private eventBus: EventBus | undefined;
  private mBase: BaseComponent = new BaseComponent();
  private mOpacity: number = 0.6;
  @State isFlashEnable: boolean = true;
  @State isShowDefault: boolean = false;
  private setTimeout: Function = () => {};
  @State isAICompositionOpen: boolean = false;
  private treasureBoxOrder: number[] = CameraAppCapability.getInstance().getTreasureBoxOrder();

  aboutToAppear(): void {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.displayWidth = state.get<number>('windowReducer', 'windowWidth');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isLightPaintingFlashShow = state.get<boolean>('settingReducer', 'isLightPaintingFlashShow');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
      this.isNightStarPortraitFlashShow = state.get<boolean>('settingReducer', 'isNightStarPortraitFlashShow');
      this.isAICompositionOpen = state.get<boolean>('aiCompositionReducer', 'isAICompositionOpen');
    }, null);
    this.eventBus = EventBusManager.getInstance().getEventBus();
    this.eventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, (data: FunctionValueType) => {
    }, this.mBase.hashCode());
    this.resetList();
    if (this.isVdeCollapsed) {
      this.setTimeout();
    }
  }

  aboutToDisappear() {
    this.eventBus?.clear(this.mBase.hashCode());
    this.subscriber.destroy();
  }

  private resetAnimateIndex(): void {
    this.selectorAnimateIndex = this.mainList.indexOf(this.recordSelector);
  }

  // 由List统一刷新所有的按钮UIElement，目前刷新都可以到按钮内部判断刷新
  private changeElement(): void {
    HiLog.i(TAG, 'changeElement invoke.');
    this.refreshListElement = !this.refreshListElement;
  }

  private resetList(): void {
    HiLog.i(TAG, 'resetList begin.');
    this.mainList = treasureBoxConfig.getResetListData();
    this.selectorAnimateIndex = this.mainList.indexOf(this.recordSelector);
    this.listSpace = treasureBoxConfig.getListSpace(this.displayWidth);
    this.listLeftMargin = treasureBoxConfig.getFirstListLeftMargin();
    let childrenWidth: number =
      this.mainList.length * TREASURE_BOX_ELEMENT_WIDTH + (this.mainList.length - 1) * this.listSpace +
        this.listLeftMargin * MARGIN_COUNT;
    if (this.mainList.length < DEFAULT_LOAD_COUNT && (childrenWidth - this.displayWidth) < LIST_SCROLL_THRESHOLD) {
      this.listLeftMargin = this.listLeftMargin + (this.displayWidth + LIST_SCROLL_THRESHOLD - childrenWidth) / 2;
    }
    this.listIsAppeared = false;
    this.refreshMainList = !this.refreshMainList;
    HiLog.i(TAG, `resetList end, mainList: ${this.mainList.toString()}.`);
  }

  build() {
    if (this.refreshMainList) {
      this.listBuilder(this.scrollerMap.get(true) || new Scroller());
    } else {
      this.listBuilder(this.scrollerMap.get(false) || new Scroller());
    }
  }

  private setKey(functionId: FunctionId): string {
    return ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, functionId)
  }

  @Builder
  vdeCollapsListBuilder(scroller: Scroller) {
    Column() {
      Column() {
        this.listBuilder(scroller);
      }
      .width('100%')
      .height('100%')
      .blendMode(BlendMode.SRC_IN, BlendApplyType.OFFSCREEN)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .id('Column')
    .alignRules({
      middle: { anchor: '__container__', align: HorizontalAlign.Center },
      top: { anchor: '__container__', align: VerticalAlign.Top },
    })
    .width(this.displayWidth)
    .height(TREASURE_BOX_ELEMENT_HEIGHT)
    .linearGradient({
      angle: 90,
      colors: [
        ['rgba(255,255,255,0)', 0], ['rgba(255,255,255,0.2)', 0.02],
        ['rgba(255,255,255,1)', 0.05], ['rgba(255,255,255,1)', 0.95],
        ['rgba(255,255,255,0.2)', 0.98], ['rgba(255,255,255,0)', 1]]
    })
    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
  }

  @Builder
  listBuilder(scroller: Scroller) {
    List({ space: this.listSpace, scroller: scroller}) {
      ForEach(this.mainList, (functionId: FunctionId, index: number = 0) => {
        ListItem() {
          FirstListButton({
            functionId: functionId,
            uiEnable: ((this.isFlashType(functionId) && !this.isFlashEnable) ||
            this.isSuperIsoValue(functionId)) ? false : this.uiEnable,
            changeSelector: (functionId: FunctionId) => this.changeSelector(functionId),
            refresh: this.refreshListElement,
            setTimeout: this.setTimeout,
          })
            .opacity(this.getOpacity(index, functionId))
            .width(this.isVdeCollapsed ? TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH :
              this.isHalfCollapsLEM ? TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH :
                TREASURE_BOX_ELEMENT_WIDTH)
            .height(this.isVdeCollapsed ? TREASURE_BOX_ELEMENT_VDE_COLLAPS_HEIGHT :
              this.isVdeSemiCollapsed ? TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH : TREASURE_BOX_ELEMENT_HEIGHT)
        }
        .key(this.setKey(functionId))
        .id(this.setKey(functionId))
        .margin(this.getFirstLevelListMargin(index, this.mainList.length))
      })
    }
    .cachedCount(this.mainList.length - DEFAULT_LOAD_COUNT)
    .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
      if (treasureBoxConfig.getIsOpening() || !this.listIsAppeared || scrollState === ScrollState.Idle) {
        return;
      }
      treasureBoxConfig.setListOffset(scroller.currentOffset()?.xOffset ?? 0);
    })
    .enabled(this.uiEnable)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .listDirection(Axis.Horizontal)
    .alignListItem(ListItemAlign.Start)
    .key(ComponentIdKeys.TREASURE_BOX_FIRST_LIST)
    .onAppear((): void => {
      this.listIsAppeared = true;
      scroller.scrollTo({ xOffset: treasureBoxConfig.getListOffset(), yOffset: 0, animation: { duration: 0 } });
      this.firstIconIndex = this.getFirstShowIconIndex();
    })
  }

  private getFirstLevelListMargin(index: number, length: number): Margin {
    if (this.isVdeCollapsed) {
      const width: number = getStates().get<number>('windowReducer', 'windowWidth');
      let leftMargin: number = 5;
      let rightMargin: number = 5;
      const tmpMargin: number = length > 6 ? 16 : (width - (TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH + 10) * length) / 2 + 5;
      if (index === 0) {
        leftMargin = tmpMargin;
      }
      if (index === length - 1) {
        rightMargin = tmpMargin;
      }
      return {
        left: SystemLanguageUtil.isRTL() ? rightMargin : leftMargin,
        right: SystemLanguageUtil.isRTL() ? leftMargin : rightMargin,
        top: '10vp'
      };
    }
    if (this.isShowDefault && SystemLanguageUtil.isRTL()) {
      return {
        right: index === 0 ? this.listLeftMargin : 0,
        left: index === this.mainList.length - 1 ? this.listLeftMargin : 0
      };
    }
    return {
      left: index === 0 ? (SystemLanguageUtil.isRTL() ? 0 : this.listLeftMargin) : 0,
      right: index === this.mainList.length - 1 ? (SystemLanguageUtil.isRTL() ? 0 : this.listLeftMargin) :
        0
    };
  }

  private getOpacity(index: number, functionId: number): number {
    if ((this.isFlashType(functionId) && !this.isFlashEnable) || this.isSuperIsoValue(functionId)) {
      return this.mOpacity;
    }
    return 1;
  }

  private isSuperIsoValue(itemId: FunctionId): boolean {
    if (itemId === FunctionId.FLASH) {
      return true;
    }
    return false;
  }

  private isFlashType(itemId: FunctionId): boolean {
    if (itemId === FunctionId.FLASH) {
      return true;
    }
    return false;
  }

  private getFirstShowIconIndex(): number {
    const offset: number = treasureBoxConfig.getListOffset();
    return Math.max(Math.floor(offset / (TREASURE_BOX_ELEMENT_WIDTH + this.listSpace)), 0);
  }
}