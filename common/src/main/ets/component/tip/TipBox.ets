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

import lazy { ModeType } from '../../mode/ModeType';
import lazy { OhCombinedState, Unsubscribe, getStates, reduxSubscribe } from '../../redux';
import lazy { ChangeState } from '../../redux/Store';
import lazy { AdaptiveLayoutService, TAB_BAR_HEIGHT } from '../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { PositionType } from '../../utils/types';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { INIT_VIDEO_TIMER_HEIGHT, VIDEO_TIMER_MARGIN_TOP } from '../videoTimer/VideoTimer';
import lazy { TextInfo } from './TextInfo';
import lazy { Tip } from './Tip';
import display from '@ohos.display';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { ActionData } from '../../redux/actions/Action';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import window from '@ohos.window';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { AspectRatioOperation } from '../../function/aspectratio/AspectRatioOperation';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import camera from '@ohos.multimedia.camera';
import lazy { UIOperationType } from '../uicomponent/UIOperationType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PublicTag } from '../../service/preferences/PropTag';
import lazy { screenLock } from '@kit.BasicServicesKit';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { storageStatistics } from '@kit.CoreFileKit';
import lazy { MemoryService } from '../../service/Memory/MemoryService';

/* instrument ignore file */
const TAG: string = 'TipBox';

export const POSITION_Y_VERTICAL_RECORDING: number = 162;

const MARGIN_LANDSCAPE_COMPONENT_LEFT: number = 24;
const MARGIN_LANDSCAPE_TIP_TO_TREASURE_BOX: number = 16;
const MARGIN_DEFAULT_HORIZONTAL_TOP: number = 16;
const MARGIN_HALF_COLLAPSED_LANDSCAPE_TOP: number = 24;
const MARGIN_SEMI_COLLAPSED_PREVIEW_BOTTOM: number = 40;
const MARGIN_LANDSCAPE_HORIZONTAL_LEFT: number = 24 + 48 + 17; //24为百宝箱左边距，48为百宝箱宽度，17为与百宝箱之间的距离。
const TEXT_INFO_DEFAULT_VERTICAL_WIDTH: number = 260;
const TEXT_INFO_DEFAULT_HORIZONTAL_WIDTH: number = 160;
const TEXT_INFO_MARGIN_WIDTH: number = 80;
const MARGIN_HALF_COLLAPSED_PREVIEW: number = 52
const MARGIN_HALF_VDE_COLLAPSED_PREVIEW: number = 42;
const WINDOW_WIDTH_THRESHOLDS: number = 715;
const MARGIN_PICKER_LEFT_RIGHT: number = 12;
const MARGIN_VDE_COLLAPS_TOP: number = 18;
const MARGIN_VDE_COLLAPS_LEFT_RIGHT: number = 33;
const TEXT_INFO_WIDTH_TABLET: number = 400;
const VERTICAL_TIP_POSITION: number = 35;
const VERTICAL_COLLAPSED_TIP_POSITION: number = -2;
const NEW_FLOAT_WINDOW_POSITION_Y: number =
  38 + AnimSpecifications.NEW_FLOAT_WINDOW_TOP_OFFSET; // tabBar上边距32 + tabBar高度30 + tip与tabBar的间距8
const NUMBER_9_TO_16: number = 9 / 16;
const NUMBER_1_TO_1: number = 1;
const NUMBER_MIN: number = 0.07;
const MAX_TIP_WIDTH: number = 400;
const TREASURE_BOX_ELEMENT_INNER_WIDTH: number = 48;
const TEXT_NO_i_WIDTH: number = 64;
const TEXT_HAS_i_WIDTH: number = 44;
const ANGLE_0: number = 0;
const ANGLE_180: number = 180;
const BYTE_UNIT_CARRY = 1024;

class StateStruct {
  public videoTimerState: boolean = false;
  public videoTimerStateExceptSuperSlowMo = false;
  public isHalfCollapsLEM: boolean = false;
  public isRecordTimeComponentLarge: boolean = false;
  public mode: ModeType = ModeType.NONE;
  public isLockRotation: boolean = true;
}

export class DirectionType {
  public direction: number = 2;
}

