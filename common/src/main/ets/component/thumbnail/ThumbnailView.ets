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

import image from '@ohos.multimedia.image';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { Action } from '../../redux/actions/Action';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import MediaLibraryUiService from '../../service/medialibrary/MediaLibraryUiService';
import lazy { VibratorService } from '../vibration/VibratorService';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { OhCombinedState, Dispatch, Unsubscribe, reduxSubscribe, getStates } from '../../redux';
import lazy { ThumbnailUpdateScene } from './ThumbnailAction';
import lazy { ThumbnailAction } from './ThumbnailAction';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import Want from '@ohos.app.ability.Want';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '../../function/core/FunctionAction';
import lazy { ThumbnailService } from './ThumbnailService';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import camera from '@ohos.multimedia.camera';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { RecordingControlButton } from '../../function/recordcontrol/RecordingControlButton';
import lazy { performanceMonitor } from '../../utils/LazyImportUtil';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';
import lazy { ThumbnailStruct } from '../../utils/types';
import lazy { TreasureBoxAction } from '../treasurebox/reduce/TreasureBoxAction';
import lazy { ThumbnailInfo } from './ThumbnailInfo';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { PhotoBrowserManager } from '../../service/photoBrowser/PhotoBrowserManager';
import lazy { window } from '@kit.ArkUI';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { RecordingCaptureButton } from '../../function/recordcontrol/RecordingCaptureButton';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { AppLockUtil } from '../../utils/AppLockUtil';
import screenLock from '@ohos.screenLock';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { ThumbnailActionType } from '../../redux/actions/ThumbnailActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { FocusExposureAction } from '../focusExposure/FocusExposureAction';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { LeftRightSwipeActionType } from '../../redux/actions/LeftRightSwipeActionType';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { CameraRunningState } from '../../camera/uithread/CameraAction';

/* instrument ignore file */
const TAG: string = 'ThumbnailView';

const PHOTO_ACTION: string = 'ohos.want.action.viewData'; //'ability.params.backToOtherMissionStack';
const PHOTO_BUNDLE_NAME: string = 'com.ohos.photos';
const PHOTO_ABILITY_NAME: string = 'com.ohos.photos.MainAbility';
const ENTER_ROUND_THUMBNAIL_MAX_COUNT: number = 5;
const THUMBNAIL_UPDATE_DURATION: number = 200;
const COLD_START_THUMBNAIL_DELAY_MS: number = 320;
const BORDER_WIDTH_ZERO: number = 0;
const BORDER_WIDTH_NORMAL: number = 1.5;
const BORDER_WIDTH_BOLD: number = 2;

class ThumbnailViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public showThumbnailReminder(isShow: boolean): void {
    this.mDispatch(Action.showThumbnailReminder(isShow));
  }

  public showAppLockReminder(isShow: boolean): void {
    this.mDispatch(Action.showAppLockReminder(isShow));
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public changeFunctionValue(id: FunctionId, value: number | string | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public hideFocus(): void {
    this.mDispatch(FocusExposureAction.hideFocus());
  }

  public proSonChangeState(): void {
    this.mDispatch(Action.proSonChangeState(-1));
  }

  public setTreasureBoxStatus(isOpen: boolean): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(isOpen));
  }

  public emitBackGroundWhite(): void { // 关闭环形补光白底
    this.mDispatch(execAction('RingLightAction', 'emitBackGroundWhite', false));
  }
}

class LastThumbnailStruct {
  public lastThumbnail: image.PixelMap | undefined = undefined;
}

class RefreshDefaultThumbnail {
  public isRefreshDefaultThumbnail: boolean = false;
}

class ChangeThumbnailStruct {
  public thumbnail: image.PixelMap | undefined = undefined;
  public hasAnimate: boolean = false;
}

