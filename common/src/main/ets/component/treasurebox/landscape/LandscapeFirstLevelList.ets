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
import lazy { execDispatch, getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { camera } from '@kit.CameraKit';
import lazy { HiLog } from '../../../utils/HiLog';
import landscapeTreasureBoxConfig from './LandscapeTreasureBoxConfig';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { LandscapeFirstListButton } from './button/LandscapeFirstListButton';
import lazy {
  SLEEP_TIME,
  TREASURE_BOX_ELEMENT_INNER_HEIGHT,
  TREASURE_BOX_ELEMENT_INNER_WIDTH
} from '../common/DataType';
import lazy { LANDSCAPE_TREASURE_BOX_TAG } from './LandscapeTreasureBox';
import lazy { PersistType, PreferencesService } from '../../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../../service/preferences/PropTag';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { BaseFunction } from '../../../function/core/BaseFunction';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { LandscapeIconElement } from './button/LandscapeIconElement';
import lazy { PhotoFormatMode } from '../../../function/enumbase/PhotoFormatMode';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { LengthMetrics } from '@kit.ArkUI';
import lazy { SystemParamService } from '../../../service/systemparameter/SystemParamService';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { FunctionValueType } from '../../../utils/types';
import lazy { ContextActionType } from "../../../redux/actions/ContextActionType"

/* instrument ignore file */
const TAG: string = 'LandscapeFirstLevelList';
const MAIN_CAMERA_ZOOM = 1;
const D_VALUE = 0.1;

interface ProIsoValue {
  functionId: FunctionId,
  value: number
}

enum SlidState {
  START = 'start',
  CENTER = 'center',
  END = 'end'
}

@Component
export struct LandscapeFirstLevelList {
  // 全局数据
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State uiEnable: boolean = true;
  // 一级列表基础数据
  @State mainList: FunctionId[] = [];
  @State showVideoTimer: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State listTopMargin: number = 0;
  private isReverse: boolean = false;
  @State isSelected: boolean = false;
  // 一二级界面切换相关
  private changeSelector: (functionId: FunctionId) => void = () => {
  };
  @State selectorAnimateIndex: number = -1;
  @Prop @Watch('resetAnimateIndex') recordSelector: FunctionId;
  // 刷新一级页面
  @Link isFirstShow: boolean;
  @Prop @Watch('resetList') resetListFlag: boolean;
  @State isLightPaintingFlashShow: boolean = false;
  @State isNightStarPortraitFlashShow: boolean = false;
  @State refreshMainList: boolean = false;
  private mOpacity: number = 0.6;
  @State isFlashEnable: boolean = true;
  private scrollerMap: Map<boolean, Scroller> = new Map([
    [true, new Scroller()],
    [false, new Scroller()]
  ]);
  @State listIsAppeared: boolean = false;
  private firstIconShowTime: number = 0;
  private firstIconIndex: number = 0;
  // 业务相关处理
  private cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  // 超慢逻辑：超慢按下相当于录像录制
  @StorageLink('isDownSuperSlowBtnState') isDownSuperSlowBtn: boolean = false;
  private scrollOffsetY: number = 0;
  private maxOffsetY: number = 0;
  private treasureBoxHeight: number = 0;
  @LocalStorageLink('xmagePositionLink') xmagePosition: Length | undefined = 0;
  @State superIsoValue: number = 0;
  private eventBus: EventBus | undefined;
  private mBase: BaseComponent = new BaseComponent();
  private treasureBoxOrder: number[] = CameraAppCapability.getInstance().getTreasureBoxOrder();

  aboutToAppear(): void {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.showVideoTimer = state.get<boolean>('recordReducer', 'videoTimerState');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isLightPaintingFlashShow = state.get<boolean>('settingReducer', 'isLightPaintingFlashShow');
      this.isNightStarPortraitFlashShow = state.get<boolean>('settingReducer', 'isNightStarPortraitFlashShow');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
    }, null);
    this.eventBus = EventBusManager.getInstance().getEventBus();
    this.isReverse = landscapeTreasureBoxConfig.isReverse();
    this.resetList();
    this.eventBus.on(ActionType.ACTION_UPDATE_PRO_PARAMETERS_VALUE, (data: ProIsoValue) =>
    this.updateSuperIsoValue(data), this.mBase.hashCode());
    this.eventBus.on([FunctionActionType.ACTION_CHANGE_FUNCTION_VAL], (data: FunctionValueType) => {
    }, this.mBase.hashCode());
  }

  aboutToDisappear() {
    this.eventBus?.clear(this.mBase.hashCode());
    this.subscriber.destroy();
  }

  private updateSuperIsoValue(data: ProIsoValue): void {
  }

  private isAudioViewShow(): boolean | undefined {
    const systemAudioZoomSupport: boolean =
      SystemParamService.getInstance().get(true, 'const.multimedia.audio.show_audiozoom_switch', 'false') === 'true';
    HiLog.i(TAG, 'systemAudioZoomSupport：' + systemAudioZoomSupport);
    return false;
  }

  private resetList(): void {
    HiLog.i(TAG, 'resetBoxFuncIds invoke.');
    const state = getStates();
    if (this.showVideoTimer || this.isDownSuperSlowBtn) {
      if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
        // 新规格，录像开始后不再显示滤镜和xmage图标
        if (FeatureManager.getInstance().getFunction(FunctionId.FLASH).isAvailable()) { //录像中是否显示闪光灯
          this.mainList = [FunctionId.FLASH];
        } else {
          this.mainList = [];
        }
        if (this.isAudioViewShow()) {
        }
        if (this.isReverse) {
          this.mainList.reverse();
        }
      } else {
        this.mainList = [];
      }
    } else {
      this.TreasureBoxFilter(state);
    }
    this.selectorAnimateIndex = this.mainList.indexOf(this.recordSelector);

    landscapeTreasureBoxConfig.setFirstList(this.mainList);

    if (!this.isReverse) {
      this.notReversedTreasureBoxInit();
    }
    this.listTopMargin = landscapeTreasureBoxConfig.getFirstListTopMargin();
    HiLog.i(TAG, `listTopMargin: ${this.listTopMargin}.`);

    this.listIsAppeared = false;
    this.refreshMainList = !this.refreshMainList;
  }

  private TreasureBoxFilter(state: OhCombinedState) {
    const set = state.get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap')
      .get(RenderLocation.TREASURE_BOX) || new Set();
    this.mainList = Array.from(set)
      // 产品要求：屏蔽百宝箱内“录像帧率”入口（仅隐藏 UI，不影响底层能力与编码逻辑）
      .filter((item: FunctionId) => item !== FunctionId.FRAME_RATE)
      .sort((a, b) => (this.isShowSemiCollapsed || this.isReverse ?
      this.treasureBoxOrder.indexOf(a) - this.treasureBoxOrder.indexOf(b) : this.treasureBoxOrder.indexOf(b) -
      this.treasureBoxOrder.indexOf(a)))
  }

  private notReversedTreasureBoxInit(): void {
    this.maxOffsetY = this.mainList.length * TREASURE_BOX_ELEMENT_INNER_HEIGHT + (this.mainList.length - 1) *
    landscapeTreasureBoxConfig.getListSpace(this.isShowSemiCollapsed) +
      2 * landscapeTreasureBoxConfig.getFirstListTopMargin() - this.treasureBoxHeight;
    if (this.maxOffsetY > 0 && !this.isShowSemiCollapsed && !landscapeTreasureBoxConfig.getIsFirstTimeInitCompleted()) {
      this.scrollOffsetY = this.maxOffsetY;
      landscapeTreasureBoxConfig.setListOffset(this.scrollOffsetY);
    } else {
      this.scrollOffsetY = landscapeTreasureBoxConfig.getListOffset();
    }
  }

  private resetAnimateIndex(): void {
    this.selectorAnimateIndex = this.mainList.indexOf(this.recordSelector);
  }

  private getInitialIndex(): number {
    return this.isShowSemiCollapsed || this.isReverse ? 0 : this.mainList.length - 1;
  }

  private listOnScrollStartFunction(scroller: Scroller): void {
    if (!this.isReverse && !landscapeTreasureBoxConfig.getIsFirstTimeInitCompleted()) {
      let offsetError: number = this.maxOffsetY - scroller.currentOffset()?.yOffset;
      landscapeTreasureBoxConfig.setListOffsetError(offsetError);
      HiLog.i(TAG, `Offset Error: ${landscapeTreasureBoxConfig.getListOffsetError()}`);
    }
    landscapeTreasureBoxConfig.setIsFirstTimeInitCompleted(true);
  }

  private listOnDidScrollFunction(scroller: Scroller, scrollOffset: number, scrollState: ScrollState): void {
    if (!this.listIsAppeared || scrollState === ScrollState.Idle) {
      return;
    }
    if (!this.isReverse) {
      if (scrollState !== ScrollState.Fling || this.scrollOffsetY !== 0 && this.scrollOffsetY !== this.maxOffsetY) {
        this.scrollOffsetY += scrollOffset;
      }
      this.scrollOffsetY = Math.min(this.scrollOffsetY, this.maxOffsetY);
      this.scrollOffsetY = Math.max(this.scrollOffsetY, 0);
      landscapeTreasureBoxConfig.setListOffset(this.scrollOffsetY || 1);
    } else {
      landscapeTreasureBoxConfig.setListOffset(scroller.currentOffset()?.yOffset || 1);
    }
  }

  private listOnAppearFunction(scroller: Scroller): void {
    this.listIsAppeared = true;
    let offset: number = landscapeTreasureBoxConfig.getListOffset();
    if (!this.isReverse && !getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed')) {
      let offsetError: number = landscapeTreasureBoxConfig.getListOffsetError();
      offset -= offsetError; //如果未倒置百宝箱而直接从底部显示，百宝箱初始的offset会有误差
    }
    if (!!offset) {
      scroller.scrollTo({ xOffset: 0, yOffset: offset });
    }
    HiLog.i(TAG, 'LandscapeFirstLevelList onAppear.');
    this.firstIconIndex = this.getFirstShowIconIndex();
    setTimeout((): void => {
      this.isFirstShow = false;
    }, SLEEP_TIME)
  }

  build() {
    if (this.refreshMainList) {
      this.listBuilder(this.scrollerMap.get(true) || new Scroller());
    } else {
      this.listBuilder(this.scrollerMap.get(false) || new Scroller());
    }
  }

  @Builder
  listItemBuilder(functionId: FunctionId, index: number) {
    ListItem() {
      if ((this.showVideoTimer || this.isDownSuperSlowBtn) && functionId !== FunctionId.FLASH) {
        // 录像时有这么两个特殊的图标要显示
        VideoSpecialIcon({
          functionId: functionId
        })
          .enabled(false)
          .opacity(!this.listItemOpacity(functionId) ? 0 : 0.5)
      } else {
        LandscapeFirstListButton({
          functionId: functionId,
          uiEnable: this.isFlashType(functionId) ? this.isFlashEnable : this.uiEnable,
          changeSelector: (functionId: FunctionId) => this.changeSelector(functionId)
        })
          .opacity(this.listItemOpacity(functionId))
          .enabled(this.isSuperIsoValue(functionId) ? false : true)
      }
    }
    .onAreaChange((oldValue, newValue) => {
    })
    .key(ComponentIdKeys.getInstance().getKey(LANDSCAPE_TREASURE_BOX_TAG, functionId))
    .margin({
      top: index === 0 ? this.listTopMargin : 0,
      bottom: index === this.mainList.length - 1 ? this.listTopMargin : 0
    })
    .rotate({ angle: this.isReverse ? 180 : 0 })
  }

  @Builder
  listBuilder(scroller: Scroller) {
    RelativeContainer() {
      List({
        space: landscapeTreasureBoxConfig.getListSpace(this.isShowSemiCollapsed),
        scroller: scroller,
        initialIndex: this.getInitialIndex()
      }) {
        ForEach(this.mainList, (functionId: FunctionId, index: number = 0) => {
          this.listItemBuilder(functionId, index);
        })
      }
      .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(80) })
      .onScrollStart(() => {
        this.listOnScrollStartFunction(scroller);
      })
      .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
        this.listOnDidScrollFunction(scroller, scrollOffset, scrollState);
      })
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .width(TREASURE_BOX_ELEMENT_INNER_WIDTH)
      .height('100%')
      .enabled(this.uiEnable)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .listDirection(Axis.Vertical)
      .blendMode(BlendMode.SRC_IN, BlendApplyType.OFFSCREEN)
      .onAppear((): void => {
        this.listOnAppearFunction(scroller);
      })
      .id('LandscapeTreasureBox_First_List')
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        center: { anchor: '__container__', align: VerticalAlign.Center },
      })
    }
    .rotate({ angle: this.isReverse ? 180 : 0 })
    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
  }

  private getFirstShowIconIndex(): number {
    const offset: number = landscapeTreasureBoxConfig.getListOffset();
    return Math.max(Math.floor(offset / (TREASURE_BOX_ELEMENT_INNER_WIDTH +
    landscapeTreasureBoxConfig.getListSpace(this.isShowSemiCollapsed))), 0);
  }

  private listItemOpacity(functionId: number): number {
    if ((this.isFlashType(functionId) && !this.isFlashEnable) || this.isSuperIsoValue(functionId)) {
      return this.mOpacity;
    }
    return 1;
  }

  private isFlashType(itemId: FunctionId): boolean {
    if (itemId === FunctionId.FLASH
    ) {
      return true;
    }
    return false;
  }

  private isSuperIsoValue(itemId: FunctionId): boolean {
    return false;
  }
}

@Component
struct VideoSpecialIcon {
  @State uiElement: UiElement = new UiElement();
  private functionId: FunctionId = FunctionId.NONE;
  private isWhiteFont: boolean = true;

  aboutToAppear() {
    if (this.functionId === FunctionId.NONE) {
      return;
    }
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(this.functionId);
    if (!functionImpl) {
      return;
    }
    HiLog.i(TAG, 'Button get uiElement by Function id.');
    this.uiElement = Array.from<Object[]>(functionImpl.getUiElements(RenderLocation.TREASURE_BOX))
      .filter(values => values[0] === functionImpl.getValue())
      .map((item: Object[]) => item[1] as UiElement)[0];
    HiLog.i(TAG, 'Get button uiElement end.');
  }

  build() {
    LandscapeIconElement({
      uiElement: this.uiElement,
      isWhiteFont: this.isWhiteFont
    })
  }
}