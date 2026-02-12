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

import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { AnimSpecifications } from '../../../animation/AnimSpecifications';
import lottie, { AnimationItem } from '@ohos/lottie';
import lazy {
  TREASURE_BOX_ELEMENT_INNER_HEIGHT,
  TREASURE_BOX_ELEMENT_INNER_WIDTH,
  VDE_TREASURE_BOX_ELEMENT_INNER_HEIGHT,
  VDE_TREASURE_BOX_ELEMENT_INNER_WIDTH
} from './DataType';
import lazy { OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { FunctionValueType, ValueType } from '../../../utils/types';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { LongPressDialogView } from '../../customdialog/dialogComponent/LongPressDialogView';
import lazy { CollaborateActionType } from '../../../redux/actions/CollaborateActionType';
import lazy { LeftRightSwipeActionType } from '../../../redux/actions/LeftRightSwipeActionType';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { camera } from '@kit.CameraKit';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { getElementWidth } from './TreasureBoxCommonFunction';
import lazy { getStates } from '../../../redux/Store';

/* instrument ignore file */
const TAG: string = 'LottieAnimate';
const DELAY_DESTROY_LOTTIE: number = 10;
const VDE_ICON_SIZE: number = 18;
const STABILIZATION_WIDTH: number = 30;
const STABILIZATION_HEIGHT: number = 24;
const AUXILIARY_LOTTIE_WIDTH: number = 25;


const TREASURE_BOX_LOTTIE_BUTTON: Set<FunctionId> = new Set([
  FunctionId.ASSISTIVE_GRID
]);

export function getTreasureBoxLottieFunctions(): Set<FunctionId> {
  return TREASURE_BOX_LOTTIE_BUTTON;
}

const TREASURE_BOX_LOTTIE_PATH: Map<FunctionId, Map<ValueType, string>> = new Map([
  [FunctionId.ASSISTIVE_GRID, new Map<ValueType, string>([
    [true, 'common/lottie/treasure_box_assistive_grid_open.json'],
    [false, 'common/lottie/treasure_box_assistive_grid_close.json']
  ])]
]);

const LOTTIE_IMAGE_PATH: Map<string, ResourceStr> = new Map([
  [FunctionId.ASSISTIVE_GRID + '' + true, $r('app.media.treasure_box_assistive_grid_open')],
  [FunctionId.ASSISTIVE_GRID + '' + false, $r('app.media.treasure_box_assistive_grid_close')],
]);

const PATH_RING_LIGHT: Map<FunctionId, Map<ValueType, string>> = new Map([
  [FunctionId.ASSISTIVE_GRID, new Map([
    [true, 'common/lottie/treasure_box_assistive_grid_open_ring_light.json'],
    [false, 'common/lottie/treasure_box_assistive_grid_close_ring_light.json']
  ])],
]);
// 百宝箱一二级切换过程中的lottie图标延迟销毁，解决一二级切换过程lottie图标变空的问题
const DISAPPEAR_DELAY: number = 30;

@Component
export struct LottieAnimate {
  // function业务
  @Prop functionId: FunctionId = FunctionId.NONE;
  private functionValue: ValueType = false;
  // 公共事件通知
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private base: BaseComponent = new BaseComponent();
  // 旋转
  @Prop @Watch('onRotateAngle') angleRotate: number = 0;
  @State angleRotateShow: number = 0;
  // 适老化
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private customDialogViewController?: CustomDialogController;
  // lottie animate
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private animationItem: AnimationItem | undefined = undefined;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLowAngleShotView: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  private prevPathKey: string | undefined = undefined;
  @State isShowCanvas: boolean = false;
  @State isShowIcon: boolean = true;
  @State isIconOn: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, `aboutToAppear, functionId: ${this.functionId}.`);
    this.functionValue = FeatureManager.getInstance().getFunction(this.functionId).getValue();
    this.isIconOn = this.functionValue as boolean;
    this.angleRotateShow = this.angleRotate;

    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
    });
    this.eventBus.on([FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      CollaborateActionType.SHOW_OR_HIDE_COLLABORATE_ICON],
      (data: FunctionValueType) => {
        if (data.id === this.functionId) {
          this.onFunctionValueChanged(data);
        }
      }, this.base.hashCode());
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, `aboutToDisappear, functionId: ${this.functionId}.`)
    this.eventBus.clear(this.base.hashCode());
    this.subscriber.destroy();
  }

  private onFunctionValueChanged(data: FunctionValueType): void {
    if (data.value === undefined || data.value === this.functionValue) {
      HiLog.e(TAG, `value is undefined return--${data.value}---${this.functionValue}`);
      return;
    }
    this.isShowCanvas = true;
    this.functionValue = data.value as ValueType;
    if (typeof this.functionValue === 'number') {
      this.functionValue = this.functionValue === 1;
    }
  }

  private onCanvasReady(): void {
    const path: string | undefined = this.getLottiePath(this.functionValue);
    this.animationItem = lottie.loadAnimation({
      container: this.canvasContext,
      renderer: 'canvas',
      loop: false,
      autoplay: false,
      autoSkip: false,
      path: path,
      name: path
    });
    this.animationItem.addEventListener('DOMLoaded', (): void => {
      this.isShowIcon = false;
      this.animationItem?.resetSegments(true);
      this.animationItem?.play();
      HiLog.i(TAG, 'lottieCanvasBuilder Canvas DOMLoaded.');
      // 首次切换时，两次的path是一致的 销毁会导致画布是空的 延迟销毁解决动效切换空帧的问题
      if (this.prevPathKey && this.prevPathKey !== path) {
        const temPath = this.prevPathKey;
        setTimeout(() => {
          lottie.destroy(temPath);
        }, DELAY_DESTROY_LOTTIE);
      }
      this.prevPathKey = path;
    });
    this.animationItem?.addEventListener('complete', (): void => {
      this.isShowIcon = true;
      this.isShowCanvas = false;
      this.isIconOn = this.functionValue as boolean;
      HiLog.i(TAG, 'lottie complete');
    })
    this.animationItem?.addEventListener('destroy', (): void => {
      this.isIconOn = this.functionValue as boolean;
      HiLog.i(TAG, 'lottie destroy');
    })
  }

  build() {
    Row() {
      this.LottieBuilder();
    }
    .width(this.isVdeCollapsed ? VDE_TREASURE_BOX_ELEMENT_INNER_WIDTH : TREASURE_BOX_ELEMENT_INNER_WIDTH)
    .height(this.isVdeCollapsed ? VDE_TREASURE_BOX_ELEMENT_INNER_HEIGHT : TREASURE_BOX_ELEMENT_INNER_HEIGHT)
    .border({ radius: 24 })
    .backgroundColor($r('app.color.component_normal_dark'))
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .rotate({ angle: this.angleRotateShow })
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            let value: ValueType = FeatureManager.getInstance().getFunction(this.functionId)?.getValue() as ValueType;
            value = this.getReverseValue(value);
            const canvasPath = this.getLottiePath(value, true);
            this.customDialogViewController = new CustomDialogController({
              builder: LongPressDialogView({
                iconItem: {
                  iconRes: '',
                  isEnabled: true,
                  label: undefined,
                  isCanvasIcon: true,
                  canvasPath: canvasPath
                },
                textRes: undefined
              }),
              maskColor: Color.Transparent,
              isModal: true,
              customStyle: true
            });
            this.customDialogViewController.open();
          }
        })
    )
    .onTouch((event) => {
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.customDialogViewController?.close();
      }
    })
  }

  private onRotateAngle(): void {
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.angleRotateShow = this.angleRotate;
    });
  }

  private getReverseValue(value: ValueType): ValueType {
    if (typeof value === 'boolean') {
      return !value
    }
    return !value;
  }

  private getLottiePath(value: ValueType, isForLongPressDialog?: boolean): string | undefined {
    if (PATH_RING_LIGHT.has(this.functionId) && this.isShowWhiteBackground() && !isForLongPressDialog) {
      return PATH_RING_LIGHT.get(this.functionId)?.get(value);
    }
    return TREASURE_BOX_LOTTIE_PATH.get(this.functionId)?.get(value);
  }

  // lottie图标展示环形补光色
  private isShowWhiteBackground(): boolean {
    if (!this.isShowRingLightView) {
      return false;
    }
    if (this.isVdeCollapsed || this.isVdeSemiCollapsed) {
      return true;
    }
    if (this.isShowLowAngleShotView && this.isShowSemiCollapsed) {
      return false;
    }
    return this.isShowLandscape || DeviceInfo.isTablet();
  }

  @Builder
  LottieBuilder() {
    Stack() {
      if (this.isShowCanvas) {
        this.CanvasBuilder();
      }
    }
  }

  @Builder
  CanvasBuilder() {
    Row() {
      Canvas(this.canvasContext)
        .width(this.isVdeCollapsed ? VDE_ICON_SIZE : getElementWidth(this.functionId))
        .height(getElementWidth(this.functionId))
        .onReady((): void => {
          HiLog.i(TAG, 'lottieCanvasBuilder Canvas onReady.');
          this.onCanvasReady();
        })
        .onDisAppear((): void => {
          HiLog.d(TAG, 'lottieCanvasBuilder Canvas onDisAppear.');
          lottie.destroy(this.getLottiePath(this.functionValue));
        })
    }
  }
}