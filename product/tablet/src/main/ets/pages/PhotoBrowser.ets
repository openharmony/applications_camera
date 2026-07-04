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

// import {
//   initPhotoBrowserController,
//   PhotoBrowserController,
//   PhotoBrowserView,
//   unInitPhotoBrowserController
// } from '@photobrowser/browserlibrary';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { ThumbnailAction } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailAction';
import { UiUtil } from '@ohos/common/src/main/ets/animation/UiUtil';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { Dispatch, Unsubscribe, getStates } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import { ThumbnailService } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailService';
import { PhotoBrowserManager } from '@ohos/common/src/main/ets/service/photoBrowser/PhotoBrowserManager';
import {
  PhotoAssetObj,
  ThumbnailObj } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailInfo';
import { image } from '@kit.ImageKit';
import { PhotoBrowserOperation } from '@ohos/common/src/main/ets/utils/PhotoBrowserOperation';
import { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { FrameLockScene } from '@ohos/common/src/main/ets/utils/FrameLockScene';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { apsSetScene } from '@ohos/common/src/main/ets/utils/FrameLockSceneUtil';

const TAG: string = 'PhotoBrowser';
const JUMP_TYPE: string = 'jump_type';
const PAGE_FROM: number = 1;
const BROWSER_FULL_SHOW: string = 'browser_full_show';

interface CameraShotData {
  cameraShotKey: string;
}

enum PhotoBrowserJumpType {
  JUMP_TO_GALLERY = 0, // 从大图组件跳转进图库
  BACK = 2, // 返回相机
}

class PhotoBrowserDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public reloadThumbnail(): void {
    this.mDispatch(ThumbnailAction.refresh());
  }

  public updatePhotoBrowser(photoBrowserStatus: boolean): void {
    this.mDispatch(ThumbnailAction.updatePhotoBrowser(photoBrowserStatus));
  }

  public closeCamera(): void {
    this.mDispatch(CameraAction.close({ isNeedSaveRestore: true, isEnterPhotoBrowser: true }));
  }

  public startup(): void {
    ZoomOperation.getInstance().setRemainZoomRatio(true);
    this.mDispatch(CameraAction.warmStart());
  }

  public setPreviewFrameStart(isFrameStart: boolean): void {
    this.mDispatch(Action.onPreviewFrameStart(isFrameStart));
  }
}

@Builder
export function PhotoBrowserLoader() {
  PhotoBrowser()
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
}

@Component
struct PhotoBrowser {
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: PhotoBrowserDispatcher = new PhotoBrowserDispatcher();
  // PhotoBrowser组件成员属性
  @State pageStatus: boolean = false;
  @State isRunningAnimation: boolean = false;
  private isShowPbInterrupted: boolean = false;
  private isShowPhotoBrowserAnimateEnd: boolean = true;
  private isHidePhotoBrowserAnimateEnd: boolean = true;
  // @Provide browserController: PhotoBrowserController = new PhotoBrowserController(
  //   ContextManager.getInstance().getAbilityContext(),
  //   GlobalContext.get().getWindowStage(),
  //   ContextManager.getInstance().getAbilityStageContext());
  // 是否显示组件
  @StorageLink('isShowPhotoBrowser') isShowPhotoBrowser: boolean = false;
  // 当前主界面切后台后，是否需要退出当前大图页面
  @StorageLink('isBackground') needDisappearBrowserWhenIndexHided: boolean = false;
  // 查看图片事件
  @StorageLink('showPhotoBrowserAction') @Watch('showPhotoBrowserOnChange') showPhotoBrowserAction: boolean = false;
  // 更新缩略图事件
  @StorageLink('thumbnailMediaUri') @Watch('onThumbnailMediaUri') thumbnailMediaUri: string = '';
  private waitCapturePhotoTimerId: number = Number.MAX_VALUE; // 进入大图浏览等待80分图落盘超时机制
  private mQuickThumbnailMap: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private mLastCaptureId: string = '';
  private mLastCaptureIdUri: string = '';

  private jumpType: number = -1;
  private mSubscriber: Unsubscribe | null = null;
  @State lastCameraShotKey: string = '';

