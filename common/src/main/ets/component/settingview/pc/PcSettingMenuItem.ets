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
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { PcSettingToggleItem } from './PcSettingToggleItem';
import lazy { PcSettingPopupItem } from './PcSettingPopupItem';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '../../../function/core/functionproperty/RenderType';
import lazy { SETTING_MENU_COMMON_ORDER, SETTING_MENU_PHOTO_ORDER, SETTING_MENU_VIDEO_ORDER } from '../SettingViewOrder';
import lazy { RecordingState } from '../../../function/recordcontrol/RecordAction';
import lazy { AnimSpecifications } from '../../../animation/AnimSpecifications';
import lazy { GlobalContext } from '../../../../ets/utils/GlobalContext';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { CameraActionType } from '../../../redux/actions/CameraActionType';
import lazy { getStates } from '../../../redux';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';
import lazy { ActionData } from '../../../redux/actions/Action';
import lazy { ActionType } from '../../../redux/actions/ActionType';

/* instrument ignore file */
const TAG: string = 'PcSettingMenuItem';
const TITLE_MARGIN_LEFT: number = 12;

class StateStruct {
  public settingFunctions: Set<FunctionId> = new Set<FunctionId>();
}

class FunctionRenderType {
  public functionId: FunctionId = FunctionId.NONE;
  public renderType: RenderType = RenderType.NONE;
}


@Component
export struct PcSettingMenuItem {
  @State settingFunctions: FunctionId[] = [];
  private menuLocation: RenderLocation = RenderLocation.NONE;
  private settingTitle: Resource | string = '';
  private WH_100_100: string = '100%';
  @Link recordingState: RecordingState;
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @State isChangeMode: boolean = false;
  @State showPicker: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear start.');
    const settingFunctionIds: Set<FunctionId> | undefined = getStates()
      .get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap')
      .get(this.menuLocation);
    this.settingFunctions = settingFunctionIds ? Array.from(settingFunctionIds) : [];
    this.sortFuncMenuItem(this.settingFunctions);
    this.initSettingTitle();
    this.mEventBus.on(ContextActionType.ABILITY_ACTIVE, this.initSettingPage.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CHANGE_MODE, this.changeMode.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_PICKER, this.getShowPickerState.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  private changeMode(): void {
    this.isChangeMode = true;
  }

  private initSettingPage(): void {
    if (this.isChangeMode) {
      HiLog.i(TAG, `initSettingPage E.`)
      const settingFunctionIds: Set<FunctionId> | undefined = getStates()
        .get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap')
        .get(this.menuLocation);
      this.settingFunctions = settingFunctionIds ? Array.from(settingFunctionIds) : [];
      this.isChangeMode = false;
      this.sortFuncMenuItem(this.settingFunctions);
      HiLog.i(TAG, `initSettingPage X.`)
    }
  }

  private getCurRecordState(): boolean {
    return this.recordingState === RecordingState.RECORDING ||
      this.recordingState === RecordingState.PAUSED || this.recordingState === RecordingState.PAUSING ||
    this.showPicker;
  }

  private getShowPickerState(data: ActionData): void {
    this.showPicker = data['showPicker'];
  }

  build() {
    if (this.settingFunctions.length > 0) {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween
      }) {
        Column() {
          Row() {
            Text(this.settingTitle)
              .margin({ top: 20, left: 24, bottom: $r('app.float.margin_value_8') })
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .opacity($r('app.float.opacity_6'))
              .fontSize($r('sys.float.Subtitle_S'))
              .lineHeight(19)
              .fontWeight(FontWeight.Medium)
              .textCase(TextCase.Normal)
              .fontFeature('\"ss01\" on')
              .margin({
                left: SystemLanguageUtil.isRTL() ? 0 : TITLE_MARGIN_LEFT,
                right: SystemLanguageUtil.isRTL() ? TITLE_MARGIN_LEFT : 0,
              })
          }
          .width(this.WH_100_100)
          .height(this.WH_100_100)
        }
        .width(this.WH_100_100)
        .height(48)

        Column() {
          List() {
            ForEach(this.settingFunctions.map((item: FunctionId) => {
              let renderType = FeatureManager.getInstance().getFunction(item).getRenderType(this.menuLocation);
              let res: FunctionRenderType = { functionId: item, renderType: renderType };
              return res;
            }), (item: FunctionRenderType) => {
              ListItem() {
                Column() {
                  if (item.renderType === RenderType.TOGGLE_SETTING_ITEM) {
                    PcSettingToggleItem({
                      functionId: item.functionId,
                      renderLocation: this.menuLocation
                    })
                  } else if (item.renderType === RenderType.POPUP_SETTING_ITEM) {
                    PcSettingPopupItem({
                      functionId: item.functionId,
                      renderLocation: this.menuLocation
                    })
                  }
                }
                .margin({top:4, bottom: 4})
                .enabled(this.getCurRecordState() ? false : true)
                .opacity(this.getCurRecordState() ? AnimSpecifications.ALPHA_HALF :
                AnimSpecifications.ALPHA_OPAQUE)
              }
            })
          }
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 0.5, color: $r('sys.color.comp_divider'), startMargin: 56, endMargin: 12 })
          .borderRadius($r('sys.float.corner_radius_level8'))
          .backgroundColor($r('sys.color.background_primary'))
          .padding({ top: $r('sys.float.padding_level2'), bottom: $r('sys.float.padding_level2') })
        }.width(this.WH_100_100)
      }
    }
  }

  private sortFuncMenuItem(funId: FunctionId[]): void {
    switch (this.menuLocation) {
      // case RenderLocation.SETTING_MENU_PHOTO:
      //   funId.sort((a, b) => (SETTING_MENU_PHOTO_ORDER.indexOf(a) - SETTING_MENU_PHOTO_ORDER.indexOf(b)));
      //   break;
      case RenderLocation.SETTING_MENU_VIDEO:
        funId.sort((a, b) => (SETTING_MENU_VIDEO_ORDER.indexOf(a) - SETTING_MENU_VIDEO_ORDER.indexOf(b)));
        break;
      case RenderLocation.SETTING_MENU_COMMON:
        funId.sort((a, b) => (SETTING_MENU_COMMON_ORDER.indexOf(a) - SETTING_MENU_COMMON_ORDER.indexOf(b)));
        break
      default:
        break;
    }
  }

  private initSettingTitle() {
    switch (this.menuLocation) {
      case RenderLocation.SETTING_MENU_PHOTO:
        this.settingTitle = $r('app.string.pic_title');
        break;
      case RenderLocation.SETTING_MENU_VIDEO:
        this.settingTitle = $r('app.string.video_title');
        break;
      case RenderLocation.SETTING_MENU_COMMON:
        this.settingTitle = $r('app.string.general');
        break;
      default:
        break;
    }
  }
}