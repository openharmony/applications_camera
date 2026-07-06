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
import lazy { PersistType, PreferencesService } from '../../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../../service/preferences/PropTag';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import ResGetter from '../../../utils/ResGetter';
import Configuration from '@system.configuration';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { SettingFuncDialogItemIndex } from '../SettingFuncDialogItemIndex';
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import { camera } from '@kit.CameraKit';

/* instrument ignore file */
const TAG: string = 'SettingToggleItem';

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
export struct SettingToggleItem {
  private mBase: BaseComponent = new BaseComponent();
  @State itemEnable: boolean = true;
  private functionId: FunctionId = FunctionId.NONE;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  private function: BaseFunction | undefined = undefined;
  @State uiElement: UiElement = new UiElement();
  private WH_100_100: string = '100%';
  private mAction: SettingToggleDispatcher = new SettingToggleDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State functionValue: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @StorageLink('isMirrorSupported') isMirrorSupported: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear start.');
    reduxSubscribe(null, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    this.mEventBus.on([FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, ActionType.ACTION_IS_SECURITY_CAMERA],
      this.toggleItemChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      this.onConflictParamChange.bind(this), this.mBase.hashCode());
    this.toggleItemChange();
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  protected isFrontCamera(): boolean {
    return getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
      camera.CameraPosition.CAMERA_POSITION_FRONT;
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear start.');
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private setToggleVal(conflictParam: ConflictParam | undefined): void {
    if (!this.function) {
      return;
    }
    const uiElementTemp: UiElement | undefined =
      this.function.getUiElements(this.renderLocation)?.get(UiElement.DEFAULT);
    if (uiElementTemp) {
      this.uiElement = uiElementTemp;
    }
    if (this.functionId === FunctionId.MIRROR) { // 自拍镜像禁用置灰，开关默认关闭
      const isFront = this.isFrontCamera();
      this.itemEnable = this.isMirrorSupported || (!conflictParam || !conflictParam.disabled) && isFront;
      this.functionValue = this.itemEnable ? this.function.getValue() : false;
      if (this.itemEnable) { // 镜像支持使能不展示描述
        this.uiElement.desc = '';
      }
    } else if (this.functionId === FunctionId.SAVE_GEO_LOCATION) {
      this.itemEnable = !getStates().get<boolean>('securityCameraReducer', 'isSecurityCamera');
      this.functionValue = this.function.getValue();
    } else if (this.is60fpsConflictHdrVivid()) {
      this.itemEnable = false;
      this.functionValue = false;
    } else {
      this.itemEnable = !conflictParam || !conflictParam.disabled;
      this.functionValue = this.function.getValue();
    }
    // 相机设置开关类型赋值逻辑，functionValue为开关赋值，itemEnable为按钮是否可点击
    HiLog.i(TAG, `setToggleVal functionId: ${this.functionId}, functionValue: ${this.functionValue}, itemEnable: ${this.itemEnable}`);
  }

  private toggleItemChange(): void {
    this.function = FeatureManager.getInstance().getFunction(this.functionId);
    const conflictParam: ConflictParam | undefined =
      getStates().get<Map<FunctionId, ConflictParam>>('functionReducer', 'functionConflictParamMap').get(this.functionId);
    this.setToggleVal(conflictParam);
  }

  private onConflictParamChange(data: Record<'id', number>): void {
    HiLog.i(TAG, `onConflictParamChange functionId: ${this.functionId}, data.id: ${data.id}.`);
    if (this.functionId !== data.id) {
      return;
    }
    this.toggleItemChange();
  }

  private is60fpsConflictHdrVivid(): boolean {
    return SettingFuncDialogItemIndex.INDEX_SEC ===
    FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE)?.getValue();
  }

  @Builder
  ToggleItemBuilder() {
    // 适老化需求，字体倍数在1.45及以内时，为左右结构
    if (this.fontSizeScale <= CommonConstants.TEXT_SIZE_HUGE) {
      this.ListItemImageBuilder();

      Column() {
        Text(this.uiElement.title)
          .id('Text')
          .fontColor(Color.White)
          .fontSize($r('sys.float.Body_L'))
          .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
          .fontWeight(FontWeight.Medium)
          .lineHeight(22)
          .fontFeature('\"ss01\" on')

        this.DescTextViewBuilder();
      }
      .width(this.WH_100_100)
      .layoutWeight(1)
      .margin({
        left: Configuration.getLocale().dir === 'rtl' ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.ohos_id_elements_margin_horizontal_l') : 0
      })
      .alignItems(HorizontalAlign.Start)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)

      Row() {
        this.ListItemToggleBuilder();
      }
      .height(20)
      .id('Toggle')
    } else {
      //适老化适配，1.75倍数以上布局，上下结构
      Column() {
        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center
        }) {
          this.ListItemImageBuilder();

          Text(this.uiElement.title)
            .id('Text')
            .fontColor(Color.White)
            .fontSize($r('sys.float.Body_L'))
            .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
            .fontWeight(FontWeight.Medium)
            .lineHeight(22)
            .fontFeature('\"ss01\" on')
            .width(this.WH_100_100)
            .layoutWeight(1)
            .margin({
              left: Configuration.getLocale().dir === 'rtl' ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_l'),
              right: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.ohos_id_elements_margin_horizontal_l') : 0
            })
            .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)

          this.ListItemToggleBuilder();
        }
        .width(this.WH_100_100)