/* instrument ignore next */
@Component
export struct ThumbnailView {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: ThumbnailViewDispatcher = new ThumbnailViewDispatcher();
  @Prop isThumbnailViewVisibility: boolean = false;
  public onShowCallBack: () => void | undefined = () => {
  };
  @State thumbnailBorder: BorderOptions = {};
  @State oldThumbnail: image.PixelMap | Resource = $r('app.media.ic_camera_thumbnail_default_white');
  private oldCacheThumbnail: image.PixelMap | undefined = undefined;
  @State thumbnail: image.PixelMap | Resource = $r('app.media.ic_camera_thumbnail_default_white');
  @State hasThumbnail: boolean = false;
  @State thumbnailScale: ScaleOptions = { x: 1, y: 1 };
  @StorageLink('isShowThumb') @Watch('handleThumbnailBorderUpdate') isShowThumb: boolean = true;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @StorageLink('showPhotoBrowserAction') showPhotoBrowserAction: boolean = false;
  @StorageLink('isThumbnailOpened') @Watch('handleThumbnailVisibility') isThumbnailOpened: boolean = false;
  @State directionState: WindowDirection = WindowDirection.TOP;
  @State innerOpacity: number = 1;
  @State thumbUpdateAnimating: boolean = false;
  @State thumbUpdateInnerOpacity: number = 0;
  @State thumbUpdateInnerScale: ScaleOptions = { x: 1, y: 1 };
  @State recordThumScale: ScaleOptions = { x: 0, y: 0 };
  @State @Watch('changeRotateAngle') rotateAngleWatch: number = 0;
  @State rotateAngle: number = 0;
  private mTimerId: number = Number.MIN_VALUE;
  private currentRotationAngle: number = 0;
  private mCameraShotKey: string = '';
  private mCachedThumbnail: ThumbnailStruct | null = null;
  private mIsThumbnailLate: boolean = false;
  @State isPowerModeAwakenScreen: boolean = false;
  @State @Watch('updatePowerModeChange') isPowerModeChange: boolean = false;
  @State density: number = 1 //DisplayService.getInstance().getDisplay().densityPixels;
  @State thumbnailRadius: number = 22;
  private timer: number = 0;
  @State isShowLandscape: boolean = false;
  @StorageLink('shoot_count') roundShootCount: number = 0;
  @Provide userSelectedValue: string = 'none';
  @State uiEnable: boolean = true;
  @State isShowSemiCollapsed: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  // 环形补光
  @State isShowRingLightView: boolean = false;
  @State isShowWhiteBack: boolean = false;
  @State isSetGeometryTransition: boolean = true; // 用于控制设置到共享元素上是否设置共享元素id
  private ringLightThumbView: Resource = $r('app.media.ic_camera_thumbnail_default_ring_light');
  // 慢动作
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  private mPromiseResolve: (() => void) | null = null;
  private isLoadThumbnail: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @State isShowtimeLapse: boolean = false
  @State isEnterBurst: boolean = false;
  @StorageLink('onCustomFilterCardActionMenuShow') isShowActionMenu: boolean = false;
  private nightPromiseResolve: (() => void) | null = null;
  @StorageLink('nightCaptureStarted') nightCaptureStarted: boolean = false;
  private isBurstEnd: boolean = false;
  @State curStyleIndex: number = 0;
  @State isCustomFilterImmersive: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    if (this.isLemCollaps) {
      this.thumbnailRadius = 33;
    } else {
      if (this.isLoadThumbnail) {
        return;
      }
      const coldDeferThumb: boolean = getStates().get<boolean>('cameraReducer', 'isColdStart') &&
        getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED;
      if (coldDeferThumb) {
        HiLog.i(TAG, `defer loadThumbnail ${COLD_START_THUMBNAIL_DELAY_MS}ms for cold start.`);
        setTimeout((): void => {
          if (!this.isLoadThumbnail) {
            this.loadThumbnail();
          }
        }, COLD_START_THUMBNAIL_DELAY_MS);
      } else {
        this.loadThumbnail();
      }
    }
    this.rotateAngle = getStates().get<number>('contextReducer', 'rotateAngle');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.mCameraShotKey = state.get<string>('securityCameraReducer', 'cameraShotKey');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.rotateAngleWatch = state.get<number>('contextReducer', 'rotateAngle');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isPowerModeChange = state.get<boolean>('contextReducer', 'isDuringSavePowerMode');
      this.density = state.get<number>('collapsReducer', 'density');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowWhiteBack = state.get<boolean>('ringLightReducer', 'isShowWhiteBack');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.curStyleIndex = state.get<number>('customFilterStyleReducer', 'styleIndex');
      this.isCustomFilterImmersive = state.get<boolean>('customFilterStyleReducer', 'customFilterCardOpened');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.nightCaptureStarted = false;

