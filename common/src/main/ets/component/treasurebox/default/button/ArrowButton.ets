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

import lazy { lottie, AnimationItem} from '../../../../utils/LazyImportUtil';
import lazy { RecordingState } from '../../../../function/recordcontrol/RecordAction';
import lazy { Dispatch, getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../../redux/index';
import lazy { PersistType, PreferencesService } from '../../../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../../../service/preferences/PropTag';
import lazy { AdaptiveLayoutService, ARROW_HEIGHT } from '../../../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { ComponentIdKeys } from '../../../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../../../utils/HiLog';
import lazy { ZIndex } from '../../../../utils/ZIndex';
import lazy { TreasureBoxAction } from '../../reduce/TreasureBoxAction';
import window from '@ohos.window';
import lazy { EventBus } from '../../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../../../worker/BaseComponent';
import lazy { WindowEventData } from '../../../../utils/types';
import lazy { ActionData } from '../../../../redux/actions/Action';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../../../mode/ModeType';
import lazy { CommonConstants } from '../../../../statistics/CommonConstants';
import lazy { AccessibilityUtils } from '../../../../utils/AccessibilityUtils';
import ResGetter from '../../../../utils/ResGetter';
import lazy { GlobalContext } from '../../../../utils/GlobalContext';
import lazy { FunctionId } from '../../../../function/core/functionproperty/FunctionId';
import lazy { TREASURE_BOX_TAG, } from '../TreasureBox';
import lazy { ActionType } from '../../../../redux/actions/ActionType';
import lazy { ContextActionType } from '../../../../redux/actions/ContextActionType';

/* instrument ignore file */
const TAG: string = 'ArrowButton';
const ARROW_WIDTH: number = 60;
const ARROW_LOOP_SHOW_COUNT = 5;
const ARROW_LOOP_PLAY_COUNT = 3;
const RING_OPACITY_TIME_DELAY: number = 3000;
const SLIDER_OPEN: string = 'sliderOpen';
const ARROW_LOOP: string = 'arrowLoop';
const SLIDER_OPEN_PATH: string = 'common/lottie/treasure_box_slider_open.json';
const SLIDER_RING_OPEN_PATH: string = 'common/lottie/treasure_box_ring_slider_open.json';
const ARROW_LOOP_PATH: string = 'common/lottie/arrow_notification_loop.json';

const OPEN_ANIMATE_DURING: number = 500;

@Component
export struct ArrowButton {
  // 全局数据与事件通知
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mDispatch: Dispatch = (data) => data;
  // lottie组件
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private loopController: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private sliderController: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private sliderOpenItem: AnimationItem | undefined = undefined;
  private arrowLoopItem: AnimationItem | undefined = undefined;
  // 动效相关继承数据
  private uncollapsBegin: (isShow: boolean) => void = () => {
  };
  private uncollapsEnd: (isShow: boolean) => void = () => {
  };
  @Link transDistance: number;
  @Link treasureBoxOpacity: number;
  // 关键标志位流程控制
  @State @Watch('uncollapsTreasureBox') isOpen: boolean = false;
  @State isShowArrowLoop: boolean = false;
  @State isUpwardArrow: boolean = true;
  @State isCustomFilterButtonShow: boolean = false;
  // StorageLink触发全局事件
  @StorageLink('isPanGestureDoing') isPanGestureDoing: boolean = false;
  @StorageLink('isProShutterCaptureState') isProShutterCapture: boolean = false;
  @StorageLink('showPhotoBrowserAction') showPhotoBrowserAction: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  // 业务数据
  private arrowPlayCount: number = 0;
  private uiEnable: boolean = true;
  private isOpened: boolean = false;
  // 环形补光相关
  @State isShowRingLightView: boolean = false;
  @State isShowRingIconOpacity: boolean = false;
  private ringOpacityTimer: number = Number.MIN_VALUE;
  private isPicker: boolean = GlobalContext.get().getIsPicker();
  private lottieName: string = '';
  functionId: FunctionId = FunctionId.NONE;
  private animationTimer:  number = Number.MIN_VALUE;

  aboutToAppear() {
    this.isShowArrowLoop = this.checkArrowLoopShow();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isOpen = state.get<boolean>('treasureBoxReducer', 'isOpen');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, (dispatch: Dispatch): void => {
      this.mDispatch = dispatch;
    });
    this.handleRingArrowOpacity();
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, (data: WindowEventData) => {
      if (data.windowStageEventType === window.WindowStageEventType.RESUMED && !this.isHalfCollapsLEM) {
        this.openTreasureBox(false);
      }
    }, this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.closeTreasureBox(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_CAPTURE_START, () => this.handleNightCapture(), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, () => this.startLottieAnimation(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_MORE_PAGE, () => this.closeTreasureBox(), this.mBase.hashCode());
  }

  aboutToDisappear() {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  private onCustomFilterPreviewSizeChanged(data: ActionData): void {
    this.isCustomFilterButtonShow = data['isPreviewScaled'];
  }

  private handleRingArrowOpacity(): void {
    if (this.ringOpacityTimer !== Number.MIN_VALUE) {
      clearTimeout(this.ringOpacityTimer);
    }
    this.ringOpacityTimer = setTimeout(() => {
      this.isShowRingIconOpacity = true;
      this.ringOpacityTimer = Number.MIN_VALUE;
      clearTimeout(this.ringOpacityTimer);
    }, RING_OPACITY_TIME_DELAY)
  }

  // 打开关闭百宝箱动效逻辑入口
  private uncollapsTreasureBox(): void {
    HiLog.d(TAG, `uncollapsTreasureBox isOpen: ${this.isOpen}`);
    this.isOpened = true;
    this.uncollapsBegin(this.isOpen);
    const arrowUpDistance = AdaptiveLayoutService.getInstance().arrowUpDistance;
    if (this.isOpen) {
      HiLog.i(TAG, 'openTreasure start.');
      this.uncollapsTreasureBoxBegin(true);
      this.isShowRingIconOpacity = false;
      HiLog.begin(TAG,'open TreasureBox');
      animateToImmediately({
        duration: OPEN_ANIMATE_DURING, curve: Curve.Friction, onFinish: () => {
          this.uncollapsTreasureBoxEnd(true);
          this.uncollapsEnd(true);
          HiLog.end(TAG,'open TreasureBox');
        }
      }, () => {
        if (this.isHalfCollapsLEM) {
          this.transDistance = 0;
        } else {
          this.transDistance = -arrowUpDistance;
        }
      });
      animateToImmediately({ duration: 100, delay: 50 }, () => {
        this.treasureBoxOpacity = 1;
      });
    } else {
      HiLog.i(TAG, 'closeTreasure start.');
      this.handleRingArrowOpacity();
      this.uncollapsTreasureBoxBegin(false);
      HiLog.begin(TAG,'collaps TreasureBox');
      animateToImmediately({
        duration: 550, curve: Curve.Friction, onFinish: () => {
          this.uncollapsTreasureBoxEnd(false);
          this.uncollapsEnd(false);
          HiLog.end(TAG,'collaps TreasureBox');
        }
      }, () => {
        this.transDistance = 0;
      });
      animateToImmediately({ duration: 100, delay: 50 }, () => {
        this.treasureBoxOpacity = 0;
      });
    }
  }

  private uncollapsTreasureBoxBegin(isOpen: boolean): void {
    let lottieName: string = SLIDER_OPEN + this.isPicker;
    if (isOpen) {
      this.isShowArrowLoop = false;
      if (this.isUpwardArrow) {
        this.isUpwardArrow = false;
      } else {
        this.sliderOpenItem?.stop(lottieName);
        this.sliderOpenItem?.setDirection(1);
        this.sliderOpenItem?.play(lottieName);
      }
    } else {
      this.sliderOpenItem?.setDirection(-1);
      this.sliderOpenItem?.play(lottieName);
    }
  }

  private uncollapsTreasureBoxEnd(isOpen: boolean): void {
    if (this.isOpen !== isOpen) {
      return;
    }
    if (!isOpen) {
      this.isUpwardArrow = true;
    }
    this.isOpened = false;
  }

  private openTreasureBox(open: boolean): void {
    const videoState: RecordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    // 专业模式进行中，UI禁用状态下，禁用百宝箱
    HiLog.i(TAG, `openTreasureBox open: ${open}, videoState: ${videoState},
    isOpen:${this.isOpen}, isProShutterCapture: ${this.isProShutterCapture}.`);
    if ((open && videoState !== RecordingState.READY) || (open === this.isOpen) || this.isProShutterCapture) {
      return;
    }
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(open));
    // 百宝箱打开或者关闭的过程中，双击打开的图标，下层快门键会响应，增加标志位拦截下层快门键响应
    AppStorage.setOrCreate('isOpenOrCloseTreasureBox', true);
    this.animationTimer = setTimeout(() => {
      AppStorage.setOrCreate('isOpenOrCloseTreasureBox', false);
      clearTimeout(this.animationTimer);
    }, OPEN_ANIMATE_DURING);
  }

  private handleNightCapture(): void {
    HiLog.i(TAG, 'handleNightCapture.');
    const currMode = getStates().get<ModeType>('modeReducer', 'mode');
    const position: camera.CameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    if (position === camera.CameraPosition.CAMERA_POSITION_BACK) {
      this.closeTreasureBox();
    }
  }

  build() {
    Row() {
      if (this.isUpwardArrow && this.isShowArrowLoop) {
        this.lottieCanvasBuilder(this.loopController, ARROW_LOOP, ARROW_LOOP_PATH);
      } else if (!this.isUpwardArrow) {
        this.lottieCanvasBuilder(this.sliderController, SLIDER_OPEN,
          this.isShowRingLightView ? SLIDER_RING_OPEN_PATH : SLIDER_OPEN_PATH);
      } else {
        Image($r('app.media.treasure_fold'))
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .width(ARROW_WIDTH)
          .height(ARROW_HEIGHT)
          .fillColor(Color.White)
          .opacity(1)
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.IDENTITY,
              TransitionEffect.OPACITY.animation({ duration: 10, delay: 30 })))
      }
    }
    .width(ARROW_WIDTH)
    .height(ARROW_HEIGHT)
    .visibility((this.isHalfCollapsLEM || this.isLemCollaps) ? Visibility.Hidden : Visibility.Visible)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityText(this.isOpen ? $r('app.string.treasure_box_collaps') : $r('app.string.treasure_box_uncollaps'))
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityNextFocusId(this.functionId === FunctionId.NONE ?
      ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.functionId) :
      ComponentIdKeys.TREASURE_BOX_SECOND_LIST_BACK_BTN)
    .onClick((): void => {
      if (!this.uiEnable || this.isOpened || this.showPhotoBrowserAction) {
        return;
      }
      if (this.isCustomFilterButtonShow) {
        return;
      }
      if (this.isOpen) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe($r('app.string.accessibility_treature_box_closed')));
      } else {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe($r('app.string.accessibility_treature_box_open')));
      }
      PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.TREASURE_BOX,
        ARROW_LOOP_SHOW_COUNT);
      this.openTreasureBox(!this.isOpen);
    })
    .gesture(GestureGroup(GestureMode.Exclusive,
      PanGesture({ fingers: 1, direction: PanDirection.Up, distance: 1 })
        .onActionStart((): void => {
          if (this.isCustomFilterButtonShow) {
            return;
          }
          HiLog.i(TAG, 'isPanGestureDoing true, onActionStart 1');
          this.isPanGestureDoing = true;
          this.openTreasureBox(true);
        })
        .onActionEnd((): void => {
          HiLog.i(TAG, 'isPanGestureDoing false, onActionEnd 1');
          this.isPanGestureDoing = false;
        })
        .onActionCancel((): void => {
          HiLog.i(TAG, 'isPanGestureDoing false, onActionCancel 1');
          this.isPanGestureDoing = false;
        }),
      PanGesture({ fingers: 1, direction: PanDirection.Down, distance: 1 })
        .onActionStart((): void => {
          if (this.isCustomFilterButtonShow) {
            return;
          }
          HiLog.i(TAG, 'isPanGestureDoing true, onActionStart 2');
          this.isPanGestureDoing = true;
          this.openTreasureBox(false);
        })
        .onActionEnd((): void => {
          HiLog.i(TAG, 'isPanGestureDoing false, onActionEnd 2');
          this.isPanGestureDoing = false;
        })
        .onActionCancel((): void => {
          HiLog.i(TAG, 'isPanGestureDoing false, onActionCancel 2');
          this.isPanGestureDoing = false;
        })
    ))
    .key(ComponentIdKeys.TREASURE_BOX_ARROW)
    .accessibilityNextFocusId(ComponentIdKeys.PICKER_PRIVACY_BANNER)
    .offset({x: 0, y: 0})
    .zIndex(ZIndex.TOP)
  }

  @Builder
  lottieCanvasBuilder(controller: CanvasRenderingContext2D, name: string, path: string) {
    Canvas(controller)
      .width('100%')
      .height('100%')
      .onReady((): void => {
        this.lottieOnReady(controller, name, path);
      })
      .onDisAppear((): void => {
        if (name === SLIDER_OPEN) {
          HiLog.i(TAG, 'sliderOpenItem end.');
          this.sliderOpenItem?.stop(SLIDER_OPEN);
          this.removeArrowListener();
          this.sliderOpenItem?.destroy(SLIDER_OPEN);
          this.sliderOpenItem = undefined;
        } else {
          this.destroyArrowLoop();
        }
      })
  }

  private lottieOnReady(controller: CanvasRenderingContext2D, name: string, path: string): void {
    HiLog.i(TAG, `lottieCanvasBuilder Canvas onReady name: ${name},isUpwardArrow: ${this.isUpwardArrow}.`);
    controller.imageSmoothingEnabled = true;
    controller.imageSmoothingQuality = 'medium';
    this.lottieName = name + this.isPicker;
    let pickerLottieName: string = name + 'true';
    let cameraLottieName: string = name + 'false';
    lottie.pause(pickerLottieName);
    lottie.pause(cameraLottieName);
    if (this.isPicker) {
      lottie.destroy(pickerLottieName);
    } else {
      lottie.destroy(cameraLottieName);
    }
    const item: AnimationItem = lottie.loadAnimation({
      container: controller,
      renderer: 'canvas',
      loop: name === ARROW_LOOP,
      autoplay: name === ARROW_LOOP,
      name: this.lottieName,
      path: path,
    });

    if (name === SLIDER_OPEN) {
      HiLog.i(TAG, 'sliderOpenItem start.');
      this.sliderOpenItem = item;
      item.setDirection(1);
      this.sliderOpenItem.addEventListener('DOMLoaded', () => {
        if (!this.sliderOpenItem) {
          HiLog.w(TAG, `arrowButton lottie DomLoaded, this.sliderOpenItem is null.`);
          return;
        }
        this.sliderOpenItem.play();
      });
      this.sliderOpenItem.addEventListener('complete', () => {
        this.removeArrowListener();
      });
    } else {
      this.arrowLoopItem = item;
      // 动画播放一遍结束触发
      this.arrowLoopItem.addEventListener('loopComplete', (args: Object): void => {
        this.arrowPlayCount += 1;
        HiLog.i(TAG, `ArrowLoopItem loopComplete count: ${this.arrowPlayCount}.`);
        if (this.arrowPlayCount < ARROW_LOOP_PLAY_COUNT) {
          return;
        }
        this.isShowArrowLoop = false;
        this.destroyArrowLoop();
      });
    }
  }

  private checkArrowLoopShow(): boolean {
    const preferencesService = PreferencesService.getInstance();
    const count: number = preferencesService.getPropValue(PersistType.FOREVER, PropTag.TREASURE_BOX, 0) as number;
    HiLog.i(TAG, `checkArrowLoopShow invoke, treasureBox hasShow count: ${count}.`)
    if (count < ARROW_LOOP_SHOW_COUNT) {
      preferencesService.putPropValue(PersistType.FOREVER, PropTag.TREASURE_BOX, count + 1);
      return true;
    }
    return false;
  }

  private removeArrowListener(): void {
    if (!this.sliderOpenItem) {
      HiLog.w(TAG, `removeArrowListener this.sliderOpenItem is null.`);
      return;
    }
    this.sliderOpenItem.removeEventListener(`DOMLoaded`);
    this.sliderOpenItem.removeEventListener(`complete`);
  }

  private destroyArrowLoop(): void {
    if (!this.arrowLoopItem) {
      return;
    }
    this.arrowLoopItem.removeEventListener('loopComplete');
    let lottieName: string = ARROW_LOOP + this.isPicker;
    this.arrowLoopItem.destroy(lottieName);
    lottie.destroy(lottieName);
    this.arrowLoopItem = undefined;
  }

  private closeTreasureBox(): void {
    this.sliderOpenItem?.destroy();
    // 解决沉浸式锁屏后footbar位置下移
    if (this.isOpen && !this.isHalfCollapsLEM && !this.isCustomFilterButtonShow) {
      this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
    }
  }

  // ArrowLoop动画执行完之前打开cameraPicker会pause掉loop动画
  // 如果loop动画未执行完就被打断, 进入相机后需要重新启动loop动画
  private startLottieAnimation(): void {
    if (this.lottieName.length) {
      HiLog.i(TAG, `start lottie animation lottieName: ${this.lottieName}`);
      lottie.play(this.lottieName);
    }
  }
}