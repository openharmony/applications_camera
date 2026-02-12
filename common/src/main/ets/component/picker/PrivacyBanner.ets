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
import lazy { Dispatch, OhCombinedState, Unsubscribe, getStates, reduxSubscribe } from '../../redux';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PublicTag } from '../../service/preferences/PropTag';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { AdaptiveLayoutService, TAB_BAR_HEIGHT } from '../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { XComponentSize } from '../../utils/types';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import display from '@ohos.display';
import lazy { DirectionCorrectionService } from '../../service/direction/DirectionCorrectionService';
import lazy { PickerWindowType } from './PickerWindowType';
import lazy { PickerAction } from '../../service/picker/PickerAction';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { SettingFuncDialogItemIndex } from '../settingview/SettingFuncDialogItemIndex';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { LengthMetrics, window } from '@kit.ArkUI';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import ResGetter from '../../utils/ResGetter';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';

const TAG: string = 'PrivacyBanner';

const ASPECT_RATIO_4_3 = 4 / 3;

export const DIALOG_OFFSET: number = -240;

const BANNER_BACKGROUND_COLOR: string = '#80000000';
const BANNER_HEIGHT: number = 84;
const BANNER_WIDTH_MAX: number = 400;
const BANNER_HORIZON_WIDTH_MAX: number = 232;
const MARGIN_BANNER_TOP: number = 8;
const MARGIN_BANNER_TOP_HORIZONTAL: number = 12;
const MARGIN_BANNER_TOP_LANDSCAPE: number = 60;
const MARGIN_BANNER_TOP_LANDSCAPE_HORIZONTAL: number = 84;
const MARGIN_BANNER_LEFT_LANDSCAPE_HORIZONTAL: number = 88; //24为百宝箱左边距，48为百宝箱宽度，16为与百宝箱之间的距离。
//tablet
const TABLET_BANNER_TOP: number = 60;
const TABLET_BANNER_TOP_HORIZONTAL = 164;
// pc
const PCTABBAR_HEIGHT: number = 24;
const MARGIN_PCTABBAR_TOP: number = 32;
// GL-B
const G_TOP_FULL: number = -400;
const G_TOP_NO_FULL: number = 70;

const BANNER_ICON_SIZE: number = DeviceInfo.isTv() ? 42 : 32;
const BANNER_PRIVACY_ICON_SIZE: number = DeviceInfo.isTv() ? 24 : 22;
const BANNER_CAMERA_ICON_SIZE: number = DeviceInfo.isTv() ? 18 : 14;
const BORDER_RADIUS_ICON: number = 8;
const BORDER_RADIUS_WIDTH: number = px2vp(1);
const BORDER_RADIUS_ICON_WIDTH: number = px2vp(0.5);
const BORDER_RADIUS_CAMERA_ICON: number = 4;
const BORDER_RADIUS_COLOR: string = '#33808080';
const PRIVACY_ICON_BACKGROUND_COLOR: string = '#e6ffffff';

const MAX_FONT_SCALE: number = 1.3;
const FONT_SIZE_16: Resource = DeviceInfo.isTv() ? $r('sys.float.Caption_L') : $r('sys.float.Body_L');
const FONT_SIZE_14: number = 14;
const FONT_COLOR: string = '#e6ffffff';
const FONT_COLOR_CONTENT: string = '#99ffffff';
const FONT_COLOR_LEARN_MORE: string = '#FF317AF7';
const TEXT_HEIGHT_TITLE: number = 22;
const TEXT_HEIGHT_CONTENT: number = 19;
const TEXT_HEIGHT_CONTENT_SCROLL: number = 38;

const CANCEL_BTN_W: number = 18;
const MARGIN_LEFT_RIGHT: number = 16;
const PADDING_AROUND: number = DeviceInfo.isTv() ? 16 : 12;
const MARGIN_TEXT_LEFT_RIGHT: number = DeviceInfo.isTv() ? 0 : 12;
const BANNER_BORDER_RADIUS: number = 18;

const BANNER_WIDTH_TV: number = 362;

class PickerPrivacyBannerDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public learnMoreSecurityCamera(): void {
    this.mDispatch(PickerAction.learnMoreSecurityCamera());
  }
}

