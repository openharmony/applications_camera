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
import lazy { SettingToggleItem } from './SettingToggleItem';
import lazy { SettingPopupItem } from './SettingPopupItem';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '../../../function/core/functionproperty/RenderType';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { SETTING_MENU_COMMON_ORDER, SETTING_MENU_PHOTO_ORDER, SETTING_MENU_VIDEO_ORDER } from '../SettingViewOrder';
import Configuration from '@system.configuration';
import lazy { getStates, OhCombinedState } from '../../../redux';
import lazy { reduxSubscribe, Unsubscribe } from '../../../redux/Store';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { window } from '@kit.ArkUI';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'SettingMenuItem';

const TITLE_MARGIN_BOTTOM_TABLET: number = 10;
const TITLE_MARGIN_BOTTOM_PHONE: number = 8;
const TITLE_MARGIN_LEFT: number = 12;
const TITLE_MARGIN_TOP: number = 32;

class FunctionStruct {
  public functionId: FunctionId = FunctionId.NONE;
  public renderType: RenderType = RenderType.NONE;
}

@Component
export struct SettingMenuItem {
  @State settingFunctions: FunctionId[] = [];
  @State @Watch('onWindowStatusChange') windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  private menuLocation: RenderLocation = RenderLocation.NONE;
  private settingTitle: Resource | string = '';
  private WH_100_100: string = '100%';
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear start.');
    this.initSettingFunctions();
    this.initSettingTitle();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.windowStatus = state.get<window.WindowStatusType>('windowReducer', 'windowStatus');
    }, null);
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  aboutToDisappear(): void {
    this.mSubscriber.destroy();
  }

  private initSettingFunctions(): void {
    const settingFunctionIds: Set<FunctionId> | undefined = getStates()
      .get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap')
      .get(this.menuLocation);
    this.settingFunctions = settingFunctionIds ? Array.from(settingFunctionIds) : [];
    this.settingFunctions = this.settingFunctions
      .filter(item => FeatureManager.getInstance().getFunction(item).isAvailable());
    this.sortFuncMenuItem(this.settingFunctions);
  }

  private onWindowStatusChange(): void {
    // 直板机Picker分屏不支持水平仪
    const isInSplitScreen: boolean = this.windowStatus === window.WindowStatusType.SPLIT_SCREEN;
    const isShowDefault: boolean = getStates().get<boolean>('collapsReducer', 'isShowDefault');
    const isPicker: boolean = GlobalContext.get().getIsPicker();
    if (isInSplitScreen && isShowDefault && isPicker && DeviceInfo.isPhone()) {
      this.settingFunctions = this.settingFunctions.filter(item => item !== FunctionId.HORIZONTAL_LEVEL);
    } else {
      this.initSettingFunctions();
    }
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
              .fontColor(Color.White)
              .opacity($r('app.float.opacity_6'))
              .fontSize(DeviceInfo.isTablet() ? $r('sys.float.Subtitle_S') : $r('app.float.font_14'))
              .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
              .lineHeight(Configuration.getLocale().dir === 'rtl' ?
                (DeviceInfo.isTablet() ? $r('sys.float.Subtitle_S') : 19) : 22)
              .fontWeight(DeviceInfo.isTablet() ? FontWeight.Medium : FontWeight.Bold)
              .fontFeature('\"ss01\" on')
              .margin({
                left: SystemLanguageUtil.isRTL() ? 0 : TITLE_MARGIN_LEFT,
                right: SystemLanguageUtil.isRTL() ? TITLE_MARGIN_LEFT : 0,
              })
          }
          .width(this.WH_100_100)
          .alignItems(VerticalAlign.Bottom)
        }
        .width(this.WH_100_100)
        .margin({
          top: TITLE_MARGIN_TOP,
          bottom: DeviceInfo.isTablet() ? TITLE_MARGIN_BOTTOM_TABLET : TITLE_MARGIN_BOTTOM_PHONE
        })

        Column() {
          List() {
            ForEach(this.settingFunctions.map((item: FunctionId) => {
              const renderType = FeatureManager.getInstance().getFunction(item).getRenderType(this.menuLocation);
              let res: FunctionStruct = { functionId: item, renderType: renderType };
              return res;
            }), (item: FunctionStruct, index: number) => {
              ListItem() {
                Column() {
                  if (item.renderType === RenderType.TOGGLE_SETTING_ITEM) {
                    SettingToggleItem({
                      functionId: item.functionId,
                      renderLocation: this.menuLocation
                    })
                  } else if (item.renderType === RenderType.POPUP_SETTING_ITEM) {
                    SettingPopupItem({
                      functionId: item.functionId,
                      renderLocation: this.menuLocation
                    })
                  }
                }
              }
            })
          }
          .listDirection(Axis.Vertical)
          .divider({
            strokeWidth: 0.5,
            color: $r('sys.color.font_on_fourth'),
            startMargin: 52,
            endMargin: $r('sys.float.padding_level6')
          })
          .borderRadius(20)
          .backgroundColor('#19FFFFFF')
          .padding($r('sys.float.padding_level2'))
        }.width(this.WH_100_100)
      }
    }
  }

  private sortFuncMenuItem(funId: FunctionId[]): FunctionId[] {
    switch (this.menuLocation) {
      case RenderLocation.SETTING_MENU_PHOTO:
        return funId.sort((a, b) => (SETTING_MENU_PHOTO_ORDER.indexOf(a) - SETTING_MENU_PHOTO_ORDER.indexOf(b)));
      case RenderLocation.SETTING_MENU_VIDEO:
        return funId.sort((a, b) => (SETTING_MENU_VIDEO_ORDER.indexOf(a) - SETTING_MENU_VIDEO_ORDER.indexOf(b)));
      case RenderLocation.SETTING_MENU_COMMON:
        return funId.sort((a, b) => (SETTING_MENU_COMMON_ORDER.indexOf(a) - SETTING_MENU_COMMON_ORDER.indexOf(b)));
      default:
        return funId;
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