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
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { Unsubscribe } from '../../../redux';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { SettingFuncDialogItemIndex } from '../../settingview/SettingFuncDialogItemIndex';
import lazy { OhCombinedState, Dispatch, getStates, reduxSubscribe } from '../../../redux';
import lazy { ModeType } from '../../../mode/ModeType';
import camera from '@ohos.multimedia.camera';
import lazy { ChangeState } from '../../../redux/Store';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'EntryComponent';

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
}

class EntryComponentDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@Component
export default struct EntryComponent {
  @State state: StateStruct = new StateStruct();
  private mAction: EntryComponentDispatcher = new EntryComponentDispatcher();
  private itemText: Resource | string = '';
  private itemValue: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_NONE;
  private itemDesc: Resource | string = '';
  private itemDisable: boolean | undefined = false;
  @Link checkedValue: SettingFuncDialogItemIndex;
  private functionId: FunctionId = FunctionId.NONE;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  private mFeatureManager = FeatureManager.getInstance();
  private index: number = 0;
  private mSubscriber: Unsubscribe | null = null;

  aboutToAppear(): void {
    HiLog.i(TAG, `aboutToAppear itemText: ${this.itemText}, itemValue: ${this.itemValue}.`);
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition')
      });
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.checkedValue = this.mFeatureManager.getFunction(this.functionId).getValue();
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Column() {
        Row() {
          Text(this.itemText)
            .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_primary') : '#DBFFFFFF')
            .fontSize($r('sys.float.Body_L'))
            .maxFontScale(
            CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
            .fontWeight(FontWeight.Medium)
            .opacity(this.itemDisable ? $r('sys.float.ohos_id_alpha_disabled') : 1)
            .key(ComponentIdKeys.SETTING_DIALOG_ITEM_DESC + this.index)
            .fontFeature('\"ss01\" on')
        }

        if (this.itemDesc) {
          Row() {
            Text(this.itemDesc)
              .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_secondary') : '#99FFFFFF')
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Regular)
              .maxFontScale(
              CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
              .lineHeight(SystemLanguageUtil.isTibetan() ? 25 : 16)
              .fontFeature('\"ss01\" on')
              .opacity(this.itemDisable ? $r('sys.float.ohos_id_alpha_disabled') : 1)
          }
          .margin({
            top: $r('sys.float.ohos_id_text_margin_vertical')
          })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)

      Stack({alignContent: Alignment.Center}) {
        Radio({ group: 'settingChildren', value: this.itemValue?.toString() })
          .width(20)
          .height(20)
          .margin(2)
          .borderColor($r('sys.color.comp_background_emphasize'))
          .opacity(this.itemDisable ? $r('sys.float.ohos_id_alpha_disabled') : 1)
          .checked(this.checkedValue === this.itemValue)
          .visibility(this.checkedValue === this.itemValue ?
          Visibility.Visible : Visibility.Hidden)
          .radioStyle({
            checkedBackgroundColor: $r('sys.color.ohos_id_color_component_activated'),
            uncheckedBorderColor: '#66FFFFFF',
          })
          .touchable(false)
          .key(ComponentIdKeys.getInstance().getKey('SettingDialog', this.functionId, this.itemValue))
      }
      .width(24)
      .height(24)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)
    }
    .key(ComponentIdKeys.getInstance().getKey('SettingDialog', this.functionId, this.itemValue))
    .width('100%')
  }
}