@Extend(Button)
function bannerCancelPartTVTextStyle() {
  .type(ButtonType.Capsule)
  .buttonStyle(ButtonStyleMode.NORMAL)
  .fontColor($r('sys.color.font_primary'))
  .fontSize(18)
  .fontWeight(FontWeight.Regular)
  .maxFontScale(CommonConstants.TEXT_SIZE_HUGE)
  .width(157)
  .height(38)
  .backgroundColor('#1AFFFFFF')
}

@CustomDialog
export struct PrivacyBanner {
  controller: CustomDialogController;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe | null = null;
  private mAction: PickerPrivacyBannerDispatcher = new PickerPrivacyBannerDispatcher();
  private layoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  @State previewPosition: number = 0;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State @Watch('onDirectionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isHorizontal: boolean = false;
  @State rotateAngle: number = 0;
  @State isRotateLocked: boolean = true;
  @State offsetFullScreen: number = 0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  // picker分屏状态
  @State isCollapsedSplitScreen: boolean = !DeviceInfo.isTablet();
  @State isExpandedTopBottomSplitScreen: boolean = PickerUtils.getIsExpandedTopBottomSplitScreen();
  @State isTabletSplitScreen: boolean = PickerUtils.getIsTabletSplitScreen();
  @Link isBannerLoaded: boolean;
  @Link isBannerOpen: boolean;
  @StorageLink('isBannerVisiblePick') isBannerVisiblePick: boolean = false;
  @Link isBannerVisible: boolean;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State isFontScaling: boolean = false;
  private displayRotation: number = 0;
  @State bannerHeight: number = 0;
  @StorageProp('isRTL') isRTL: boolean = false;
  @State isShowTricollaps: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'Picker privacy banner appears.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isRotateLocked = state.get<boolean>('windowReducer', 'isLockRotation');
      if (this.isSubscriptionNeeded(state.get<WindowDirection>('contextReducer', 'direction'))) {
        this.mDirection =
          DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
            state.get<boolean>('windowReducer', 'isLockRotation'));
      }
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      // 因state.get<boolean>('collapsReducer', 'isShowLandscape')更新太慢，导致时序问题，需通过pickerWindowType去判断isShowLandscape
      this.isShowLandscape =
        state.get<PickerWindowType>('windowReducer', 'pickerWindowType') === PickerWindowType.EXPANDED_FULL_SCREEN;
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isHorizontal = DisplayService.getInstance().isHorizontal();
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.displayRotation = DisplayService.getInstance().getDisplay().rotation;
    this.getOffsetFullScreen();
    this.uxInit();
    this.onDirectionChange();
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      (data: XComponentSize) => this.onChangeXComponentSize(), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, () => this.uxInit(), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.REFRESH_UX, () => this.refreshRotation(), this.mBase.hashCode());
    if (DeviceInfo.isPhone()) {
      this.isBannerVisiblePick = true;
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'Picker privacy banner disappears.');
    if (DeviceInfo.isPhone()) {
      this.isBannerVisiblePick = false;
    }
    this.mSubscriber?.destroy();
  }

  private isSubscriptionNeeded(direction: WindowDirection): boolean {
    if (this.isCollapsedSplitScreen) {
      return false;
    }
    const orientation: display.Orientation = DisplayService.getInstance().getDisplay().orientation;
    if (DeviceInfo.isTablet() && this.isRotateLocked &&
      !this.isTabletDirectionSameAxisWithOrientation(direction, orientation)) {
      return false;
    }
    return true;
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

  private uxInit(): void {
    const aspectRatio: number = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue();
    if (!this.isShowLandscape && aspectRatio !== SettingFuncDialogItemIndex.INDEX_SEC) {
      this.layoutService.calLayoutRuleParam(this.windowWidth, this.windowHeight);
      this.layoutService.changePreviewPosition(this.xComponentWidth, this.xComponentHeight);
    }
    this.getOffsetFullScreen();
    this.updateOffsetXY();
    this.isCollapsedSplitScreen = !DeviceInfo.isTablet();
    this.isExpandedTopBottomSplitScreen = PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer();
    this.isTabletSplitScreen = PickerUtils.getIsTabletSplitScreen();
  }

  private refreshRotation(): void {
    this.displayRotation = DisplayService.getInstance().getDisplay().rotation;
    this.onDirectionChange();
  }

  private onDirectionChange(): void {
    this.updateOffsetXY();
    const isUIExtensionPicker: boolean =
      PickerUtils.getIsPicker() && !!ContextManager.getInstance().getUiExtensionContext();
    HiLog.i(TAG, 'isUIExtensionPicker: ' + isUIExtensionPicker);
    if (isUIExtensionPicker) {
      if (this.displayRotation === 0) {
        this.rotateAngle = getStates().get<number>('contextReducer', 'rotateAngle');
      } else {
        this.rotateAngle = 0;
      }
    } else {
      this.rotateAngle = getStates().get<number>('contextReducer', 'rotateAngle');
    }
    if (this.isRotateLocked) {
      if (DeviceInfo.isTablet() && !PickerUtils.getIsTabletFullScreenFromReducer()) {
        this.rotateAngle = 0;
        return;
      }
      if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer()) {
        this.rotateAngle -= 90;
      }
    }
  }

  private updateOffsetXY(): void {
    this.offsetX = this.getBannerOffsetX();
    this.offsetY = this.getBannerOffsetY();
  }

  private onChangeXComponentSize(): void {
    setTimeout(() => {
      // 时序问题，刷新XComponentSize大小，预览区位置等配置还未刷新，picker就获取，导致获取的不对，设置延时，使配置刷新之后再去获取
      this.getOffsetFullScreen();
      this.bannerTranslateAnimation();
    }, 100);
  }

  private bannerTranslateAnimation(): void {
    animateTo({ curve: Curve.Sharp, duration: 250 }, () => {
      this.updateOffsetXY();
    });
  }

  private closeBannerButton(): void {
    HiLog.i(TAG, 'The privacy banner has been closed.');
    this.isBannerLoaded = true;
    PreferencesService.getInstance()
      .putPublicValue(PersistType.FOREVER, PublicTag.PICKER_IS_BANNER_LOADED, this.isBannerLoaded);
    AppStorage.setOrCreate('isBannerLoaded', true);
    HiLog.i(TAG, `isBannerLoaded was stored as: ${this.isBannerLoaded}`);
    this.isBannerOpen = false;
    this.controller.close();
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private getBannerWidth(): number {
    if (DeviceInfo.isTv()) {
      return BANNER_WIDTH_TV;
    }
    if (this.isCollapsedSplitScreen) {
      return this.windowWidth - 2 * MARGIN_LEFT_RIGHT;
    }
    let bannerWidth: number = this.isShowSemiCollapsed ? this.xComponentHeight - 2 * MARGIN_LEFT_RIGHT :
      this.xComponentWidth - 2 * MARGIN_LEFT_RIGHT;
    if (PickerUtils.getIsTabletLeftRightSplitScreenFromReducer()) {
      return 360;
    }
    if (this.isVertical() || this.isShowLandscape) {
      return Math.min(BANNER_WIDTH_MAX, bannerWidth);
    } else {
      return Math.min(BANNER_HORIZON_WIDTH_MAX, bannerWidth);
    }
  }

  private getBannerOffsetX(): number {
    let coefficient: number = this.mDirection === WindowDirection.LEFT && !this.isVdeCollapsed ? -1 : 1;
    if (this.isExpandedTopBottomSplitScreen) {
      let prevPos: number = this.layoutService.previewPosition;
      let compHeight: number = this.xComponentHeight;
      if (this.layoutService.previewPosition === 0) {
        prevPos = this.layoutService.previewPosition4to3;
        compHeight = this.layoutService.preview4to3Height;
      }
      if (!this.isVertical()) {
        return prevPos + compHeight / 2 - this.windowHeight / 2;
      } else {
        return prevPos + 6 - this.windowHeight / 2 + BANNER_HEIGHT / 2;
      }
    }
    if (this.isTabletSplitScreen) {
      return 0;
    }
    if (DeviceInfo.isPc()) {
      return 0;
    } else if (DeviceInfo.isTablet()) {
      return 0;
    } else if (this.isHorizontal) {
      if (this.isShowLandscape && !this.isShowSemiCollapsed && this.isRotateLocked) {
        if (this.isVertical()) {
          return 0;
        }
        return (-1 / 2 * this.xComponentHeight + 45);
      }
      return this.isRotateLocked && this.isVertical() ?
        (-1 / 2 * this.xComponentHeight + 30) * coefficient : 0;
    } else {
      if (this.isShowTricollaps && !this.isVertical()) {
        const offset = -1 / 2 * (this.xComponentWidth - this.bannerHeight) + MARGIN_BANNER_LEFT_LANDSCAPE_HORIZONTAL;
        return offset < G_TOP_FULL ? offset : offset - G_TOP_NO_FULL;
      }
      let offset =
        this.isShowLandscape ? -1 / 2 * this.windowHeight + MARGIN_BANNER_LEFT_LANDSCAPE_HORIZONTAL + BANNER_HEIGHT :
          (1 / 2 * this.windowWidth - MARGIN_BANNER_TOP_HORIZONTAL - 1 / 2 * this.bannerHeight) * coefficient;
      return this.isShowSemiCollapsed ? BANNER_HEIGHT : !this.isVertical() ? offset : 0;
    }
  }

  private getBannerOffsetY(): number {
    if (this.isExpandedTopBottomSplitScreen) {
      const offsetLeftDirection: number = this.windowWidth - BANNER_HEIGHT - MARGIN_BANNER_TOP_HORIZONTAL;
      const offsetRightDirection: number = MARGIN_BANNER_TOP_HORIZONTAL;
      const offsetTopDirection: number =
        this.windowWidth - (BANNER_HEIGHT / 2 + this.getBannerWidth() / 2) - MARGIN_LEFT_RIGHT;
      const resultArr: number[] = [offsetLeftDirection, offsetRightDirection, offsetTopDirection, offsetTopDirection];
      return resultArr[this.mDirection];
    }
    if (this.isCollapsedSplitScreen) {
      return PickerUtils.currentTabBarPosition + TAB_BAR_HEIGHT + 8;
    }
    if (DeviceInfo.isTablet()) {
      return this.getTabletBannerOffsetY();
    } else if (DeviceInfo.isPc()) {
      let offset =
        ((this.windowHeight - this.xComponentHeight) >= 0) ? (this.windowHeight - this.xComponentHeight) / 2 : 0;
      return offset - PCTABBAR_HEIGHT;
    } else if (this.isShowSemiCollapsed) {
      return 1 / 2 * this.windowHeight - BANNER_ICON_SIZE - PADDING_AROUND + 2;
    } else {
      return this.getBannerPhoneOffsetY();
    }
  }

  private getTabletBannerOffsetY(): number {
    if (this.isTabletSplitScreen) {
      return 50;
    }
    if (DisplayService.getInstance().isOrientationVertical()) {
      const previewPosition4to3: number = (this.windowHeight - this.windowWidth * 4 / 3) / 2;
      const previewPosition1to1: number = (this.windowHeight - this.windowWidth) / 2;
      const offset: number = previewPosition4to3 + (previewPosition1to1 - previewPosition4to3 - BANNER_HEIGHT) / 2;
      return this.mDirection === WindowDirection.TOP ? offset : this.windowHeight - offset - BANNER_HEIGHT;
    } else {
      return this.mDirection === WindowDirection.TOP ? TABLET_BANNER_TOP :
        this.windowHeight - TABLET_BANNER_TOP - BANNER_HEIGHT;
    }
  }

  private getOffsetFullScreen(): void {
    const previewPosition4to3: number = this.layoutService.previewPosition4to3;
    this.previewPosition = this.isShowTricollaps ? 90 : this.layoutService.previewPosition;
    const isFullRatio = this.previewPosition === 0;
    this.offsetFullScreen = (isFullRatio && !this.isShowTricollaps) ? previewPosition4to3 : 0;
  }

  private getBannerPhoneOffsetY(): number {
    if (this.isHorizontal) {
      if (this.isShowLandscape && !this.isShowSemiCollapsed && this.isRotateLocked) {
        if (this.isVertical()) {
          return MARGIN_BANNER_TOP_LANDSCAPE_HORIZONTAL;
        }
        return 1 / 2 * this.xComponentHeight;
      }
      return this.isRotateLocked && this.isVertical() ?
        1 / 2 * this.xComponentWidth - MARGIN_BANNER_LEFT_LANDSCAPE_HORIZONTAL : MARGIN_BANNER_TOP_LANDSCAPE_HORIZONTAL;
    }
    if (this.isVertical()) {
      return this.isShowLandscape ? MARGIN_BANNER_TOP_LANDSCAPE :
        this.previewPosition + MARGIN_BANNER_TOP + this.offsetFullScreen;
    }
    if (this.isShowTricollaps) {
      return (1 / 2 * (this.xComponentHeight - this.getBannerWidth()) +
        1 / 2 * (this.getBannerWidth() - this.bannerHeight));
    }
    let previewPosition1to1Center =
      this.layoutService.previewPosition1to1 + 1 / 2 * (this.getBannerWidth() - this.bannerHeight) +
        1 / 2 * (this.xComponentWidth - this.getBannerWidth());
    if (getStates().get<window.WindowStatusType>('windowReducer', 'windowStatus') ===
      window.WindowStatusType.FLOATING) {
      previewPosition1to1Center -= 62;
    }
    return this.isShowLandscape ? 1 / 2 * this.xComponentHeight - 30 : previewPosition1to1Center;
  }

  private getBannerTextContentWidth(): number {
    if (DeviceInfo.isTv()) {
      return 272;
    } else {
      return this.getBannerWidth() - BANNER_ICON_SIZE - PADDING_AROUND - 2 * MARGIN_TEXT_LEFT_RIGHT;
    }
  }

  private isMinorityLanguage(): boolean { //法语|越南语|西班牙语|藏语
    return SystemLanguageUtil.French() || SystemLanguageUtil.isSpanish() || SystemLanguageUtil.isVietnamese() ||
    SystemLanguageUtil.isTibetan()
  }

  @Builder
  BannerIconPart() {
    Stack() {
      Rect({ width: BANNER_ICON_SIZE, height: BANNER_ICON_SIZE, radius: BORDER_RADIUS_ICON })
        .fill(PRIVACY_ICON_BACKGROUND_COLOR)
        .borderRadius({
          topLeft: BORDER_RADIUS_ICON,
          topRight: BORDER_RADIUS_ICON,
          bottomLeft: BORDER_RADIUS_ICON,
          bottomRight: BORDER_RADIUS_CAMERA_ICON
        })
        .borderWidth(BORDER_RADIUS_WIDTH)
        .borderColor(BORDER_RADIUS_COLOR)
      Image($r('app.media.ic_public_privacy'))
        .width(BANNER_PRIVACY_ICON_SIZE)
        .height(BANNER_PRIVACY_ICON_SIZE)
        .draggable(false)
        .alignSelf(ItemAlign.Center)
        .align(Alignment.Center)

      Image($r('app.media.foreground_icon_phone'))
        .borderRadius(BORDER_RADIUS_CAMERA_ICON)
        .borderWidth(BORDER_RADIUS_ICON_WIDTH)
        .borderColor(BORDER_RADIUS_COLOR)
        .width(BANNER_CAMERA_ICON_SIZE)
        .height(BANNER_CAMERA_ICON_SIZE)
        .margin({
          left: BANNER_ICON_SIZE - BANNER_CAMERA_ICON_SIZE - 2 * BORDER_RADIUS_WIDTH + 2 * BORDER_RADIUS_ICON_WIDTH,
          top: BANNER_ICON_SIZE - BANNER_CAMERA_ICON_SIZE - 2 * BORDER_RADIUS_WIDTH + 2 * BORDER_RADIUS_ICON_WIDTH
        })
        .draggable(false)
    }
    .margin(DeviceInfo.isTv() ? { end: LengthMetrics.vp(16) } : undefined)
    .id('banner_icon')
  }

  @Builder
  BannerTextPart() {
    Column() {
      Row() {
        Text($r('app.string.picker_security_camera_popup_title'))
          .size({
            width: DeviceInfo.isTv() ? this.getBannerTextContentWidth() :
              this.getBannerTextContentWidth() - CANCEL_BTN_W
          })
          .height(DeviceInfo.isTv() ? 24 : undefined)
          .fontSize(DeviceInfo.isTv() ? 18 : FONT_SIZE_16)
          .lineHeight(TEXT_HEIGHT_TITLE)
          .maxFontScale(MAX_FONT_SCALE)
          .maxLines(2)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .fontColor(FONT_COLOR)
          .textAlign(TextAlign.Start)
          .fontWeight(FontWeight.Medium)
          .id('banner_title')
        if (!DeviceInfo.isTv()) {
          this.BannerCancelPart();
        }
      }
      .alignItems(VerticalAlign.Top)
      .justifyContent(DeviceInfo.isTv() ? FlexAlign.Start : FlexAlign.SpaceBetween)

      if (this.isMinorityLanguage()) {
        Text() {
          Span($r('app.string.picker_security_camera_banner_content', ''))
            .fontColor(DeviceInfo.isTv() ? FONT_COLOR_CONTENT : FONT_COLOR)
        }
        .accessibilityNextFocusId('focusExposureArea')
        .wordBreak(DeviceInfo.isTv() ? WordBreak.BREAK_ALL : undefined)
        .lineHeight(this.fontSizeScale)
        .size({ width: this.getBannerTextContentWidth() })
        .margin(DeviceInfo.isTv() ? { top: 4 } : undefined)
        .fontSize(DeviceInfo.isTv() ? FONT_SIZE_16 : FONT_SIZE_14)
        .fontWeight(FontWeight.Regular)
        .lineHeight(TEXT_HEIGHT_CONTENT)
        .maxFontScale(MAX_FONT_SCALE)
        .id('banner_content')
        .height(this.isVdeCollapsed ? 62 : (DeviceInfo.isTv() ? 42 : ''))

        if (!DeviceInfo.isTv()) {
          Row() {
            Text() {
              Span($r('app.string.picker_security_camera_banner_learn_more'))
                .fontColor(FONT_COLOR_LEARN_MORE)
                .onClick(() => {
                  this.mAction.learnMoreSecurityCamera();
                })
            }
            .accessibilityNextFocusId('focusExposureArea')
            .wordBreak(DeviceInfo.isTv() ? WordBreak.BREAK_ALL : undefined)
            .lineHeight(this.fontSizeScale)
            .size({ width: this.getBannerTextContentWidth() })
            .margin(DeviceInfo.isTv() ? { top: 4 } : undefined)
            .fontSize(DeviceInfo.isTv() ? FONT_SIZE_16 : FONT_SIZE_14)
            .fontWeight(FontWeight.Regular)
            .lineHeight(TEXT_HEIGHT_CONTENT)
            .maxFontScale(MAX_FONT_SCALE)
            .id('banner_content')
            .height(this.isVdeCollapsed ? 62 : (DeviceInfo.isTv() ? 42 : ''))
          }.visibility(Visibility.None)
        }
      } else {
        Text() {
          Span($r('app.string.picker_security_camera_banner_content', ''))
            .fontColor(DeviceInfo.isTv() ? FONT_COLOR_CONTENT : FONT_COLOR)
          if (!DeviceInfo.isTv()) {
            Span($r('app.string.picker_security_camera_banner_learn_more'))
              .fontColor(FONT_COLOR_LEARN_MORE)
              .onClick(() => {
                this.mAction.learnMoreSecurityCamera();
              }).visibility(Visibility.None)
          }
        }
        .accessibilityNextFocusId('focusExposureArea')
        .wordBreak(DeviceInfo.isTv() ? WordBreak.BREAK_ALL : undefined)
        .lineHeight(this.fontSizeScale)
        .size({ width: this.getBannerTextContentWidth() })
        .margin(DeviceInfo.isTv() ? { top: 4 } : undefined)
        .fontSize(DeviceInfo.isTv() ? FONT_SIZE_16 : FONT_SIZE_14)
        .fontWeight(FontWeight.Regular)
        .lineHeight(TEXT_HEIGHT_CONTENT)
        .maxFontScale(MAX_FONT_SCALE)
        .id('banner_content')
        .height(this.isVdeCollapsed ? 62 : (DeviceInfo.isTv() ? 42 : ''))
      }
    }
  }

  @Builder
  BannerCancelPart() {
    Button() {
      Image($r('app.media.ic_camera_cancel_w'))
        .width(CANCEL_BTN_W)
        .fillColor(Color.White)
        .draggable(false)
        .syncLoad(true)
    }
    .type(ButtonType.Normal)
    .backgroundColor(Color.Transparent)
    .key(ComponentIdKeys.PICKER_PRIVACY_BANNER_BUTTON)
    .onClick(() => {
      this.closeBannerButton();
    })
  }

  @Builder
  BannerCancelPartTV() {
    Row({ space: 16 }) {
      Button($r('app.string.light_painting_help_no_more'))
        .onClick(() => {
          this.closeBannerButton();
        })
        .bannerCancelPartTVTextStyle()
      Button($r('app.string.distributed_mode_learn_more'))
        .onClick(() => {
          this.mAction.learnMoreSecurityCamera();
        })
        .bannerCancelPartTVTextStyle()
    }
    .margin({ top: 16 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  build() {
    Column() {
      Row() {
        this.BannerIconPart();
        Row() {
          this.BannerTextPart();
        }
        .alignItems(VerticalAlign.Top)
        .margin({ left: MARGIN_TEXT_LEFT_RIGHT, right: MARGIN_TEXT_LEFT_RIGHT })
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')

      if (DeviceInfo.isTv()) {
        this.BannerCancelPartTV()
      }
    }
    .padding(PADDING_AROUND)
    .backgroundColor(DeviceInfo.isTv() ? undefined : BANNER_BACKGROUND_COLOR)
    .backgroundBlurStyle(DeviceInfo.isTv() ? BlurStyle.COMPONENT_THIN : undefined)
    .clip(true)
    .offset(this.getOffSet())
    .width(this.getBannerWidth())
    .border(DeviceInfo.isTv() ? { width: 1, color: '#26FFFFFF' } : undefined)
    .borderRadius(DeviceInfo.isPc() ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level10'))
    .shadow(DeviceInfo.isTv() ? ShadowStyle.OUTER_DEFAULT_MD : undefined)
    .rotate({ angle: this.isShowSemiCollapsed ? 90 : this.isVdeCollapsed || DeviceInfo.isPc() ? 0 : this.rotateAngle })
    .key(ComponentIdKeys.PICKER_PRIVACY_BANNER)
    .visibility(this.isBannerVisible ? Visibility.Visible : Visibility.None)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      HiLog.i(TAG,
        `area new width:${newValue?.width},height:${newValue?.height},isBannerVisible:${this.isBannerVisible}`);
      if (!this.isBannerVisible) {
        return;
      }
      this.bannerHeight = parseFloat(newValue?.height?.toString()) ?? BANNER_HEIGHT;
      this.updateOffsetXY();
    })
  }

  private getOffSet(): Position {
    if (DeviceInfo.isTv()) {
      return this.isRTL ? { x: -403, y: 22 } : { x: 403, y: 22 };
    }
    if (this.isVdeCollapsed) {
      const isLockOrientation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation'); //锁定方向
      if (isLockOrientation) {
        return { x: this.offsetX - 56, y: this.offsetY - DIALOG_OFFSET + 40 };
      }
      switch (this.mDirection) {
        case WindowDirection.TOP:
          return { x: this.offsetX, y: this.offsetY - DIALOG_OFFSET + 40 };
        case WindowDirection.RIGHT:
          return { x: this.offsetX - 56, y: this.offsetY - DIALOG_OFFSET + 40 };
        case WindowDirection.LEFT:
          return { x: this.offsetX + 56, y: this.offsetY - DIALOG_OFFSET + 40 };
        default:
          return { x: this.offsetX - 56, y: this.offsetY - DIALOG_OFFSET + 40 };
      }
    }
    if (DeviceInfo.isPc() || (DeviceInfo.isTablet() && PickerUtils.getIsInPcMode())) {
      // PC和自由多窗下CustomDialog 组件无法偏移出窗口
      return {
        x: this.offsetX,
        y: this.offsetY
      }
    }
    return {
      x: this.offsetX,
      y: this.offsetY - DIALOG_OFFSET
    };
  }
}