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

// import lazy {
//   initPhotoBrowserController,
//   PhotoBrowserController,
//   unInitPhotoBrowserController
// } from '@photobrowser/browserlibrary';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { ThumbnailAction } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailAction';
import lazy { UiUtil } from '@ohos/common/src/main/ets/animation/UiUtil';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { Dispatch, OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { apsSetScene } from '@ohos/common/src/main/ets/utils/FrameLockSceneUtil';
import lazy { FrameLockScene } from '@ohos/common/src/main/ets/utils/FrameLockScene';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { PhotoBrowserViewLoaderParams, SubScreenPhotoBrowserViewLoaderParams } from './photoBrowserViewLoader';
import lazy { CameraTask, TaskQueue } from '@ohos/common/src/main/ets/utils/TaskQueue';
import lazy { ThumbnailService } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailService';
import lazy { PhotoBrowserManager } from '@ohos/common/src/main/ets/service/photoBrowser/PhotoBrowserManager';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { image } from '@kit.ImageKit';
import lazy { PhotoBrowserOperation } from '@ohos/common/src/main/ets/utils/PhotoBrowserOperation';
import lazy { PhotoBrowserFlowType } from '@ohos/common/src/main/ets/utils/types';
import lazy { execDispatch, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { ComponentAttrUtils, RectInfoInPx } from '@ohos/common/src/main/ets/utils/ComponentAttrUtils';
import lazy { Rect } from '@kit.ArkUI';
import lazy { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';
import lazy { window } from '@kit.ArkUI';
import { PhotoAssetObj, ThumbnailObj } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailInfo';
import lazy {
  CollaborateControlAction
} from '@ohos/common/src/main/ets/service/collaborateControl/CollaborateControlAction'

/* instrument ignore file */
const TAG: string = 'PhotoBrowser';
const JUMP_TYPE: string = 'jump_type';
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

  public updatePhotoBrowser(photoBrowserStatus: boolean, isTriggeredByBack?: boolean): void {
    this.mDispatch(ThumbnailAction.updatePhotoBrowser(photoBrowserStatus, isTriggeredByBack));
  }

  public setTreasureBoxStatus(isOpen: boolean): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(isOpen));
  }

  public setPreviewFrameStart(isFrameStart: boolean): void {
    this.mDispatch(Action.onPreviewFrameStart(isFrameStart));
  }
}

export interface NavigationToPhoto {
  onStart: () => void;
  onFinish: () => void;
}

export interface GridStartParams extends Rect {
  mDirection?: WindowDirection,
  radius?: number,
  borderWidth?: number
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
  @State pageStatus: boolean = true;
  @State isRunningAnimation: boolean = true;
  private mSubscriber: Unsubscribe | null = null;
  private isBrowserFullShow: boolean = false;
  private isCollaborationOpenBefore: boolean = false;
  private mirrorSelfieSwiperIndexBefore: number = 0;
  // 大图组件相关
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
  @StorageLink(`thumnailPixelMap`) thumbnailPixelMap: image.PixelMap | null = null;
  private waitCapturePhotoTimerId: number = Number.MAX_VALUE; // 进入大图浏览等待80分图落盘超时机制
  private mQuickThumbnailMap: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private mLastCaptureId: string = '';
  private mLastCaptureIdUri: string = '';
  private mPhotoBrowserFlowState: number = PhotoBrowserFlowType.CAMERA_STEADY_FLOW; // 相机进大图场景流类型
  private backTime: number = 0;
  private mTaskQueue: TaskQueue = new TaskQueue();
  @State isShowRingLightView: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State lastCameraShotKey: string = '';
  @BuilderParam photoBrowserViewLoader: ($$: PhotoBrowserViewLoaderParams) => void;
  @BuilderParam subScreenPhotoBrowserViewLoader: ($$: SubScreenPhotoBrowserViewLoaderParams) => void;

