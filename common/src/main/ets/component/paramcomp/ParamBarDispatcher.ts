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
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { Action } from '../../redux/actions/Action';
import lazy { Dispatch } from '../../redux';
import lazy { FunctionAction } from '../../function/core/FunctionAction';
import lazy { execAction } from '../../redux/ActionRegistry';

export class ParamBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch): void {
    this.mDispatch = dispatch;
  }

  public showApertureView(): void {
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.APERTURE));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public showBeautyView(): void {
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.PORTRAIT_BEAUTY));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public updateIsShowShutterView(): void {
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.SHUTTER));
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public showMacroFocusView(): void {
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.FOCUS));
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public showSlowView(): void {
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.MOTION_FRAME_RATE));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public showLightPaintingView(): void {
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.LIGHT_PAINTING_TYPE));
    this.mDispatch(Action.updateIsShowExtendBar(true));
    this.mDispatch(execAction('LightPaintingAction', 'updateLightPaintingExtendBar', true));
  }

  public showTimeLapseView(): void {
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.REAL_TIME_LAPSE));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }
}