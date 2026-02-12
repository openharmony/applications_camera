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

import lazy { Dispatch, OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { ViewRotateTranslate } from '@ohos/common/src/main/ets/utils/ViewRotateTranslate';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { NavDestinationTitle } from '@ohos/common/src/main/ets/component/NavDestinationTitle/NavDestinationTitle';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import screenLock from '@ohos.screenLock';
import lazy { BusinessError } from '@ohos.base';
import lazy { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';

/* instrument ignore file */
const TAG: string = 'AppLockThumbnailReminder';

const ROTATE_ANGLE_90: number = 90;
const PADDING_RIGHT_24: number = 24;
const TOP_HOLE: number = 36;
const OFFSET_0: number = 0;
const OPACITY_SHOW: number = 1;

class ThumbnailViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public showAppLockReminder(isShow: boolean): void {
    this.mDispatch(Action.showAppLockReminder(isShow));
  }
}

@Component
export struct AppLockThumbnailReminder {
  private readonly ANIMATION_DURATION_420: number = 420;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State isShowLandscape: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State titleOpacity: number = OPACITY_SHOW;
  @State backButtonOpacity: number = OPACITY_SHOW;
  @State translateTitle: number | string = OFFSET_0;
  @State @Watch('rotateChange') rotateAngle: number = 0;
  @State rotateAngleDuration: number = this.ANIMATION_DURATION_420;
  @State animationIsExit: boolean = false;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State mGutter: number = 12; //列间距
  private mAction: ThumbnailViewDispatcher = new ThumbnailViewDispatcher();
  private lastRotateAngle: number = 0;
  private readonly ANIMATION_DURATION_840: number = 840;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mBase: BaseComponent = new BaseComponent();
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();

  aboutToDisappear(): void {
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  @Builder
  title() {
    NavDestinationTitle({
      mDirection: this.mDirection,
      isShowLandscape: this.isShowLandscape,
      isShowSemiCollapsed: this.isShowSemiCollapsed,
      isTablet: false,
      titleOpacity: this.titleOpacity,
      backButtonOpacity: this.backButtonOpacity,
      translateTitle: this.translateTitle,
      clickFunction: () => {
        HiLog.i(TAG, `thumbnailReminder:onClick`);
        this.mAction.showAppLockReminder(false);
      }
    })
      .zIndex(ZIndex.TOP)
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
  }

  /* instrument ignore file */
  private rotateChange() {
    HiLog.i(TAG, 'rotateChange E.');
    if ((this.rotateAngle - this.lastRotateAngle) % AnimSpecifications.ANIM_ROTATE_180 === 0) {
      this.rotateAngleDuration = this.ANIMATION_DURATION_840;
    } else {
      this.rotateAngleDuration = this.ANIMATION_DURATION_420;
    }
    this.lastRotateAngle = this.rotateAngle;
    HiLog.i(TAG, 'rotateChange X.');
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private getPageLeft(): number {
    return this.isShowSemiCollapsed ? 0 : this.mDirection === WindowDirection.RIGHT ? TOP_HOLE : 0;
  }

  private getPageTop(): number {
    return this.isShowSemiCollapsed ? this.windowWidth / 2 + 12 : this.isVertical() ? TOP_HOLE : 0;
  }

  private getViewWidth(): number {
    return this.isShowSemiCollapsed ? this.windowHeight : this.isVertical() ? this.windowWidth : this.windowHeight;
  }

  private getViewHeight(): number {
    return this.isShowSemiCollapsed ? this.windowWidth : this.isVertical() ? this.windowHeight : this.windowWidth;
  }

  private getTranslateX(): number {
    return this.isShowSemiCollapsed ?
    ViewRotateTranslate.getTranslateSize(this.windowHeight, this.windowWidth)
      .translateX :
      this.isVertical() ? 0 :
      ViewRotateTranslate.getTranslateSize(this.windowHeight, this.windowWidth).translateX;
  }

  private getTranslateY(): number {
    return this.isShowSemiCollapsed ? 42 :
      this.isVertical() ? 0 :
      ViewRotateTranslate.getTranslateSize(this.windowHeight, this.windowWidth).translateY;
  }

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      if (WindowService.getInstance().isSubscriptionNeeded() && !this.animationIsExit) {
        this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
        this.rotateAngle = state.get<number>('contextReducer', 'settingAngle');
      }
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    if (this.isShowLandscape) {
      this.mGutter = PADDING_RIGHT_24;
    }
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 返回标题栏
        Column() {
          this.title()
        }
        .width('100%')
        .flexShrink(0)
        .padding({ top: this.getPageTop(), left: this.getPageLeft() })
        .zIndex(2)

        // 中间内容
        Column() {
          Scroll() {
            Column() {
              // 图标
              Image($r('app.media.security_icon'))
                .width(72)
                .height(72)
                .draggable(false)
                .fillColor('#99FFFFFF')
              // 灰色文字
              Text($r('app.string.camera_app_lock_tip'))
                .margin({
                  top: 8,
                  bottom: 4
                })
                .textAlign(TextAlign.Center)
                .fontColor('#99FFFFFF')
                .fontSize(16)
                .maxFontScale(2)
              // 蓝色文字
              Text($r('app.string.camera_app_lock_go_to_photo'))
                .fontColor('#5291FF')
                .fontSize(16)
                .maxFontScale(2)
                .fontWeight(FontWeight.Medium)
                .onClick((): void => {
                  if (screenLock.isLocked()) {
                    screenLock.unlock().then((data: Boolean) => {
                      HiLog.i(TAG, `Succeeded in unlocking the screen. result: ${data}`);
                      if (data) {
                        let param: Want = {
                          bundleName: 'com.ohos.photos',
                          abilityName: 'com.ohos.photos.MainAbility',
                        };
                        HiLog.i(TAG, `routeToTimelinePage parm: ${JSON.stringify(param)}`);
                        try {
                          ContextManager.getInstance().getAbilityContext().startAbility(param, (error) => {
                            if (error && error.code !== 0) {
                              HiLog.e(TAG, `startAbility fail, error: ${error?.code}`);
                            } else {
                              HiLog.i(TAG, `routeToTimelinePage parm: ${JSON.stringify(param)}`);
                            }
                          });
                        } catch (error) {
                          HiLog.e(TAG, `startAbility fail, error: ${error?.code}`);
                        }
                      }
                    }).catch((err: BusinessError) => {
                      HiLog.e(TAG, `Failed to unlock the screen, Code: ${err?.code}`);
                    });
                  } else {
                    let param: Want = {
                      bundleName: 'com.ohos.photos',
                      abilityName: 'com.ohos.photos.MainAbility',
                    };
                    HiLog.i(TAG, `routeToTimelinePage parm: ${JSON.stringify(param)}`);
                    try {
                      ContextManager.getInstance().getAbilityContext().startAbility(param, (error) => {
                        if (error && error.code !== 0) {
                          HiLog.e(TAG, `startAbility fail, error: ${error?.code}`);
                        } else {
                          HiLog.i(TAG, `routeToTimelinePage parm: ${JSON.stringify(param)}`);
                        }
                      });
                    } catch (error) {
                      HiLog.e(TAG, `startAbility fail, error: ${error?.code}`);
                    }
                  }
                })
            }
          }
          .width('100%')

        }
        .layoutWeight(1)
        .height('100%')
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .padding({
          top: this.getPageTop(),
          left: 24,
          right: 24,
          bottom: this.getPageTop()
        })
        .zIndex(1)

      }
      .layoutWeight(1)

    }
    .width(this.getViewWidth())
    .height(this.getViewHeight())
    .backgroundColor(Color.Black)
    .rotate({
      angle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : this.rotateAngle
    })
    .animation(
      {
        duration: this.rotateAngleDuration,
        curve: Curve.Sharp,
        iterations: 1,
        playMode: PlayMode.Normal,
        onFinish: () => {
          HiLog.i(TAG, 'animation onFinish');
          AppStorage.setOrCreate('settingAnimationDoing', false);
        }
      })
    .translate({
      x: this.getTranslateX(),
      y: this.getTranslateY(),
    })

  }
}