  private async setPhotoBrowserViewLoader(): Promise<void> {
    try {
      let photoBrowserViewLoader = await import('./photoBrowserViewLoader');
      this.photoBrowserViewLoader = photoBrowserViewLoader.PhotoBrowserViewLoader;
      this.subScreenPhotoBrowserViewLoader = photoBrowserViewLoader.SubScreenPhotoBrowserViewLoader;
      HiLog.i(TAG, 'setPhotoBrowserViewLoader success');
    } catch (error) {
      HiLog.i(TAG, `setPhotoBrowserViewLoader error:${error}`);
    }
  }

  private watchSetPhotoBrowser(): void {
    this.setPhotoBrowserViewLoader();
  }

  aboutToAppear(): void {
    this.watchSetPhotoBrowser();
    AppStorage.setOrCreate('canClickThumbnailView', true); // 大图View加载之后才允许点击操作
    this.initPhotoBrowser();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
      this.mTaskQueue.setDispatch(dispatch);
    });

    const code: string = this.mBase.hashCode();
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), code);
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), code);
    this.mEventBus.on(ActionType.ACTION_PHOTO_BROWSER_ON_BACK_PRESS, this.backPress.bind(this), code);
    this.mEventBus.on(CameraActionType.STARTED, this.onCameraStarted.bind(this), code);
    this.mEventBus.on(ActionType.ACTION_CAMERA_SHOT_KEY, this.onCameraShotKeyChange.bind(this), code);
    this.mEventBus.on(ThumbnailActionType.BROWSER_ADD_THUMBNAIL, this.onBrowserAddThumbnail.bind(this), code);
    this.mEventBus.on(ThumbnailActionType.BROWSER_UPDATE_THUMBNAIL_ASSET,
      this.onBrowserUpdateThumbnailAsset.bind(this), code);
    this.mEventBus.on(ThumbnailActionType.ROLL_BACK, this.browserRemoveThumbnail.bind(this), code);
    this.mEventBus.on(ContextActionType.SCREEN_LOCKED_STATE, () => {
      this.lastCameraShotKey = '';
    }, this.mBase.hashCode());
    this.onCameraShotKeyChange({ cameraShotKey: getStates().get<string>('securityCameraReducer', 'cameraShotKey') });
  }

  private onCameraStarted(): void {
    HiLog.i(TAG, `onCameraStarted`);
    this.mTaskQueue.taskDone();
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
    if (!this.mQuickThumbnailMap.get(data.captureId)) {
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
    AppStorage.setOrCreate('canClickThumbnailView', false);
    this.mSubscriber?.destroy();
    // unInitPhotoBrowserController(this.browserController);
    // this.browserController.unregisterCallback(JUMP_TYPE);
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private backPress(): void {
    // this.browserController.onBackPress();
  }

  private onForeground(): void {
    this.pageStatus = true;
    // const isJumpToPhoto: boolean = this.browserController.getJumpToPhoto();
    // HiLog.i(TAG,`onForeground isJumpToPhoto: ${isJumpToPhoto}`);
    // if (!isJumpToPhoto) {
    //   this.mPhotoBrowserFlowState = PhotoBrowserFlowType.CAMERA_STEADY_FLOW;
    // }
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground E.');
    // this.browserController.pullUpToCamera();
    // const isJumpToPhoto: boolean = this.browserController.getJumpToPhoto();
    // HiLog.i(TAG, `onBackground isJumpToPhoto: ${isJumpToPhoto}`);
    // if (isJumpToPhoto) {
    //   return;
    // }
    this.photoBrowserReset();
    this.resetPhotoBrowserStatus();
  }

  private resetPhotoBrowserStatus(): void {
    HiLog.i(TAG, 'resetPhotoBrowserStatus close photo browser');
    this.pageStatus = false;
    if (this.showPhotoBrowserAction) {
      WindowService.getInstance().setFullScreen();
    }

    if (this.isHalfCollapsLEM) {
      this.mAction.setTreasureBoxStatus(true);
    }
    // this.browserController.unregisterCallback(BROWSER_FULL_SHOW);
    AppStorage.setOrCreate('isThumbnailOpened', false);

    // this.browserController.cleanSingleGeometryId();

    this.mLastCaptureId = '';
    this.mLastCaptureIdUri = '';
  }

  private photoBrowserReset(): void {
    this.isShowPhotoBrowser = false;
    this.showPhotoBrowserAction = false;
    this.mAction.updatePhotoBrowser(false, true);
    AppStorage.setOrCreate('isShowThumb', true);
  }

  private onChangeCollapsStatus(): void {
  }

  build() {
    if (this.isShowPhotoBrowser) {
      if (!AppStorage.get('isLemCollaps')) {
        Column() {
          this.photoBrowserViewLoader({
            pageStatus: this.pageStatus,
            hidePhotoBrowser: (isPlayAni: boolean) => this.hidePhotoBrowser(isPlayAni),
            isRunningAnimation: this.isRunningAnimation,
            isShowMenu: true,
            canPullingUp: true,
            isShowThumbSource: true,
            isShowImageAnalyzer: true,
            onDeleteAllPhoto: () => this.onDeleteAllPhoto(),
            reportStartTime: 0
          })
        }.width('100%')
        .height('100%')
      } else {
        Column() {
          this.subScreenPhotoBrowserViewLoader({
            pageStatus: this.pageStatus,
            hidePhotoBrowser: (isPlayAni: boolean) => this.hidePhotoBrowser(isPlayAni),
            isRunningAnimation: this.isRunningAnimation,
            isShowMenu: false,
            canPullingUp: false,
            isShowThumbSource: false,
            isShowImageAnalyzer: false,
            onDeleteAllPhoto: () => this.onDeleteAllPhoto(),
            enterCount: PreferencesService.getInstance()
              .getPropValue(PersistType.FOREVER, PropTag.ENTER_ROUND_THUMBNAIL_COUNT, 0) as number
          })
        }.width('100%')
        .height('100%')
      }
    }
  }

  private async initPhotoBrowser(): Promise<void> {
    HiLog.begin(TAG, 'initPhotoBrowser');
    // initPhotoBrowserController(this.browserController);
    UiUtil.setBorderInvisible();
    // this.browserController?.initCameraAnim(this.onEnter, this.onExit, this.getGridStartParams);
    // this.browserController.registerCallback(JUMP_TYPE, (jumpType: number, backTime: number):
    //   void => this.onJumpStatusChange(jumpType, backTime));
    // this.browserController.setSupportRotation(!getStates().get<boolean>('collapsReducer', 'isShowLandscape'));
    HiLog.end(TAG, 'initPhotoBrowser');
  }

  // 即将拉起大图组件时,根据80分图是否全部落盘完成状态,决定closeCamera时机
  private handleBrowserShowCloseCamera(isNeedWaitCloseCamera: boolean): void {
    if (!isNeedWaitCloseCamera || ThumbnailService.getInstance().isOfflineSupported()) { // 离线拍照不需要等待
      HiLog.i(TAG, 'handleBrowserShowCloseCamera isNeedWaitCloseCamera false.');
      this.mPhotoBrowserFlowState = PhotoBrowserFlowType.CLOSE;
      this.mTaskQueue.addTask(CameraTask.CLOSE);
      return;
    }
    HiLog.i(TAG, 'handleBrowserShowCloseCamera isNeedWaitCloseCamera true.');
    if (this.waitCapturePhotoTimerId !== Number.MAX_VALUE) {
      clearTimeout(this.waitCapturePhotoTimerId);
      this.waitCapturePhotoTimerId = Number.MAX_VALUE;
    }
    // 超时等待机制
    this.waitCapturePhotoTimerId = setTimeout(() => {
      HiLog.i(TAG, `handleBrowserShowCloseCamera 3000ms WaitCloseCamera, FlowState: ${this.mPhotoBrowserFlowState}.`);
      if (this.isShowPhotoBrowser && this.mPhotoBrowserFlowState === PhotoBrowserFlowType.CAMERA_STEADY_FLOW) {
        this.mPhotoBrowserFlowState = PhotoBrowserFlowType.CLOSE;
        this.mTaskQueue.addTask(CameraTask.CLOSE);
      }
      this.waitCapturePhotoTimerId = Number.MAX_VALUE;
    }, 3000);
  }

  // 全部80分图落盘完成时机,立即执行closeCamera
  private handleCapturePhotoComeCloseCamera(): void {
    if (this.waitCapturePhotoTimerId !== Number.MAX_VALUE) {
      clearTimeout(this.waitCapturePhotoTimerId);
      this.waitCapturePhotoTimerId = Number.MAX_VALUE;
    }
    HiLog.i(TAG, `handleCapturePhotoComeCloseCamera E, FlowState: ${this.mPhotoBrowserFlowState}.`);
    if (this.isShowPhotoBrowser && this.mPhotoBrowserFlowState === PhotoBrowserFlowType.CAMERA_STEADY_FLOW) {
      this.mPhotoBrowserFlowState = PhotoBrowserFlowType.CLOSE;
      this.mTaskQueue.addTask(CameraTask.CLOSE);
    }
  }

  private onEnter: NavigationToPhoto = {
    onStart: () => {
      HiLog.i(TAG, 'photoBrowser animate enterOnStart.');

      AppStorage.setOrCreate('isShowThumb', false);
      AppStorage.setOrCreate('isThumbnailOpened', true);

      apsSetScene(TAG, true); // 进入页面开始锁帧,trace点之前
      FrameLockScene.getInstance().apsSetScene(TAG, true); // 进入页面解除锁帧,trace点之前
    },
    onFinish: () => {
      HiLog.i(TAG, 'photoBrowser animate enterOnEnd.');
      if (DeviceInfo.isPhone()) {
        PhotoBrowserManager.getInstance().setViewHidden();
      }
    }
  }
  private onExit: NavigationToPhoto = {
    onStart: () => {
      HiLog.i(TAG, 'photoBrowser animate exitOnStart X.');
      if (DeviceInfo.isPhone() && !getStates().get<boolean>('contextReducer', 'isViewVisibility')) {
        PhotoBrowserManager.getInstance().setViewVisibility();
      }
      AppStorage.setOrCreate('isShowThumb', true);
      HiLog.i(TAG, 'photoBrowser animate exitOnStart E.');
    },
    onFinish: () => {
      HiLog.i(TAG, 'photoBrowser animate exitOnEnd.');
      this.isShowPhotoBrowser = false;

      this.showPhotoBrowserAction = false;
      AppStorage.setOrCreate('isThumbnailOpened', false);
      apsSetScene(TAG, false); // 退出页面结束锁帧,trace点之后
      FrameLockScene.getInstance().apsSetScene(TAG, false); // 退出页面开始锁帧,trace点之后
      this.mPhotoBrowserFlowState = PhotoBrowserFlowType.CAMERA_STEADY_FLOW;
      this.mAction.updatePhotoBrowser(false);
      this.mAction.reloadThumbnail();
      HiLog.d(TAG, 'hide photo browser onFinish.');
      HiLog.i(TAG, `isCollaborationOpenBefore : ${this.isCollaborationOpenBefore}`);
      if (this.isCollaborationOpenBefore) {
        HiLog.i(TAG, 'mirror selfie reLoadToIndex before photoBrowser open');
        AppStorage.setOrCreate('reloadMirrorSwiperItemToIndex', true);
      }
    }
  }
  private getGridStartParams = (): GridStartParams => {
    let rect: RectInfoInPx =
      ComponentAttrUtils.getRectInfoByIdWithTransform(this.getUIContext(), ComponentIdKeys.THUMBNAIL_STACK_COLUMN);
    let mDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
    const isLockOrientation: boolean = getStates().get<string>('windowReducer', 'rotationStatus') === '0'; //锁定方向
    let screenWidth = WindowService.getInstance().getWindowRect().width;
    let screenHeight = WindowService.getInstance().getWindowRect().height;
    HiLog.i(TAG, `rect left: ${rect.left}, right: ${rect.right}, top: ${rect.top} bottom: ${rect.bottom},
     mDirection: ${mDirection} screenWidth: ${screenWidth}, screenHeight: ${screenHeight}`);
    return {
      left: rect.left,
      right: rect.right,
      top: rect.top,
      bottom: rect.bottom,
      radius: rect.width / 2,
      borderWidth: 1.5,
      mDirection: mDirection
    }
  }

  // 注册监听: 即将退出大图组件显示相机页面时机,执行openCamera
  private registerBrowserHideOpenCamera(): void {
    HiLog.i(TAG, 'registerBrowserHideOpenCamera E.');
    // this.browserController.registerCallback(BROWSER_FULL_SHOW, (isBrowserFullShow: boolean): void => {
    //   HiLog.i(TAG, `browserController onBrowserFullShow, isBrowserFullShow: ${isBrowserFullShow}.`);
    //   this.isBrowserFullShow = isBrowserFullShow;
    //   if (isBrowserFullShow) {
    //     if (this.waitCapturePhotoTimerId !== Number.MAX_VALUE) {
    //       clearTimeout(this.waitCapturePhotoTimerId);
    //       this.waitCapturePhotoTimerId = Number.MAX_VALUE;
    //     }
    //     if (this.mPhotoBrowserFlowState !== PhotoBrowserFlowType.CLOSE) { // 避免重复close
    //       this.mTaskQueue.addTask(CameraTask.CLOSE);
    //     }
    //     this.mPhotoBrowserFlowState = PhotoBrowserFlowType.CLOSE; // 进入此处代表后续为close状态
    //     return;
    //   }
    //   if (this.waitCapturePhotoTimerId != Number.MAX_VALUE) {
    //     clearTimeout(this.waitCapturePhotoTimerId);
    //     this.waitCapturePhotoTimerId = Number.MAX_VALUE;
    //     PhotoBrowserManager.getInstance().setViewVisibility();
    //     StoreManager.getInstance().postMessage(Action.onPreviewFrameStart(true));
    //     HiLog.i(TAG, 'in 3s waiting time, no need to open camera again');
    //     return;
    //   }
    //   PhotoBrowserManager.getInstance().setViewVisibility();
    //   if (this.mPhotoBrowserFlowState === PhotoBrowserFlowType.CLOSE) { // 避免重复启流
    //     this.mTaskQueue.addTask(CameraTask.OPEN);
    //   } else {
    //     this.mAction.setPreviewFrameStart(true);
    //   }
    //   this.mPhotoBrowserFlowState = PhotoBrowserFlowType.BROWSER_NOT_FULL_TRANSIENT; // 进入此处代表后续应为非全屏启流暂态
    // });
  }

  private async showPhotoBrowserOnChange(): Promise<void> {
    // this.browserController.setSupportRotation(!getStates().get<boolean>('collapsReducer', 'isShowLandscape'));
    StoreManager.getInstance().postMessage(CollaborateControlAction.photoBrowser(this.showPhotoBrowserAction));
    if (!this.showPhotoBrowserAction) {
      return;
    }
    HiLog.i(TAG, `show photo browser: ${this.showPhotoBrowserAction}.`);
    this.setCurrentPhoto2ShowPhotoBrowser(); // 关闭相机
    this.doShowPhotoBrowser();
  }

  private doShowPhotoBrowser() {
    this.registerBrowserHideOpenCamera();
    this.isShowPhotoBrowser = true;
    setTimeout((): void => {
      this.mAction.updatePhotoBrowser(true);
    }, 50);
  }

  private reSetWinOrientation(): void {
    HiLog.i(TAG, 'reSetWinOrientation');
    const isShowLandscape = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const isShowSemiCollapsed = getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    if (isShowLandscape && isShowSemiCollapsed) { //半折态
      WindowService.getInstance().setWinOrientation(window.Orientation.PORTRAIT);
    } else {
      WindowService.getInstance().setWinOrientation(window.Orientation.FOLLOW_DESKTOP);
    }
  }

  private hidePhotoBrowser(isPlayAni: boolean): void {
    this.reSetWinOrientation();
    if (!isPlayAni) {
      HiLog.i(TAG, 'hide photo browser isPlayAni true return');
      this.photoBrowserReset();
      return;
    }
    HiLog.i(TAG, 'hide photo browser.');
    this.mLastCaptureId = '';
    this.mLastCaptureIdUri = '';
    // this.browserController.unregisterCallback(BROWSER_FULL_SHOW);
    if (this.isHalfCollapsLEM) {
      this.mAction.setTreasureBoxStatus(true);
    }
  }

  private onDeleteAllPhoto(): void {
    HiLog.i(TAG, 'onDeleteAllPhoto E.');
    this.resetPhotoBrowserStatus();
  }

  private onThumbnailMediaUri(): void {
    let isSetCapturePhotoMediaUri =
      ThumbnailService.getInstance().isSetCapturePhotoMediaUri(AppStorage.get('thumbnailMediaUri'));
    HiLog.i(TAG,
      `onThumbnailMediaUri ${isSetCapturePhotoMediaUri},${this.isShowPhotoBrowser}.`);
    if (isSetCapturePhotoMediaUri && this.isShowPhotoBrowser) {
      this.handleCapturePhotoComeCloseCamera();
    }
  }

  private setCurrentPhoto2ShowPhotoBrowser(): void {
    let isNeedGivePixelMap2Browser = ThumbnailService.getInstance().isNeedGivePixelMap2Browser();
    this.handleBrowserShowCloseCamera(isNeedGivePixelMap2Browser);

    HiLog.i(TAG, `setCurrentPhoto2ShowPhotoBrowser isNeedGivePixelMap2Browser: ${isNeedGivePixelMap2Browser}.`);
    if (isNeedGivePixelMap2Browser && this.mLastCaptureId !== '') {
      HiLog.i(TAG,
        `setCurrentPhoto2ShowPhotoBrowser captureId: ${this.mLastCaptureId}. mQuickThumbnailMap.keys: ${this.mQuickThumbnailMap.keys()}.`);
      // PhotoBrowserOperation.setCurrentMediaUri(this.browserController, this.mLastCaptureId,
      //   this.mQuickThumbnailMap.get(this.mLastCaptureId));
    } else {
      let curMediaUri: string | undefined = AppStorage.get('thumbnailMediaUri');
      HiLog.i(TAG, `setCurrentPhoto2ShowPhotoBrowser currentUri: ${curMediaUri}.`);
      // PhotoBrowserOperation.setCurrentMediaUri(this.browserController, curMediaUri, this.thumbnailPixelMap)
    }
  }

  private onJumpStatusChange(jumpType: number, backTime: number): void {
    HiLog.i(TAG, `onJumpStatusChange, jumpType: ${jumpType}, backTime: ${backTime}`);
    this.backTime = backTime;
    if (jumpType === PhotoBrowserJumpType.JUMP_TO_GALLERY || jumpType === PhotoBrowserJumpType.BACK) {
      WindowService.getInstance().setFullScreen();
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, false);
    }
    if (jumpType === PhotoBrowserJumpType.JUMP_TO_GALLERY) {
      apsSetScene(TAG, false); // 大图跳转图库包名结束锁帧,规避aps按包名切换场景
    }
  }
}