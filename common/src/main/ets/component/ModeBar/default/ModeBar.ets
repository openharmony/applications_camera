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

import lazy { camera } from '@kit.CameraKit';
import lazy { AnimSpecifications } from '../../../animation/AnimSpecifications';
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';
import lazy { FunctionAction } from '../../../function/core/FunctionAction';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { RecordingState } from '../../../function/recordcontrol/RecordAction';
import lazy { ModeListManager } from '../../../mode/ModeListManager';
import lazy { MoreModeConfig } from '../../../mode/MoreModeConfig';
import lazy { ChangeState, Dispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { CameraActionType } from '../../../redux/actions/CameraActionType';
import lazy { CaptureActionType } from '../../../redux/actions/CaptureActionType';
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { RecordActionType } from '../../../redux/actions/RecordActionType';
import lazy { PersistType, PreferencesService } from '../../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../../service/preferences/PropTag';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { BlurAnimateUtil } from '../../../utils/BlurAnimateUtil';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { getColorString } from '../../../utils/ColorUtil';
import ResGetter from '../../../utils/ResGetter';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';
import lazy { WindowDirection } from '../../../utils/WindowDirection';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { VibratorService } from '../../vibration/VibratorService';
import lazy { HiLog } from '../../../../ets/utils/HiLog';
import lazy { ModeType } from '../../../../ets/mode/ModeType';
import lazy { ActionType } from '../../../../ets/redux/actions/ActionType';
import lazy { Action } from '../../../../ets/redux/actions/Action';
import lazy {
  SwipeChangeNumberData, WithAnimateType
} from '../../../../ets/utils/types';
import lazy { DirectionToAngleUtil } from '../../../utils/DirectionToAngleUtil';


/* instrument ignore file */
const TAG: string = 'ModeBar';
const TRIANGLES_POSITION_RIGHT: number = -24;
const MODE_BAR_HEIGHT: number = 56;
const MODE_LIST_MARGIN_TOP: number = 12;
const MORE_PAGE_TIP_ICON: number = 24;
const SWIPE_DEBOUNCE_TIME: number = 400;
const OFFSET_TOP_BIG_SIZE: number = 4;

class StateStruct {
  public direction: number = 0;
  public xComponentWidth: number = 0;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public videoState: RecordingState = RecordingState.READY;
}

class ModeBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: number | string): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public async changeToMode(oldMode: ModeType, newMode: ModeType): Promise<void> {
    MoreModeConfig.getInstance().doConfigModeChange(oldMode, newMode);
  }

  public changeModePlaySound(): void {
    this.mDispatch(Action.changeModePlaySound());
  }
}

/**
 * 模式显示栏组件: ModeBar
 * */
