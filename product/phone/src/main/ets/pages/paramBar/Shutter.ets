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

import lazy { ParamBarIconTextRotate } from '@ohos/common/src/main/ets/component/paramcomp/ParamBarIconTextRotate';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { Dispatch, getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { ExtraData, ParamBarService } from './ParamBarService';
import lazy { ParamBarDispatcher } from '@ohos/common/src/main/ets/component/paramcomp/ParamBarDispatcher';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ShutterEffectMode } from '@ohos/common/src/main/ets/function/enumbase/ShutterEffectMode';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { camera } from '@kit.CameraKit';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { NightSubMode } from '@ohos/common/src/main/ets/function/operationbase/NightSubModeUtil';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';

/* instrument ignore file */
const TAG: 'Shutter' = 'Shutter';

@Component
export struct Shutter {
  @State isShow: boolean = false;
  private mSubscriber: Unsubscribe | null = null;
  private updatePosition: (visibility: boolean, cb: (isShow: boolean) => void) => void = (visibility) => {
  };
  private mAction: ParamBarDispatcher = new ParamBarDispatcher();
  @State textContent: string | Resource = '';
  @State modeType: String = ModeType.NONE;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State nightSubModeType: NightSubMode = 0;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.modeType = state.get<ModeType>('modeReducer', 'mode');
      this.nightSubModeType = state.get<NightSubMode>('nightSubModeReducer', 'nightSubMode');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.setTextSrc();
    this.handleShutterShow();
    this.mEventBus.on(CameraActionType.STARTED, this.handleShutterShow.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      () => this.resetParamValue(), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private handleShutterShow() {
    const state = getStates();
    const extraData: ExtraData = {
      cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition')
    };

    const visibility = ParamBarService.getInstance().handleFunctionVisibility(FunctionId.SHUTTER, extraData);
    this.updatePosition(visibility, (isShow) => {
      this.isShow = isShow;
    });
  }

  private resetParamValue(): void {
    //反转镜头后快门速度重置为自动，ShutterEffectFunction的unload中已将值设为Auto
    if (this.modeType === ModeType.NIGHT) {
      this.mAction.changeFunctionValue(FunctionId.SHUTTER, ShutterEffectMode.AUTO);
      const shutterSpeed: number = FeatureManager.getInstance()
        .getFunction(FunctionId.SHUTTER)?.getValue();
      let text: string | Resource = shutterSpeed.toString();
      if (shutterSpeed === 0) {
        text = $r('app.string.shutter');
      } else if (shutterSpeed < 1) {
        text = shutterSpeed === 0.25 ? '1/4' : '1/2';
      }
      this.textContent = text;
    }
  }

  private handleClick = (): void => {
    HiLog.i(TAG, 'handleClick onClick.');
    this.mAction.updateIsShowShutterView();
    VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
  }

  private setTextSrc() {
    const shutterValue: number = FeatureManager.getInstance().getFunction(FunctionId.SHUTTER)?.getValue();
    let text: string | Resource = shutterValue.toString();
    if (shutterValue === 0) {
      text = $r('app.string.shutter');
    } else if (shutterValue < 1) {
      text = shutterValue === 0.25 ? '1/4' : '1/2';
    }
    this.textContent = text;
  }

  build() {
    if (this.isShow) {
      Row() {
        ParamBarIconTextRotate({
          defaultImgSrc: $r('app.media.ic_camera_night_shutter_1'),
          defaultTextSrc: this.textContent
        })
      }
      .id('Shutter')
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityText(ResGetter.getStringSafe($r('app.string.shutter_speed')) +
      ResGetter.getStringSafe(this.textContent))
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .visibility((this.nightSubModeType === NightSubMode.DEFAULT ||
        !CameraAppCapability.getInstance().getIsSupportedNightSubMode()) ? Visibility.Visible : Visibility.Hidden)
      .onClick(this.handleClick)
    }
  }
}