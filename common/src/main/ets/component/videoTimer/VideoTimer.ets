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

import systemDateTime from '@ohos.systemDateTime';
import lazy { RecordAction, RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { Action, UiStateMode } from '../../redux/actions/Action';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { RecordMode } from '../../function/recordcontrol/RecordMode';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '../../function/core/FunctionAction';
import lazy { OhCombinedState, Unsubscribe, Dispatch, reduxSubscribe, getStates } from '../../redux';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { DirectionToAngleUtil } from '../../utils/DirectionToAngleUtil';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PositionType, DirectionType } from '../../utils/types';
import lazy { AdaptiveLayoutService, TAB_BAR_HEIGHT } from '../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { execDispatch } from '../../redux/Store';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import Curves from '@ohos.curves';
import lazy { DisplayCalculator } from '../xcomponent/DisplayCalculator';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import display from '@ohos.display';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import Configuration from '@system.configuration';
import lazy { DirectionCorrectionService } from '../../service/direction/DirectionCorrectionService';
import lazy { RecordController, RecordType } from '../../function/recordcontrol/RecordController';
import lazy { window } from '@kit.ArkUI';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { WorkerTask } from '../../camera/WorkerTask';
import ResGetter from '../../utils/ResGetter';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'VideoTimer';

const VIDEO_TIMER_DEFAULT_WIDTH: number = 100;
const VIDEO_TIMER_DEFAULT_HEIGHT: number = 44;
const VIDEO_TIMER_POSITION_OFFSET: number = 36;
const VIDEO_TIMER_MINI_MARGIN_TOP_TABLET: number = 65;
const VIDEO_TIMER_MARGIN_TOP_TRICOLLAPS: number = 20;
const VIDEO_TIMER_MARGIN_LEFT_TRICOLLAPS: number = 226;
const TIME_SYSTEM: number = 60;
export const VIDEO_TIMER_MARGIN_TOP: number = 33;

export const INIT_VIDEO_TIMER_HEIGHT: number = 80;
export const INIT_VDE_VIDEO_TIMER_HEIGHT: number = 61.125;

class VideoTimerDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public stopRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.stop());
  }

  public changeFunctionValue(id: FunctionId, value: number | string | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public updateRecordingTimerComponentLargeState(isLarge: boolean): void {
    this.mDispatch(RecordAction.updateRecordingTimerComponentLargeState(isLarge));
  }
}

