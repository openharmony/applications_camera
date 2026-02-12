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
import lazy { Dispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { Action } from '../../../redux/actions/Action';
import lazy { PersistType, PreferencesService } from '../../../service/preferences/PreferencesService';
import lazy { PublicTag } from '../../../service/preferences/PropTag';
import lazy { AdaptiveLayoutService } from '../../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { DisplayService } from '../../../service/UIAdaptive/DisplayService';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { DirectionToAngleUtil } from '../../../utils/DirectionToAngleUtil';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { PickerUtils } from '../../../utils/PickerUtils';
import lazy { XComponentSize } from '../../../utils/types';
import lazy { WindowDirection } from '../../../utils/WindowDirection';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { StoreManager } from '../../../worker/StoreManager';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import display from '@ohos.display';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { WindowService } from '../../../service/window/WindowService';
import window from '@ohos.window';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { WindowActionType } from '../../../redux/actions/WindowActionType';
import lazy { SettingsValueUtil } from '../../../utils/SettingsValueUtil';

/* instrument ignore file */
const TAG: string = 'RequestLocationDialog';

const ASPECT_RATIO_4_3 = 4 / 3;

const DIALOG_OFFSET: number = 120;
const LOCATION_BACKGROUND_COLOR: string = '#80000000';
const LOCATION_HEIGHT: number = 84;
const LOCATION_WIDTH_MAX: number = 480;
const MARGIN_LOCATION_TOP: number = 8;
const MARGIN_LOCATION_TOP_HORIZONTAL: number = 12;
const MARGIN_LOCATION_TOP_LANDSCAPE: number = 60;
const MARGIN_LOCATION_TOP_LANDSCAPE_HORIZONTAL: number = 84;
const MARGIN_LOCATION_LEFT_LANDSCAPE_HORIZONTAL: number = 88; //24为百宝箱左边距，48为百宝箱宽度，16为与百宝箱之间的距离。
//tablet
const TABLET_LOCATION_TOP: number = 60;
const TABLET_LOCATION_TOP_HORIZONTAL = 164;
// pc
const PCTABBAR_HEIGHT: number = 24;
const MARGIN_PCTABBAR_TOP: number = 32;

const LOCATION_ICON_SIZE: number = 32;

const FONT_SIZE_16: Resource = $r('sys.float.Body_L');
const FONT_SIZE_14: number = 14;
const FONT_COLOR: string = '#e6ffffff';
const FONT_COLOR_LEARN_MORE: string = '#FF317AF7';
const TEXT_HEIGHT_TITLE: number = 22;
const TEXT_HEIGHT_CONTENT: number = 19;
const TEXT_HEIGHT_CONTENT_SCROLL: number = 38;

const CANCEL_BTN_W: number = 18;
const MARGIN_LEFT_RIGHT: number = 16;
const PADDING_AROUND: number = 12;
const MARGIN_TEXT_LEFT_RIGHT: number = 12;
const LOCATION_BORDER_RADIUS: number = 16;

const BANNER_BACKGROUND_COLOR: string = '#80000000';
const BANNER_HEIGHT: number = 84;
const BANNER_WIDTH_MAX_LANDSCAPE: number = 360;
const BANNER_WIDTH_MAX_TAB: number = 480;
const MARGIN_BANNER_TOP: number = 8;
const MARGIN_BANNER_TOP_HORIZONTAL: number = 12;
const MARGIN_BANNER_TOP_LANDSCAPE: number = 60;
const MARGIN_BANNER_TOP_LANDSCAPE_HORIZONTAL: number = 84;
const MARGIN_BANNER_LEFT_LANDSCAPE_HORIZONTAL: number = 88; //24为百宝箱左边距，48为百宝箱宽度，16为与百宝箱之间的距离。
//tablet
const TABLET_BANNER_TOP: number = 60;
const BANNER_ICON_SIZE: number = 32;
const OFFSET_Y_CUSTOM_FILTER: number = 18;

class RequestLocationDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@CustomDialog
export struct RequestLocationDialog {
  controller: CustomDialogController;
  private mSubscriber: Unsubscribe | null = null;
  private mAction: RequestLocationDispatcher = new RequestLocationDispatcher();
  private layoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @State previewPosition: number = 0;
  @State windowHeight: number = 0;
  @State windowWidth: number = 0;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State @Watch('onDirectionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isHorizontal: boolean = false;
  @State rotateAngle: number = 0;
  @State isRotateLocked: boolean = true;
  @State offsetFullScreen: number = 0;
  @State isVdeLandscape: boolean = false;
  private checkTreasureBoxTip: () => void = () => {};
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @LocalStorageLink('changeCustomFilterImmersive') isCustomFilterImmersive: boolean = false;
  @State @Watch('updateRotationStatus') mIsLockRotation: boolean = true;
  @StorageLink('isOpenHdrBrightness') isOpenHdrBrightness: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'Picker privacy Location appears.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      if (this.isSubscriptionNeeded(state.get<WindowDirection>('contextReducer', 'direction'))) {
        this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      }
      this.isRotateLocked = state.get<boolean>('windowReducer', 'isLockRotation');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.previewPosition = AdaptiveLayoutService.getInstance().previewPosition;
      this.isHorizontal = DisplayService.getInstance().isHorizontal();
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth')
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.mIsLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.getOffsetFullScreen();
    this.uxInit();
    this.onDirectionChange();
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      (data: XComponentSize) => this.onChangeXComponentSize(), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, () => this.uxInit(), this.mBase.hashCode());
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'Picker privacy Location disappears.');
    this.mSubscriber?.destroy();
    this.checkTreasureBoxTip();
  }

  private closeLocationButton(): void {
    PreferencesService.getInstance()
      .putPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED, true);
    AppStorage.setOrCreate('isRequestLocationLoaded', true);
    // 开启相机在相机未弹出过位置卡片时初始化位置开关状态，供图库获取使用
    SettingsValueUtil.setValueSync('camera_location_switch', '0');
    this.controller.close();
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  @Builder
  LocationTextPart() {
    Column() {
      Row() {
        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
        Scroll() {
          Text($r('app.string.request_location_msg'))
            .fontSize(FONT_SIZE_14)
            .lineHeight(TEXT_HEIGHT_TITLE)
            .maxFontScale(CommonConstants.TEXT_SIZE_HUGE)
            .fontColor(FONT_COLOR)
            .textAlign(TextAlign.Start)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .id('Location_title')
        }
        .width(this.getTextPartWidth())
        .scrollBar(BarState.Off)
        this.LocationCancelPart();
        }
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')
      .height(2 * TEXT_HEIGHT_TITLE)
    }
  }

  private getTextPartWidth(): Length {
    if (DeviceInfo.isPhone()) {
      return this.getBannerWidth() - CANCEL_BTN_W - PADDING_AROUND * 2;
    }
    return '';
  }

  @Builder
  LocationCancelPart() {
    Button() {
      Image($r('app.media.ic_camera_cancel_w'))
        .width(CANCEL_BTN_W)
        .fillColor(Color.White)
        .draggable(false)
        .syncLoad(true)
    }
    .type(ButtonType.Normal)
    .backgroundColor(Color.Transparent)
    .key(ComponentIdKeys.LOCATION_DIALOG_CANCEL)
    .onClick(() => {
      HiLog.i(TAG, 'cancel location onClick.');
      this.closeLocationButton();
    })
  }

  build() {
    Row() {
      Column() {
        this.LocationTextPart();
        Text($r('app.string.allow_access')).fontColor('#5291FF').fontSize($r('sys.float.Subtitle_S')).margin({ top: 8 })
          .key(ComponentIdKeys.LOCATION_DIALOG_ACCESS)
          .maxFontScale(CommonConstants.TEXT_SIZE_HUGE)
          .onClick(() => {
            HiLog.i(TAG, 'allow access location onClick.');
            this.closeLocationButton();
            StoreManager.getInstance().postMessage(Action.isRequestPermission(true));
          })

      }.width('100%').alignItems(HorizontalAlign.Start)
    }
    .offset(this.getOffSet())
    .translate({ y: this.isCustomFilterImmersive && this.isVertical() ? OFFSET_Y_CUSTOM_FILTER : 0 })
    .margin({
      left: this.isCustomFilterImmersive && this.mDirection === WindowDirection.LEFT ? OFFSET_Y_CUSTOM_FILTER : 0,
      right: this.isCustomFilterImmersive && this.mDirection === WindowDirection.RIGHT ? OFFSET_Y_CUSTOM_FILTER : 0,
    })
    .width(this.getBannerWidth())
    .borderRadius(LOCATION_BORDER_RADIUS)
    .alignItems(VerticalAlign.Top)
    .backgroundColor(LOCATION_BACKGROUND_COLOR)
    .padding(PADDING_AROUND)
    .rotate({ angle: DeviceInfo.isTablet() ? 0 : this.isShowSemiCollapsed ? 90 : this.rotateAngle })
  }

  private getOffSet(): Position {
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      return { x: this.offsetX, y: this.offsetY - DIALOG_OFFSET + 24 };
    }
    return { x: this.offsetX, y: this.offsetY - DIALOG_OFFSET };
  }

  private getBannerWidth(): number {
    let bannerWidth: number = this.isShowSemiCollapsed ? this.xComponentHeight - 2 * MARGIN_LEFT_RIGHT :
      this.xComponentWidth - 2 * MARGIN_LEFT_RIGHT;
    let maxWidth = DeviceInfo.isTablet() ? BANNER_WIDTH_MAX_TAB : BANNER_WIDTH_MAX_LANDSCAPE;
    return Math.min(maxWidth, bannerWidth);
  }

  private updateOffsetXY(): void {
    this.offsetX = this.getBannerOffsetX();
    this.offsetY = this.getBannerOffsetY();
  }

  private onChangeXComponentSize(): void {
    this.getOffsetFullScreen();
    this.bannerTranslateAnimation();
  }

  private bannerTranslateAnimation(): void {
    animateTo({ curve: Curve.Sharp, duration: 250 }, () => {
      this.updateOffsetXY();
    });
  }

  private getBannerOffsetX(): number {
    let coefficient: number = this.mDirection === WindowDirection.LEFT ? -1 : 1;
    if (DeviceInfo.isTablet()) {
      return 0;
    } else if (this.isHorizontal) {
      return this.isRotateLocked && this.isVertical() ? (-1 / 2 * this.xComponentHeight + 30) * coefficient : 0;
    } else {
      let offset =
        this.isShowLandscape ? -1 / 2 * this.windowHeight + MARGIN_BANNER_LEFT_LANDSCAPE_HORIZONTAL + BANNER_HEIGHT :
          (1 / 2 * this.xComponentWidth - MARGIN_BANNER_TOP_HORIZONTAL - 1 / 2 * BANNER_HEIGHT) * coefficient;
      return this.isShowSemiCollapsed ? BANNER_HEIGHT : !this.isVertical() ? offset : 0;
    }
  }

  private getBannerOffsetY(): number {
    if (DeviceInfo.isTablet()) {
      return this.getTabletBannerOffsetY();
    } else if (this.isShowSemiCollapsed) {
      return 1 / 2 * this.windowHeight - BANNER_ICON_SIZE - PADDING_AROUND + 2;
    } else {
      return this.getBannerPhoneOffsetY();
    }
  }

  private getTabletBannerOffsetY(): number {
    if (DisplayService.getInstance().isOrientationVertical()) {
      const previewPosition4to3: number = (this.windowHeight - this.windowWidth * 4 / 3) / 2;
      const previewPosition1to1: number = (this.windowHeight - this.windowWidth) / 2;
      const offset: number = previewPosition4to3 + (previewPosition1to1 - previewPosition4to3 - BANNER_HEIGHT) / 2;
      if (DeviceInfo.isTablet() && this.isRotateLocked) {
        return offset;
      }
      return this.mDirection === WindowDirection.TOP ? offset : this.windowHeight - offset - BANNER_HEIGHT;
    } else if (DeviceInfo.isTablet() && this.isRotateLocked) {
      return TABLET_BANNER_TOP;
    } else {
      return this.mDirection === WindowDirection.TOP ? TABLET_BANNER_TOP :
        this.windowHeight - TABLET_BANNER_TOP - BANNER_HEIGHT;
    }
  }

  private getOffsetFullScreen(): void {
    const previewPosition4to3: number = this.layoutService.previewPosition4to3;
    this.previewPosition = this.layoutService.previewPosition;
    const isFullRatio = this.previewPosition === 0;
    this.offsetFullScreen = isFullRatio ? previewPosition4to3 : 0;
  }

  private getBannerPhoneOffsetY(): number {
    if (this.isHorizontal) {
      return this.isRotateLocked && this.isVertical() ?
        1 / 2 * this.xComponentWidth - MARGIN_BANNER_LEFT_LANDSCAPE_HORIZONTAL : MARGIN_BANNER_TOP_LANDSCAPE_HORIZONTAL;
    }
    if (this.isVertical()) {
      return this.isShowLandscape ? MARGIN_BANNER_TOP_LANDSCAPE :
        this.previewPosition + MARGIN_BANNER_TOP + this.offsetFullScreen;
    }
    return this.isShowLandscape ? 1 / 2 * this.xComponentHeight - 30 :
      this.layoutService.previewPosition1to1 + 1 / 3 * this.getBannerWidth() + 10 +
        1 / 2 * (this.xComponentWidth - this.getBannerWidth());
  }

  private onDirectionChange(): void {
    this.updateOffsetXY();
    if (!this.isRotateLocked) {
      this.rotateAngle = PickerUtils.getIsPicker() ? 0 : DirectionToAngleUtil.geViewRotate(this.mDirection);
    } else {
      if (DeviceInfo.isTablet() && !PickerUtils.getIsTabletFullScreenFromReducer()) {
        this.rotateAngle = 0;
        return;
      }
      this.rotateAngle = this.getStackRotateAngle();
      if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer()) {
        this.rotateAngle -= 90;
      }
    }
  }

  private updateRotationStatus(): void {
    this.getStackRotateAngle();
  }

  private getStackRotateAngle(): number {
    if ((this.isShowLandscape || DeviceInfo.isTablet()) && !this.isShowSemiCollapsed && !this.mIsLockRotation) {
      return 0;
    }
    return this.rotateAngle;
  }

  private uxInit(): void {
    this.updateOffsetXY();
  }
//TODO 这里闪退先屏蔽
  private isSubscriptionNeeded(direction: WindowDirection): boolean {
    // const orientation: display.Orientation = DisplayService.getInstance().getDisplay().orientation;
    // if (DeviceInfo.isTablet() && this.isRotateLocked &&
    //   !this.isTabletDirectionSameAxisWithOrientation(direction, orientation)) {
    //   return false;
    // }
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
}