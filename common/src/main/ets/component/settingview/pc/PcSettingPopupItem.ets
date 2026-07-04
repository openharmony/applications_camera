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

import lazy { Action } from '../../../redux/actions/Action';
import lazy { CustomDialogDetails, CustomDialogView } from '../../customdialog/dialogComponent/CustomDialogView';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { Dispatch, reduxSubscribe } from '../../../redux';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { BaseFunction } from '../../../function/core/BaseFunction';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { FunctionAction } from '../../../function/core/FunctionAction';
import lazy { SettingFuncDialogItemIndex } from '../SettingFuncDialogItemIndex';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { ContextAction } from '../../../redux/actions/ContextAction';
import lazy { StringResourceType } from '../../../utils/types';
import lazy { ContextManager } from '../../../service/context/ContextManager';
import lazy { ConfigurationConstant } from '@kit.AbilityKit';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { BlurAnimateUtil } from '../../../utils/BlurAnimateUtil';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'PcSettingPopupItem';
const MENU_ITEM_HEIGHT: number = 40;

class SetResolutionDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: SettingFuncDialogItemIndex): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public closeDialog(isCloseFlag: boolean): void {
    this.mDispatch(Action.closeDialog(isCloseFlag));
  }

  public isUpdateAspectRatio(): void {
    this.mDispatch(Action.isUpdateAspectRatio());
  }

  public resetSaveModeTimer(): void {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  };
}

