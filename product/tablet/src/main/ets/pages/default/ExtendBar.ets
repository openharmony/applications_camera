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

import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { Dispatch, OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { MIDDLE_COMPONENT_WIDTH } from './ParamBar';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { ZoomActionType } from '@ohos/common/src/main/ets/redux/actions/ZoomActionType';
import { CaptureActionType } from '@ohos/common/src/main/ets/redux/actions/CaptureActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';

const TAG: string = 'ExtendBar';

class ExtendBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public hideExtendBar(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
  }

  public hideAllView(): void {
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.NONE));
  }

  public hideExtendView(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
  }

}

/**
 * 拓展Bar组件,如大光圈模式光圈调节Bar、录像模式美颜调节Bar、人像模式效果和美颜调节Bar、专业模式专业参数调节Bar等;
 * 布局说明：大部分场景ExtendBar显示与(ZoomView和ParamBar)显示互斥;
 *         仅专业模式参数调节Bar、前置人像模式美颜特性调节Bar ExtendBar位于ParamBar上方;
 * */
@Component
export struct ExtendBar {
  private mBase: BaseComponent = new BaseComponent();
  private mAction: ExtendBarDispatcher = new ExtendBarDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe | null = null;
  @State showComponent: FunctionId = FunctionId.NONE;

  aboutToAppear() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.showComponent = state.get<FunctionId>('uiReducer', 'extendBarEffectView');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on([CameraActionType.SWITCH_CAMERA, CameraActionType.CHANGE_MODE,
      CameraActionType.CHANGE_OUTPUT_TYPE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE,
      ActionType.ACTION_PREVIEW_CLICKED, ContextActionType.ABILITY_ON_BACKGROUND,
      ZoomActionType.ACTION_UPDATE_SHOW_PINCH, CaptureActionType.CAPTURE, ActionType.ACTION_RESTORE_DIALOG_CONFIRM],
      () => this.hideExtendBar(), this.mBase.hashCode());
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
    this.mAction.hideAllView();

    this.mEventBus.clear(this.mBase.hashCode());
  }

  private hideExtendBar(): void {
    this.mAction.hideExtendBar();
  }

  build() {
    Column() {
      Blank()
        .layoutWeight(1)
        .onClick((): void => {
          this.mAction.hideExtendView();
        })
      Blank()
        .layoutWeight(1)
        .onClick((): void => {
          this.mAction.hideExtendView();
        })
    }
    .width(MIDDLE_COMPONENT_WIDTH)
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}