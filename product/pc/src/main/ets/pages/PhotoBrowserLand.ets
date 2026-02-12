/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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

import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
// import {
//   initPhotoBrowserController,
//   PhotoBrowserController,
//   unInitPhotoBrowserController,
//   PhotoBrowserViewPC
// } from '@photobrowser/browserlibrary';
import { UiUtil } from '@ohos/common/src/main/ets/animation/UiUtil';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { ThumbnailAction, } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailAction';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import MediaLibraryUiService from '@ohos/common/src/main/ets/service/medialibrary/MediaLibraryUiService';
import { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { execDispatch } from '@ohos/common/src/main/ets/redux';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import { window } from '@kit.ArkUI';

const TAG: string = 'PhotoBrowserLand';
const BROWSER_FULL_SHOW: string = 'browser_full_show';

@Builder
export function PhotoBrowserLoader() {
  PhotoBrowserLand()
}

@Entry
@Component
struct PhotoBrowserLand {
  private mBase: BaseComponent = new BaseComponent();
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private isShowPhotoBrowserAnimateEnd: boolean = true;
  private isHidePhotoBrowserAnimateEnd: boolean = true;
  // 大图组件相关
  // @Provide browserController: PhotoBrowserController = new PhotoBrowserController(
  //   ContextManager.getInstance().getAbilityContext(),
  //   GlobalContext.get().getWindowStage(),
  //   ContextManager.getInstance().getAbilityStageContext());
  @StorageLink('showPhotoBrowserAction') @Watch('showPhotoBrowserOnChange') showPhotoBrowserAction: boolean = false;
  @StorageLink('isShowPhotoBrowser') showPhotoBrowser: boolean = false; // 控制大图组件UI开关
  @State pageStatus: boolean = false;
  @State isRunningAnimation: boolean = false;
  private isShowPbInterrupted: boolean = false;
  @StorageLink('thumbnailMediaUri') @Watch('thumbnailUpdate') thumbnailMediaUri: string = '';
  // 用于判断，当前主界面切后台后，是否需要退出当前大图页面
  @StorageLink('isBackground') needDisappearBrowserWhenPhotoBrowserHided: boolean = false;

  aboutToAppear(): void {
    HiLog.begin(TAG, 'aboutToAppear');
    this.initPhotoBrowser();
    AppStorage.setOrCreate('canClickThumbnailView', true);

    this.eventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.eventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.photoBrowserBackCamera.bind(this),
      this.mBase.hashCode());
    this.eventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.eventBus.on(ActionType.ACTION_PHOTO_BROWSER_ON_BACK_PRESS, this.backPress.bind(this), this.mBase.hashCode());
    HiLog.end(TAG, 'aboutToAppear');
  }

  aboutToDisappear(): void {
    this.eventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear E.');
    if (this.showPhotoBrowser) {
      this.pageStatus = false;
      // this.browserController.onBackground();
      // this.browserController.unregisterCallback(BROWSER_FULL_SHOW);
      this.isShowPbInterrupted = this.isRunningAnimation;
      this.isRunningAnimation = false;
      this.showPhotoBrowser = false;
      UiUtil.resetGeometryTransitionParamsSize();
      AppStorage.setOrCreate('isThumbnailOpened', false);
      this.showPhotoBrowserAction = false;
      execDispatch(ThumbnailAction.updatePhotoBrowser(false));
      execDispatch(ThumbnailAction.refresh());
      // this.browserController.cleanSingleGeometryId();
    }
    // unInitPhotoBrowserController(this.browserController);
  }

  private backPress(): void {
    HiLog.i(TAG, 'backPress begin.');
    if (this.showPhotoBrowser) {
      HiLog.i(TAG, 'browserController backPress');
      // this.browserController.onBackPress();
    }
  }

  private onForeground(): void {
    this.pageStatus = true;
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground E.');
    this.showPhotoBrowser = false;
    this.pageStatus = false;
    this.showPhotoBrowserAction = false;
    // this.browserController.onBackground();
    HiLog.i(TAG, 'onBackground close photo browser on background');
    // this.browserController.unregisterCallback(BROWSER_FULL_SHOW);
    this.isShowPbInterrupted = this.isRunningAnimation;
    this.isRunningAnimation = false;
    UiUtil.resetGeometryTransitionParamsSize();
    AppStorage.setOrCreate('isThumbnailOpened', false);
    execDispatch(ThumbnailAction.updatePhotoBrowser(false));
    execDispatch(ThumbnailAction.refresh());
     AppStorage.setOrCreate('isShowThumb', true);
    // this.browserController.cleanSingleGeometryId();
    HiLog.i(TAG, 'onBackground X.');
  }

  private photoBrowserBackCamera(data: ActionData): void {
    HiLog.i(TAG, 'photoBrowserBackCamera E.');
    if (data['windowStageEventType'] === window.WindowStageEventType.HIDDEN && this.showPhotoBrowser) {
      this.onBackground();
    }
    HiLog.i(TAG, 'photoBrowserBackCamera X.');
  }

  build() {
    if (this.showPhotoBrowser) {
      // PhotoBrowserViewPC({
      //   pageStatus: this.pageStatus,
      //   hidePhotoBrowser: () => this.hidePhotoBrowser(),
      //   isRunningAnimation: $isRunningAnimation,
      //   isShowMenu: true,
      //   canPullingUp: true,
      //   isShowThumbSource: true,
      //   isShowImageAnalyzer: true
      // }).width('100%')
      //   .height('100%')
    }
  }

  private async initPhotoBrowser(): Promise<void> {
    HiLog.begin(TAG, 'initPhotoBrowser.');
    // initPhotoBrowserController(this.browserController);
    UiUtil.setBorderInvisible();
    const mediaUri = await MediaLibraryUiService.getInstance().getLastFileUri();
    // this.browserController.setCurrentMediaUri(mediaUri);
    AppStorage.setOrCreate('canClickThumbnailView', true);
    HiLog.end(TAG, 'initPhotoBrowser.');
  }

  // 大图背景蒙黑动效
  private blackMaskAnimate(isClose: boolean) {
    animateToImmediately({
      duration: AnimSpecifications.ANIM_PB_SHARE_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        HiLog.i(TAG, 'close photo browse background view onFinish.');
      }
    }, () => {
      if (isClose) {
        UiUtil.setGeometryTransitionParamsVisible();
      } else {
        UiUtil.setGeometryTransitionParamsInvisible();
      }
    });
  }

  private showPhotoBrowserOnChange(): void {
    HiLog.i(TAG, `show photo browser:${this.showPhotoBrowserAction}`);
    if (this.showPhotoBrowserAction) {
      this.isRunningAnimation = true;
      this.isShowPbInterrupted = false;
      this.isShowPhotoBrowserAnimateEnd = false;
      WindowService.getInstance().setDecorButtonStyle(true);
      AppStorage.setOrCreate('isHideWindowBar', true);
      // this.browserController.setSingleGeometryId(AnimSpecifications.GEOMETRY_TRANSITION_ID_THUMBNAIL);
      this.handleCameraCloseOpen();
      // 大图动效
      HiLog.i(TAG, 'start show photo browser animation.');
      animateToImmediately({
        curve: AnimSpecifications.ANIM_PB_SHARE_OPEN_CURVE,
        duration: 550,
        onFinish: () => {
          HiLog.i(TAG, `show photo browse animation is interrupted:${this.isShowPbInterrupted}.`);
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
          HiLog.i(TAG, 'show photo browse onFinish.');
        }
      }, () => {
        UiUtil.resetGeometryTransitionParamsSize();
        UiUtil.setBorderInvisible();
        AppStorage.setOrCreate('isShowThumb', false);
        this.showPhotoBrowser = true;
      });

      // 大图背景蒙黑动效
      this.blackMaskAnimate(true);
    }
  }

  private handleCameraCloseOpen(): void {
    execDispatch(CameraAction.close({ isNeedSaveRestore: true, isEnterPhotoBrowser: true }));
    // this.browserController.registerCallback(BROWSER_FULL_SHOW, (isBrowserFullShow: boolean): void => {
    //   HiLog.i(TAG, `browserController onBrowserFullShow, isBrowserFullShow: ${isBrowserFullShow}`);
    //   if (isBrowserFullShow) {
    //     return;
    //   }
    //   execDispatch(CameraAction.warmStart());
    // });
  }

  private hidePhotoBrowser(): void {
    HiLog.i(TAG, 'hide photo browser.');
    this.isShowPbInterrupted = this.isRunningAnimation; // 打断场景
    this.isRunningAnimation = true;
    this.isHidePhotoBrowserAnimateEnd = false;
    // this.browserController.unregisterCallback(BROWSER_FULL_SHOW);
    // this.browserController.setSingleGeometryId(AnimSpecifications.GEOMETRY_TRANSITION_ID_THUMBNAIL);
    WindowService.getInstance().setDecorButtonStyle(false);
    WindowService.getInstance().setWindowDecorVisiblePc(false);
    AppStorage.setOrCreate('isHideWindowBar', false);
    AppStorage.setOrCreate('isThumbnailOpened', false);
    HiLog.begin(TAG, 'hide photoBrowser animate');
    animateToImmediately({
      curve: AnimSpecifications.ANIM_PB_SHARE_CLOSE_CURVE,
      onFinish: () => {
        HiLog.end(TAG, 'hide photoBrowser animate');
        this.isHidePhotoBrowserAnimateEnd = true;
        if (this.isShowPhotoBrowserAnimateEnd) {
          // 打断场景，大图已返回，并且打开动效已结束
          this.showPhotoBrowserAction = false;
          this.isRunningAnimation = false;
        }
        execDispatch(ThumbnailAction.refresh());
        // this.browserController.cleanSingleGeometryId();
        this.thumbnailUpdate();
        HiLog.d(TAG, 'hide photo browser onFinish.');
      }
    }, () => {
      UiUtil.setBorderVisible();
      AppStorage.setOrCreate('isShowThumb', true);
      this.showPhotoBrowser = false;
    });

    // 大图背景蒙黑动效
    this.blackMaskAnimate(false);
  }

  private async thumbnailUpdate(): Promise<void> {
    HiLog.iWithUri(TAG, `thumbnailUpdate thumbnail mediaUri: ${this.thumbnailMediaUri}.`);
    if (this.thumbnailMediaUri && !this.showPhotoBrowser) {
      // this.browserController.setCurrentMediaUri(this.thumbnailMediaUri);
    }
  }
}