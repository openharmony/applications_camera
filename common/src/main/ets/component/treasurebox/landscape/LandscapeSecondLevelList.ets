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
import lazy { Dispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { StoreManager } from '../../../worker/StoreManager';
import lazy { execAction } from '../../../redux/ActionRegistry';
import lazy { BlurAnimateUtil } from '../../../utils/BlurAnimateUtil';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { ValueType } from '../../../utils/types';
import lazy { ZIndex } from '../../../utils/ZIndex';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { TipService } from '../../tip/TipService';
import lazy {
  FunctionConflictParamData,
  FunctionType,
  TREASURE_BOX_ELEMENT_INNER_WIDTH,
  TREASURE_BOX_IMAGE_ELEMENT
} from '../common/DataType';
import lazy { TREASURE_BOX_TAG } from '../default/TreasureBox';
import lazy { LandscapeSecondListButton } from './button/LandscapeSecondListButton';
import lazy { LANDSCAPE_TREASURE_BOX_TAG } from './LandscapeTreasureBox';
import landscapeTreasureBoxConfig from './LandscapeTreasureBoxConfig';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import ResGetter from '../../../utils/ResGetter';
import lazy { AccessibilityUtils } from '../../../utils/AccessibilityUtils';
import lazy { Action } from '../../../redux/actions/Action';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { LandscapeFirstListButton } from './button/LandscapeFirstListButton';

/* instrument ignore file */
const TAG: string = 'LandscapeSecondLevelList';
const CLOSE_SECOND_LIST_AUTO = 4 * 1000;

@Component
export struct LandscapeSecondLevelList {
  // 全局数据
  private mBase: BaseComponent = new BaseComponent();
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private dispatch: Dispatch = (data) => data;
  private storeManager: StoreManager = StoreManager.getInstance();
  @State uiEnable: boolean = true;
  @State isShowSemiCollapsed: boolean = false;
  // 业务数据
  @State mainList: FunctionType[] = [];
  private scrollerMap: Map<boolean, Scroller> = new Map([
    [true, new Scroller()],
    [false, new Scroller()]
  ]);
  @StorageLink('treasureBoxSelector') @Watch('resetSecondList') selector: FunctionId = FunctionId.NONE;
  private selectorStore: FunctionId = FunctionId.NONE;
  // 切换相关
  @State selectModeIndex: number = 0;
  private changeSelectorNone: () => void = () => {
  };
  private autoChangeNoneTimer: number = Number.MIN_VALUE;
  @State isReloadSecondAnimation: boolean = false; //更新二级界面动效
  @State listTopMargin: number = 0;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isShowStyleMenuChange') isShowStyleMenu: boolean = false;
  @LocalStorageLink('xmagePositionLink') xmagePosition: Length | undefined = 0;

  aboutToAppear(): void {
    HiLog.i(TAG, `aboutToAppear begin, selector: ${this.selector}.`);

    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    }, (dispatch: Dispatch): void => {
      this.dispatch = dispatch;
    });

    this.eventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, (data: FunctionConflictParamData) => {
      HiLog.i(TAG, `handleConflict id: ${data.id}, conflictParam: ${data.conflictParam}, selector: ${this.selector}.`);
      if (data.id !== this.selector || this.selector !== FunctionId.FRAME_RATE) {
        return;
      }
      this.resetSecondList();
    }, this.mBase.hashCode());

    this.resetSecondList();
    this.autoChangeSelectorNone();
    HiLog.i(TAG, `aboutToAppear end, secondList length: ${this.mainList.length}.`);
  }

  aboutToDisappear() {
    this.eventBus.clear(this.mBase.hashCode());
    this.subscriber.destroy();
    if (this.autoChangeNoneTimer !== Number.MIN_VALUE) {
      clearTimeout(this.autoChangeNoneTimer);
    }
  }

  /*
   * 超时自动从二级界面返回一级界面，调用时刷新时间
   */
  private autoChangeSelectorNone() {
    if (this.autoChangeNoneTimer !== Number.MIN_VALUE) {
      clearTimeout(this.autoChangeNoneTimer);
    }
    this.autoChangeNoneTimer = setTimeout((): void => {
      this.changeSelectorNone();
      this.autoChangeNoneTimer = Number.MIN_VALUE;
    }, this.enableScreenReader ? 5 * CLOSE_SECOND_LIST_AUTO : CLOSE_SECOND_LIST_AUTO); // 开启屏幕朗读延长5倍时间自动关闭
  }

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
    landscapeTreasureBoxConfig.setSecondListLength(this.mainList.length);
    this.selectModeIndex = this.getSelectedMode(functionImpl.getValue());
    this.isReloadSecondAnimation = !this.isReloadSecondAnimation;
    this.listTopMargin = landscapeTreasureBoxConfig.getSecondListTopMargin();
  }

  // 显示二级界面中正在被使用的模式
  private getSelectedMode(value: ValueType): number {
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

  build() {
    if (this.isReloadSecondAnimation) {
      this.listBuilder(this.scrollerMap.get(true) || new Scroller());
    } else {
      this.listBuilder(this.scrollerMap.get(false) || new Scroller());
    }
  }

  @Builder
  listBuilder(scroller: Scroller) {
    List({
      initialIndex: TREASURE_BOX_IMAGE_ELEMENT.has(this.selector) ? this.selectModeIndex : 0,
      space: landscapeTreasureBoxConfig.getListSpace(this.isShowSemiCollapsed),
      scroller: scroller
    }) {
      this.eachItemBuilder()
    }
    .onAreaChange((oldValue, newValue) => {
    })
    .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
      if (scrollState === ScrollState.Idle) {
        return;
      }
    })
    .zIndex(ZIndex.MIDDLE_BOTTOM)
    .enabled(this.uiEnable)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .width(TREASURE_BOX_ELEMENT_INNER_WIDTH)
    .height('100%')
    .key(ComponentIdKeys.getInstance().getKey(LANDSCAPE_TREASURE_BOX_TAG, this.selector))
  }

  @Builder
  eachItemBuilder() {
    ForEach(this.mainList, (item: FunctionType, index: number = 0) => {
      ListItem() {
        this.landscapeItemBuilder(item, index)
      }
      .enabled(item.uiElement.disabled ? false : true)
      .key(ComponentIdKeys.getInstance().getKey(LANDSCAPE_TREASURE_BOX_TAG, this.selector, item.value))
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityText(this.getAbText(item, index))
      .id(ComponentIdKeys.getInstance().getKey(LANDSCAPE_TREASURE_BOX_TAG, this.selector, item.value))
      .margin({
        top: index === 0 ? this.listTopMargin : 0,
        bottom: index === this.mainList.length - 1 ? this.listTopMargin : 0
      })
      .onAppear(() => {
        if (index === this.selectModeIndex && this.enableScreenReader) {
          AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance()
            .getKey(LANDSCAPE_TREASURE_BOX_TAG, this.selector, item.value))
        }
      })
      .onTouch((event: TouchEvent) => {
        this.onTouchItem(event);
      })
      .onClick((): void => {
        this.onSecondListClick(index, item);
      });
    })
  }

  private getAbText(item: FunctionType, index: number): string {
    return `${index === this.selectModeIndex ? ResGetter.getStringSafe($r('app.string.accessibility_checked')) : ''}
      ${ResGetter.getStringSafe(item.uiElement.accessibilityDescription)}`
  }

  private onTouchItem(event: TouchEvent) {
    if (event.type === TouchType.Down) {
      if (BlurAnimateUtil.checkIfNeedBlur(this.selector)) {
        BlurAnimateUtil.generatePixelMapFromSurface();
      }
    }
    this.autoChangeSelectorNone();
  }

  @Builder
  landscapeItemBuilder(item: FunctionType, index: number) {
    LandscapeSecondListButton({
      uiElement: item.uiElement,
      isSelected: index === this.selectModeIndex,
      functionId: item.id
    })
      .key(index === this.selectModeIndex ?
        `${ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.selector, item.value)}-choose` : '')
  }

  private onSecondListClick(index: number, item: FunctionType): void {
    if (!this.uiEnable) {
      return;
    }
    if (this.selectModeIndex === index) {
      this.selector = FunctionId.NONE;
      return;
    }
    if (this.selector === FunctionId.VIDEO_RESOLUTION || this.selector === FunctionId.FRAME_RATE) {
      this.dispatch(Action.updateIsShowParamBar(true));
      this.dispatch(Action.updateIsShowExtendBar(false));
    }
    this.dispatch(FunctionAction.changeFunctionValue(this.selector, item.value, RenderLocation.TREASURE_BOX));

    if (item.uiElement.desc) {
      TipService.getInstance().showTip(item.uiElement.desc, 3000);
    }
    this.selectModeIndex = index;
    this.changeSelectorNone();
  }
}