@Component
export struct TipBox {
  @State state: StateStruct = new StateStruct();
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private adaptiveLayoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  @State displayInfo: display.Display = DisplayService.getInstance().getDisplay();
  private taskTimerId: number = Number.MIN_VALUE;
  @State imageOpacity: number = 0;
  @State mRotate: number = 0;
  @State @Watch('onDirection') mDirection: number = WindowDirection.TOP;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State @Watch('initTip') isShowDefault: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowBigText: boolean = false;
  @State @Watch('bigToSmallAnim') isRecordTimeComponentLarge: boolean = false;
  @State heightBetweenPreviewArea4to3And1to1: number = 0;
  @State defaultVerticalTipPositionY: number = 0;
  @State defaultPreviewPosition4to3: number = 0;
  @State isHalfCollapsLEM: boolean = false;
  @Prop landscapePreviewPosition: PositionType = { x: 0, y: 0 };
  @Prop isTablet: boolean = false;
  @Prop isShowLongExposureInfo: boolean = false;
  @Link isShowTextInfo: boolean;
  @State isShowMorePage: boolean = false;
  @Prop isShowPanoramaInfo: boolean;
  @State lightPaintingTimerState: boolean = false;
  @State isVdeLandscape: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State isFontScaling: boolean = false;
  private mTabTipRotate: number = 0;
  private mTabTipOffsetY: number = 0;
  @State isImmersive: boolean = false;
  @State windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @State isTimelapseFront: boolean = false;
  @State immersiveUIType: UIOperationType = UIOperationType.NULL;
  @StorageLink('isBannerLoaded') isBannerLoaded: boolean = false;
  @StorageLink('isRequestLocationLoaded') isRequestLocationLoaded: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State tipTopMargin: number = this.getTipMarginTop();
  @StorageLink('isTipLongText') isTipLongText: boolean = false;
  @StorageProp('isBannerVisiblePick') isBannerVisiblePick: boolean = false;
  @Prop isHdr: boolean = false;
  @LocalStorageProp('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @State smartControlConfig: boolean = false;
  @StorageLink('smartControlVisible') smartControlVisible: boolean = false;
  @StorageLink('depthFusionPopupVisibility') depthFusionPopupVisibility: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @StorageLink('isPSDCollaps') isPSDCollapsed: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        videoTimerState: state.get<boolean>('recordReducer', 'videoTimerState'),
        // 非超级慢动作下的videoTimerState
        videoTimerStateExceptSuperSlowMo: state.get<boolean>('recordReducer', 'videoTimerState') &&
        this.isVideoTimerShow(state.get<ModeType>('modeReducer', 'mode')),
        isHalfCollapsLEM: state.get<boolean>('collapsReducer', 'isHalfCollapsLEM'),
        isRecordTimeComponentLarge: state.get<boolean>('recordReducer', 'isRecordTimeComponentLarge'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        isLockRotation: state.get<boolean>('windowReducer', 'isLockRotation'),
      });
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowBigText = state.get<boolean>('modeReducer', 'isShowBigText');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isImmersive = state.get<boolean>('uiReducer', 'isImmersive');
      this.isRecordTimeComponentLarge = state.get<boolean>('recordReducer', 'isRecordTimeComponentLarge');
      if (this.isSubscriptionNeeded(state)) {
        this.mRotate = state.get<number>('contextReducer', 'rotateAngle');
        this.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'));
      }
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.lightPaintingTimerState = state.get<boolean>('lightPaintingReducer', 'lightPaintingTimerState');
      this.windowStatus = state.get<window.WindowStatusType>('windowReducer', 'windowStatus');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.smartControlConfig = state.get<boolean>('uiReducer', 'isSmartControlConfig');
    }, null);
    this.initTip();
    this.defaultVerticalTipPositionY = this.defaultPreviewPosition4to3;
    this.mEventBus.on(RecordActionType.START, this.startToRecord.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.STOP, this.onRecordStop.bind(this), this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, WindowActionType.REFRESH_UX], this.initTip.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_TOAST_PANORAMA, (data: ActionData) => this.isPanoramaToast(data),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.initTip.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_DIRECTION_CHANGE, this.onDirection.bind(this), this.mBase.hashCode());
    if (this.isShowDefault && this.fontSizeScale >= CommonConstants.TEXT_SIZE_LARGE) {
      this.isFontScaling = true;
    }
    this.isBannerLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.PICKER_IS_BANNER_LOADED, false) as boolean;
    this.isRequestLocationLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED, false) as boolean;
  }

  private isStorageSpaceSufficient(): void {
    try {
      MemoryService.getInstance().checkStorageStatus(false);
    } catch (error) {
      const faultReason = `getFreeSize failed because: ${error.message}`;
      HiLog.e(TAG, faultReason);
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear');
    this.isFontScaling = false;
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private isVideoTimerShow(mode: ModeType): boolean {
    return true;
  }

  private isSubscriptionNeeded(state: OhCombinedState): boolean {
    if (AppStorage.get('windowDisplayName') === 'SuperLauncher') {
      return false;
    }
    if (PickerUtils.getIsExpandedHorizontalPreviewSize()) {
      return false;
    }
    if (this.isShowSemiCollapsed) {
      return !this.isVertical(state.get<WindowDirection>('contextReducer', 'direction')) ? true : false;
    }
    if (this.isShowLandscape && !this.isShowSemiCollapsed) {
      return this.state.isLockRotation;
    }
    return true;
  }

  private isVertical(inputDirection?: WindowDirection): boolean {
    if (inputDirection) {
      return inputDirection === WindowDirection.TOP || inputDirection === WindowDirection.BOTTOM;
    }
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private onDirection(data: DirectionType): void {
    if (data === undefined || data.direction === undefined) {
      return;
    }
    HiLog.i(TAG, `onDirection onDirection: ${this.mDirection}`);
  }

  private initTip(): void {
    if (PickerUtils.getIsExpandedTopBottomVertical()) {
      this.mDirection = WindowDirection.RIGHT;
      this.mRotate = 90;
    }
    if (PickerUtils.getIsExpandedLeftRightHorizontal()) {
      this.mDirection = WindowDirection.TOP;
      this.mRotate = 0;
    }
    let windowStatus: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    this.defaultPreviewPosition4to3 = AdaptiveLayoutService.getInstance().previewPosition4to3;
    if (windowStatus === window.WindowStatusType.FLOATING) {
      this.heightBetweenPreviewArea4to3And1to1 = 60;
    } else if (this.isShowDefault) {
      this.heightBetweenPreviewArea4to3And1to1 = Math.abs(
        this.adaptiveLayoutService.previewPosition1to1 - this.defaultPreviewPosition4to3);
    }
    this.displayInfo = DisplayService.getInstance().getDisplay();
    // 相机热启动时判断空间是否充足
    if (!this.isLemCollaps && !this.isPSDCollapsed && !GlobalContext.get().getIsPicker()) {
      // 外屏不予判断，picker不走此处
      this.isStorageSpaceSufficient();
    }
  }

  private isPanoramaToast(data: ActionData): void {
    this.isShowPanoramaInfo = data['isPanoramaToastInfo'];
  }

  private calcLandscapeHorizontalPreviewPosition4to3(): number {
    let shortEdge: number = Math.min(this.windowWidth, this.windowHeight);
    let longEdge: number = Math.max(this.windowWidth, this.windowHeight);
    let preview4to3Position: number = Math.abs(shortEdge - 3 / 4 * longEdge) / 2;
    return preview4to3Position;
  }

  private calcLandscapeHorizontalPreviewPosition16to9(): number {
    let shortEdge: number = Math.min(this.windowWidth, this.windowHeight);
    let longEdge: number = Math.max(this.windowWidth, this.windowHeight);
    let preview16to9Position: number = Math.abs(shortEdge - 9 / 16 * longEdge) / 2;
    return preview16to9Position;
  }

  private getColumnWidth(): number {
    if (this.isShowDefault && !DeviceInfo.isTablet()) {
      if (PickerUtils.getIsExpandedTopBottomVertical()) {
        return Math.min(this.xComponentHeight, this.xComponentWidth / 4 * 3 - 2 * MARGIN_PICKER_LEFT_RIGHT);
      }
      return this.windowWidth - TEXT_NO_i_WIDTH;
    } else if (this.isShowSemiCollapsed) {
      return this.windowHeight;
    } else {
      let width = this.windowHeight > this.windowWidth ? this.windowHeight * 9 / 21 : this.windowWidth * 9 / 21;
      return Math.min(this.state.mode === ModeType.VIDEO ? width : this.xComponentWidth, MAX_TIP_WIDTH);
    }
  }

  private getColumnHeight(): number | string {
    if (this.isTipLongText) {
      return '';
    }
    if (this.isVdeCollapsed) {
      const rotation = DisplayService.getInstance().getDisplay().rotation;
      if (getStates().get<boolean>('windowReducer', 'isLockRotation') && (rotation === 0 || rotation === 2)) {
        return this.isVertical() ? 149 : '';
      }
      return this.isVertical() ? '' : 149;
    }
    if (DeviceInfo.isTablet()) {
      if (PickerUtils.getIsTabletLeftRightSplitScreenFromReducer()) {
        return this.windowWidth / 8;
      }
      return this.isOrientationVertical() && !this.state.videoTimerStateExceptSuperSlowMo ? this.windowWidth / 6 : '';
    } else if (this.isShowDefault) {
      if (this.adaptiveLayoutService.previewPosition4to3 === this.adaptiveLayoutService.previewPosition1to1) {
        return '';
      }
      if (PickerUtils.getIsExpandedLeftRightHorizontal()) {
        return Math.abs(this.adaptiveLayoutService.previewPosition16to9 -
        this.adaptiveLayoutService.previewPosition4to3);
      }
      if (PickerUtils.getIsExpandedTopBottomVertical()) {
        return '';
      }
      if (this.isVertical() && (this.isShowTextInfo || this.isShowLongExposureInfo) && SystemLanguageUtil.isTibetan()) {
        return '';
      }
      return '';
    } else {
      if (this.state.isLockRotation && !this.isOrientationVertical()) {
        return this.isVertical() ? '' :
          this.calcLandscapeHorizontalPreviewPosition16to9() - this.calcLandscapeHorizontalPreviewPosition4to3();
      }
      if (!this.state.isLockRotation && !this.isShowSemiCollapsed && !this.isOrientationVertical()) {
        return this.state.videoTimerStateExceptSuperSlowMo ? '' : this.calcLandscapeHorizontalPreviewPosition16to9() -
        this.calcLandscapeHorizontalPreviewPosition4to3();
      }
      return this.calcLandscapeHorizontalPreviewPosition16to9() - this.calcLandscapeHorizontalPreviewPosition4to3();
    }
  }

  private getColumnContainerOffsetX(): number | undefined {
    if (this.isVdeCollapsed) {
      return 0;
    }
    if (PickerUtils.getIsExpandedTopBottomVertical()) {
      return this.adaptiveLayoutService.previewPosition - (this.windowWidth - this.xComponentHeight) / 2;
    }
    if (this.isShowDefault && !this.isVertical() && !DeviceInfo.isTablet()) {
      let coefficient: number = this.mDirection === WindowDirection.RIGHT ? 1 : -1;
      let windowStatus: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
      if (windowStatus === window.WindowStatusType.FLOATING) {
        return ((this.adaptiveLayoutService.modeBarPosition + this.defaultPreviewPosition4to3 -
        this.getTextInfoWidth()) / 2) * coefficient;
      }
      if (this.isHalfCollapsLEM) {
        return (this.windowHeight / 4 - this.getColumnWidth() / 2) * coefficient;
      }
      if (this.adaptiveLayoutService.previewPosition === 0) {
        return (this.defaultPreviewPosition4to3 + 1 / 2 * this.adaptiveLayoutService.preview4to3Height -
          1 / 2 * this.windowWidth) * coefficient;
      }
      if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer() && this.getIsExpandedFullRatio() &&
        this.state.mode === ModeType.PHOTO) {
        return (this.adaptiveLayoutService.previewPosition + 1 / 2 * this.xComponentHeight -
          1 / 2 * this.windowWidth) * coefficient;
      }
      if (this.adaptiveLayoutService.previewPosition === this.adaptiveLayoutService.previewPosition1to1 &&
        this.state.mode === ModeType.PHOTO && !this.isVdeLandscape) { // 拍照 横屏 1:1 提示语位置居中
        if (this.mDirection === WindowDirection.RIGHT) {
          return this.previewAnimatePosition.y;
        }
        return -this.previewAnimatePosition.y;
      }
      if (this.isVdeLandscape) {
        if (this.mDirection === WindowDirection.RIGHT) {
          return (this.adaptiveLayoutService.previewPosition + 1 / 2 * this.adaptiveLayoutService.preview4to3Height -
            1 / 2 * this.windowWidth) * coefficient - MARGIN_HALF_COLLAPSED_PREVIEW;
        } else {
          return (this.adaptiveLayoutService.previewPosition + 1 / 2 * this.adaptiveLayoutService.preview4to3Height -
            1 / 2 * this.windowWidth) * coefficient + MARGIN_HALF_COLLAPSED_PREVIEW;
        }
      }
      return (this.adaptiveLayoutService.previewPosition + 1 / 2 * this.adaptiveLayoutService.preview4to3Height -
        1 / 2 * this.windowWidth) * coefficient;
    }
    return 0;
  }

  private getIsExpandedFullRatio(): boolean {
    let aspectRatio: number = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
    const cameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    const profile = AspectRatioOperation.getPreviewProfile(aspectRatio, cameraPosition, this.state.mode);
    const profileWidth = profile?.size?.width;
    const profileHeight = profile?.size?.height;
    return profileWidth === 1216 && profileHeight === 1080;
  }

  private isOrientationVertical(): boolean {
    return this.displayInfo.orientation === display.Orientation.PORTRAIT ||
      this.displayInfo.orientation === display.Orientation.PORTRAIT_INVERTED;
  }

  private getLightPaintingOffsetY(): number {
    let tipboxOffset = 30;
    if (this.mDirection === WindowDirection.BOTTOM) {
      tipboxOffset = 33;
    }
    if (this.windowWidth >= WINDOW_WIDTH_THRESHOLDS) {
      tipboxOffset += 12;
    }
    HiLog.i(TAG, `getLightPaintingOffsetY tipboxOffset: ${tipboxOffset}`);
    return this.isVertical() ?
      (this.lightPaintingTimerState ?
        (this.windowHeight - this.windowWidth) / 2 + INIT_VIDEO_TIMER_HEIGHT + tipboxOffset :
        Math.abs(this.windowHeight - this.windowWidth) / 2 + 16) :
      (this.lightPaintingTimerState ? INIT_VIDEO_TIMER_HEIGHT + 90 : MARGIN_LANDSCAPE_HORIZONTAL_LEFT);
  }

  private getColumnContainerOffsetY(): number {
    if (this.windowStatus === window.WindowStatusType.FLOATING &&
      this.windowHeight / this.windowWidth < AnimSpecifications.NEW_FLOAT_WINDOW_RATIO) {
      return NEW_FLOAT_WINDOW_POSITION_Y;
    }
    if (this.isVdeCollapsed) {
      return VERTICAL_COLLAPSED_TIP_POSITION;
    }
    if (this.isVdeSemiCollapsed) {
      return 35;
    }
    if (DeviceInfo.isTablet()) {
      if (PickerUtils.getIsTabletLeftRightSplitScreenFromReducer()) {
        return (this.windowHeight - this.windowWidth) / 2;
      }
      if (PickerUtils.getIsTabletTopBottomSplitScreen()) {
        return 0;
      }
      if (this.isOrientationVertical()) {
        if (this.state.isLockRotation && !this.isVertical()) {
          return (this.state.videoTimerStateExceptSuperSlowMo ?
            (this.windowHeight - this.windowWidth * 9 / 16) / 2 + 92 :
            (this.windowHeight - this.windowWidth * 9 / 16) / 2 + 20);
        }
        return (this.state.videoTimerStateExceptSuperSlowMo ?
          (this.windowHeight - this.windowWidth * 4 / 3) / 2 + 92 :
          (this.windowHeight - this.windowWidth * 4 / 3) / 2);
      }
      return (this.state.videoTimerStateExceptSuperSlowMo ? (this.windowHeight - this.windowWidth * 9 / 16) / 2 + 92 :
        (this.windowHeight - this.windowWidth * 9 / 16) / 2 + 20);
    } else if (this.isShowDefault) {
      return this.getColumnShowDefaultOffsetY();
    } else if (this.isShowSemiCollapsed) {
      return this.getColumnShowSemiCollapsedOffsetY();
    } else {
      if (!this.state.isLockRotation && !this.isOrientationVertical()) {
        return this.getColumnShowRotateLandscapeOffsetY();
      }
      if (!this.state.isLockRotation && !this.isOrientationVertical()) {
        return this.isVertical() ? MARGIN_LANDSCAPE_HORIZONTAL_LEFT : this.getColumnShowRotateLandscapeOffsetY();
      }
      return this.getColumnRealOffsetY();
    }
  }

  private getColumnRealOffsetY(): number {
    if (this.isVertical()) {
      if (this.state.videoTimerStateExceptSuperSlowMo) {
        return INIT_VIDEO_TIMER_HEIGHT + VIDEO_TIMER_MARGIN_TOP;
      } else {
        return Math.abs(this.windowHeight - this.windowWidth) / 2 + 16;
      }
    } else if (this.state.videoTimerStateExceptSuperSlowMo) {
      return (this.isShowLandscape ?
        MARGIN_LANDSCAPE_HORIZONTAL_LEFT : 60 + INIT_VIDEO_TIMER_HEIGHT + 12);
    } else {
      return MARGIN_LANDSCAPE_HORIZONTAL_LEFT;
    }
  }

  private getColumnShowDefaultOffsetY(): number {
    if (PickerUtils.getIsExpandedTopBottomVertical()) {
      return 12;
    }
    if (PickerUtils.getIsExpandedLeftRightHorizontal()) {
      return this.adaptiveLayoutService.previewPosition4to3;
    }
    if (this.isVertical()) {
      if (this.isVdeSemiCollapsed) {
        return this.state.videoTimerStateExceptSuperSlowMo ?
          this.defaultVerticalTipPositionY - MARGIN_HALF_VDE_COLLAPSED_PREVIEW : VERTICAL_TIP_POSITION;
      }
      if (this.isHalfCollapsLEM) {
        return this.state.videoTimerStateExceptSuperSlowMo ?
          this.defaultVerticalTipPositionY - MARGIN_HALF_COLLAPSED_PREVIEW :
          this.adaptiveLayoutService.previewPosition4to3 - MARGIN_HALF_COLLAPSED_PREVIEW;
      }
      const ratio: number = this.getRatio();
      if (this.isVdeLandscape) {
        let offset: number = 12;
        if (this.isShowRingLightView) {
          offset = this.isEqual(ratio, NUMBER_1_TO_1) ? 12 : this.isEqual(ratio, NUMBER_9_TO_16) ? 22 : 4;
        }
        return this.adaptiveLayoutService.tabBarPosition + TAB_BAR_HEIGHT + offset;
      }
      if (!this.isBannerLoaded && GlobalContext.get().getIsPicker()) {
        return this.defaultPreviewPosition4to3 + 90 + (this.isEqual(ratio, NUMBER_1_TO_1) ? 60 : 0);
      }
      if (!this.isRequestLocationLoaded && !GlobalContext.get().getIsPicker() && !screenLock.isLocked()) {
        return this.defaultPreviewPosition4to3 + 100;
      }
      return this.state.videoTimerStateExceptSuperSlowMo && !this.isTimelapseFront ? this.defaultVerticalTipPositionY :
      this.defaultPreviewPosition4to3;
    } else {
      if (this.isHalfCollapsLEM) {
        return this.state.videoTimerStateExceptSuperSlowMo ? INIT_VIDEO_TIMER_HEIGHT + 12 :
          MARGIN_HALF_COLLAPSED_LANDSCAPE_TOP;
      }
      return this.state.videoTimerStateExceptSuperSlowMo ? INIT_VIDEO_TIMER_HEIGHT + 12 :
        ((!this.isRequestLocationLoaded && !GlobalContext.get().getIsPicker()) ||
          (GlobalContext.get().getIsPicker() && !this.isBannerLoaded) ?
          MARGIN_DEFAULT_HORIZONTAL_TOP + 90 :
          MARGIN_DEFAULT_HORIZONTAL_TOP) +
          (GlobalContext.get().getIsPicker() && !this.isBannerLoaded ? 30 : 0);
    }
  }

  private getRatio(): number {
    this.xComponentWidth = getStates().get<number>('previewReducer', 'xComponentWidth');
    this.xComponentHeight = getStates().get<number>('previewReducer', 'xComponentHeight');
    let ratio: number = this.xComponentHeight / this.xComponentWidth;
    ratio = ratio <= 1 ? ratio : 1 / ratio;
    return ratio;
  }

  private isEqual(num1: number, num2: number): boolean {
    return Math.abs(num1 - num2) <= NUMBER_MIN;
  }

  private getColumnShowSemiCollapsedOffsetY(): number {
    HiLog.e(TAG, `getColumnShowSemiCollapsedOffsetY timerState: ${this.lightPaintingTimerState},` +
      ` isShowTextInfo: ${this.isShowTextInfo}, isShowLongExposureInfo: ${this.isShowLongExposureInfo}`);
    return this.state.videoTimerStateExceptSuperSlowMo ? 8 + INIT_VIDEO_TIMER_HEIGHT + 12 :
      (this.isShowTextInfo || this.isShowLongExposureInfo) ? 24 :
        MARGIN_SEMI_COLLAPSED_PREVIEW_BOTTOM;
  }

  private getColumnShowRotateLandscapeOffsetY(): number {
    return this.state.videoTimerStateExceptSuperSlowMo ? 44 + INIT_VIDEO_TIMER_HEIGHT :
    this.calcLandscapeHorizontalPreviewPosition4to3();
  }

  private getAuxiliaryRotateBoxWidth(): number {
    if (this.isShowDefault && !DeviceInfo.isTablet()) {
      return this.windowWidth;
    } else if (this.isShowSemiCollapsed) {
      return this.windowWidth / 2;
    } else if (DeviceInfo.isTablet() && this.state.isLockRotation) {
      return this.windowWidth
    } else {
      if (this.state.isLockRotation) {
        if (this.isOrientationVertical()) {
          return this.isVertical() ? this.xComponentWidth : this.windowHeight;
        } else {
          return this.isVertical() ? this.windowHeight : this.windowWidth;
        }
      } else {
        return this.isOrientationVertical() ? this.xComponentWidth : this.windowWidth;
      }
    }
  }

  private getAuxiliaryRotateBoxHeight(): number {
    if (this.isShowDefault && !DeviceInfo.isTablet()) {
      return this.windowWidth;
    } else if (this.isShowSemiCollapsed) {
      return this.windowWidth / 2;
    } else if (DeviceInfo.isTablet() && this.state.isLockRotation) {
      return this.windowHeight
    } else {
      if (this.state.isLockRotation) {
        if (this.isOrientationVertical()) {
          return this.isVertical() ? this.windowHeight : this.windowWidth;
        } else {
          return this.isVertical() ? this.windowWidth : this.windowHeight;
        }
      } else {
        return this.windowHeight;
      }
    }
  }

  private getAuxiliaryRotateBoxOffsetX(): number {
    if (this.isShowSemiCollapsed) {
      return this.windowWidth / 2;
    } else if (DeviceInfo.isTablet()) {
      return this.landscapePreviewPosition.x - (this.windowWidth - this.xComponentWidth) / 2;
    } else if (this.isShowLandscape) {
      if (this.state.isLockRotation && this.isOrientationVertical() && this.isVertical() ||
        !this.state.isLockRotation && this.isOrientationVertical()) {
        return this.landscapePreviewPosition.x - (this.windowWidth - this.xComponentWidth) / 2;
      }
    }
    return 0;
  }

  private getRotateAngle(): number {
    if (this.isShowDefault && this.mDirection === WindowDirection.BOTTOM && !DeviceInfo.isTablet() &&
      !this.isVdeCollapsed) {
      return 0;
    } else if (this.isShowSemiCollapsed) {
      return -90;
    } else if (this.isShowLandscape || DeviceInfo.isTablet()) {
      if (this.state.isLockRotation) {
        if (this.isOrientationVertical()) {
          return this.isVertical() ? this.mRotate : -90;
        } else {
          return this.isVertical() ? -90 : this.mRotate;
        }
      } else {
        return 0;
      }
    }
    return this.mRotate;
  }

  private getContentRotateAngle(): number {
    if (this.isVdeCollapsed) {
      return 0;
    }
    if ((this.isShowLandscape || DeviceInfo.isTablet()) && !this.isShowSemiCollapsed) {
      if (this.state.isLockRotation) {
        if (this.isOrientationVertical()) {
          return this.getRealRotate();
        } else {
          return (this.displayInfo.orientation === display.Orientation.LANDSCAPE &&
            this.mDirection === WindowDirection.TOP) ||
            (this.displayInfo.orientation === display.Orientation.LANDSCAPE_INVERTED &&
              this.mDirection === WindowDirection.BOTTOM) || this.isGRLNeedMirrorRotate() ? 180 : 0;
        }
      }
    }
    if (DeviceInfo.isTablet() && !this.state.isLockRotation) {
      return 0;
    }
    if ((this.isShowDefault && this.mDirection === WindowDirection.BOTTOM) ||
      (this.isShowSemiCollapsed && this.mDirection === WindowDirection.RIGHT)) {
      return 180;
    }
    return 0;
  }

  private getTextInfoWidth(): number {
    if (this.isShowDefault && !DeviceInfo.isTablet()) {
      return this.getFloatingWidth();
    } else {
      return TEXT_INFO_WIDTH_TABLET;
    }
  }

  private getFloatingWidth(): number {
    if (!this.isVertical() && WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      return TEXT_INFO_DEFAULT_HORIZONTAL_WIDTH;
    }
    return this.isVertical() || this.isHalfCollapsLEM ||
      WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING ?
      TEXT_INFO_DEFAULT_VERTICAL_WIDTH : this.windowWidth;
  }

  private getTextInfoHeight(): number | string {
    if (this.adaptiveLayoutService.previewPosition4to3 === this.adaptiveLayoutService.previewPosition1to1) {
      return '';
    }
    return this.isShowDefault && this.isVertical() && !DeviceInfo.isTablet() ?
    this.heightBetweenPreviewArea4to3And1to1 : '';
  }

  private getTipMarginTop(): number {
    if (this.isVdeCollapsed) {
      return MARGIN_VDE_COLLAPS_TOP;
    }
    if ((this.isShowTextInfo || this.isShowLongExposureInfo) &&
    this.isShowDefault && !DeviceInfo.isTablet() && this.isVertical()) {
      return 0;
    }
    return 12;
  }

  private getTipMarginLeftRight(): number {
    if (this.isVdeCollapsed) {
      return MARGIN_VDE_COLLAPS_LEFT_RIGHT;
    }
    if (PickerUtils.getIsExpandedTopBottomVertical()) {
      return MARGIN_PICKER_LEFT_RIGHT;
    }
    return this.isShowLandscape || DeviceInfo.isTablet() ? this.showFont() : this.showPro();
  }

  private getRealRotate(): number {
    return this.mDirection === WindowDirection.RIGHT ? ANGLE_180 : ANGLE_0;
  }

  private getNewTriCollapsFullExpanded(): number {
    if (this.displayInfo.orientation === display.Orientation.PORTRAIT_INVERTED &&
      this.mDirection === WindowDirection.RIGHT) {
      return ANGLE_0;
    } else if (this.displayInfo.orientation === display.Orientation.PORTRAIT_INVERTED &&
      this.mDirection === WindowDirection.LEFT) {
      return ANGLE_180;
    } else if (this.displayInfo.orientation === display.Orientation.PORTRAIT &&
      this.mDirection === WindowDirection.RIGHT) {
      return ANGLE_180;
    }
    return ANGLE_0;
  }

  private isGRLNeedMirrorRotate(): boolean {
    return false;
  }

  private showPro(): number {
    return 32;
  }

  private showFont(): number {
    if (this.isShowLandscape) {
      if (this.state.mode === ModeType.VIDEO) {
        return 0;
      }
      const margin: number =
        MARGIN_LANDSCAPE_COMPONENT_LEFT + TREASURE_BOX_ELEMENT_INNER_WIDTH + MARGIN_LANDSCAPE_TIP_TO_TREASURE_BOX;
      const tipWidth: number = this.xComponentWidth - 2 * margin;
      if (tipWidth > MAX_TIP_WIDTH) {
        return (this.xComponentWidth - MAX_TIP_WIDTH) / 2;
      }
      return margin;
    }
    return 0;
  }

  private startToRecord(): void {
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction
    }, () => {
      this.defaultVerticalTipPositionY = this.defaultPreviewPosition4to3 + INIT_VIDEO_TIMER_HEIGHT;
    });
  }

  private onRecordStop(): void {
    clearTimeout(this.taskTimerId);
  }

  private bigToSmallAnim() {
    if (!this.isRecordTimeComponentLarge) {
      animateToImmediately({
        duration: 300,
        curve: Curve.Friction,
        delay: 200
      }, () => {
        this.defaultVerticalTipPositionY = this.defaultPreviewPosition4to3;
      });
    }
  }

  private directionCorrection(direction: WindowDirection): void {
    if (PickerUtils.getIsExpandedTopBottomSplitScreen() &&
      this.displayInfo.orientation === display.Orientation.LANDSCAPE) {
      const correctionArr: WindowDirection[] =
        [WindowDirection.RIGHT, WindowDirection.LEFT, WindowDirection.BOTTOM, WindowDirection.TOP];
      this.mDirection = correctionArr[direction];
      return;
    }
    this.mDirection = direction;
  }

  build() {
    Stack({ alignContent: Alignment.Top }) { //辅助旋转容器
      Column() {
        TextInfo({
          textInfoWidth: this.getTextInfoWidth(),
          textInfoHeight: this.getTextInfoHeight(),
          isShowTextInfo: this.isShowTextInfo,
          isShowLongExposureInfo: this.isShowLongExposureInfo,
        })
          .rotate({ angle: this.getContentRotateAngle() })
        Tip({
          isHdr: this.isHdr
        })
          .margin({
            top: this.tipTopMargin,
          })
          .visibility(this.getVisibility())
          .rotate({ angle: this.getContentRotateAngle() })
      }
      .width(this.getColumnWidthInFloat())
      .height(this.getColumnHeight())
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .offset({ x: this.getColumnOffsetX(), y: this.getColumnContainerOffsetY() })
      .hitTestBehavior(HitTestMode.None)
      .margin({
        top: this.getMarginTop(),
        left: this.getMarginLeft(),
        right: this.getMarginRight(),
        bottom: this.isFontScaling ? 10 : ''
      })
    }
    .width(this.getAuxiliaryRotateBoxWidth())
    .height(this.getAuxiliaryRotateBoxHeight())
    .rotate({ angle: this.getRotateAngle() })
    .offset({
      x: this.getAuxiliaryRotateBoxOffsetX()
    })
    .hitTestBehavior(HitTestMode.None)
  }

  private getColumnWidthInFloat(): Length | undefined {
    if (!this.isVertical() && WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      return this.getColumnWidth() - TEXT_INFO_MARGIN_WIDTH;
    }
    return this.getColumnWidth();
  }

  private getMarginTop(): Length | undefined {
    if (this.isVertical() && WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      return 10;
    }
    return this.isFontScaling ? 10 : '';
  }

  private getMarginLeft(): Length | undefined {
    if (!this.isVertical() && WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      if (this.mDirection === WindowDirection.RIGHT) {
        if (FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() === 1 &&
          this.adaptiveLayoutService.zoomPosition + 20 > this.windowWidth) {
          return TEXT_INFO_MARGIN_WIDTH + MARGIN_SEMI_COLLAPSED_PREVIEW_BOTTOM;
        }
        return TEXT_INFO_MARGIN_WIDTH;
      }
    }
    return this.isFontScaling ? 10 : '';
  }

  private getMarginRight(): Length | undefined {
    if (!this.isVertical() && WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      if (this.mDirection === WindowDirection.LEFT) {
        if (FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() === 1 &&
          this.adaptiveLayoutService.zoomPosition + 20 > this.windowWidth) {
          return TEXT_INFO_MARGIN_WIDTH + MARGIN_SEMI_COLLAPSED_PREVIEW_BOTTOM;
        }
        return TEXT_INFO_MARGIN_WIDTH;
      }
    }
    return this.isFontScaling ? 10 : '';
  }

  private getColumnOffsetX(): number | undefined {
    if (!this.isVertical() && WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      return 0;
    }
    return this.getColumnContainerOffsetX();
  }

  private getVisibility(): Visibility {
    if (this.isShowDefault && !this.isVertical() &&
      ((this.smartControlConfig && this.smartControlVisible) || this.depthFusionPopupVisibility)) {
      return Visibility.Hidden;
    }
    return this.isShowMorePage || this.isImmersive && this.immersiveUIType === UIOperationType.LR_SWIPE ?
    Visibility.Hidden : Visibility.Visible;
  }
}