@Component
export struct PcSettingPopupItem {
  private mBase: BaseComponent = new BaseComponent();
  @State textTitle: Resource | string | undefined = undefined;
  private mAction: SetResolutionDispatcher = new SetResolutionDispatcher();
  private functionId: FunctionId = FunctionId.NONE;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  private function: BaseFunction | undefined = undefined;
  private uiElement: UiElement = new UiElement();
  private WH_100_100: string = '100%';
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  customDialogView: CustomDialogController = new CustomDialogController({
    builder: CustomDialogView({
      functionId: this.functionId,
      renderLocation: this.renderLocation,
      cancel: (): void => this.existView()
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    cancel: this.existView,
    customStyle: true,
    maskColor: $r('sys.color.mask_fourth'),
  });
  @Provide customDialogDetails: CustomDialogDetails = {
    confirmCallback: () => {
    },
    confirmItem: true,
    height: 256,
    width: 256,
    itemTextList: [],
    itemValueList: [],
    itemDescList: [],
    disabledValueList: [],
    itemTitle: ''
  };
  @State private isShow: boolean = false;
  private mFeatureManager: FeatureManager = FeatureManager.getInstance();
  @State private isShowMenu: boolean = true;
  @State pcSelected: Resource = $r('app.media.pc_menu_item_selected');
  @State isHover: boolean = false;

  existView() {
    HiLog.i(TAG, 'existView E.');
    this.mAction.closeDialog(false);
    HiLog.i(TAG, 'existView X.');
  }

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.function = FeatureManager.getInstance().getFunction(this.functionId);
    const uiElementTemp: UiElement | undefined =
      this.function?.getUiElements(this.renderLocation)?.get(UiElement.DEFAULT);
    if (uiElementTemp) {
      this.uiElement = uiElementTemp;
    }
    this.popupItemChange();

    reduxSubscribe(null, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.popupItemChange.bind(this),
      this.mBase.hashCode());
    this.getPcSelectedColor();
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear() {
    this.isShow = false;
    this.mEventBus.clear(this.mBase.hashCode());
  }

  public onCloseDialog() {
    HiLog.i(TAG, 'onCloseDialog E.');
    this.mAction.closeDialog(false);
    this.customDialogView.close();
    HiLog.i(TAG, 'onCloseDialog X.');
  }

  private getPcSelectedColor(): void {
    let abilityStageContext = ContextManager.getInstance().getAbilityStageContext();
    HiLog.i(TAG, `getPcSelected colorMode ${abilityStageContext?.config.colorMode}`);
    if (abilityStageContext?.config.colorMode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      this.pcSelected = $r('app.media.pc_menu_item_selected_white');
    } else if (abilityStageContext?.config.colorMode == ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      this.pcSelected = $r('app.media.pc_menu_item_selected');
    }
  }

  private popupItemChange(): void {
    this.textTitle = this.function?.getUiElements(this.renderLocation).get(this.function.getValue())?.title;
    this.onItemStateChange();
  }

  private onItemStateChange(): void {
    let textList: StringResourceType = [];
    let defaultTitle: Resource | string | undefined = this.function?.getUiElements(this.renderLocation)
    ?.get(SettingFuncDialogItemIndex.INDEX_NONE)?.title;
    let defaultValue: number | undefined = this.function?.getUiElements(this.renderLocation)
    ?.get(UiElement.DEFAULT)?.functionValue;
    this.function?.getUiElements(this.renderLocation).forEach((value: UiElement, key: number | string) => {
      if (key !== UiElement.DEFAULT && key !== SettingFuncDialogItemIndex.INDEX_NONE) {
        if (defaultTitle) {
          textList.push(key !== defaultValue ? value.title : defaultTitle); // 推荐值Title使用INDEX_NONE
        }
      }
    })
    this.isShowMenu = textList.length > 1 ? true : false;
    this.isShow = false;
  }

  private onContextMenuAppear(): void {
    HiLog.i(TAG, 'openDetailsDialog start.');
    const textList: StringResourceType = [];
    const valueList: SettingFuncDialogItemIndex[] = [];
    const disabledList: boolean[] = [];
    // 准备dialog二级窗口数据列表
    this.function?.getUiElements(this.renderLocation).forEach((value: UiElement, key: number | string) => {
      if (key !== UiElement.DEFAULT && key !== SettingFuncDialogItemIndex.INDEX_NONE) {
        textList.push(value.title);
        valueList.push(value.functionValue);
        disabledList.push(value.disabled ? true : false);
      }
    });
    this.customDialogDetails.itemTextList = textList;
    this.customDialogDetails.itemValueList = valueList;
    this.customDialogDetails.disabledValueList = disabledList;
    this.customDialogDetails.itemTitle = this.transformTitle(UiElement.DEFAULT);
  }

  @Builder
  MenuItemBuilderNormal(menuGroup: Resource, index: number) {
    MenuItem({
      content: menuGroup, endIcon: this.mFeatureManager?.getFunction(this.functionId)?.getValue() ===
      this.customDialogDetails.itemValueList[index] ? this.pcSelected : undefined
    })
      .selected(this.mFeatureManager?.getFunction(this.functionId)?.getValue() ===
      this.customDialogDetails.itemValueList[index])
      .onClick(() => {
        if (!this.customDialogDetails?.disabledValueList[index]) {
          if (this.functionId === FunctionId.ASPECT_RATIO || this.functionId === FunctionId.VIDEO_RESOLUTION ||
            this.functionId === FunctionId.FRAME_RATE) {
            BlurAnimateUtil.generatePixelMapFromSurface();
          }
          HiLog.i(TAG, `onClick checkedValue: ${this.mFeatureManager?.getFunction(this.functionId)?.getValue()},
           itemValue: ${this.customDialogDetails?.itemValueList[index]},${this.functionId}.`);
          if (this.mFeatureManager?.getFunction(this.functionId)
            .getValue() !== this.customDialogDetails.itemValueList[index]) {
            if (this.functionId === FunctionId.ASPECT_RATIO || this.functionId === FunctionId.VIDEO_RESOLUTION) {
              this.mAction.isUpdateAspectRatio();
            }
            this.mAction.changeFunctionValue(this.functionId, this.customDialogDetails.itemValueList[index]);
          }
          this.mAction.resetSaveModeTimer();
        }
      })
      .height(MENU_ITEM_HEIGHT)
      .margin({ top: $r('sys.float.padding_level1') })
  }

  @Builder
  ClickMenuBuilder() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Start
    }) {
      Menu() {
        ForEach(this.customDialogDetails.itemTextList, (menuGroup: Resource, index: number) => {
          this.MenuItemBuilderNormal(menuGroup, index);
        })
      }
    }
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
                .margin({ left: 16 })
                .fontColor($r('sys.color.font_primary'))
                .fontSize($r('sys.float.Subtitle_M'))
                .fontWeight(FontWeight.Regular)
                .fontFeature('\"ss01\" on')
                .margin({
                  left: SystemLanguageUtil.isRTL() ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_l'),
                  right: SystemLanguageUtil.isRTL() ? $r('sys.float.ohos_id_elements_margin_horizontal_l') : 0
                })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          if (this.uiElement.desc) {
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

          Row() {
            Text(this.textTitle)
              .fontColor($r('sys.color.font_primary'))
              .fontSize($r('sys.float.Subtitle_S'))
              .fontWeight(FontWeight.Regular)
              .opacity($r('app.float.opacity_6'))
              .fontFeature('\"ss01\" on')
            Image($r('app.media.ic_public_arrow_right_black'))
              .width(12)
              .height(24)
              .fillColor($r('sys.color.icon_primary'))
              .opacity(this.isShowMenu ? $r('app.float.opacity_2') : 0)
              .margin({ left: 4 })
              .draggable(false)
              .rotate({ angle: SystemLanguageUtil.isRTL() ? 180 : 0 })
          }
          .height('100%')
          .bindContextMenu(this.isShow && this.isShowMenu, this.ClickMenuBuilder, {
            aboutToAppear: () => {
              this.getPcSelectedColor();
              this.onContextMenuAppear();
            },
            placement: Placement.RightTop,
            onDisappear: () => {
              if (this.isShow) {
                this.isShow = false;
              }
            }
          })
        }
        .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
        .backgroundColor(this.isHover && this.isShowMenu ?
        $r('sys.color.interactive_hover') : Color.Transparent)
        .borderRadius(this.isHover ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level2'))
        .stateStyles({
          pressed: {
            .backgroundColor($r('sys.color.interactive_click'))
            .borderRadius($r('sys.float.corner_radius_level4'))
          },
        })
        .onHover((isHover: boolean, event: HoverEvent) => {
          this.isHover = isHover;
        })
      }
      .width(this.WH_100_100)
      .height(this.uiElement?.desc ? 56 : 40)
      .onClick(()=>{
        this.isShow = !this.isShow;
      })
      .key(ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', this.functionId))
    }
  }

  private transformTitle(val: string | number): Resource | string {
    const res: Resource | string | undefined = this.function?.getUiElements(this.renderLocation).get(val)?.title;
    return res ? res : '';
  }
}