    this.mEventBus.on([CameraActionType.WARM_START,
      CameraActionType.WARM_START_WITH_MODE_AND_POS,
    ], this.reloadThumbnail.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CAMERA_SHOT_KEY, this.handleShotKey.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.REFRESH, this.refreshThumbnail.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.RECEIVED, this.onThumbnailUpdate.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.ANIMATION, this.onThumbnailAnimation.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.CHANGE_THUMBNAIL, this.onChangeThumbnail.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_END, ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END], () => {
      const mode = getStates().get<ModeType>('modeReducer', 'mode');
    }, this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.ROLL_BACK, this.rollBackThumbnail.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.CAPTURE, this.updateCacheThumbnail.bind(this), this.mBase.hashCode());
    this.mEventBus.on(LeftRightSwipeActionType.BURST, this.enterBurst.bind(this), this.mBase.hashCode());
    this.roundShootCount = 0;
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  private enterBurst(): void {
    this.isEnterBurst = true;
  }

  private updateCacheThumbnail(): void {
    let cacheThumbnail = this.hasThumbnail ? this.oldThumbnail as image.PixelMap : undefined;
    HiLog.i(TAG, `capture updateCacheThumbnail ${(cacheThumbnail === undefined)}`);
    this.oldCacheThumbnail = cacheThumbnail;
  }

  private onBackground(): void {
    this.isSetGeometryTransition = false;
  }

  private onForeground(): void {
    this.isSetGeometryTransition = true;
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    try {
      (this.thumbnail as image.PixelMap)?.release();
    } catch (err) {
      HiLog.e(TAG, `release thumbnail err: ${err}.`);
    }
    clearTimeout(this.mTimerId);
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  private handleShotKey(): void {
    if (this.isLoadThumbnail) {
      new Promise<void>((resolve: () => void) => {
        this.mPromiseResolve = resolve;
      }).then(() => {
        this.reloadThumbnail();
      });
    } else {
      this.reloadThumbnail();
    }
  }

  // 处理缩略图更新
  private handleThumbUpdateAnim(): void {
    this.thumbUpdateAnim();
  }

  // 夜景后置缩略图更新
  private handleNightThumbnailUpdate(): void {
    HiLog.i(TAG, 'handleNightThumbnailUpdate E');
    if (this.nightPromiseResolve) {
      this.nightPromiseResolve();
      this.nightPromiseResolve = null;
    } else {
      HiLog.i(TAG, 'handleNightThumbnailUpdate Promise');
      new Promise<void>((resolve: () => void) => {
        this.nightPromiseResolve = resolve;
      }).then(() => {
        HiLog.i(TAG, 'handleNightThumbnailUpdate then');
        this.thumbUpdateAnim();
      });
    }
  }

  private handleThumbnailVisibility(): void {
    HiLog.i(TAG, `handleThumbnailVisibility isThumbnailOpened: ${this.isThumbnailOpened}`);
  }

  private refreshThumbnail(data: RefreshDefaultThumbnail): void {
    HiLog.i(TAG, `refreshThumbnail: ${JSON.stringify(data)}.`);
    if (data && data.isRefreshDefaultThumbnail) {
      this.oldThumbnail = $r('app.media.ic_camera_thumbnail_default_white');
      this.thumbnail = $r('app.media.ic_camera_thumbnail_default_white');
      this.thumbnailBorder = { width: 0 };
      this.hasThumbnail = false;
      return;
    }
    this.reloadThumbnail();
    HiLog.i(TAG, `refreshThumbnail end.`);
  }

  private async loadThumbnail(): Promise<void> {
    HiLog.begin(TAG, 'loadThumbnail');
    this.isLoadThumbnail = true;
    let thumbnailInfo: ThumbnailInfo | undefined = MediaLibraryUiService.getInstance().getThumbnailInfoForColdStart();
    if (thumbnailInfo) {
      // 仅用于冷启动，用完就删
      let appLock = await AppLockUtil.getInstance().isPhotoAppLocked();
      if (appLock) {
        // 冷启动且添加了应用锁状态下，缩略图不显示
        thumbnailInfo = undefined;
      }
      MediaLibraryUiService.getInstance().setThumbnailInfoForColdStart(null);
      HiLog.i(TAG, `get thumbnailInfoForColdStart.`);
    } else {
      thumbnailInfo = await MediaLibraryUiService.getInstance().getThumbnailInfo();
    }
    AppStorage.setOrCreate('thumbnailMediaUri', thumbnailInfo?.mediaUri);

    const thumbnail = thumbnailInfo?.thumbnailPixelMap;
    this.changeThumbnail(thumbnail, false, true);
    if (!this.isLemCollaps) {
      // 大图打开，退出相机或锁屏，再次进入圆角不生效，需要更新圆角值，才能生效，一镜到底问题，后续一镜到底会修复，暂时规避
      this.thumbnailRadius = this.thumbnailRadius % 22 ? 22 : 23;
    }
    this.mPromiseResolve?.();
    this.isLoadThumbnail = false;
    HiLog.end(TAG, 'loadThumbnail');
  }

  private async reloadThumbnail(): Promise<void> {
    this.isLoadThumbnail = true;
    if (this.showPhotoBrowserAction) {
      // 大图动效过程中，不能更新缩略图和uri
      HiLog.i(TAG, 'reloadThumbnail PhotoBrowser is show, ignore...');
      this.mPromiseResolve?.();
      this.isLoadThumbnail = false;
      return;
    }
    const thumbnailInfo: ThumbnailInfo | undefined = await MediaLibraryUiService.getInstance().getThumbnailInfo();
    AppStorage.setOrCreate('thumbnailMediaUri', thumbnailInfo?.mediaUri);
    HiLog.i(TAG, 'onThumbnailLoad.');
    this.thumbnailScale = { x: 1, y: 1 };
    this.changeThumbnail(thumbnailInfo?.thumbnailPixelMap, false, true);
    this.mAction.proSonChangeState();
    if (!this.isLemCollaps) {
      // 大图打开，退出相机或锁屏，再次进入圆角不生效，需要更新圆角值，才能生效，一镜到底问题，后续一镜到底会修复，暂时规避
      this.thumbnailRadius = this.thumbnailRadius % 22 ? 22 : 23;
    }
    this.mPromiseResolve?.();
    this.isLoadThumbnail = false;
    HiLog.i(TAG, `onThumbnailLoad this.thumbnail X.`);
  }

  private getThumbnailViewVis(): boolean {
    HiLog.i(TAG, 'slowRecordingCompVisible = ' + this.slowRecordingCompVisible +
      ' ,isThumbnailViewVisibility = ' + this.isThumbnailViewVisibility);
    return this.slowRecordingCompVisible && this.isThumbnailViewVisibility;
  }

  private getLemAnimateParam(): AnimateParam | undefined {
    if (this.getThumbnailViewVis()) {
      return { curve: Curve.Sharp, duration: AnimSpecifications.ANIM_DURATION_150 }
    } else {
      return undefined;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Image(this.oldThumbnail)
            .width('100%')
            .aspectRatio(1)
            .borderRadius(this.thumbnailRadius)
            .objectFit(ImageFit.Cover)
            .key(ComponentIdKeys.THUMBNAIL_1)
            .enabled(this.mCameraShotKey ? true : this.hasThumbnail)
            .draggable(false)
            .syncLoad(true)
            .geometryTransition(this.isSetGeometryTransition ? AnimSpecifications.GEOMETRY_TRANSITION_ID_THUMBNAIL : '',
              { follow: this.isLemCollaps ? false : true })
            .visibility((this.isThumbnailOpened && !AppStorage.get('pcPickerActive')) ? Visibility.Hidden :
              Visibility.Visible)
            .border(this.thumbnailBorder)
        }
        .accessibilityText(ResGetter.getStringSafe($r('app.string.accessibility_review_thumbnail')))
        .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_clickable')))
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .accessibilityLevel(this.videoState === RecordingState.RECORDING ||
          this.videoState === RecordingState.RESUMING ?
          CommonConstants.ACCESSIBILITY_LEVEL_NO : CommonConstants.ACCESSIBILITY_LEVEL_YES)
        // .onClickStyle()
      }
      .enabled(this.uiEnable)
      .key(ComponentIdKeys.THUMBNAIL_STACK_COLUMN)
      .width(this.isLemCollaps ? '100%' : this.isVdeCollapsed ? 28 : $r('app.float.thumbnail_size'))
      .borderRadius(this.thumbnailRadius)
      .backgroundColor(Color.Transparent)
      .scale(this.thumbnailScale)
      .opacity(this.innerOpacity)
      .rotate({ angle: DeviceInfo.isPc() ? 0 : this.rotateAngle })
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .onTouch((event?: TouchEvent) => {
        this.thumbnailOnTouch(event);
      })

      if (this.thumbUpdateAnimating) {
        Column() {
          Image(this.thumbnail)
            .width('100%')
            .aspectRatio(1)
            .borderRadius(this.thumbnailRadius)
            .objectFit(ImageFit.Cover)
            .opacity(this.thumbUpdateInnerOpacity)
            .rotate({ angle: DeviceInfo.isPc() ? 0 : this.rotateAngle })
            .scale(this.thumbUpdateInnerScale)
            .syncLoad(true)
        }
        .width(this.isLemCollaps ? 64 : this.isVdeCollapsed ? 25 : 42)
        .key(ComponentIdKeys.THUMBNAIL_STACK_COLUMN_ANIMATE)
        .borderRadius(this.thumbnailRadius)
        .hitTestBehavior(HitTestMode.Transparent)
      }
      if (!this.isLemCollaps) {
        if (this.isSupportContinuumVideo() && this.videoState !== RecordingState.READY) {
          RecordingCaptureButton({ isPicker: GlobalContext.get().getIsPicker() });
        } else {
          RecordingControlButton();
        }
      }
    }
    .width(this.isLemCollaps ? 66 : $r('app.float.thumbnail_size'))
    .aspectRatio(1)
    .key(ComponentIdKeys.THUMBNAIL_STACK)
    .visibility(this.getThumbnailViewVis() ? Visibility.Visible : Visibility.Hidden)
  }

  @Styles
  private onClickStyle() {
    .onClick((event) => {
      // 仅在无障碍服务下生效
      if (event && this.enableScreenReader && this.isOpenTouchGuide && this.uiEnable) {
        this.showPhotoBrowser();
      }
    })
  }

  private thumbnailOnTouch(event?: TouchEvent): void {
    HiLog.i(TAG, `thumbnailOnTouch type: ${event?.type}, uiEnable: ${this.uiEnable}`);
    if (!event || event.type === TouchType.Move || event.type === TouchType.Cancel ||
    this.thumbUpdateAnimating) {
      HiLog.i(TAG, `thumbnailOnTouch return type: ${event?.type}, thumbUpdateAnimating: ${this.thumbUpdateAnimating}`);
      if (this.enableScreenReader) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(
          ResGetter.getStringSafe($r('app.string.accessibility_review_thumbnail')));
      }
      return;
    }

    const isShowPhotoBrowser: boolean | undefined = AppStorage.get('showPhotoBrowserAction');
    HiLog.i(TAG, `The PhotoBrowser is not over, ${isShowPhotoBrowser}.`);
    const isEnableCanShowPhotoBrowser: boolean = ThumbnailService.getInstance().isEnableCanShowPhotoBrowser();
    if (!this.uiEnable || !ThumbnailService.getInstance().isEnableCanShowPhotoBrowser() || isShowPhotoBrowser) {
      HiLog.i(TAG,
        `thumbnailOnTouch return uiEnable: ${this.uiEnable}, isEnableCanShowPhotoBrowser: ${isEnableCanShowPhotoBrowser}`);
      if (event?.type === TouchType.Up) {
        this.thumbnailUpAnim();
      }
      return;
    }

    if (event?.type === TouchType.Down) {
      StoreManager.getInstance().postMessage(ThumbnailAction.updatePhotoBrowserTouch(true));
      this.thumbnailDownAnim();
    } else if (event?.type === TouchType.Up) {
      StoreManager.getInstance().postMessage(ThumbnailAction.updatePhotoBrowserTouch(false));
      this.showPhotoBrowser();
    }
  }

  private thumbnailDownAnim(): void {
    HiLog.i(TAG, 'thumbnail Down Anim.');
    BlurAnimateUtil.generatePixelMapFromSurface();
    this.thumbnailScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
      }
    }, () => {
      this.thumbnailScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_DOWN;
    });
  }

  private thumbnailUpAnim(): void {
    this.thumbnailScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_DOWN;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
      }
    }, () => {
      this.thumbnailScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    });
  }

  private async showPhotoBrowser(): Promise<void> {
    HiLog.i(TAG, `start show photo browser. this.hasThumbnail: ${this.hasThumbnail}.`);
    this.thumbnailUpAnim();
    this.isShowActionMenu = false;
    this.persistEnterRoundThumbnailCount();
    if (this.hasThumbnail) {
      BlurAnimateUtil.setHasShowBlurWhenExit(true);
      StoreManager.getInstance().postMessage(Action.onPreviewFrameStart(false, true));
      HiLog.i(TAG, `start show photo browser canClick ,${AppStorage.get('canClickThumbnailView')}`);
      if (GlobalContext.get().getPhotoBrowserDisabled() ||
      CameraAppCapability.getInstance().getIsSuspendPhotoBrowser()) {
        ContextManager.getInstance().getUiContext().startAbility(this.getPhotoWant(false)).then(
          () => {
            // 手动触发修改ShutterButton isFrameStarted 标识位
            StoreManager.getInstance().postMessage(Action.onPreviewFrameStart(true, true));
          }
        );
      } else if (AppStorage.get('canClickThumbnailView')) {
        AppStorage.setOrCreate('showPhotoBrowserAction', true);
        if (!DeviceInfo.isPhone()) {
          PhotoBrowserManager.getInstance().setViewHidden();
        }
        this.mAction.setTreasureBoxStatus(false);
      }
    } else {
      if (screenLock.isLocked() && GlobalContext.get().getT('isSecureMode')) {
        HiLog.i(TAG, 'show ThumbnailReminder.');
        this.mAction.showThumbnailReminder(true);
      } else {
        let isAppLock = await AppLockUtil.getInstance().isPhotoAppLocked();
        if (isAppLock) {
          //跳转应用锁提示界面
          HiLog.i(TAG, 'show AppLockReminder.');
          this.mAction.showAppLockReminder(true);
        }
      }
    }
    setTimeout((): void => {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }, 100);
  }

  private persistEnterRoundThumbnailCount(): void {
    if (this.isLemCollaps) {
      if (this.timer) {
        clearTimeout(this.timer);
      }
      this.isThumbnailViewVisibility = false;
      // 统计当前进入外屏缩略图的次数
      let enterRoundThumbnailCount = PreferencesService.getInstance()
        .getPropValue(PersistType.FOREVER, PropTag.ENTER_ROUND_THUMBNAIL_COUNT, 0) as number;
      HiLog.i(TAG, `persistEnterRoundThumbnailCount: ${enterRoundThumbnailCount}`);
      if (enterRoundThumbnailCount < ENTER_ROUND_THUMBNAIL_MAX_COUNT) {
        PreferencesService.getInstance()
          .putPropValue(PersistType.FOREVER, PropTag.ENTER_ROUND_THUMBNAIL_COUNT, ++enterRoundThumbnailCount);
      }
    }
  }

  private onChangeThumbnail(data: ChangeThumbnailStruct): void {
    if (!data) {
      HiLog.e(TAG, 'onChangeThumbnail error');
      return;
    }
    HiLog.i(TAG, 'onChangeThumbnail');
    this.changeThumbnail(data.thumbnail, data.hasAnimate);
  }

  private onThumbnailUpdate(data: ThumbnailStruct): void {
    HiLog.i(TAG, `onThumbnailUpdate data: ${data.scene}, mIsThumbnailLate: ${this.mIsThumbnailLate} E.`);
    if (this.mIsThumbnailLate) {
      this.mCachedThumbnail = null;
      this.changeThumbnail(data.thumbnail, true);
      this.mIsThumbnailLate = false;
    } else {
      this.mCachedThumbnail = data;
    }
    if (this.isLemCollaps) {
      this.isPowerModeAwakenScreen = false;
      this.roundShootCount++;
      HiLog.i(TAG, `onThumbnailUpdate roundShootCount: ${this.roundShootCount}`);
    }
    if (data.scene === ThumbnailUpdateScene.CAPTURE) {
    } else if (data.scene === ThumbnailUpdateScene.RECORD || data.scene === ThumbnailUpdateScene.BURST) {
      this.onThumbnailAnimation();
    }
  }

  private isSupportContinuumVideo(): boolean {
    const modeName: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    return CameraAppCapability.getInstance().getIsSupportRecordingFlowing() && modeName === ModeType.VIDEO;
  }

  private onThumbnailAnimation(): void {
    HiLog.i(TAG, 'SHOT2SEE onThumbnailAnimation E.');
    if (this.mCachedThumbnail !== null) {
      HiLog.i(TAG, 'mCachedThumbnail is not null');
      this.changeThumbnail(this.mCachedThumbnail.thumbnail, true);
      this.mCachedThumbnail = null;
      this.mIsThumbnailLate = false;
    } else {
      if (this.isEnterBurst) {
        this.isEnterBurst = false;
        return
      }
      this.mIsThumbnailLate = true;
    }
  }

  private getBorderColor(): string | Color {
    return Color.White;
  }

  private getThumbnailDefault(): image.PixelMap | Resource {
    return $r('app.media.ic_camera_thumbnail_default_white');
  }

  private handleRingLightThumb(): void {
    HiLog.i(TAG, `handleRingLightThumb:${this.hasThumbnail},${this.isShowRingLightView}`)
    if (this.hasThumbnail) {
      this.thumbnailBorder.color = this.getBorderColor();
    } else {
      this.thumbnail = this.getThumbnailDefault();
      this.oldThumbnail = this.thumbnail;
    }
  }

  private handleThumbnailBorderUpdate(): void {
    const thumbnailBorder: BorderOptions = { width: BORDER_WIDTH_ZERO, color: Color.White, style: BorderStyle.Solid };
    thumbnailBorder.color = this.getBorderColor();
    if (this.hasThumbnail && this.isShowThumb) {
      if (this.isShowRingLightView) {
        thumbnailBorder.width = BORDER_WIDTH_NORMAL;
      } else if (this.isLemCollaps) {
        thumbnailBorder.width = BORDER_WIDTH_BOLD;
      } else {
        thumbnailBorder.width = BORDER_WIDTH_NORMAL;
      }
    }

    this.thumbnailBorder = thumbnailBorder;
  }

  private async changeThumbnail(thumbnail: image.PixelMap | undefined, hasAnimate: boolean,
    firstEntry: boolean = false, isRollBack: boolean = false): Promise<void> {
    HiLog.begin(TAG, 'changeThumbnail');
    HiLog.i(TAG,
      `changeThumbnail thumbnail info: ${thumbnail?.getImageInfoSync()?.size?.height}x${thumbnail?.getImageInfoSync()?.size?.width}.`);
    if (this.hasThumbnail) {
      try {
        HiLog.i(TAG, 'release thumbnail');
        await (this.thumbnail as image.PixelMap)?.release();
      } catch (err) {
        HiLog.e(TAG, `release thumbnail err: ${err}.`);
      }
    }
    if (AppStorage.get<boolean>('isBackground')) {
      // 由于在background已经将缩略图置空了，录像中直接退后台等场景在结束后又会刷新缩略图，由此进行拦截，后台状态下不再刷新缩略图，使其 保持置空状态
      HiLog.i(TAG, 'background changeThumbnail return.');
      return;
    }
    if (this.isShowWhiteBack) {
      this.mAction.emitBackGroundWhite();
    }
    this.hasThumbnail = thumbnail !== undefined;
    HiLog.i(TAG, 'SHOT2SEE change thumbnail.' + this.hasThumbnail);
    if (thumbnail !== undefined) {
      this.thumbnail = thumbnail;
    } else {
      this.thumbnail =
        this.isShowRingLightView ? this.ringLightThumbView : $r('app.media.ic_camera_thumbnail_default_white');
    }
    if (this.isLemCollaps) {
      if (!thumbnail || this.roundShootCount === 0) {
        this.isThumbnailViewVisibility = false;
        return;
      }
      this.oldThumbnail = this.thumbnail;
      this.showThumbnailView();
      HiLog.i(TAG, `changeThumbnail roundThumbnailCount = ${AppStorage.get('shoot_count')}`);
      return;
    }
    AppStorage.setOrCreate('thumbnailPixelMap', this.thumbnail);
    if (hasAnimate) {
      this.handleThumbUpdateAnim();
    } else {
      this.oldThumbnail = this.thumbnail;
      this.handleThumbnailBorderUpdate();
    }
    HiLog.end(TAG, 'changeThumbnail');
  }

  /* instrument ignore next */
  private rollBackThumbnail(data: LastThumbnailStruct): void {
    HiLog.i(TAG, 'rollback thumbnail');
    this.mCachedThumbnail = {
      thumbnail: this.oldCacheThumbnail,
      scene: ThumbnailUpdateScene.REFRESH
    };
    let thumbnail: image.PixelMap | undefined = this.oldCacheThumbnail;
    HiLog.i(TAG, `post thumbnail as ${(thumbnail == undefined)}`);
    this.changeThumbnail(thumbnail, false, true);
  }

  private getAnimationDuration(): number {
    if (this.currentRotationAngle % AnimSpecifications.ANIM_ROTATE_180 === 0) {
      return AnimSpecifications.ANIM_DURATION_600;
    } else {
      return AnimSpecifications.ANIM_DURATION_450;
    }
  }

  private thumbUpdateAnimFinish = (): void => {
    HiLog.i(TAG, 'thumbUpdateAnimFinish E.');
    if (this.thumbUpdateAnimating) {
      this.oldThumbnail = this.thumbnail;
      this.thumbUpdateAnimating = false;
      this.handleThumbnailBorderUpdate();
    } else {
      HiLog.i(TAG, 'thumbUpdateAnimFinish finished.')
    }
  }

  private thumbUpdateAnim(): void {
    this.thumbUpdateInnerOpacity = AnimSpecifications.ANIM_CAPTURE_THUMBNAIL_OPACITY_FROM;
    this.thumbUpdateInnerScale = AnimSpecifications.ANIM_CAPTURE_THUMBNAIL_SCALE_FROM;
    this.thumbUpdateAnimating = true;
    HiLog.i(TAG, 'thumbUpdateAnim E.');
    animateToImmediately({
      duration: THUMBNAIL_UPDATE_DURATION,
      curve: Curve.Sharp,
      onFinish: this.thumbUpdateAnimFinish
    }, () => {
      this.thumbUpdateInnerOpacity = AnimSpecifications.ANIM_CAPTURE_THUMBNAIL_OPACITY_TO;
      this.thumbUpdateInnerScale = AnimSpecifications.ANIM_CAPTURE_THUMBNAIL_SCALE_TO;
    });
  }

  private videoStateOnChange(): void {
    HiLog.d(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      this.recordStartAnim();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
    }
  }

  private recordStartAnim(): void {
    HiLog.d(TAG, 'recordStartAnim');
    this.innerOpacity = 1;
    this.thumbnailScale = { x: 1, y: 1 };
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        const windowStageEventType: window.WindowStageEventType | undefined = AppStorage.get('windowStageEventType');
        const isWindowInactive: boolean = windowStageEventType === window.WindowStageEventType.PAUSED ||
          windowStageEventType === window.WindowStageEventType.INACTIVE ||
          windowStageEventType === window.WindowStageEventType.HIDDEN;

        if (isWindowInactive) {
          this.innerOpacity = 1;
          this.thumbnailScale = { x: 1, y: 1 };
        }
      }
    }, () => {
      this.thumbnailScale = { x: 0, y: 0 };
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp,
      onFinish: () => {
      }
    }, () => {
      this.innerOpacity = 0;
    });

  }

  private recordEndAnim(): void {
    HiLog.d(TAG, 'recordEndAnim');
    this.innerOpacity = 0;
    this.thumbnailScale = { x: 0, y: 0 };
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        HiLog.d(TAG, 'recordEndAnim finish');
      }
    }, () => {
      this.thumbnailScale = { x: 1, y: 1 };
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp,
      onFinish: () => {
      }
    }, () => {
      this.innerOpacity = 1;
    });
  }

  private getPhotoWant(isSecurity: boolean): Want {
    const parameters: Record<string, Object> = {
      'ability.params.backToOtherMissionStack': true
    }
    if (isSecurity) {
      parameters.cameraShotKey = this.mCameraShotKey;
      parameters.isShowTabMenu = false;
      parameters.isShowToolMenu = false;
    }
    return {
      parameters: parameters,
      uri: MediaLibraryUiService.getInstance().getRecentFileUri(),
      action: PHOTO_ACTION,
      bundleName: PHOTO_BUNDLE_NAME,
      abilityName: PHOTO_ABILITY_NAME
    }
  }

  private updatePowerModeChange() {
    this.isPowerModeAwakenScreen = true;
  }

  private showThumbnailView() {
    if (this.isPowerModeAwakenScreen) {
      // 如果是省电模式唤醒屏幕 则不显示缩略图
      this.isPowerModeAwakenScreen = !this.isPowerModeAwakenScreen;
      return;
    }
    if (this.timer) {
      clearTimeout(this.timer);
    }
    this.onShowCallBack?.();
    this.handleThumbnailBorderUpdate();
    this.isThumbnailViewVisibility = true;
    this.timer = setTimeout((): void => {
      if (this.isLemCollaps) {
        HiLog.i(TAG, 'hide thumbnailView.');
        this.isThumbnailViewVisibility = false;
      }
    }, 3000);
  }

  private changeRotateAngle(): void {
    if (this.rotateAngle === this.rotateAngleWatch) {
      return;
    }
    animateToImmediately({
      duration: this.getAnimationDuration(),
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.rotateAngle = this.rotateAngleWatch
    });
  }
}