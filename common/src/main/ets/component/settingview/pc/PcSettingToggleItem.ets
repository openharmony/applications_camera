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

import lazy { HiLog } from '../../../utils/HiLog';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { FunctionAction } from '../../../function/core/FunctionAction';
import lazy { BaseFunction } from '../../../function/core/BaseFunction';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { Dispatch, getStates, reduxSubscribe } from '../../../redux';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { ConflictParam } from '../../../function/core/ConflictParam';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { ActionData } from '../../../redux/actions/Action';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import CommonEventManager, { CUSTOM_EVENTS } from '../../commonevent/CommonEventManager';
import lazy { CameraProxy } from '../../../camera/uithread/CameraProxy';
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'PcSettingToggleItem';

class StateStruct {
  public enable: boolean = false;
}

class SettingToggleDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  };
}

@Component
export struct PcSettingToggleItem {
  private mBase: BaseComponent = new BaseComponent();
  @State itemEnable: boolean = true;
  @State itemFunctionValue: boolean = false;
  private functionId: FunctionId = FunctionId.NONE;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  private function: BaseFunction | null = null;
  private uiElement: UiElement = new UiElement();
  private WH_100_100: string = '100%';
  private mAction: SettingToggleDispatcher = new SettingToggleDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear start.');
    reduxSubscribe(null, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    this.function = FeatureManager.getInstance().getFunction(this.functionId);
    this.itemFunctionValue = this.function.getValue();
    let uiElementTemp = this.function.getUiElements(this.renderLocation).get(UiElement.DEFAULT);
    if (uiElementTemp) {
      this.uiElement = uiElementTemp;
    }
    this.mEventBus.on([FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, ActionType.ACTION_REFRESH_LOCATION_TOGGLE_ITEM],
      this.toggleItemChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.settingPageChange.bind(this),
      this.mBase.hashCode());
    this.toggleItemChange();
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  aboutToDisappear() {
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private settingPageChange(data: ActionData): void {
    if (data['windowStageEventType'] === 3 && this.functionId === FunctionId.MIRROR) {
      this.toggleItemChange();
    }
  }

  private setToggleVal(conflictParam: ConflictParam | undefined): void {
    const uiElementTemp: UiElement | undefined =
      this.function?.getUiElements(this.renderLocation)?.get(UiElement.DEFAULT);
    if (uiElementTemp) {
      this.uiElement = uiElementTemp;
    }
    if (this.functionId === FunctionId.MIRROR) { // 自拍镜像禁用置灰，开关默认关闭
      const isSupportVideoMirror: boolean = CameraProxy.getInstance().getIsVideoMirrorSupported();
      this.itemEnable = isSupportVideoMirror || (!conflictParam || !conflictParam.disabled);
      this.itemFunctionValue = this.itemEnable ? this.function?.getValue() : false;
    } else {
      this.itemEnable = !conflictParam || !conflictParam.disabled;
      this.itemFunctionValue = this.function?.getValue();
    }
  }

  private toggleItemChange(): void {
    const conflictParam: ConflictParam | undefined = getStates()
      .get<Map<FunctionId, ConflictParam>>('functionReducer', 'functionConflictParamMap')
      .get(this.functionId);
    this.setToggleVal(conflictParam);
  }

  build() {
    if (this.function?.isAvailable()) {
      Row() {
        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween
        }) {
          Column() {
            Row() {
              Image(this.uiElement.icon)
                .width(24)
                .height(24)
                .fillColor($r('sys.color.icon_primary'))
                .draggable(false)
              Text(this.uiElement.title)
                .fontColor($r('sys.color.font_primary'))
                .fontSize($r('sys.float.Subtitle_M'))
                .fontSize($r('sys.float.Subtitle_M'))
                .fontWeight(FontWeight.Regular)
                .fontFeature('\"ss01\" on')
                .margin({
                  left: SystemLanguageUtil.isRTL() ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_l'),
                  right: SystemLanguageUtil.isRTL() ? $r('sys.float.ohos_id_elements_margin_horizontal_l') : 0
                })
            }

            if (this.uiElement.desc && !this.itemEnable) {
              Row() {
                Text(this.uiElement.desc)
                  .fontColor($r('sys.color.font_primary'))
                  .fontSize($r('sys.float.Body_M'))
                  .fontWeight(FontWeight.Regular)
                  .opacity($r('sys.float.alpha_secondary'))
                  .fontFeature('\"ss01\" on')
              }
              .margin({ top: $r('sys.float.padding_level1'), left: 40 })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Row() {
            Toggle({
              type: ToggleType.Switch,
              isOn: this.itemFunctionValue
            })
              .width(36)
              .height(20)
              .selectedColor($r('sys.color.icon_emphasize'))
              .onChange((isOn: boolean) => {
                HiLog.i(TAG, `settingItemToggle functionId: ${this.functionId}, onChange: ${isOn}.`);
                if (this.itemFunctionValue === isOn) {
                  return;
                }
                this.changeFunctionValue(this.functionId, isOn);
              })
              .key(ComponentIdKeys.getInstance().getKey('SettingItemComponentTOGGLE', this.functionId))
          }
        }
        .height('100%')
      }
      .opacity(this.itemEnable ? 1 : 0.5)
      .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
      .height(this.uiElement?.desc ? 56 : 40)
      .width(this.WH_100_100)
      .enabled(this.itemEnable)
      .key(ComponentIdKeys.getInstance().getKey('SettingItemTOGGLE', this.functionId))
    }
  }

  changeFunctionValue(functionId: FunctionId, isOn: boolean): void {
    if (GlobalContext.get().getIsPicker() && DeviceInfo.isPc()) {
      CommonEventManager.getInstance().publishCommonEventMg(CUSTOM_EVENTS.CHANGE_FUNCTION_VAL,
        { isPicker: true, functionId: functionId, functionValue: isOn });
      this.mAction.changeFunctionValue(functionId, isOn);
    } else {
      this.mAction.changeFunctionValue(functionId, isOn);
    }
  }
}