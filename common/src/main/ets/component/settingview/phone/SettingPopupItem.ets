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
import lazy { Action, ActionData } from '../../../redux/actions/Action';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { FunctionAction } from '../../../function/core/FunctionAction';
import lazy { BaseFunction } from '../../../function/core/BaseFunction';
import lazy { UiElement } from '../../../function/core/UiElement';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { OhCombinedState, Unsubscribe, Dispatch, getStates, reduxSubscribe } from '../../../redux';
import lazy { CustomDialogDetails, CustomDialogView } from '../../customdialog/dialogComponent/CustomDialogView';
import lazy { SettingFuncDialogItemIndex } from '../SettingFuncDialogItemIndex';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { WindowDirection } from '../../../utils/WindowDirection';
import lazy { ConflictParam } from '../../../function/core/ConflictParam';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { ContextAction } from '../../../redux/actions/ContextAction';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { WindowService } from '../../../service/window/WindowService';
import lazy { PhotoFormatMode } from '../../../function/enumbase/PhotoFormatMode';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { StringResourceType } from '../../../utils/types';
import Configuration from '@system.configuration';
import lazy { PickerUtils } from '../../../utils/PickerUtils';
import ResGetter from '../../../utils/ResGetter';
import lazy { StoreManager } from '../../../worker/StoreManager';
import lazy { TreasureBoxAction } from '../../treasurebox/reduce/TreasureBoxAction';
import lazy { FunctionActionType } from '../../../redux/actions/FunctionActionType';
import lazy { ActionType } from '../../../redux/actions/ActionType';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';
import { JSON } from '@kit.ArkTS';

/* instrument ignore file */
const TAG: string = 'SettingPopupItem';

const ITEM_HEIGHT: number = 56;
const ITEM_HEIGHT_TABLET: number = 48;
const RATE_24_FPS = 24;
const RATE_30_FPS = 30;
const RATE_60_FPS = 60;

class SettingPopupDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: SettingFuncDialogItemIndex): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  };

  public closeDialog(isCloseFlag: boolean): void {
    this.mDispatch(Action.closeDialog(isCloseFlag));
  };

  public isShowWatermarkPage(isShow: boolean): void {
    this.mDispatch(Action.isShowWatermarkPage(isShow));
  };

  public resetSaveModeTimer() {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  };
}

const ROTATE_ANGLE_90: number = 90;
const TITLE_WIDTH_100: number = 100;