  aboutToAppear(): void {
    this.initPhotoBrowser();
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.onCameraStarted.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_PHOTO_BROWSER_ON_BACK_PRESS, this.backPress.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CAMERA_SHOT_KEY, this.onCameraShotKeyChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.SCREEN_LOCKED_STATE, () => {
      this.lastCameraShotKey = '';
    }, this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.BROWSER_ADD_THUMBNAIL, this.onBrowserAddThumbnail.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.BROWSER_UPDATE_THUMBNAIL_ASSET,
      this.onBrowserUpdateThumbnailAsset.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.ROLL_BACK, this.browserRemoveThumbnail.bind(this), this.mBase.hashCode());

    this.mSubscriber = reduxSubscribe(null, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.onCameraShotKeyChange({cameraShotKey: getStates().get<string>('securityCameraReducer', 'cameraShotKey')});
  }

  private onCameraStarted(): void {
    this.mQuickThumbnailMap.clear();
    this.mLastCaptureId = '';
    this.mLastCaptureIdUri = '';
  }

  private onCameraShotKeyChange(data: CameraShotData): void {
    HiLog.i(TAG, 'onCameraShotKeyChange, data.cameraShotKey = ' + data.cameraShotKey,
      'lastCameraShotKey:' + this.lastCameraShotKey);
    // 桌面相机直接息屏拉锁屏相机或锁屏相机界面不退出直接指纹解锁重新解绑绑定大图组件
    // this.browserController.updateCameraShotKey(data.cameraShotKey);
    if ((!this.lastCameraShotKey && data.cameraShotKey) ||
      (!data.cameraShotKey && this.lastCameraShotKey)) {
      // unInitPhotoBrowserController(this.browserController);
      HiLog.i(TAG, 'unInitPhotoBrowserController.');
      // initPhotoBrowserController(this.browserController);
      HiLog.i(TAG, 'initPhotoBrowserController.');
    }
    this.lastCameraShotKey = data.cameraShotKey;
  }

  private onBrowserAddThumbnail(data: ThumbnailObj): void {
    if (!data?.captureId || !data?.thumbnail) {
      return;
    }
    HiLog.i(TAG, `onBrowserAddThumbnail mLastCaptureId: ${data.captureId}.`);
    this.mLastCaptureId = data.captureId;
    try {
      // PhotoBrowserOperation.addThumbnail(this.browserController, this.mLastCaptureId, data.thumbnail);
    } catch (err) {
      HiLog.e(TAG, `addThumbnail err: ${err?.code}.`);
    }
    HiLog.i(TAG, `onBrowserAddThumbnail captureId: ${this.mLastCaptureId}.`);
    this.mQuickThumbnailMap.set(data.captureId, data.thumbnail);
  }

  private onBrowserUpdateThumbnailAsset(data: PhotoAssetObj): void {
    HiLog.i(TAG, `onBrowserUpdateThumbnailAsset data: ${data.captureId}.`);
    if (!data?.captureId || !data?.photoAsset) {
      return;
    }
    if (this.mLastCaptureId === data.captureId) {
      this.mLastCaptureIdUri = data.photoAsset.uri;
    }
    if (!this.mQuickThumbnailMap.get(data?.captureId)) {
      return;
    }
    HiLog.i(TAG, `onBrowserUpdateThumbnailAsset updateThumbnail: ${data.captureId}.`);
    try {
      // PhotoBrowserOperation.updateThumbnail(this.browserController, data.captureId, data.photoAsset);
    } catch (err) {
      HiLog.e(TAG, `updateThumbnail err: ${err?.code}.`);
    }
  }

