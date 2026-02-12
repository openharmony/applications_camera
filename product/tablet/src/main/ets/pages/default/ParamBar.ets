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

import { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import { Dispatch, OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import { PARAM_ELEMENT_SIDE_LENGTH, ParamBarIconTextRotate } from './ParamBarIconTextRotate';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import camera from '@ohos.multimedia.camera';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import { ChangeState, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import { intl } from '@kit.LocalizationKit';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';

const TAG: string = 'ParamBar';

export const MIDDLE_COMPONENT_WIDTH: number = 72

const PARAM_BAR_ICON_TEXT_OFFSET: number = 12
const PARAM_BAR_ICON_TEXT_OFFSET_PANORAMA: number = 6

class StateStruct {
  public position?: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public mode: ModeType = ModeType.NONE;
  public recordState: RecordingState = RecordingState.READY;
}

class ParamBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }


  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public showMacroFocusView(): void {
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.FOCUS));
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }
}

@Component
export struct ParamBar {
  private mBase: BaseComponent = new BaseComponent();
  @State state: StateStruct = new StateStruct();
  private mAction: ParamBarDispatcher = new ParamBarDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State imgSrc: Resource = $r('app.media.setting');
  private mSubscriber: Unsubscribe | null = null;
  @State isPicker: boolean = false;
  private zoomChangeAperture: number = 3.3;
  @State isShowParamBar: boolean = false;
  @StorageLink('isAperture') isAperture: boolean = true;
  @StorageLink('isApertureShow') isApertureShow: boolean = true;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  private apertureParams: Map<string, number> = new Map();
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
    isSupport4k: boolean = false;
  @State isSupport60fps: boolean = false;
  @State isSupportEffectFunc: boolean = false;
  @State isSupportBeautyFunc: boolean = false;
  @State isSupportShutterFunc: boolean = false;
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true;
  @State beautyPortraitText: Resource | string = '';
  private isDisAbleRealTimeLapsePro: boolean = CameraAppCapability.getInstance().getIsDisAbleRealTimeLapsePro();

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        position: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        mode:state.get<ModeType>('modeReducer', 'mode'),
        recordState: state.get<RecordingState>('recordReducer', 'recordingState')
      });
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.resetParamFunctions();
    this.mEventBus.on(CameraActionType.STARTED, this.resetParamFunctions.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  private resetParamFunctions(): void {
    this.isSupport4k = FeatureManager.getInstance()?.getFunction(FunctionId
      .VIDEO_RESOLUTION)?.getValue() === 1 ? false : true;
    this.isSupport60fps = FeatureManager.getInstance()?.getFunction(FunctionId
      .FRAME_RATE)?.getValue() === 2 ? false : true;
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  @Builder
  ParamListBuilder() {
    if (this.isSupportBeautyFunc &&
      ((this.state.mode === ModeType.VIDEO &&
        (this.state.recordState === RecordingState.READY || this.state
          .recordState === RecordingState.STOPPING) && this.isSupport4k && this.isSupport60fps))) {
    }
    if (this.isSupportEffectFunc) { // 效果特性入口
    }
    if (this.isSupportShutterFunc &&
      this.state.position !== camera.CameraPosition.CAMERA_POSITION_FRONT) { // 快门入口
      this.shutterBuilder()
    }
    if (this.state.mode === ModeType.PHOTO) {
    }
  }

  @Builder
  shutterBuilder() {
    ParamBarIconTextRotate({
      defaultImgSrc: $r(null),
    })
      .onClick((event) => {
        HiLog.i(TAG, 'isSupportShutterFunc onClick.');
        VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
      })
      .id('timeLapse')
      .alignRules({
        right: {anchor: '__container__', align: HorizontalAlign.End},
        center: {anchor: '__container__', align: VerticalAlign.Center},
      })
      .key(ComponentIdKeys.PARAM_BAR_TIME_LAPSE)
      .offset({ x: SystemLanguageUtil.isRTL() ? 0 : -12 })
  }

  build() {
    Column() {
      this.ParamListBuilder();
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width(MIDDLE_COMPONENT_WIDTH)
    .height('100%')
  }
}