@Component
export struct SettingPopupItem {
  private mBase: BaseComponent = new BaseComponent();
  @State itemEnable: boolean = true;
  @State textTitle: Resource | string | undefined = undefined;
  @State isShowSemiCollapsed: boolean = false;
  @State dialogDescription: string = '';
  @State descriptionVisible: Visibility = Visibility.None;
  private mAction: SettingPopupDispatcher = new SettingPopupDispatcher();
  private functionId: FunctionId = FunctionId.NONE;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  private function: BaseFunction | undefined = undefined;
  @State uiElement: UiElement = new UiElement();
  private WH_100_100: string = '100%';
  private customDialogViewController?: CustomDialogController;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State @Watch('dialogShowChange') isDialogShow: boolean = false;
  private isFirstTime: boolean = true;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  private mRotateAngle: number = 0;
  private mTimerId: number = Number.MIN_VALUE;
  private mSubscriber: Unsubscribe | null = null;
  @State withoutPopup: boolean = false;
  @Consume @Watch('isShowSavePowerModeViewChanged') isShowSavePowerModeView: boolean;
  @State @Watch('changePopupDisplay') isShowLandscape: boolean = false;
  @StorageLink('isSettingViewScrollStart') isSettingViewScrollStart: boolean = false;
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
    itemTitle: '',
  }
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State isShowDefault: boolean = true;

  existView(): void {
    HiLog.i(TAG, 'existView E.');
    this.mAction.closeDialog(false);
    this.mAction.resetSaveModeTimer();
    this.isDialogShow = false;
    if (this.functionId === FunctionId.PHOTO_FORMAT) {
      this.popupItemChange();
    }
    StoreManager.getInstance().postMessage(TreasureBoxAction.refreshTreasureBoxView());
    HiLog.i(TAG, 'existView X.');
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private isShowSavePowerModeViewChanged(): void {
    if (this.isDialogShow && this.isShowSavePowerModeView) {
      this.customDialogViewController?.close();
    }
  }

  private changePopupDisplay(): void {
    this.withoutPopup = this.functionId === FunctionId.FRAME_RATE &&
      this.function?.getUiElements(this.renderLocation).size === 3;
  }

  private createDialog(): void {
    this.customDialogViewController = new CustomDialogController({
      builder: CustomDialogView({
        functionId: this.functionId,
        renderLocation: this.renderLocation,
        cancel: (): void => this.existView(),
        popupItemChange: (): void => this.popupItemChange(),
        rotateAngle: this.getRotateAngle(),
        currentDirection: this.mDirection,
        isShowLandscape: this.isShowLandscape,
        isShowSemiCollapsed: this.isShowSemiCollapsed,
        dialogDescription: this.dialogDescription,
        descriptionVisible: this.descriptionVisible,
      }),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      offset: { dx: this.isShowSemiCollapsed ? this.getOffset() : 0, dy: 0 },
      cancel: this.existView,
      customStyle: true,
      maskColor: '#66000000',
    });
  }

  private getRotateAngle(): number {
    return this.isShowLandscape && !this.isShowSemiCollapsed ? 0 :
      this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : this.mRotateAngle;
  }

  private getOffset(): number {
    return -(getStates().get<number>('windowReducer', 'windowWidth') / 4);
  }

  public onCloseDialog() {
    HiLog.i(TAG, 'onCloseDialog E.');
    this.mAction.closeDialog(false);
    this.customDialogViewController?.close();
    this.isDialogShow = false;
    HiLog.i(TAG, 'onCloseDialog X.');
  }

  private dialogShowChange(): void {
    GlobalContext.get().setObject('isDialogShow', this.isDialogShow);
  }

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear start.');
    this.function = FeatureManager.getInstance().getFunction(this.functionId);
    let uiElementTemp: UiElement | undefined = this.function.getUiElements(this.renderLocation).get(UiElement.DEFAULT);
    if (uiElementTemp) {
      this.uiElement = uiElementTemp;
    }
    this.popupItemChange();

    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.updateDirectionAndRotationAngle(state.get<WindowDirection>('contextReducer', 'direction'),
        state.get<number>('contextReducer', 'rotateAngle'));
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on(ActionType.ACTION_CLOSE_SETTING_DIALOG, this.onCloseDialog.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, this.onConflictParamChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_UPDATE_VIDEO_RESOLUTION, this.changePopupDisplay.bind(this), this.mBase.hashCode());
    this.descriptionVisible = FeatureManager.getInstance().getFunction(this.functionId).getValue() ==
      SettingFuncDialogItemIndex.INDEX_FIR ? Visibility.None : Visibility.Visible;
    this.withoutPopup = this.functionId === FunctionId.FRAME_RATE &&
      this.function.getUiElements(this.renderLocation).size === 3;
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear start.');
    clearTimeout(this.mTimerId);
    this.mSubscriber?.destroy();
    this.confirmDialogClose();
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear end.');
  }

  setDialogDescription(data: ActionData): void {
    HiLog.i(TAG, 'setDialogDescription: ' + data['index']);
    let value: string = ResGetter.getStringSafe($r('app.string.dynamic_frame_rate_description', RATE_24_FPS, RATE_30_FPS));
    if (data['index'] === SettingFuncDialogItemIndex.INDEX_THR) {
      value = ResGetter.getStringSafe($r('app.string.dynamic_frame_rate_description', RATE_24_FPS, RATE_60_FPS));
    }
    HiLog.i(TAG, 'setDialogDescription: ' + value);
    this.dialogDescription = value;

    if (data['index'] === SettingFuncDialogItemIndex.INDEX_FIR) {
      this.descriptionVisible = Visibility.None;
    } else {
      this.descriptionVisible = Visibility.Visible;
    }
  }

  private popupItemChange(isNeedUpdateDesc: boolean = false, data?: ActionData): void {
    HiLog.i(TAG, `popupItemChange data: ${JSON.stringify(data)}`);
    const conflictParam: ConflictParam | undefined = getStates()
      .get<Map<FunctionId, ConflictParam>>('functionReducer', 'functionConflictParamMap')
      .get(this.functionId);
    // 相机设置Popup类型赋值逻辑，this.textTitle为展示赋值，itemEnable为Popup是否可点击
    this.itemEnable = (!conflictParam || !conflictParam.disabled) && !this.uiElement.disabled;
    let uiElementKey: string = this.function?.getValue();
    // 设置页面中不同的选项会对应不同的执行函数
    // console.log('this.function', this.function?.constructor.name, this.renderLocation, uiElementKey)
    const uiElement = this.function?.getUiElements(this.renderLocation).get(uiElementKey);
    if (uiElement) {
      this.textTitle = uiElement.settingDisplayTitle || uiElement.title;
    }

    if (isNeedUpdateDesc) {
      let uiElementTemp: UiElement | undefined =
        this.function?.getUiElements(this.renderLocation).get(UiElement.DEFAULT);
      if (uiElementTemp) {
        this.uiElement = uiElementTemp;
      }
    }
    // PHOTO_FORMAT特殊流程,与现有逻辑冲突较大
    if (this.functionId === FunctionId.PHOTO_FORMAT) {
      let textValue: number;
      textValue = FeatureManager.getInstance().getFunction(this.functionId).getValue();
      FeatureManager.getInstance().getFunction(this.functionId)
        .getUiElements(RenderLocation.SETTING_MENU_PHOTO)
        .forEach((value: UiElement, key: SettingFuncDialogItemIndex | string) => {
          if (key !== UiElement.DEFAULT && value.functionValue === textValue) {
            this.textTitle = value.title;
          }
        });
      let uiElementTemp: UiElement | undefined =
        this.function?.getUiElements(this.renderLocation).get(UiElement.DEFAULT);
      if (uiElementTemp) {
        this.uiElement = uiElementTemp;
      }
    }
  }

  private onConflictParamChange(): void {
    if (this.functionId === FunctionId.FRAME_RATE) {
      this.withoutPopup = this.function?.getUiElements(this.renderLocation).size === 3;
    }
  }

  private confirmDialogClose(): void {
    clearTimeout(this.mTimerId);
    this.onCloseDialog();
  }

  private statusChange(): void {
    clearTimeout(this.mTimerId);
    if (this.isDialogShow && this.isFirstTime) {
      this.customDialogViewController?.close();
      this.isFirstTime = false;
      this.mTimerId = setTimeout((): void => {
        if (!getStates().get<boolean>('settingViewReducer', 'isShowSettingView')) {
          return;
        }
        // 录像分辨率的弹窗 需要刷一下
        if (this.functionId === FunctionId.VIDEO_RESOLUTION) {
          let defaultValue = this.function?.getUiElements(this.renderLocation).get(UiElement.DEFAULT)?.functionValue;
          let defaultTitle: Resource | string | undefined = this.function?.getUiElements(this.renderLocation)
            .get(SettingFuncDialogItemIndex.INDEX_NONE)?.title;
          let textList: StringResourceType = [];
          let descList: (string | Resource)[] = [];
          let valueList: SettingFuncDialogItemIndex[] = [];
          let disabledList: boolean[] = [];
          // 准备dialog二级窗口数据列表
          this.function?.getUiElements(this.renderLocation).forEach((value: UiElement, key: number | string) => {
            if (key !== UiElement.DEFAULT && key !== SettingFuncDialogItemIndex.INDEX_NONE) {
              if (this.functionId === FunctionId.PHOTO_FORMAT) {
                textList.push(value.title);
              } else if (defaultTitle) {
                textList.push(key !== defaultValue ? value.title : defaultTitle); // 推荐值Title使用INDEX_NONE
              }
              valueList.push(value.functionValue);
              descList.push(value.desc);
              disabledList.push(value.disabled ? true : false);
            }
          });
          this.customDialogDetails.itemTextList = textList;
          this.customDialogDetails.itemValueList = valueList;
          this.customDialogDetails.itemDescList = descList;
          this.customDialogDetails.disabledValueList = disabledList;
          this.customDialogDetails.itemTitle = this.transformTitle(UiElement.DEFAULT);
        }
        this.createDialog();
        this.customDialogViewController?.open();
        this.isFirstTime = true;
      }, 250);
    }
  }

  private directionChange(): void {
    HiLog.i(TAG, 'directionChange start.');
    if (this.mDirection === WindowDirection.BOTTOM || !this.isDialogShow || this.isShowSemiCollapsed) {
      return;
    }
    this.statusChange();
    HiLog.i(TAG, 'directionChange end.');
  }

  private updateDirectionAndRotationAngle(direction: WindowDirection, rotateAngle: number): void {
    if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer()) {
      this.mDirection = WindowDirection.RIGHT;
      this.mRotateAngle = 0;
      return;
    }
    if (PickerUtils.getIsExpandedLeftRightSplitScreenFromReducer() || this.isShowDefault) {
      this.mDirection = WindowDirection.TOP;
      this.mRotateAngle = 0;
      return;
    }
    if (WindowService.getInstance().isSubscriptionNeeded()) {
      this.mDirection = direction;
      this.mRotateAngle = rotateAngle;
    }
  }

  private isOverVerticalLayoutFontScale(): boolean {
    if (this.fontSizeScale > CommonConstants.TEXT_SIZE_LARGE) {
      return false;
    }
    return this.fontSizeScale <= CommonConstants.TEXT_SIZE_HUGE;
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      // 适老化需求，字体倍数在1.45及以内时，为左右结构
      if (this.isOverVerticalLayoutFontScale()) {
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

            if (this.uiElement?.desc) {
              Text(this.uiElement?.desc)
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
            }
          }
          .width(this.WH_100_100)
          .layoutWeight(1)
          .margin({
            left: Configuration.getLocale().dir === 'rtl' ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_l'),
            right: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.ohos_id_elements_margin_horizontal_l') : 0
          })
          .alignItems(HorizontalAlign.Start)

          Row() {
            // 弹框类型的展示值，需要根据选项进行更新，目前是没有进行回传的，一直没变。
            // 目前每一项的枚举值需要重新检查，有的选择后展示不对
            Text(this.textTitle)
              .width(SystemLanguageUtil.French() || SystemLanguageUtil.isJapanese() || SystemLanguageUtil.isRussian() ||
              SystemLanguageUtil.isTibetan() ? TITLE_WIDTH_100 : '')
              .textAlign(TextAlign.End)
              .fontColor($r('app.color.secondary'))
              .fontSize($r('sys.float.Body_M'))
              .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
              .fontWeight(FontWeight.Regular)
              .fontFeature('\"ss01\" on')
              .margin({ right: this.withoutPopup ? $r('sys.float.padding_level1') : 0 })

            this.ListItemArrowRight();
          }
      } else {
        // 适老化适配，字体倍数 >= 1.75 上下布局
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
          }
          Flex({
            direction: FlexDirection.Row,
            alignItems: ItemAlign.Center
          }) {
            if (this.uiElement?.desc) {
              Text(this.uiElement?.desc)
                .id('desc')
                .fontColor($r('app.color.secondary'))
                .fontSize($r('sys.float.Body_M'))
                .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
                .fontWeight(FontWeight.Regular)
                .textAlign(TextAlign.Start)
                .layoutWeight(1)
                .fontFeature('\"ss01\" on')
                .padding({
                  left: Configuration.getLocale().dir === 'rtl' ? 12 : 40,
                  right: Configuration.getLocale().dir === 'rtl' ? 40 : 12
                })
            }
          }
          .width(this.WH_100_100)

          Flex({
            direction: FlexDirection.Row,
            alignItems: ItemAlign.Center
          }) {
            Text(this.textTitle)
              .fontColor($r('app.color.secondary'))
              .fontSize($r('sys.float.Body_M'))
              .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
              .fontWeight(FontWeight.Regular)
              .fontFeature('\"ss01\" on')
              .layoutWeight(1)

            this.ListItemArrowRight();
          }
          .width(this.WH_100_100)
          .margin({ top: 16 })
          .padding({
            left: Configuration.getLocale().dir === 'rtl' ? 0 : 40,
            right: Configuration.getLocale().dir === 'rtl' ? 40 : 0
          })
        }
        .width(this.WH_100_100)
      }
    }
    .opacity(this.itemEnable ? 1 : 0.5)
    .borderRadius(16)
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
      top: CommonConstants.getListItemVerticalPadding(this.fontSizeScale),
      bottom: CommonConstants.getListItemVerticalPadding(this.fontSizeScale)
    })
    .width(this.WH_100_100)
    .enabled(this.itemEnable)
    .onClick((): void => {
      if (this.withoutPopup || this.uiElement.disabled) {
        return;
      }
      HiLog.i(TAG, `setting设置-----popupItemClick------点击开始`)
      this.createDialog();
      this.openDetailsDialog();
      this.isDialogShow = true;
      this.isFirstTime = true;
    })
    .key(ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', this.functionId))
    .borderRadius(16)
    .backgroundColor(Color.Transparent)
    .stateStyles({
      pressed: {
        .backgroundColor('#19ffffff')
        .borderRadius(16)
      }
    })
    .onDisAppear(() => {
      HiLog.d(TAG, 'component aboutToDisappear start');
      this.mEventBus.clear(this.mBase.hashCode());
    })
  }

  @Builder
  BreakLinePopupItemBuilder() {
    if (SystemLanguageUtil.isHansChinese()) {
      Column() {
        Text(this.uiElement.title)
          .id('Text')
          .fontColor(Color.White)
          .fontSize($r('sys.float.Body_L'))
          .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
          .fontWeight(FontWeight.Medium)
          .lineHeight(22)
          .fontFeature('\"ss01\" on')

        if (this.uiElement?.desc) {
          Text(this.uiElement?.desc)
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
        }
      }
      .width(this.WH_100_100)
      .layoutWeight(1)
      .margin({
        left: Configuration.getLocale().dir === 'rtl' ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.ohos_id_elements_margin_horizontal_l') : 0
      })
      .alignItems(HorizontalAlign.Start)

      Row() {
        Text(this.textTitle)
          .textAlign(TextAlign.End)
          .fontColor($r('app.color.secondary'))
          .fontSize($r('sys.float.Body_M'))
          .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
          .fontWeight(FontWeight.Regular)
          .fontFeature('\"ss01\" on')

        this.ListItemArrowRight();
      }
    } else {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Row() {
          Text(this.uiElement.title)
            .id('Text')
            .fontColor(Color.White)
            .fontSize($r('sys.float.Body_L'))
            .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
            .fontWeight(FontWeight.Medium)
            .lineHeight(22)
            .fontFeature('\"ss01\" on')

          if (this.uiElement?.desc) {
            Text(this.uiElement?.desc)
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
          }
        }
        .width(this.WH_100_100)

        Row() {
          Text(this.textTitle)
            .fontColor($r('app.color.secondary'))
            .fontSize($r('sys.float.Body_M'))
            .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
            .fontWeight(FontWeight.Regular)
            .fontFeature('\"ss01\" on')
            .layoutWeight(1)

          this.ListItemArrowRight();
        }
        .width(this.WH_100_100)
      }
      .margin({
        left: Configuration.getLocale().dir === 'rtl' ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.ohos_id_elements_margin_horizontal_l') : 0
      })
    }
  }

  async openDetailsDialog(): Promise<void> {
    HiLog.i(TAG, 'openDetailsDialog start.');
    // 推荐值对应Index
    let defaultValue = this.function?.getUiElements(this.renderLocation).get(UiElement.DEFAULT)?.functionValue;
    let defaultTitle: Resource | string | undefined = this.function?.getUiElements(this.renderLocation)
      .get(SettingFuncDialogItemIndex.INDEX_NONE)?.title;
    let textList: StringResourceType = [];
    let descList: (string | Resource)[] = [];
    let valueList: SettingFuncDialogItemIndex[] = [];
    let disabledList: boolean[] = [];
    // 准备dialog二级窗口数据列表
    this.function?.getUiElements(this.renderLocation).forEach((value: UiElement, key: number | string) => {
      if (key !== UiElement.DEFAULT && key !== SettingFuncDialogItemIndex.INDEX_NONE) {
        if (this.functionId === FunctionId.PHOTO_FORMAT) {
          textList.push(value.title);
        } else if (defaultTitle) {
          textList.push(key !== defaultValue ? value.title : defaultTitle); // 推荐值Title使用INDEX_NONE
        }
        valueList.push(value.functionValue);
        descList.push(value.desc);
        disabledList.push(value.disabled ? true : false);
      }
    });
    this.customDialogDetails.itemTextList = textList;
    this.customDialogDetails.itemValueList = valueList;
    this.customDialogDetails.itemDescList = descList;
    this.customDialogDetails.disabledValueList = disabledList;
    this.customDialogDetails.itemTitle = this.transformTitle(UiElement.DEFAULT);
    this.mAction.closeDialog(true);
    this.customDialogViewController?.open();
    this.isDialogShow = true;
    HiLog.i(TAG, 'openDetailsDialog end.');
  }

  private transformTitle(val: string | number): Resource | string {
    const res: Resource | string | undefined = this.function?.getUiElements(this.renderLocation).get(val)?.title;
    return res ? res : '';
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
  }

  @Builder
  ListItemArrowRight() {
    if (!this.withoutPopup) {
      Image($r('app.media.ic_public_arrow_right_black'))
        .width(12)
        .height(24)
        .fillColor(Color.White)
        .opacity($r('app.float.opacity_2'))
        .margin({
          left: Configuration.getLocale().dir === 'rtl' ? 0 : $r('sys.float.padding_level2'),
          right: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.padding_level2') : 0
        })
        .rotate({ angle: Configuration.getLocale().dir === 'rtl' ? 180 : 0 })
        .draggable(false)
    }
  }
}