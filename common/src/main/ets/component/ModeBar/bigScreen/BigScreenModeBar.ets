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
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';
import lazy { RecordingState } from '../../../function/recordcontrol/RecordAction';
import lazy { ModeListManager } from '../../../mode/ModeListManager';
import lazy { MoreModeConfig } from '../../../mode/MoreModeConfig';
import lazy { ChangeState, Dispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { CameraActionType } from '../../../redux/actions/CameraActionType';
import lazy { CaptureActionType } from '../../../redux/actions/CaptureActionType';
import lazy { RecordActionType } from '../../../redux/actions/RecordActionType';
import lazy { PersistType, PreferencesService } from '../../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../../service/preferences/PropTag';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { BlurAnimateUtil } from '../../../utils/BlurAnimateUtil';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import ResGetter from '../../../utils/ResGetter';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';
import lazy { WindowDirection } from '../../../utils/WindowDirection';
import lazy { ZIndex } from '../../../utils/ZIndex';
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
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { AnimSpecifications } from '../../../animation/AnimSpecifications';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { MODE_BAR_HEIGHT } from '../../../service/UIAdaptive/AdaptiveLandscapeLayoutService';

/* instrument ignore file */
const TAG: string = 'BigScreenModeBar';
const MODE_LIST_SPACE: number = 12;
const TRIANGLES_POSITION_RIGHT: number = 0;
const TRIANGLES_POSITION_TOP: number = -22;
const TRIANGLES_POSITION_ROTATE: number = -90;
const MORE_PAGE_TIP_ICON: number = 24;
const SWIPE_DEBOUNCE_TIME: number = 400;
const ROTATE_ANGLE_90: number = 90;
const COMPONENT_WIDTH: number = 84;

class StateStruct {
  public direction: number = 0;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public videoState: RecordingState = RecordingState.READY;
}

class ModeBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public async changeToMode(oldMode: ModeType, newMode: ModeType):
    Promise<void> {
    MoreModeConfig.getInstance().doConfigModeChange(oldMode, newMode);
  }

  public changeModePlaySound(): void {
    this.mDispatch(Action.changeModePlaySound());
  }
}

/*大屏和平板模式条
 * */