@Component
export struct ModeBar {
  @Prop isPicker: boolean = false;
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  private mAction: ModeBarDispatcher = new ModeBarDispatcher();
  private mPreferencesService: PreferencesService = PreferencesService.getInstance();
  private modeListManager: ModeListManager = ModeListManager.getInstance();
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  private readonly pointerMarginTop: number = 6;
  private readonly modeListHeight: number = 24;
  private scroller: Scroller = new Scroller();
  @State uiEnable: boolean = false;
  @State isShowMorePage: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @State currentShowModeIndex: number = 0; // 用于组件显示的Index（注意手动变更时机）
  @State modeList: ModeType[] = [];
  @State mode: ModeType = ModeType.NONE;
  @State isNeedDisShowingMode: boolean = false;
  private morePageInteractionIndex: number = 0; // 更多页的交互索引
  @State isShowSubScreenRadius: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State isOpenTreasureBox: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isLockRotation: boolean = true;
  private swipeTimer: number = Number.MAX_SAFE_INTEGER;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        direction: state.get<number>('contextReducer', 'direction'),
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
      });
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isNeedDisShowingMode = state.get<boolean>('modeReducer', 'isNeedDisShowingMode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isOpenTreasureBox = state.get<boolean>('treasureBoxReducer', 'isOpen');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.modeList = this.modeListManager.getModeList();
    this.morePageInteractionIndex = this.modeList.length - 1;
    this.currentShowModeIndex = this.isShowMorePage ? this.modeList.indexOf(ModeType.MORE) :
    this.modeList.indexOf(this.mode);
    this.mEventBus.on([
      CameraActionType.CHANGE_MODE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE,
      ContextActionType.VOLUME_KEY_UP,
      CaptureActionType.VOLUME_KEY_EVENT,
      RecordActionType.START], this.modeBarOnChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SWIPE_CHANGE_MODE, this.onSwipeChangeMode.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_UPDATE_MODE_BAR, this.updateModeList.bind(this), this.mBase.hashCode());
    this.mEventBus.on([
      ActionType.ACTION_UPDATE_MODE_POS], this.updateModePosition.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
    //zy-20251211-这里调用一下切换，避免首次进入底部按钮不对
    this.mAction.changeToMode(this.mode, this.mode);
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  // 模式列表项的点击事件
  private modeItemOnClicked(item: ModeType, index: number): void {
    if (item === undefined || this.isNeedDisShowingMode) {
      HiLog.e(TAG, `modeItemOnClicked isNeedDisShowingMode: ${this.isNeedDisShowingMode}`);
      return;
    }
    if (this.moreModeConfig.isSupportMorePage()) {
      this.modeItemInterOnClicked(item, index);
    } else {
      this.modeItemOnlyOnClicked(item, index);
    }
  }

  // 需要和更多页面交互的模式点击逻辑
  private modeItemInterOnClicked(item: ModeType, index: number): void {
    if (this.state.videoState !== RecordingState.READY) {
      HiLog.e(TAG, `modeItemInterOnClicked inRecording: ${this.state.videoState}`);
      return;
    }
    if (index !== this.morePageInteractionIndex) {
      if (this.currentShowModeIndex === index) {
        return;
      }
    } else {
      if (this.isShowMorePage) {
        return;
      }
      this.moreModeConfig.entryAOutMorePage(true);
      this.moreModeConfig.modifyMoreModeListAndName(ModeType.MORE);
    }
    HiLog.i(TAG, `Inter ListItem onclick changeToMode modeType: ${item}, ${index}, ${this.currentShowModeIndex}.`);
    if (index !== this.morePageInteractionIndex) {
      this.moreModeConfig.entryAOutMorePage(false);
      this.moreModeConfig.modifyMoreModeListAndName(ModeType.MORE);
      if (index === this.modeList.indexOf(this.mode)) {
        this.slideAnimate(index);
      } else {
        this.changeModeIndex(index);
      }
    } else {
      this.slideAnimate(index);
    }
  }

  // 不需要和更多页面交互的模式点击逻辑（用于ModeConfig配置不支持更多页的设备）
  private modeItemOnlyOnClicked(item: ModeType, index: number): void {
    if (item !== ModeType.MORE) {
      if (this.currentShowModeIndex === index) {
        return;
      }
      HiLog.i(TAG, `Only ListItem onclick changeToMode modeType: ${item}.`);
      this.changeModeIndex(index);
    }
  }

  private onModeListScrollIndex(start: number, end: number, center: number): void {
    if (this.currentShowModeIndex !== center) { // slideAnimate scrollToIndex 统一触发
      HiLog.d(TAG, `onScrollIndex center: ${center} start: ${start} end: ${end}`);
      if (this.modeList[this.currentShowModeIndex] === ModeType.MORE && this.mode === this.modeList[center]) {
        // 更多页回切原有模式，且该模式为双流，双流需要变为默认流
        this.moreModeConfig.handleSlideDoubleStreamFromMore(this.modeList[center]);
      }
      this.currentShowModeIndex = center;
      this.mAction.changeModePlaySound();
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
  }

  private onModeListTouch(event: TouchEvent): void { // 切换模式截图
    if (event.type !== TouchType.Down || !this.uiEnable) {
      return;
    }
    BlurAnimateUtil.generatePixelMapFromSurface();
  }

  private arrowheadLeftOrRight(): Edges {
    if (SystemLanguageUtil.isRTL()) {
      return {
        left: TRIANGLES_POSITION_RIGHT,
        top: MODE_LIST_MARGIN_TOP
      }
    } else {
      return {
        right: TRIANGLES_POSITION_RIGHT,
        top: this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2 ? MODE_LIST_MARGIN_TOP + OFFSET_TOP_BIG_SIZE :
          MODE_LIST_MARGIN_TOP
      }
    }
  }

  @Builder
  ListItemBuilder(item: ModeType, index: number) {
    Column() {
      Text(this.modeListManager.getModeName(item))
        .height(this.modeListHeight)
        .fontColor( Color.White)
        .fontSize(this.isVdeCollapsed ? $r('sys.float.Caption_L') : $r('sys.float.Subtitle_S'))
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL2)
        .fontWeight(this.currentShowModeIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .textShadow({
          radius: 5,
          color: '#4d000000',
          offsetX: 0,
          offsetY: 0
        })
        .textAlign(TextAlign.Center)
        .key(ComponentIdKeys.getInstance().getKey('ControlModeText', item))
        .rotate({
          angle: DirectionToAngleUtil.getTwoDirectionTextRotate(this.state.direction),
        })
        .fontFeature('\"ss01\" on')
    }
    .height('100%')
    .padding({ top: MODE_LIST_MARGIN_TOP })
    .key(index === this.modeList.indexOf(this.mode) ?
      ComponentIdKeys.getInstance().getKey('ControlModeText', item) + '-choose' : '')
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .renderGroup(true)
  }

  @Builder
  ModeListItemBuilder(item: ModeType, index: number) {
    ListItem() {
      this.ListItemBuilder(item, index);
      if (this.moreModeConfig.isSupportMorePage() && (index === this.morePageInteractionIndex) &&
        !this.isShowMorePage && (item !== ModeType.MORE)) {
        Image(this.moreModeConfig.getMoreModeIcon())
          .objectFit(ImageFit.Contain)
          .width(MORE_PAGE_TIP_ICON)
          .height(MORE_PAGE_TIP_ICON)
          .fillColor(Color.White)
          .position(this.arrowheadLeftOrRight())
          .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
          .onClick((): void => {
            this.modeItemOnClicked(item, index);
          })
      }
    }
    .accessibilitySelected(this.currentShowModeIndex === index)
    .accessibilityRole(item === ModeType.MORE ?
    AccessibilityRoleType.BUTTON : AccessibilityRoleType.BLANK)
    .accessibilityLevel(this.isOpenTreasureBox ?
    CommonConstants.ACCESSIBILITY_LEVEL_NO : CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityText(`${ResGetter.getStringSafe(this.modeListManager.getModeName(item))}`)
    .onClick((): void => {
      this.modeItemOnClicked(item, index);
    })
    .onTouch((event: TouchEvent) => {
      this.onModeListTouch(event);
    })
  }

  @Builder
  ModeListBuilder() {
    Column() {
      Column() {
        // 适老化适配，列表间距与系统字体倍数成正比
        List({
          initialIndex: this.currentShowModeIndex, scroller: this.scroller,
          space: 24 * Math.min(this.fontSizeScale, CommonConstants.TEXT_SIZE_HUGE_LEVEL2)
        }) {
          ForEach(Array.from(this.modeList), (item: ModeType, index: number) => {
            this.ModeListItemBuilder(item, index);
          })
        }
        .flingSpeedLimit(0)
        .friction(1)
        .listDirection(Axis.Horizontal)
        .edgeEffect(EdgeEffect.None)
        .chainAnimation(false)
        .pixelRound({ bottom: PixelRoundCalcPolicy.FORCE_CEIL })
        .scrollSnapAlign(ScrollSnapAlign.CENTER)
        .scrollBar(BarState.Off)
        .cachedCount(this.modeList.length - 4)
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
        .accessibilityScrollTriggerable(false) // 超过一屏，走焦不会自动触发list滑动
        .hitTestBehavior(HitTestMode.None)
        .key('ModeBar')
        .onScrollIndex((start, end, center) => { //scrollToIndex触发
          this.onModeListScrollIndex(start, end, center);
        })
      }
      .blendMode(BlendMode.SRC_IN, BlendApplyType.OFFSCREEN)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    }
    .backgroundColor(Color.Black)
    .handleScrollBarMode()
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .id('Column')
    .alignRules({
      middle: { anchor: '__container__', align: HorizontalAlign.Center },
      top: { anchor: '__container__', align: VerticalAlign.Top },
    })
    .linearGradient({
      angle: 90,
      colors: [
        ['rgba(255,255,255,0)', 0], ['rgba(255,255,255,0.2)', 0.05],
        ['rgba(255,255,255,1)', 0.1], ['rgba(255,255,255,1)', 0.9],
        ['rgba(255,255,255,0.2)', 0.95], ['rgba(255,255,255,0)', 1]]
    })
    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
  }

  @Builder
  RedPointBuilder() {
    Row() {
    }
    .width($r('app.float.control_point_size'))
    .height($r('app.float.control_point_size'))
    .borderRadius($r('app.float.control_point_radius'))
    .backgroundColor(getColorString())
    .margin({ top: this.pointerMarginTop })
    .hitTestBehavior(HitTestMode.Transparent)
    .key('ModeBar_currentMode')
    .id('Row')
    .alignRules({
      middle: { anchor: 'Column', align: HorizontalAlign.Center },
    })
    // 适老化适配，随系统字体放大，维持两者间距
    .offset({
      y: this.modeListHeight +
        MODE_LIST_MARGIN_TOP * Math.min(this.fontSizeScale, CommonConstants.TEXT_SIZE_HUGE)
    })
  }

  build() {
    RelativeContainer() {
      this.ModeListBuilder();
      this.RedPointBuilder();
    }
    .width('100%')
    .height(MODE_BAR_HEIGHT)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
  }

  @Styles
  private handleScrollBarMode() {
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        PanGesture({
          fingers: 1,
          direction: SystemLanguageUtil.isRTL() ? PanDirection.Right : PanDirection.Left,
          distance: 10
        })
          .onActionStart((): void => {
            this.onSwipeChangeMode({ swipe: 1 })
          }),
        PanGesture({
          fingers: 1,
          direction: SystemLanguageUtil.isRTL() ? PanDirection.Left : PanDirection.Right,
          distance: 10
        })
          .onActionStart((): void => {
            this.onSwipeChangeMode({ swipe: -1 })
          })
      )
    )
  }

  private onSwipeChangeMode(data: SwipeChangeNumberData): void {
    if (this.isNeedDisShowingMode) {
      return;
    }
    if (this.moreModeConfig.isSupportMorePage()) {
      this.onSwipeInteractiveChangeMode(data);
    } else {
      this.onSwipeOnlyChangeMode(data);
    }
    this.handleQuickSwipeMode();
  }

  private onSwipeInteractiveChangeMode(data: SwipeChangeNumberData): void {
    let nextIndex = -1;
    nextIndex = this.currentShowModeIndex + data.swipe; //左滑-1，右滑+1
    HiLog.i(TAG, `swipeInter: ${data.swipe}, onSwipeChangeMode: ${nextIndex},curIndex:${this.currentShowModeIndex}.`);
    if (nextIndex < 0 || nextIndex > this.modeList.length - 1) {
      return;
    }
    if (nextIndex === this.morePageInteractionIndex || !this.uiEnable) {
      this.moreModeConfig.entryAOutMorePage(nextIndex === this.morePageInteractionIndex);
      this.slideAnimate(nextIndex);
    } else {
      this.moreModeConfig.entryAOutMorePage(false);
      this.moreModeConfig.modifyMoreModeListAndName(ModeType.MORE);
      if (nextIndex === this.modeList.indexOf(this.mode)) {
        this.slideAnimate(nextIndex);
      } else {
        this.changeModeIndex(nextIndex);
      }
    }
  }

  private onSwipeOnlyChangeMode(data: SwipeChangeNumberData): void {
    let nextIndex = -1;
    nextIndex = this.currentShowModeIndex + data.swipe; //左滑-1，右滑+1
    HiLog.i(TAG, `swipeOnly: ${data.swipe}, onSwipeChangeMode: ${nextIndex},curIndex:${this.currentShowModeIndex}.`);
    if (nextIndex < 0 || nextIndex > this.modeList.length - 1) {
      return;
    }
    if (this.uiEnable) {
      this.changeModeIndex(nextIndex);
    } else {
      this.slideAnimate(nextIndex);
    }
  }

  private updateModeList(): void {
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      curve: Curve.Sharp,
    }, () => {
      this.modeList = this.modeListManager.getModeList();
      HiLog.d(TAG, `updateModeList modeList: ${this.modeList}`);
      this.morePageInteractionIndex = this.modeList.length - 1;
    });
  }

  private updateModePosition(data?: WithAnimateType): void {
    HiLog.i(TAG, 'updateModePosition');
    if (this.isShowMorePage) {
      this.currentShowModeIndex = this.morePageInteractionIndex;
    } else {
      this.currentShowModeIndex = this.modeList.indexOf(this.mode);
    }
    if (!data || !data.withAnimate) {
      this.scroller.scrollToIndex(this.currentShowModeIndex, false, ScrollAlign.CENTER);
    } else {
      this.slideAnimate(this.currentShowModeIndex);
    }
  }

  private changeModeIndex(newIndex: number): void {
    if (!this.modeList[newIndex]) {
      HiLog.e(TAG, 'changeModeIndex error');
      return;
    }
    this.slideAnimate(newIndex); // 要在模式流切换之前触发，否则不会触发OnScrollIndex
    if (newIndex !== this.modeList.indexOf(this.mode)) {
      let newMode = this.modeList[newIndex];
      HiLog.begin(TAG, 'changeMode');
      HiLog.i(TAG, `changeToMode state.mode: ${this.mode} ==> newMode: ${newMode} E.`);
      this.mAction.changeToMode(this.mode, newMode);
      this.prefService(newMode);
      HiLog.end(TAG, 'changeMode');
    }
  }

  private slideAnimate(index: number): void { // 列表滑动到指定项
    HiLog.i(TAG, `slideAnimate index: ${index}, next mode: ${this.modeList[index]}.`);
    HiLog.begin(TAG, 'modeBarAnimate');
    animateToImmediately({
      curve: AnimSpecifications.ANIM_MODE_SWITCH_CURVE,
      onFinish: () => {
        HiLog.end(TAG, 'modeBarAnimate');
      }
    }, () => {
      this.scroller.scrollToIndex(index, false, ScrollAlign.CENTER);
    });
  }

  private prefService(mode: ModeType): void { // 本地缓存选中的模式，切到更多时不缓存
    HiLog.i(TAG, `prefService mode ${mode}.`);
    if (!!mode) {
      this.mPreferencesService.putPropValue(PersistType.FOR_AWHILE, PropTag.MODE, mode);
    }
  }

  private modeBarOnChange(): void {
    const modeIndex = this.modeList.indexOf(this.mode);
    HiLog.d(TAG,
      `modeBarOnChange: ${this.currentShowModeIndex},${modeIndex},
      ${this.modeList[this.currentShowModeIndex]}, ${this.mode}`);
    if (this.currentShowModeIndex !== modeIndex) {
      this.currentShowModeIndex = modeIndex >= 0 ? modeIndex : this.morePageInteractionIndex;
      this.slideAnimate(this.currentShowModeIndex);
      this.prefService(this.mode);
    }
  }

  private handleQuickSwipeMode(): void { // 快速切换预览区域切模式防抖、兜底操作
    if (this.swipeTimer && this.swipeTimer !== Number.MAX_SAFE_INTEGER) {
      HiLog.i(TAG, 'default clear debounce swipe mode change.');
      clearTimeout(this.swipeTimer);
    }
    this.swipeTimer = setTimeout(() => {
      const curReduxMode: ModeType = this.mode;
      const curIndexMode: ModeType = this.modeList[this.currentShowModeIndex];
      HiLog.i(TAG, `default quick previewArea change, diff mode:${curReduxMode},${curIndexMode}`);
      if (curIndexMode === ModeType.MORE) {
        this.moreModeConfig.entryAOutMorePage(true);
        this.slideAnimate(this.currentShowModeIndex);
      }
      if (curReduxMode !== curIndexMode && curIndexMode !== ModeType.MORE) {
        this.moreModeConfig.entryAOutMorePage(false);
        this.changeModeIndex(this.currentShowModeIndex);
      }
      clearTimeout(this.swipeTimer)
    }, SWIPE_DEBOUNCE_TIME);
  }
}