        this.DescTextViewBuilder();
      }
      .width(this.WH_100_100)
    }
  }

  @Builder
  DescTextViewBuilder() {
    if (this.uiElement?.desc) {
      if (this.fontSizeScale <= CommonConstants.TEXT_SIZE_HUGE) {
        Text(this.uiElement.desc)
          .id('desc')
          .fontColor($r('app.color.secondary'))
          .fontSize($r('sys.float.Body_M'))
          .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
          .fontWeight(FontWeight.Regular)
          .margin({
            top: 2,
            left:  Configuration.getLocale().dir === 'rtl' ? 12 : 0,
            right: Configuration.getLocale().dir === 'rtl' ? 0 : 12,
          })
          .fontFeature('\"ss01\" on')
          .accessibilityText(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      } else {
        Column() {
          Text(this.uiElement.desc)
            .id('desc')
            .fontColor($r('app.color.secondary'))
            .fontSize($r('sys.float.Body_M'))
            .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
            .fontWeight(FontWeight.Regular)
            .fontFeature('\"ss01\" on')
            .width(this.WH_100_100)
        }
        // 设置padding值使列表项中title和desc首尾对齐
        .padding({
          top: 16,
          left: 40,
          right: 48
        })
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)
      }
    }
  }


  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      this.ToggleItemBuilder();
    }
    .opacity(this.itemEnable ? 1 : 0.5)
    //适老化，根据系统字体大小设置对应的padding
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
      top: CommonConstants.getListItemVerticalPadding(this.fontSizeScale),
      bottom: CommonConstants.getListItemVerticalPadding(this.fontSizeScale)
    })
    .width(this.WH_100_100)
    .enabled(this.itemEnable)
    .accessibilityGroup(true)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .key(ComponentIdKeys.getInstance().getKey('SettingItemTOGGLE', this.functionId))
    .accessibilityText(`${ResGetter.getStringSafe(this.uiElement.title)} ${
    ResGetter.getStringSafe(this.uiElement.desc)}`)
    .onDisAppear(() => {
      HiLog.d(TAG, 'component aboutToDisappear start');
      this.mEventBus.clear(this.mBase.hashCode());
    })
  }

  @Builder
  ListItemImageBuilder() {
    Column() {
      Image(this.uiElement?.icon)
        .id('image')
        .width(24)
        .height(24)
        .draggable(false)
        .fillColor(Color.White)
    }
    .justifyContent(FlexAlign.Center)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)
  }

  @Builder
  ListItemToggleBuilder() {
    Toggle({
      type: ToggleType.Switch,
      isOn: this.functionValue
    })
      .width($r('app.float.toggle_width'))
      .height($r('app.float.toggle_height'))
      .selectedColor($r('app.color.toggle_activated'))
      .switchPointColor($r('app.color.toggle_point'))
      .onClick((): void => {
        if (this.functionId === FunctionId.EFFICIENT_VIDEO && !AppStorage.get('userChangeEfficientVideo')) {
          AppStorage.setOrCreate('userChangeEfficientVideo', true);
        }
      })
      .onChange((isOn: boolean) => {
        HiLog.i(TAG, `settingItemToggle functionId: ${this.functionId}, onChange: ${isOn}.`);
        if (this.functionValue === isOn) {
          return;
        }
        if (this.functionId === FunctionId.EFFICIENT_VIDEO && isOn && PreferencesService.getInstance()
          .getPropValue(PersistType.FOREVER, PropTag.LAST_HDR_VIVID, false) as boolean) {
          // HDR开启，关闭高效视频格式，再次开启高效视频格式时，同步开启HDR，这里只需要开始HDR开关，HDR逻辑中会同步开启高效视频格式
        } else {
          this.mAction.changeFunctionValue(this.functionId, isOn);
          if (this.functionId === FunctionId.SAVE_GEO_LOCATION) {
            this.functionValue = isOn;
          }
        }
      })
      .enabled(this.itemEnable)
      .hoverEffect(HoverEffect.None)
      .key(ComponentIdKeys.getInstance().getKey('SettingItemComponentTOGGLE', this.functionId))
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
  }
}