@Component
export struct BigScreenModeBar {
  @Prop isPicker: boolean = false;
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  protected modeListManager: ModeListManager = ModeListManager.getInstance();
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  @State uiEnable: boolean = false;
  @State state: StateStruct = new StateStruct();
  private mAction: ModeBarDispatcher = new ModeBarDispatcher();
  private scroller: Scroller = new Scroller();
  @State modeList: ModeType[] = [];
  @State mode: ModeType = ModeType.NONE;
  @State isNeedDisShowingMode: boolean = false;
  // 模式列表中用于和更多页交互的特殊索引
  private readonly morePageInteractionIndex: number = 0;
  @State currentShowModeIndex: number = 0; // 用于组件显示的Index
  private mPreferencesService: PreferencesService = PreferencesService.getInstance();
  @State isShowMorePage: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State rotateAngle: number = 0;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  private swipeTimer: number = Number.MAX_SAFE_INTEGER;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        direction: state.get<WindowDirection>('contextReducer', 'direction'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
      });
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isNeedDisShowingMode = state.get<boolean>('modeReducer', 'isNeedDisShowingMode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.modeList = [...this.modeListManager.getModeList()].reverse();
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
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  // 模式列表项的点击事件
  private modeItemOnClicked(item: ModeType, index: number): void {
    if (item === undefined || this.isNeedDisShowingMode) {
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
    HiLog.i(TAG, `ListItem onclick changeToMode modeType: ${item},${index}.`);
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

  // 不需要和更多页面交互的模式点击逻辑（用于ModeConfig配置不支持更多页的设备或picker）
  private modeItemOnlyOnClicked(item: ModeType, index: number): void {
    if (item !== ModeType.MORE) {
      if (this.currentShowModeIndex === index) {
        return;
      }
      HiLog.i(TAG, `ListItem onclick changeToMode modeType: ${item}.`);
      this.changeModeIndex(index);
    }
  }

  private onModeListScrollIndex(start: number, end: number, center: number): void {
    if (this.currentShowModeIndex !== center) {
      HiLog.d(TAG, `onScrollIndex center: ${center} start: ${start} end: ${end}`);
      if (this.modeList[this.currentShowModeIndex] === ModeType.MORE && this.mode === this.modeList[center]) {
        this.moreModeConfig.handleSlideDoubleStreamFromMore(this.modeList[center]);
      }
      this.currentShowModeIndex = center;
      this.mAction.changeModePlaySound();
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
  }

  private onModeListTouch(event: TouchEvent): void {
    if (event.type !== TouchType.Down || !this.uiEnable) {
      return;
    }
    BlurAnimateUtil.generatePixelMapFromSurface();
  }

  @Builder
  ListItemBuilder(item: ModeType, index: number) {
    Row() {
      Text(this.modeListManager.getModeName(item))
        .fontColor(Color.White)
        .fontSize(SystemLanguageUtil.isChinese() ? $r('sys.float.Subtitle_S') : $r('sys.float.Body_S'))
        .fontWeight(this.currentShowModeIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL2)
        .opacity(this.currentShowModeIndex === index ? 1 : 0.9)
        .textShadow({
          radius: 3,
          color: '#33000000',
          offsetX: 0,
          offsetY: 0
        })
        .textAlign(TextAlign.End)
        .rotate({
          angle: this.isVertical() ? this.rotateAngle : 0,
        })
        .key(ComponentIdKeys.getInstance().getKey('ControlModeText', item))
        .fontFeature('\"ss01\" on')
        .lineHeight(19)
        .accessibilitySelected(this.currentShowModeIndex === index)
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
        .accessibilityText(`${ResGetter.getStringSafe(this.modeListManager.getModeName(item))}`)
        .onClick((): void => {
          this.modeItemOnClicked(item, index);
        })
    }
    .key(index === this.modeList.indexOf(this.mode) ?
      ComponentIdKeys.getInstance().getKey('ControlModeText', item) +
        '-choose' : '')
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .renderGroup(true)
  }

  @Builder
  ModeListItemBuilder(item: ModeType, index: number) {
    ListItem() {
      this.ListItemBuilder(item, index);
      if (this.moreModeConfig.isSupportMorePage() && index === this.morePageInteractionIndex &&
        !this.isShowMorePage && item !== ModeType.MORE) {
        Image(this.moreModeConfig.getMoreModeIcon())
          .objectFit(ImageFit.Contain)
          .width(MORE_PAGE_TIP_ICON)
          .height(MORE_PAGE_TIP_ICON)
          .fillColor(Color.White)
          .rotate({ angle: TRIANGLES_POSITION_ROTATE })
          .position({ right: TRIANGLES_POSITION_RIGHT, top: TRIANGLES_POSITION_TOP })
          .onClick((): void => {
            this.modeItemOnClicked(item, index);
          })
      }
    }.onTouch((event: TouchEvent) => {
      this.onModeListTouch(event);
    })
  }

  @Builder
  ModeListBuilder() {
    Column() {
      Column() {
        List({
          // 适老化适配，间隙随字体放大，最大为1.75倍
          space: MODE_LIST_SPACE * Math.min(this.fontSizeScale, CommonConstants.TEXT_SIZE_HUGE_LEVEL2),
          initialIndex: this.currentShowModeIndex,
          scroller: this.scroller
        }) {
          ForEach(Array.from(this.modeList), (item: ModeType, index: number) => {
            this.ModeListItemBuilder(item, index);
          })
        }
        .alignListItem(SystemLanguageUtil.isRTL() ? ListItemAlign.Start : ListItemAlign.End)
        .edgeEffect(EdgeEffect.None)
        .chainAnimation(false)
        .scrollSnapAlign(ScrollSnapAlign.CENTER)
        .scrollBar(BarState.Off)
        .cachedCount(2)
        .flingSpeedLimit(0)
        .friction(1)
        .edgeEffect(EdgeEffect.None)
        .key('ModeBar')
        .hitTestBehavior(HitTestMode.None)
        .accessibilityScrollTriggerable(false)
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
        .onScrollIndex((start, end, center) => {
          this.onModeListScrollIndex(start, end, center);
        })
      }
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .blendMode(BlendMode.SRC_IN, BlendApplyType.OFFSCREEN)
    }
    .position({ left: 0 })
    .width(COMPONENT_WIDTH * 0.8)
    .handleScrollBarMode()
    .linearGradient({
      angle: 180,
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
      Row() {
      }
      .width($r('app.float.control_point_size'))
      .height($r('app.float.control_point_size'))
      .borderRadius($r('app.float.control_point_radius'))
      .backgroundColor(CameraAppCapability.getInstance().getIsNovaProduct() ||
      DeviceInfo.isTablet() ? '#0A59F7' : Color.Red)
      .key('ModeBar_currentMode')
    }
    .zIndex(ZIndex.MIDDLE_BOTTOM)
    .position({ right: 0 })
    .width(COMPONENT_WIDTH * 0.2)
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Row() {
      this.ModeListBuilder();
      this.RedPointBuilder();
    }
    .width(COMPONENT_WIDTH)
    .height(MODE_BAR_HEIGHT)
  }

  @Styles
  private handleScrollBarMode() {
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        PanGesture({ fingers: 1, direction: PanDirection.Up, distance: 10 })
          .onActionStart((): void => {
            this.onSwipeChangeMode({ swipe: 1 });
          }),
        PanGesture({ fingers: 1, direction: PanDirection.Down, distance: 10 })
          .onActionStart((): void => {
            this.onSwipeChangeMode({ swipe: -1 });
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
    nextIndex = this.currentShowModeIndex + data.swipe; //上滑-1，下滑+1
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
    nextIndex = this.currentShowModeIndex + data.swipe; //上滑-1，下滑+1
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
      HiLog.i(TAG, 'updateMoreList.');
      this.modeList = [...this.modeListManager.getModeList()].reverse();
    })
  }

  private updateModePosition(data?: WithAnimateType): void {
    HiLog.i(TAG, 'updateMorePosition');
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

  private changeModeIndex(newIndex: number) {
    this.slideAnimate(newIndex); // 要在模式流切换之前触发，否则不会触发scrollIndex
    if (newIndex !== this.modeList.indexOf(this.mode)) {
      HiLog.i(TAG, `changeToMode state.mode: ${this.mode} ==> newMode: ${this.modeList[newIndex]} E.`);
      this.mAction.changeToMode(this.mode, this.modeList[newIndex]);
      this.prefService(this.modeList[newIndex]);
    }
    HiLog.i(TAG, 'changeToMode X.');
  }

  private slideAnimate(index: number) {
    HiLog.i(TAG, `slideAnimate index: ${index}, state.mode: ${this.mode}.`);
    animateToImmediately({
      curve: AnimSpecifications.ANIM_MODE_SWITCH_CURVE
    }, () => {
      this.scroller.scrollToIndex(index, false, ScrollAlign.CENTER);
    });
  }

  private prefService(mode: ModeType): void {
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

  private isVertical(): boolean {
    return (Math.abs(this.rotateAngle) / ROTATE_ANGLE_90) % 2 === 0; // 兼容大屏旋转，根据rotate判断所需竖直方向
  }
}