@Component
export struct VideoTimer {
  public static timelapseInterval: number = 500;
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe | null = null;
  private mAction: VideoTimerDispatcher = new VideoTimerDispatcher();
  private mGlobalContext: GlobalContext = GlobalContext.get();
  private displayInfo: display.Display = DisplayService.getInstance().getDisplay();
  // UX显示
  @State startTimeSeconds: number = 0;
  @State uselessSeconds: number = 0;
  @State isLockRotation: boolean = true;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State mFontSize: Resource = $r('sys.float.Display_M');
  @State mLemFontSize: string = '48fp';
  @State mPosition: Position = { x: 0, y: 0 };
  @State initialLocation: Position = { x: 0, y: 0 };
  @State videoTimerAnimatePosition: Position = { x: 0, y: 0 };
  @State animateSwitch: boolean = false;
  @State mIsRecording: boolean = false;
  @State mIsPausing: boolean = false;
  @State mRecordScale: ScaleOptions = { x: 1, y: 1 };
  @State mPauseScale: ScaleOptions = { x: 0, y: 0 };
  @State mRecordOpacity: number = 1;
  @State mPauseOpacity: number = 0;
  @State recordingTime: number = 0;
  @State videoTimerHeight: number = INIT_VIDEO_TIMER_HEIGHT;
  @State intervalTime: number = 0;
  @State recordingTimeDisplay: string = '00:00';
  @State @Watch('statusChange') isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isShowDefault: boolean = false;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State rotateAngle: number = 0;
  @State isPickerTopBottomSplitScreenVertical: boolean = false;
  @State isPickerLeftRightSplitScreenHorizontal: boolean = false;
  @State isPickerCollapsedHorizontalSplitScreen: boolean = false;
  private isBigTimer: boolean = true;
  private mode: ModeType = ModeType.NONE;
  private mTimer: number = Number.MIN_VALUE;
  private mFontScalingTimer: number = Number.MIN_VALUE; // 组件缩放计时器
  // 位置计算
  @State videoTimerPosition: number = 0;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @StorageLink('closeTabBar') @Watch('handleTabBarCollaps') isCollapsTabBar: boolean = true;
  @State videoTimerOpacity: number = 1; // 同时监听方向和tabBAr的展开状态
  @State startTime: number = 0;
  @State stopTime: number = 0;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @State mLemTopSpacing: string = '0fp';
  @State mLemTopSpacingFlag: boolean = false;
  @State videoTimeRules: AlignRuleOption = {
    'middle': { 'anchor': '__container__', 'align': HorizontalAlign.Center },
    'center': { 'anchor': '__container__', 'align': VerticalAlign.Center }
  }
  @State @Watch('halfCollapsChange') isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @Prop landscapePreviewPosition: PositionType = { x: 0, y: 0 };
  @State isShowRingLightView: boolean = false;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @Prop @Watch('onPreviewAnimatePositionChange') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  private mTimerId: number = Number.MIN_VALUE;
  private tabBarPosition: number = AdaptiveLayoutService.getInstance().tabBarPosition;
  public pickerSplitScreenTabBarPosition: number = 0;
  @State isSmallVideoTimer: boolean = false;
  @Prop startVideoRecording: boolean = false;
  @State startVideoTimerRecording: boolean = false;
  @State nowTimerPosition: Position = { x: 0, y: 0 };
  private preRecordDuringTime: number = 0;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mEventBus.on(ActionType.ACTION_DIRECTION_CHANGE, this.onDealDirection.bind(this),
      this.mBase.hashCode());
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.startTimeSeconds = state.get<number>('recordReducer', 'startTimeSeconds');
      this.uselessSeconds = state.get<number>('recordReducer', 'uselessSeconds');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      if (this.isDirectionSubscriptionNeeded(state.get<WindowDirection>('contextReducer', 'direction'),
        state.get<boolean>('windowReducer', 'isLockRotation'),
        state.get<boolean>('collapsReducer', 'isShowSemiCollapsed'))) {
        this.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
          state.get<boolean>('windowReducer', 'isLockRotation'));
        this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      }
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.mAction.updateRecordingTimerComponentLargeState(true);
    this.setIntervalTimer();
    if (RecordController.getInstance().isMovieFile()) {
      this.mEventBus.on(RecordActionType.WILL_PAUSE, this.onPause.bind(this), this.mBase.hashCode());
      this.mEventBus.on(WorkerTask.VIDEO_STATE_CHANGE, async (type: string) => {
        HiLog.i(TAG, `RECORD_TRACK onVideoStateChanged, type: ${type}, uselessSeconds: ${this.uselessSeconds}.`);
        if (type === 'recordingResume') {
          await this.onResume();
        }
      }, this.mBase.hashCode());
    } else {
      this.mEventBus.on(RecordActionType.PAUSE, this.onPause.bind(this), this.mBase.hashCode());
      this.mEventBus.on(RecordActionType.RESUME, this.onResume.bind(this), this.mBase.hashCode());
    }

    this.mEventBus.on(RecordActionType.STOP, this.onStop.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_RECORD_START_SECONDS, this.startToRecord.bind(this), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, this.uxRefresh.bind(this), this.mBase.hashCode());
    this.uxInit();
    this.changeTimeLapseRecord();
    if (RecordController.getInstance().getRecordType() === RecordType.longClick) {
      this.recordingTime = this.preRecordDuringTime;
      this.recordingTimeDisplay = this.getTimerString();
    }
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
    HiLog.i(TAG, `clearInterval timer id: ${this.mTimer}.`);
    this.intervalClearing();
    this.fontScalingTimerClear();
    clearInterval(this.mTimerId);
    HiLog.i(TAG, 'aboutToDisappear X.');
    //组件销毁前将动画开关置为false
    this.animateSwitch = false;
  }

  private uxInit(): void {
    if (this.isVdeCollapsed) {
      this.videoTimerHeight = INIT_VDE_VIDEO_TIMER_HEIGHT;
    }
    if (PickerUtils.getIsPicker()) {
      this.isPickerTopBottomSplitScreenVertical = PickerUtils.getIsExpandedTopBottomVertical();
      this.isPickerLeftRightSplitScreenHorizontal = PickerUtils.getIsExpandedLeftRightHorizontal();
    }
    if (this.isLemCollaps) {
      this.mLemFontSize = '40fp';
    }
    this.mLemTopSpacingFlag = false;
    if (this.isShowLandscape) {
      this.videoTimerPosition = 0;
    } else {
      this.videoTimerPosition = AdaptiveLayoutService.getInstance().videoTimerPosition;
    }
    this.tabBarPosition = AdaptiveLayoutService.getInstance().tabBarPosition;
    this.mPosition = this.isHalfCollapsLEM ? { x: 0, y: this.tabBarPosition } :
      { x: 0, y: this.videoTimerPosition }
    this.nowTimerPosition = this.getPosition();
  }

  private onPreviewAnimatePositionChange(): void {
    this.nowTimerPosition = this.getPosition();
  }

  private statusChange(): void {
    HiLog.i(TAG, `VideoTimer in statusChange: ${this.animateSwitch}, ${this.isShowSemiCollapsed}.`);
    if (this.animateSwitch) {
      if (this.isShowSemiCollapsed) {
        this.LToSDisLandPosition();
        setTimeout((): void => {
          this.LToSShowSemiPosition();
        }, 150);
      } else {
        this.SemiToLandDisShowSemi();
        setTimeout((): void => {
          this.SemiToLandShowLand();
        }, 150);
      }
    } else {
      this.videoTimerAnimatePosition = this.getLayoutPosition();
      this.animateSwitch = true;
    }
    this.directionChange();
  }

  private changeTimeLapseRecord(): void {
    if (this.startVideoTimerRecording) {
      return;
    }
    if (this.startVideoRecording) {
      this.startToRecord();
    }
  }

  private videoStateOnChange() {
    HiLog.i(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.PAUSED) {
      this.recordToPauseAnim();
    } else if (this.videoState === RecordingState.RESUMING) {
      this.pauseToRecordAnim();
    }
  }

  private isDirectionSubscriptionNeeded(direction: WindowDirection, isLockRotation: boolean,
    isShowSemiCollapsed: boolean): boolean {
    if (AppStorage.get('windowDisplayName') === 'SuperLauncher') {
      return false;
    }
    if (DeviceInfo.isTablet() && isLockRotation &&
      !this.isTabletDirectionSameAxisWithOrientation(direction, this.displayInfo.orientation)) {
      return false;
    }
    return !(this.isVertical(direction) && isShowSemiCollapsed);
  }

  private onDealDirection(data: DirectionType) {
    HiLog.i(TAG, `onDealDirection${data.direction}`);
    this.nowTimerPosition = this.getPosition();
    if (data.direction === WindowDirection.LEFT || data.direction === WindowDirection.RIGHT) {
      this.videoTimerOpacity = 1;
    } else {
      if (!this.isCollapsTabBar) {
        this.videoTimerOpacity = 0;
      }
    }
  }

  private handleTabBarCollaps() {
    if (this.isCollapsTabBar) {
      this.videoTimerOpacity = 1;
    } else {
      if ((this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM) && !this.isBigTimer) {
        this.videoTimerOpacity = 0;
      }
    }
  }

  private recordToPauseAnim() {
    this.mIsPausing = true;
    animateToImmediately({
      delay: 0,
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        this.mIsRecording = false;
      }
    }, () => {
      this.mRecordScale = { x: 0, y: 0 }
      this.mPauseScale = { x: 1, y: 1 }
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp
    }, () => {
      this.mRecordOpacity = 0;
      this.mPauseOpacity = 1;
    });
  }

  private pauseToRecordAnim() {
    this.mIsRecording = true;
    animateToImmediately({
      delay: 0,
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        this.mIsPausing = false;
      }
    }, () => {
      this.mPauseScale = { x: 0, y: 0 }
      this.mRecordScale = { x: 1, y: 1 }
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp
    }, () => {
      this.mPauseOpacity = 0;
      this.mRecordOpacity = 1;
    });
  }

  private isTabletDirectionSameAxisWithOrientation(direction: WindowDirection,
    orientation: display.Orientation): boolean {
    const verticalAxis: display.Orientation[] = [display.Orientation.PORTRAIT, display.Orientation.PORTRAIT_INVERTED];
    if (verticalAxis.includes(orientation)) {
      return direction === WindowDirection.TOP || direction === WindowDirection.BOTTOM;
    } else {
      return direction === WindowDirection.LEFT || direction === WindowDirection.RIGHT;
    }
  }

  private getRotateAngle(): number | undefined {
    if (PickerUtils.getIsPickerInSplitScreen() && !PickerUtils.getIsTabletTopBottomSplitScreenFromReducer()) {
      return this.rotateAngle;
    }
    if (DeviceInfo.isTablet() && this.isLockRotation) {
      if (this.isOrientationVertical() && this.isVertical() || !this.isOrientationVertical() && !this.isVertical()) {
        return this.mDirection === WindowDirection.TOP ? 0 : 180;
      }
    }
    if (this.isLockRotation) {
      return this.rotateAngle;
    }
    return this.isShowSemiCollapsed ?
      this.mDirection === WindowDirection.LEFT ? 270 : 90 : DirectionToAngleUtil.geViewRotate(this.mDirection);
  }

  build() {
    if (this.isLemCollaps) {
      RelativeContainer() {
        Row() {
          Image($r('app.media.ic_video_continue'))
            .id('Image')
            .width(4)
            .height(4)
            .fillColor('#FF0000')
            .scale(this.mRecordScale)
            .opacity(this.mRecordOpacity)
          Text(`${this.recordingTimeDisplay}`)
            .margin({ left: 2 })
            .textAlign(TextAlign.Center)
            .fontSize(this.mLemFontSize)
            .maxFontScale(1)
            .fontColor(Color.White)
            .fontWeight(300)
            .fontFeature('\"ss01\" on')
            .textShadow({ color: '#33000000', radius: 3 })
            .id('VideoTimerText')
        }
        .accessibilityGroup(true)
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
        .alignRules(this.videoTimeRules)
        .id('rect')
        .margin({ top: this.getTopSpacing() })
      }

      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
      .rotate({
        angle: DirectionToAngleUtil.geViewRotate(this.mDirection),
      })
    } else {
      RelativeContainer() {
        if (this.mIsRecording) {
          Image($r('app.media.ic_video_continue'))
            .id('Recording')
            .alignRules({
              top: { anchor: '__container__', align: VerticalAlign.Top },
              bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
              right: { anchor: 'VideoTimerText', align: HorizontalAlign.Start },
            })
            .offset({ x: SystemLanguageUtil.isRTL() ? 8 : -8 })
            .width(12)
            .height(12)
            .fillColor(Color.Red)
            .scale(this.mRecordScale)
            .opacity(this.mRecordOpacity)
            .renderGroup(true)
        }
        if (this.mIsPausing) {
          Image($r('app.media.ic_video_pause'))
            .id('Pausing')
            .alignRules({
              top: { anchor: '__container__', align: VerticalAlign.Top },
              bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
              right: { anchor: 'VideoTimerText', align: HorizontalAlign.Start },
            })
            .offset({ x: SystemLanguageUtil.isRTL() ? 8 : -8 })
            .width(14)
            .height(14)
            .fillColor(Color.White)
            .scale(this.mPauseScale)
            .opacity(this.mPauseOpacity)
            .draggable(false)
        }

        Text(`${this.recordingTimeDisplay}`)
          .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
          .textAlign(TextAlign.Center)
          .fontSize(this.mFontSize)
          .maxFontScale(1)
          .fontColor(Color.White)
          .fontWeight(300)
          .fontFeature('\"ss01\" on')
          .textShadow({ color: '#33000000', radius: 3 })
          .id('VideoTimerText')
          .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
          .accessibilityText(this.getABText())
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
          })
      }
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .position(this.nowTimerPosition)
      .rotate({
        angle: this.getRotateAngle()
      })
      .opacity(this.videoTimerOpacity)
      .width(this.getContainerWidth())
      .height(this.videoTimerHeight)
      .padding({ left: this.isVdeCollapsed ? 0 : 10 })
      .margin({ top: this.isShowLandscape && !this.isShowSemiCollapsed ? VIDEO_TIMER_MARGIN_TOP : 0 })
      .hitTestBehavior(HitTestMode.None)
    }
  }

  private getABText(): string {
    let minute = Number(this.recordingTimeDisplay.split(':')[0]);
    let sec = Number(this.recordingTimeDisplay.split(':')[1]);
    HiLog.i(TAG, `getABText minute: ${minute}, sec: ${sec}`);
    return ResGetter.getStringSafe(minute === 0 ?
      `${getContext(this)
        .resourceManager
        .getPluralStringValueSync($r('app.plural.accessibility_recorded_seconds'), sec)}` :
      `${ResGetter.getStringSafe($r('app.string.accessibility_recording_duration',
        getContext(this).resourceManager.getPluralStringValueSync($r('app.plural.accessibility_min'), minute),
        getContext(this).resourceManager.getPluralStringValueSync($r('app.plural.accessibility_sec'), sec)))}`);
  }

  private getContainerWidth(): number | string {
    if (this.isShowDefault) {
      if (this.isPickerTopBottomSplitScreenVertical && !this.isVertical() ||
        this.isPickerLeftRightSplitScreenHorizontal && !this.isVertical()) {
        return this.xComponentHeight;
      }
      return this.windowWidth;
    } else if (this.isShowLandscape && !this.isShowSemiCollapsed) {
      return this.xComponentWidth;
    }
    return '100%';
  }

  private isOrientationVertical(): boolean {
    return this.displayInfo.orientation === display.Orientation.PORTRAIT ||
      this.displayInfo.orientation === display.Orientation.PORTRAIT_INVERTED;
  }

  private getPosition(): Position {
    if (DeviceInfo.isTablet()) {
      return this.getTabletVideoTimerPosition();
    } else if (!this.isShowDefault) {
      return this.getTricollapsVideoTimerPosition();
    } else if (this.isVdeCollapsed) {
      return this.getVdeVideoTimerPosition();
    } else if (this.isShowDefault) {
      const coefficient: number = this.mDirection === WindowDirection.RIGHT ? 1 : -1;
      if (this.isPickerTopBottomSplitScreenVertical && !this.isVertical() ||
        this.isPickerLeftRightSplitScreenHorizontal && !this.isVertical()) {
        return {
          x: this.mDirection === WindowDirection.LEFT ? -(this.xComponentHeight - INIT_VIDEO_TIMER_HEIGHT) / 2 :
            coefficient * (this.windowWidth - INIT_VIDEO_TIMER_HEIGHT / 2 - this.xComponentHeight / 2),
          y: this.isHalfCollapsLEM ? -INIT_VIDEO_TIMER_HEIGHT / 2 + this.windowHeight / 4 :
            -INIT_VIDEO_TIMER_HEIGHT / 2 + AdaptiveLayoutService.getInstance().previewPosition +
              this.xComponentHeight / 2
        };
      }
      return this.isVertical() ? this.mPosition : {
        x: coefficient * (this.windowWidth / 2 - INIT_VIDEO_TIMER_HEIGHT / 2),
        y: this.isHalfCollapsLEM ? -INIT_VIDEO_TIMER_HEIGHT / 2 + this.windowHeight / 4 :
          -INIT_VIDEO_TIMER_HEIGHT / 2 + AdaptiveLayoutService.getInstance().previewPosition1to1 + this.windowWidth / 2
      };
    } else if (this.isShowSemiCollapsed) {
      return { x: INIT_VIDEO_TIMER_HEIGHT / 2 + 8, y: this.windowHeight / 2 - INIT_VIDEO_TIMER_HEIGHT / 2 };
    } else {
      HiLog.i(TAG, `getPosition isVertical: ${this.isVertical()}, mDirection: ${this.mDirection}`);
      if (this.isVertical()) {
        if (this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM) {
          return { x: this.previewAnimatePosition.x, y: this.videoTimerPosition };
        } else {
          return { x: 0, y: this.windowHeight - INIT_VIDEO_TIMER_HEIGHT - this.videoTimerPosition }
        }
      } else {
        return {
          x: -this.xComponentWidth / 2 + INIT_VIDEO_TIMER_HEIGHT * 2 + 30,
          y: this.windowHeight / 2 - INIT_VIDEO_TIMER_HEIGHT / 2
        };
      }
    }
  }

  private getTabletVideoTimerPosition(): Position {
    if (PickerUtils.getIsTabletTopBottomSplitScreenFromReducer()) {
      return { x: 0, y: 30 };
    }
    if (this.isLockRotation) {
      if (this.isOrientationVertical() && this.isVertical()) {
        return this.mDirection === WindowDirection.TOP ?
          { x: 0, y: (this.windowHeight - this.windowWidth * 4 / 3) / 2 } :
          { x: 0, y: this.windowHeight / 2 + this.windowWidth * 2 / 3 - INIT_VIDEO_TIMER_HEIGHT };
      }
      if (!this.isOrientationVertical() && !this.isVertical()) {
        return this.mDirection === WindowDirection.TOP ?
          { x: 0, y: (this.windowHeight - this.windowWidth * 9 / 16) / 2 } :
          { x: 0, y: this.windowHeight / 2 + this.windowWidth * 9 / 32 - INIT_VIDEO_TIMER_HEIGHT };
      }
    }
    return this.isOrientationVertical() ? { x: 0, y: (this.windowHeight - this.windowWidth * 4 / 3) / 2 } :
      { x: 0, y: (this.windowHeight - this.windowWidth * 9 / 16) / 2 };
  }

  private getTricollapsVideoTimerPosition(): Position {
    if (this.isLockRotation) {
      if (this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM) {
        return { x: this.previewAnimatePosition.x, y: this.videoTimerPosition + VIDEO_TIMER_MARGIN_TOP_TRICOLLAPS };
      } else {
        return {
          x: -this.xComponentWidth / 2 + INIT_VIDEO_TIMER_HEIGHT * 2 + 20,
          y: this.windowHeight / 2 - INIT_VIDEO_TIMER_HEIGHT / 2
        };
      }
    }
    const rotation: number = DisplayService.getInstance().getDisplay().rotation;
    switch (rotation) {
      case display.Orientation.PORTRAIT:
        return { x: this.previewAnimatePosition.x, y: this.videoTimerPosition + VIDEO_TIMER_MARGIN_TOP_TRICOLLAPS };
      case display.Orientation.LANDSCAPE:
        return { x: this.previewAnimatePosition.x, y: this.videoTimerPosition + VIDEO_TIMER_MARGIN_LEFT_TRICOLLAPS };
      case display.Orientation.PORTRAIT_INVERTED:
        return { x: this.previewAnimatePosition.x, y: this.videoTimerPosition + VIDEO_TIMER_MARGIN_TOP_TRICOLLAPS };
      case display.Orientation.LANDSCAPE_INVERTED:
        return { x: this.previewAnimatePosition.x, y: this.videoTimerPosition + VIDEO_TIMER_MARGIN_LEFT_TRICOLLAPS };
      default:
        return { x: this.previewAnimatePosition.x, y: this.videoTimerPosition };
    }
  }

  private getRotationVdeShowBackAsFront(): number {
    return this.mDirection === WindowDirection.LEFT ? this.windowWidth / 2 - INIT_VDE_VIDEO_TIMER_HEIGHT / 2 :
      INIT_VDE_VIDEO_TIMER_HEIGHT / 2 - this.windowWidth / 2;
  }

  private getVdeVideoTimerPosition(): Position {
    if (!getStates().get<boolean>('windowReducer', 'isLockRotation')) {
      return this.mPosition;
    }
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    switch (rotation) {
      case 0: // 右
        return this.isVertical() ? {
          x: 0,
          y: 12
        } : {
          x: this.mDirection === WindowDirection.LEFT ? INIT_VDE_VIDEO_TIMER_HEIGHT / 2 - this.windowWidth / 2 :
            this.windowWidth / 2 - INIT_VDE_VIDEO_TIMER_HEIGHT / 2,
          y: this.windowHeight / 2 - INIT_VDE_VIDEO_TIMER_HEIGHT / 2
        };
      case 2:
        return this.isVertical() ? {
          x: 0,
          y: 12
        } : {
          x: this.getRotationVdeShowBackAsFront(),
          y: this.windowHeight / 2 - INIT_VDE_VIDEO_TIMER_HEIGHT / 2
        };
      case 3:
      default:
        return !this.isVertical() ? this.mPosition : {
          x: this.mDirection === WindowDirection.TOP ? INIT_VDE_VIDEO_TIMER_HEIGHT / 2 - this.windowWidth / 2 :
            this.windowWidth / 2 - INIT_VDE_VIDEO_TIMER_HEIGHT / 2,
          y: this.windowHeight / 2 - INIT_VDE_VIDEO_TIMER_HEIGHT / 2
        };
    }
  }

  //展开态到悬停态的定位动画(隐藏展开态的videoTimer)
  private LToSDisLandPosition(): void {
    const height: number = getStates().get<number>('windowReducer', 'windowHeight');
    HiLog.i(TAG, `getLayoutPosition ${height}`);
    this.videoTimerAnimatePosition = { x: 0, y: 0 };
    animateToImmediately({
      duration: 150,
      curve: Curves.cubicBezierCurve(0.35, 0.00, 0.52, 0.52),
    },
      () => {
        this.videoTimerAnimatePosition.x = height * 0.18;
      });
  }

  //展开态到悬停态的定位动画(显示悬停态的videoTimer)
  private LToSShowSemiPosition(): void {
    const width = getStates().get<number>('windowReducer', 'windowWidth');
    const height = getStates().get<number>('windowReducer', 'windowHeight');
    this.videoTimerAnimatePosition.x = this.getLayoutPosition().x - (height * 0.15);
    this.videoTimerAnimatePosition.y = width / 2;
    animateToImmediately({
      duration: 350,
      curve: Curves.cubicBezierCurve(0.18, 0.52, 0.47, 1.00),
    },
      () => {
        this.videoTimerAnimatePosition = this.getLayoutPosition();
      });
  }

  //悬停态到展开态先隐藏悬停态
  private SemiToLandDisShowSemi(): void {
    const width = getStates().get<number>('windowReducer', 'windowWidth');
    const height = getStates().get<number>('windowReducer', 'windowHeight');
    this.videoTimerAnimatePosition = { x: 100, y: width / 2 };
    animateToImmediately({
      duration: 150,
      curve: Curves.cubicBezierCurve(0.35, 0.00, 0.52, 0.52),
    },
      () => {
        this.videoTimerAnimatePosition.x = 100 - (height * 0.18);
      });
  }

  //悬停态到展开态展开态再出现
  private SemiToLandShowLand(): void {
    const height = getStates().get<number>('windowReducer', 'windowHeight');
    this.videoTimerAnimatePosition.x = height * 0.18;
    this.videoTimerAnimatePosition.y = 0;
    animateToImmediately({
      duration: 350,
      curve: Curves.cubicBezierCurve(0.18, 0.52, 0.47, 1.00),
    },
      () => {
        this.videoTimerAnimatePosition = this.getLayoutPosition();
      })
  }

  private bigToSmallAnimationFunction(): void {
    this.isSmallVideoTimer = true;
    this.mFontSize = $r('sys.float.Title_S');
    if (this.isVdeCollapsed) {
      this.videoTimerHeight = 30;
      this.mPosition = { x: 0, y: 12 };
      return;
    }
    if (this.isShowDefault && this.isVertical() && !DeviceInfo.isTablet()) {
      this.videoTimerHeight = 30;
    }
    if (!this.isShowLandscape && !DeviceInfo.isTablet()) {
      this.mPosition = {
        x: 0,
        y: this.tabBarPosition + this.getVideoTimerOffset()
      };
    } else if (!this.isShowLandscape && DeviceInfo.isTablet()) {
      this.mPosition = {
        x: 0,
        y: VIDEO_TIMER_MINI_MARGIN_TOP_TABLET
      };
    } else if (this.isShowSemiCollapsed) {
      this.mPosition = { x: 0, y: 0 };
    } else {
      this.mPosition = { x: 0, y: 0 };
    }
  }

  private getVideoTimerOffset(): number {
    return getStates().get<window.WindowStatusType>('windowReducer', 'windowStatus') ===
    window.WindowStatusType.FLOATING && this.isVertical() ? 20 : 0;
  }

  private bigToSmallAnim() {
    if (!this.isCollapsTabBar) {
      this.videoTimerOpacity = 0;
      this.bigToSmallAnimationFunction();
      return;
    }
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction
    }, () => {
      this.bigToSmallAnimationFunction();
    });
  }

  private uxRefresh(): void {
    if (this.mTimerId !== Number.MIN_VALUE) {
      clearInterval(this.mTimerId);
    }
    this.mTimerId = setTimeout(() => {
      this.uxInit();
      this.bigToSmallAnimationFunction();
      this.nowTimerPosition = this.getPosition();
    }, 50);
  }

  private intervalClearing(): void {
    if (this.mTimer !== Number.MIN_VALUE) {
      clearInterval(this.mTimer);
      this.mTimer = Number.MIN_VALUE;
    }
  }

  private fontScalingTimerClear(): void {
    if (this.mFontScalingTimer != Number.MIN_VALUE) {
      clearTimeout(this.mFontScalingTimer);
      this.mFontScalingTimer = Number.MIN_VALUE;
    }
  }

  private async onPause(): Promise<void> {
    const currentTime: number = await systemDateTime.getRealTime(false);
    this.stopTime = currentTime;
    HiLog.i(TAG, `onTimerPaused, stopTime: ${this.stopTime}.`);
    this.intervalClearing();
  }

  private async onResume(): Promise<void> {
    const currentTime: number = await systemDateTime.getRealTime(false);
    this.startTime = currentTime;
    HiLog.i(TAG, `onTimerResumed, startTime: ${this.startTime}, last stopTime: ${this.stopTime}.`);

    const uselessTime: number = this.uselessSeconds + (this.startTime - this.stopTime) +
      // 经验值，后续待重构成优先用接口回调获取时间
      (RecordController.getInstance().isMovieFile() ? 0 : 200);
    execDispatch(Action.updateRecordUselessTime(uselessTime));
    this.setIntervalTimer();
  }

  private onStop(): void {
    this.isSmallVideoTimer = false;
    this.startVideoTimerRecording = false;
    this.startVideoRecording = false;
  }

  private startToRecord(): void {
    HiLog.i(TAG, 'startToRecord in');
    this.startVideoTimerRecording = true;
    this.isSmallVideoTimer = false;
    if (this.isLemCollaps) {
      clearTimeout();
      setTimeout((): void => {
        animateTo({ curve: Curve.Linear, duration: 250 }, () => {
          this.videoTimeRules = {
            'middle': { 'anchor': '__container__', 'align': HorizontalAlign.Center },
            'top': { 'anchor': '__container__', 'align': VerticalAlign.Top }
          }
          this.mLemFontSize = '20fp';
          this.mLemTopSpacingFlag = true;
        })
      }, 3000)
      this.fontScalingTimerClear();
      this.mFontScalingTimer = setTimeout((): void => {
        this.isBigTimer = false;
        this.bigToSmallAnim();
        this.mAction.updateRecordingTimerComponentLargeState(false);
        this.fontScalingTimerClear();
      }, 0);
    } else {
      const startToRecordTimer = setTimeout((): void => {
        this.mIsRecording = true;
        HiLog.e(TAG, 'startToRecord: start recording now');
        clearTimeout(startToRecordTimer);
      }, 100);

      this.fontScalingTimerClear();
      this.mFontScalingTimer = setTimeout((): void => {
        this.isBigTimer = false;
        this.bigToSmallAnim();
        this.mAction.updateRecordingTimerComponentLargeState(false);
        this.fontScalingTimerClear();
        animateToImmediately({
          duration: 300,
          curve: Curve.Friction
        }, () => {
          this.nowTimerPosition = this.getPosition();
        });
      }, 3000);
    }
  }

  public getLayoutPosition(): PositionType {
    const windowWidth = getStates().get<number>('windowReducer', 'windowWidth');
    const windowHeight = getStates().get<number>('windowReducer', 'windowHeight');
    if (this.isShowSemiCollapsed) {
      const width: number = VIDEO_TIMER_DEFAULT_WIDTH;
      const height: number = (windowHeight >> 1) - VIDEO_TIMER_POSITION_OFFSET;
      return { x: width, y: height };
    }
    if (this.mDirection !== WindowDirection.RIGHT && this.mDirection !== WindowDirection.LEFT) {
      return { x: 0, y: 0 };
    }
    const width: number = (windowWidth >> 1) - VIDEO_TIMER_DEFAULT_HEIGHT;
    const previewLocation = AdaptiveLayoutService.getInstance().previewPositionDefaultConst;
    const height: number = (DisplayCalculator.calcSurfaceDisplaySize(4 / 3, windowWidth,
      windowHeight).height - this.videoTimerHeight) / 2 + previewLocation;
    if (this.mDirection === WindowDirection.RIGHT) {
      return { x: width, y: height };
    }
    return { x: -width, y: height };
  }

  private setIntervalTimer() {
    HiLog.i(TAG, 'setIntervalTimer.');
    this.intervalClearing();
    this.mTimer = setInterval(async () => {
      if (this.videoState === RecordingState.RECORDING) {
        this.recordingTime = await this.getCurRecordingTime();
        let currentTime = this.getTimerString();
        if (this.recordingTimeDisplay === currentTime) {
          return;
        }
        HiLog.e(TAG, `time diff ${this.recordingTimeDisplay}, ${currentTime}`);
        this.recordingTimeDisplay = currentTime;
        if (this.mGlobalContext.getIsPicker() &&
          this.mGlobalContext.getCameraAbilityWant()?.parameters?.videoDuration) {
          try {
            let videoDuration: number = Number.parseInt(this.mGlobalContext
              .getCameraAbilityWant()?.parameters?.videoDuration as string)
            HiLog.i(TAG, `videoDuration is ${videoDuration}`);
            if (this.recordingTime >= videoDuration) {
              this.mAction.stopRecording();
              this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
            }
          } catch (error) {
            HiLog.e(TAG, `picker videoDuration --> ${error?.code}}`);
          }
        }
      }
    }, 70);
  }

  private async getCurRecordingTime(): Promise<number> {
    const curTime: number = await systemDateTime.getRealTime(false);
    let recordingTime: number = curTime - this.startTimeSeconds - this.uselessSeconds;
    AppStorage.setOrCreate('recordingTime', recordingTime);
    HiLog.d(TAG, `getCurRecordingTime curTime: ${curTime}, startTimeSeconds: ${
      this.startTimeSeconds}, uselessSeconds: ${this.uselessSeconds}, recordingTime: ${
      recordingTime}, preRecordTime: ${this.preRecordDuringTime}.`);
    recordingTime = Math.floor((recordingTime > 0 ? recordingTime : 0) / 1000) + this.preRecordDuringTime;
    return recordingTime;
  }

  private async getCurIntervalTime(): Promise<number> {
    let curTime: number = await systemDateTime.getRealTime(false);
    let recordingTime: number = curTime - this.startTimeSeconds - this.uselessSeconds;
    HiLog.d(TAG, `getCurRecordingTime curTime: ${curTime}, startTimeSeconds: ${this.startTimeSeconds}, uselessSeconds: ${
      this.uselessSeconds}, recordingTime: ${recordingTime}.`);
    let intervalTime = Math.floor(recordingTime / VideoTimer.timelapseInterval / 30);
    HiLog.i(TAG, `getCurIntervalTime is ${intervalTime}.`);
    return intervalTime > 0 ? intervalTime : 0;
  }

  private getTimerString(): string {
    let sec = this.recordingTime % TIME_SYSTEM;
    let minute = Math.floor(this.recordingTime % (TIME_SYSTEM * TIME_SYSTEM) / TIME_SYSTEM);
    let currentTime = `${minute < 10 ? `0${minute}` : `${minute}`}:${sec < 10 ? `0${sec}` : `${sec}`}`;
    if (this.recordingTime >= TIME_SYSTEM * TIME_SYSTEM) {
      let minute = Math.floor(this.recordingTime / (TIME_SYSTEM * TIME_SYSTEM));
      currentTime = `${minute < 10 ? `0${minute}` : `${minute}`}:${currentTime}`;
    }
    return currentTime;
  }

  private formatSecTimeLapse(): string {
    let shownSec = '00';
    let sec = Math.floor(this.intervalTime % TIME_SYSTEM);
    if (sec < 10) {
      shownSec = `0${sec}`;
    } else {
      shownSec = `${sec}`;
    }
    return shownSec;
  }

  private formatMinTimeLapse(): string {
    let shownMin = '00';
    let minute = Math.floor(this.intervalTime / TIME_SYSTEM);
    if (minute < 10) {
      shownMin = `0${minute}`;
    } else {
      shownMin = `${minute}`;
    }
    return shownMin;
  }

  private isVertical(inputDirection?: WindowDirection): boolean {
    if (inputDirection) {
      return inputDirection === WindowDirection.TOP || inputDirection === WindowDirection.BOTTOM;
    }
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private getTopSpacing(): string {
    if (!this.mLemTopSpacingFlag) {
      return '0fp';
    }
    if (DirectionToAngleUtil.geViewRotate(this.mDirection) === 90 ||
      DirectionToAngleUtil.geViewRotate(this.mDirection) === 270) {
      return '30fp';
    } else {
      return '10fp';
    }
  }

  private directionChange() {
    HiLog.i(TAG, 'directionChange E.');
    if (this.isBigTimer || this.isShowSemiCollapsed || DeviceInfo.isTablet()) {
      this.videoTimerHeight = 80;
    } else if (this.isShowDefault) {
      this.videoTimerHeight = this.isVertical() && !this.isVdeCollapsed ? 30 : 80;
    }
    if (!this.isShowLandscape) {
      this.mPosition = {
        x: 0,
        y: this.isBigTimer && this.isVertical() ? this.videoTimerPosition : AdaptiveLayoutService.getInstance()
          .tabBarPosition + this.getVideoTimerOffset()
      };
    } else if (this.isShowSemiCollapsed) {
      this.mPosition = { x: 0, y: 0 };
    } else {
      this.mPosition = { x: 0, y: this.videoTimerPosition + 15 };
    }
    HiLog.i(TAG, 'directionChange X.');
  }

  private halfCollapsChange(): void {
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction
    }, (): void => {
      if (this.isBigTimer) {
        this.mPosition = this.isHalfCollapsLEM ? { x: 0, y: AdaptiveLayoutService.getInstance().tabBarPosition } :
          { x: 0, y: this.videoTimerPosition }
      }
    });
  }

  private directionCorrection(inputDirection: WindowDirection, isLockRotation: boolean): void {
    this.mDirection = DirectionCorrectionService.directionCorrection(inputDirection, isLockRotation);
  }

  private isRingLightStatus(): boolean { // 录像计时是否展示环形补光色
    if (this.isShowDefault && this.isVertical() && !DeviceInfo.isTablet()) {
      return !this.isSmallVideoTimer ? this.isShowRingLightView : false;
    } else {
      return this.isShowRingLightView;
    }
  }
}