  private browserRemoveThumbnail(): void {
    if (this.mLastCaptureId !== '') {
      try {
        this.mQuickThumbnailMap.delete(this.mLastCaptureId);
        HiLog.i(TAG, `browserRemoveThumbnail mLastCaptureId: ${this.mLastCaptureId}.`);
        // PhotoBrowserOperation.removeThumbnail(this.browserController, this.mLastCaptureId);
      } catch (err) {
        HiLog.e(TAG, `removeThumbnail err: ${err?.code}.`);
      }
      this.mLastCaptureId = '';
      this.mLastCaptureIdUri = '';
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    if (this.isShowPhotoBrowser) {
      this.resetPhotoBrowserStatus();
      this.photoBrowserReset();
    }
    // unInitPhotoBrowserController(this.browserController);
    // this.browserController.unregisterCallback(JUMP_TYPE);
    this.mSubscriber?.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private backPress(): void {
    // this.browserController.onBackPress();
  }

  private onForeground(): void {
    this.pageStatus = true;
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground E.');
    // const isJumpToPhoto: boolean = this.browserController.getJumpToPhoto();
    // HiLog.i(TAG, `onBackground isJumpToPhoto: ${isJumpToPhoto}`);
    // if (isJumpToPhoto) {
    //   return;
    // }
    this.resetPhotoBrowserStatus();
    this.photoBrowserReset();
  }

  private resetPhotoBrowserStatus(): void {
    HiLog.i(TAG, 'resetPhotoBrowserStatus close photo browser');
    this.pageStatus = false;
    if (this.showPhotoBrowserAction) {
      WindowService.getInstance().setFullScreen();
    }
    PhotoBrowserManager.getInstance().setViewVisibility();

    this.onThumbnailMediaUri();
    // this.browserController.unregisterCallback(BROWSER_FULL_SHOW);
    this.isShowPbInterrupted = this.isRunningAnimation;
    this.isRunningAnimation = false;

    UiUtil.resetGeometryTransitionParamsSize();
    UiUtil.setBorderVisible();

    AppStorage.setOrCreate('isThumbnailOpened', false);

    // this.browserController.cleanSingleGeometryId();

    this.mLastCaptureId = '';
    this.mLastCaptureIdUri = '';
  }

  private photoBrowserReset(): void {
    apsSetScene(TAG, false);
    this.isShowPhotoBrowser = false;
    this.showPhotoBrowserAction = false;
    this.mAction.updatePhotoBrowser(false);
     AppStorage.setOrCreate('isShowThumb', true);
  }

  build() {
    if (this.isShowPhotoBrowser) {
      // PhotoBrowserView({
      //   pageStatus: this.pageStatus,
      //   hidePhotoBrowser: (isPlayAni: boolean) => this.hidePhotoBrowser(isPlayAni),
      //   isRunningAnimation: $isRunningAnimation,
      //   isShowMenu: true,
      //   canPullingUp: true,
      //   isShowThumbSource: true,
      //   isShowImageAnalyzer: true,
      //   pageFrom: PAGE_FROM,
      //   onDeleteAllPhoto: () => this.onDeleteAllPhoto(),
      // }).width('100%')
      //   .height('100%')
    }
  }

  private async initPhotoBrowser(): Promise<void> {
    HiLog.begin(TAG, 'initPhotoBrowser.');
    // initPhotoBrowserController(this.browserController);
    UiUtil.setBorderInvisible();
    // this.browserController.registerCallback(JUMP_TYPE, (jumpType: number):
    //   void => this.onJumpStatusChange(jumpType));
    // this.browserController.setSupportRotation(false);
    HiLog.end(TAG, 'initPhotoBrowser.');
  }

  // 即将拉起大图组件时,根据80分图是否全部落盘完成状态,决定closeCamera时机
  private handleBrowserShowCloseCamera(isNeedWaitCloseCamera: boolean): void {
    if (!isNeedWaitCloseCamera) {
      HiLog.i(TAG, 'handleBrowserShowCloseCamera isNeedWaitCloseCamera false.');
      this.mAction.closeCamera();
      return;
    }
    HiLog.i(TAG, 'handleBrowserShowCloseCamera isNeedWaitCloseCamera true.');
    if (this.waitCapturePhotoTimerId !== Number.MAX_VALUE) {
      clearTimeout(this.waitCapturePhotoTimerId);
      this.waitCapturePhotoTimerId = Number.MAX_VALUE;
    }
    // 超时等待机制
    this.waitCapturePhotoTimerId = setTimeout(() => {
      HiLog.i(TAG, 'handleBrowserShowCloseCamera 3000ms WaitCloseCamera.');
      if (this.isShowPhotoBrowser && !this.isShowPbInterrupted) {
        this.mAction.closeCamera();
      }
    }, 3000);
  }

  // 全部80分图落盘完成时机,立即执行closeCamera
  private handleCapturePhotoComeCloseCamera(): void {
    if (this.waitCapturePhotoTimerId !== Number.MAX_VALUE) {
      clearTimeout(this.waitCapturePhotoTimerId);
      this.waitCapturePhotoTimerId = Number.MAX_VALUE;
    }
    HiLog.i(TAG, 'handleCapturePhotoComeCloseCamera E.');
    if (this.isShowPhotoBrowser && !this.isShowPbInterrupted) {
      this.mAction.closeCamera();
    }
  }

  private showPhotoBrowserOnChange(): void {
    if (!this.showPhotoBrowserAction) {
      return;
    }
    HiLog.i(TAG, `show photo browser: ${this.showPhotoBrowserAction}.`);
    // this.browserController.registerCallback(BROWSER_FULL_SHOW, (isBrowserFullShow: boolean): void => {
    //   HiLog.i(TAG, `browserController onBrowserFullShow, isBrowserFullShow: ${isBrowserFullShow}.`);
    //   if (!isBrowserFullShow) {
    //     PhotoBrowserManager.getInstance().setViewVisibility();
    //   }
    // });
    this.mAction.updatePhotoBrowser(true);
    this.isShowPbInterrupted = false;
    this.isRunningAnimation = true;
    this.isShowPhotoBrowserAnimateEnd = false;
    HiLog.begin(TAG,'setApsSetScene:True');
    apsSetScene(TAG, true);
    this.setCurrentPhoto2ShowPhotoBrowser();
    // this.browserController.setSingleGeometryId(AnimSpecifications.GEOMETRY_TRANSITION_ID_THUMBNAIL);
    // 大图动效
    HiLog.d(TAG, 'start show photo browser animation.');
    FrameLockScene.getInstance().apsSetScene(TAG, true); // 进入页面解除锁帧,trace点之前
    animateToImmediately({
      curve: AnimSpecifications.ANIM_PB_SHARE_OPEN_CURVE,
      onFinish: () => {
        HiLog.end(TAG,'setApsSetScene:True');
        HiLog.d(TAG, `show photo browse animation is interrupted: ${this.isShowPbInterrupted}.`);
        this.isShowPhotoBrowserAnimateEnd = true;
        // 拉起大图被打断场景
        if (!this.isShowPbInterrupted) {
          this.isRunningAnimation = false;
          // this.browserController.cleanSingleGeometryId();
          AppStorage.setOrCreate('isThumbnailOpened', true);
        } else if (this.isHidePhotoBrowserAnimateEnd) {
          // 打断场景，大图返回结束时，打开动效未结束
          this.showPhotoBrowserAction = false;
          this.isRunningAnimation = false;
        }
        HiLog.d(TAG, 'show photo browse onFinish.');
      }
    }, () => {
      UiUtil.resetGeometryTransitionParamsSize();
      UiUtil.setBorderInvisible();
      AppStorage.setOrCreate('isShowThumb', false);
      this.isShowPhotoBrowser = true;
      this.jumpType = -1;
    });

    // 大图背景蒙黑动效
    animateToImmediately({
      duration: AnimSpecifications.ANIM_PB_SHARE_DURATION,
      curve: Curve.Smooth,
      onFinish: () => {
        HiLog.d(TAG, 'show photo browse background view onFinish.');
      }
    }, () => {
      UiUtil.setGeometryTransitionParamsVisible();
    });
  }

  private hidePhotoBrowser(isPlayAni: boolean): void {
    if (!isPlayAni) {
      HiLog.i(TAG, 'hide photo browser isPlayAni true return');
      this.photoBrowserReset();
      return;
    }
    HiLog.i(TAG, 'hide photo browser.');
    this.mLastCaptureId = '';
    this.isShowPbInterrupted = this.isRunningAnimation; // 打断场景
    this.isRunningAnimation = true;
    // this.browserController.unregisterCallback(BROWSER_FULL_SHOW);
    this.isHidePhotoBrowserAnimateEnd = false;
    // this.browserController.setSingleGeometryId(AnimSpecifications.GEOMETRY_TRANSITION_ID_THUMBNAIL);
    AppStorage.setOrCreate('isThumbnailOpened', false);
    HiLog.begin(TAG, 'setApsSetScene: False');
    animateToImmediately({
      curve: AnimSpecifications.ANIM_PB_SHARE_CLOSE_CURVE,
      onFinish: () => {
        HiLog.end(TAG, 'setApsSetScene: False');
        this.isHidePhotoBrowserAnimateEnd = true;
        FrameLockScene.getInstance().apsSetScene(TAG, false); // 退出页面开始锁帧,trace点之后
        if (this.isShowPhotoBrowserAnimateEnd) {
          // 打断场景，大图已返回，并且打开动效已结束
          this.showPhotoBrowserAction = false;
          this.isRunningAnimation = false;
        }
        if (this.jumpType === 2) { // 大图组件回退到相机再触发闪光灯指令下发
          this.mAction.updatePhotoBrowser(false);
        }
        this.mAction.reloadThumbnail();
        // this.browserController.cleanSingleGeometryId();
        WindowService.getInstance().setFullScreen();
        apsSetScene(TAG, false);
        HiLog.d(TAG, 'hide photo browser onFinish.');
      }
    }, () => {
      UiUtil.setBorderVisible();
      UiUtil.setGeometryTransitionParamsInvisible();
      AppStorage.setOrCreate('isShowThumb', true);
      if (this.jumpType === 2) {
        this.mAction.startup();
      }
      this.isShowPhotoBrowser = false;
    });
  }

  private onDeleteAllPhoto(): void {
    HiLog.i(TAG, 'onDeleteAllPhoto E.');
    this.resetPhotoBrowserStatus();
    if (this.jumpType === 2) {
      this.mAction.startup();
    }
  }

  private onThumbnailMediaUri(): void {
    let isSetCapturePhotoMediaUri =
      ThumbnailService.getInstance().isSetCapturePhotoMediaUri(AppStorage.get('thumbnailMediaUri'));
    HiLog.i(TAG, `onThumbnailMediaUri ${isSetCapturePhotoMediaUri},${this.isRunningAnimation},${this.isShowPhotoBrowser}.`);
    if (isSetCapturePhotoMediaUri && (this.isRunningAnimation || this.isShowPhotoBrowser)) {
      this.handleCapturePhotoComeCloseCamera();
    }
  }

  private setCurrentPhoto2ShowPhotoBrowser(): void {
    let isNeedGivePixelMap2Browser = ThumbnailService.getInstance().isNeedGivePixelMap2Browser();
    this.handleBrowserShowCloseCamera(isNeedGivePixelMap2Browser);

    HiLog.i(TAG, `setCurrentPhoto2ShowPhotoBrowser isNeedGivePixelMap2Browser: ${isNeedGivePixelMap2Browser}.`);
    if (isNeedGivePixelMap2Browser && this.mLastCaptureId !== '') {
      HiLog.i(TAG, `setCurrentPhoto2ShowPhotoBrowser captureId: ${this.mLastCaptureId}.`);
      // PhotoBrowserOperation.setCurrentMediaUri(this.browserController, this.mLastCaptureId,
      //   this.mQuickThumbnailMap.get(this.mLastCaptureId));
    } else {
      let curMediaUri: string | undefined = AppStorage.get('thumbnailMediaUri');
      HiLog.i(TAG, `setCurrentPhoto2ShowPhotoBrowser currentUri: ${curMediaUri}.`);
    }
  }

  private onJumpStatusChange(jumpType: number): void {
    HiLog.i(TAG, `onJumpStatusChange, jumpType: ${jumpType}`);
    if (jumpType === PhotoBrowserJumpType.JUMP_TO_GALLERY || jumpType === PhotoBrowserJumpType.BACK) {
      WindowService.getInstance().setFullScreen();
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, false);
    }
    this.jumpType = jumpType;
  }
}