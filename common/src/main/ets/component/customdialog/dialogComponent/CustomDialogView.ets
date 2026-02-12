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
import lazy { ContextAction } from '../../../redux/actions/ContextAction';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { Dispatch, OhCombinedState, Unsubscribe, getStates, reduxSubscribe } from '../../../redux';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import EntryComponent from './EntryComponent';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { SettingFuncDialogItemIndex } from '../../settingview/SettingFuncDialogItemIndex';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { WindowDirection } from '../../../utils/WindowDirection';
import lazy {
  DIALOG_DEFAULT_MARGIN,
  DIALOG_WIDTH_LANDSCAPE,
  DIALOG_WIDTH_TABLET,
  DIALOG_WIDTH_VDE_SEMI_COLLAPSED,
  PhoneCustomDialogOperate
} from './PhoneCustomDialogOperate';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { FunctionAction } from '../../../function/core/FunctionAction';
import CommonEventManager, { CUSTOM_EVENTS } from '../../commonevent/CommonEventManager';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import ResGetter from '../../../utils/ResGetter';
import lazy { AccessibilityUtils } from '../../../utils/AccessibilityUtils';
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';
import { CommonConstants } from '../../../statistics/CommonConstants';
import { JSON } from '@kit.ArkTS';

/* instrument ignore file */
const TAG: string = 'CustomDialogView';

const HEIGHT_TITTLE_BAR: number = 56;
const COLLAPS_AREA_HALF: number = 40;
const HEIGHT_TOP: number = 56;
const HEIGHT_BOTTOM: number = 56;
const MARGIN_LIST_BUTTON: number = 8;
const ALL_PADDING_HEIGHT: number = 56;
const MAX_DIALOG_TITLE_HEIGHT = 40;
const MAX_DIALOG_BUTTON_HEIGHT = 32;

@Observed
export class CustomDialogDetails {
  public confirmCallback: Function = () => {
  };
  public confirmItem: boolean = false;
  public height: number = 0;
  public width: number = 0;
  public itemTextList: (string | Resource)[] = [];
  public itemValueList: SettingFuncDialogItemIndex[] = [];
  public itemDescList: (string | Resource)[] = [];
  public itemTitle: Resource | string = '';
  public disabledValueList: boolean[] = [];
}

class CustomDialogDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public closeDialog(isCloseFlag: boolean): void {
    this.mDispatch(Action.closeDialog(isCloseFlag));
  };

  public resetSaveModeTimer() {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  };

  public changeFunctionValue(id: FunctionId, value: SettingFuncDialogItemIndex): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  };
}

class LocalStyleCls {
  public columns: number = 0;
  public offset: number = 0;
}

@CustomDialog
export struct CustomDialogView {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mAction: CustomDialogDispatcher = new CustomDialogDispatcher();
  mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  localStyle: LocalStyleCls = { columns: 4, offset: 0 };
  controller?: CustomDialogController;
  cancel: () => void = () => {
  };
  popupItemChange: () => void = () => {
  };
  confirm: () => void = () => {
  };
  functionId: FunctionId = FunctionId.NONE;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  rotateAngle: number = 0;
  currentDirection: number = WindowDirection.TOP;
  @State isShowLandscape: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowDefault: boolean = false;
  @Consume customDialogDetails: CustomDialogDetails;
  private isVertical: boolean = true;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State isHalfCollapsLEM: boolean = false;
  @State isButtonTouchDown: boolean = false;
  @State dialogDescription: string = '';
  @State descriptionVisible: Visibility = Visibility.None;
  @State listHeight: Length = 0;
  @State checkedValue: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_NONE;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  //限制弹窗中列表的最大高度
  private listMaxHeight: Length = 0;
  @State isHighContrastText: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;

  async aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear start.');
    if (DeviceInfo.isPcAndTablet()) {
      this.localStyle = { columns: 12, offset: 4 };
    } else {
      this.localStyle = { columns: 4, offset: 0 };
    }
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.customDialogClose.bind(this),
      this.mBase.hashCode());

    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isHighContrastText = state.get<boolean>('contextReducer', 'isHighContrastText');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.isVertical = this.currentDirection === WindowDirection.TOP || this.currentDirection === WindowDirection.BOTTOM;
    this.listMaxHeight = this.getListMaxHeight();
    HiLog.i(TAG, `consume customDialogDetails: ${JSON.stringify(this.customDialogDetails)}.`);
    HiLog.i(TAG, `isVertical currentDirection: ${this.currentDirection} ${this.isVertical}.`);
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  private customDialogClose(): void {
    this.controller?.close();
  }

  public onChange(): void {
    HiLog.i(TAG, 'onChange start.');
    this.popupItemChange()
    this.mAction.closeDialog(false);
    this.mAction.resetSaveModeTimer();
    this.controller?.close();
    this.cancel();
    HiLog.i(TAG, 'onChange end.');
  }

  private itemClick(index: number): void {
    if (!this.customDialogDetails.disabledValueList[index]) {
      HiLog.i(TAG, `onClick checkedValue: ${this.checkedValue}, itemValue: ${this.customDialogDetails.itemValueList[index]}.`);
      if (this.checkedValue !== this.customDialogDetails.itemValueList[index]) {
        this.changeFunctionValue(this.functionId, this.customDialogDetails.itemValueList[index]);
      }

      if (!this.isOpenTouchGuide) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(
          ResGetter.getStringSafe($r('app.string.accessibility_checked')) +
          ResGetter.getStringSafe(this.customDialogDetails.itemTextList[index]) +
          ResGetter.getStringSafe(this.customDialogDetails.itemDescList[index]) +
          ResGetter.getStringSafe($r('app.string.accessibility_radio_button')));
      }

      this.onChange();
    }
  }

  changeFunctionValue(functionId: FunctionId, index: SettingFuncDialogItemIndex): void {
    if (GlobalContext.get().getIsPicker() && DeviceInfo.isPc()) {
      CommonEventManager.getInstance().publishCommonEventMg(CUSTOM_EVENTS.CHANGE_FUNCTION_VAL,
        { isPicker: true, functionId: functionId, functionValue: index });
      this.mAction.changeFunctionValue(functionId, index);
    } else {
      this.mAction.changeFunctionValue(functionId, index);
    }
  }

  private getWidth(): Length {
    if (DeviceInfo.isTablet()) {
      return DIALOG_WIDTH_TABLET;
    }
    if (this.isVdeSemiCollapsed && !this.isVertical) {
      return DIALOG_WIDTH_VDE_SEMI_COLLAPSED;
    }
    if (!this.isShowLandscape && this.isVertical) {
      HiLog.i(TAG, `windowWidth: ${this.windowWidth}, width: ${this.windowWidth - DIALOG_DEFAULT_MARGIN}.`);
      return Math.min(this.windowWidth - DIALOG_DEFAULT_MARGIN, DIALOG_WIDTH_LANDSCAPE);
    }
    HiLog.i(TAG, `windowWidth: ${this.windowWidth}, width: ${DIALOG_WIDTH_LANDSCAPE}.`);
    return DIALOG_WIDTH_LANDSCAPE;
  }

  private getOffsetX(): number {
    // at collaps status of lem,  x offset should be recalculated by window height
    let result: number = 0;
    return result;
  }

  /**
   * 获取弹窗中选择列表可在当前状态的页面中显示的最大高度
   * @returns
   * 竖屏状态时 ：屏幕高度 - 状态栏 - 标题栏 - 导航栏 - Dialog中padding距离 - dialog中标题和按钮字体高度
   * 横屏状态时 ：屏幕高度 - 状态栏 - 导航栏 - Dialog中padding距离 - dialog中标题和按钮字体高度
   */
  private getListMaxHeight(): Length {
    if (this.isShowSemiCollapsed) {
      return this.windowWidth / 2 * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT -
        MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT;
    } else if (this.isVertical) {
      return this.windowHeight * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT -
        MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT;
    } else {
      return this.windowWidth * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT -
        MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT;
    }
  }

  private getAccessibilityText(index: number, itemText: Resource): string {
    if (!this.isOpenTouchGuide) {
      return ' ';
    }
    return (this.checkedValue === this.customDialogDetails.itemValueList[index] ?
    ResGetter.getStringSafe($r('app.string.accessibility_checked')) :
    ResGetter.getStringSafe($r('app.string.accessibility_unchecked'))) +
    ResGetter.getStringSafe(itemText) +
    ResGetter.getStringSafe(this.customDialogDetails.itemDescList[index]) +
    ResGetter.getStringSafe($r('app.string.accessibility_radio_button'))
  }

  private getAccessibilityDescription(index: number): string {
    if (!this.isOpenTouchGuide) {
      return ' ';
    }
    if (this.customDialogDetails.disabledValueList[index]) {
      return ResGetter.getStringSafe($r('app.string.accessibility_not_clickable'));
    }
    return ResGetter.getStringSafe($r('app.string.accessibility_clickable'));
  }

  build() {
    if (DeviceInfo.isPc()) {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Column() {
          Row() {
            Text(this.customDialogDetails.itemTitle)
              .fontSize($r('sys.float.Subtitle_S'))
              .fontColor(DeviceInfo.isPc() ? $r('sys.color.ohos_id_color_text_primary') : '#DBFFFFFF')
              .opacity(0.9)
              .fontWeight(FontWeight.Medium)
              .opacity($r('sys.float.ohos_id_alpha_content_primary'))
              .key(ComponentIdKeys.SETTING_DIALOG_TITLE + 1)
              .fontFeature('\"ss01\" on')
          }
          .width('100%')
          .height(56)

          List() {
            ForEach(this.customDialogDetails.itemTextList, (itemText: Resource, index: number = 0) => {
              ListItem() {
                EntryComponent({
                  itemText: itemText,
                  itemDisable: this.customDialogDetails.disabledValueList[index],
                  itemValue: this.customDialogDetails.itemValueList[index],
                  itemDesc: this.customDialogDetails.itemDescList[index],
                  functionId: this.functionId,
                  renderLocation: this.renderLocation,
                  checkedValue: this.checkedValue
                }).hitTestBehavior(HitTestMode.Transparent)
              }
              .onClick(() => {
                this.itemClick(index);
              })
              .height(48)
              .width('100%')
            })
          }
          .listDirection(Axis.Vertical)
          .divider({
            strokeWidth: 0.5,
            color: $r('sys.color.comp_divider'),
            startMargin: 0,
            endMargin: 12
          }) // 每行之间的分界线

          Column() {
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text($r('app.string.cancel'))
                .fontSize($r('sys.float.Body_L'))
                .fontColor(this.isHighContrastText ? Color.White : $r('sys.color.brand_font_contrary'))
                .fontWeight(FontWeight.Medium)
                .textCase(TextCase.UpperCase)
                .key(ComponentIdKeys.SETTING_DIALOG_CANCEL_TEXT + 1)
                .fontFeature('\"ss01\" on')
            }
            .height(40)
            .width(208)
            .margin({ top: 8 })
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .borderRadius($r('sys.float.corner_radius_level4'))
            .onClick((): void => {
              HiLog.i(TAG, 'onClick cancel');
              this.mAction.closeDialog(false);
              this.controller?.close();
              this.cancel();
            })
            .key(ComponentIdKeys.SETTING_DIALOG_ITEM_CANCEL_1)
          }
        }
        .width(DIALOG_WIDTH_TABLET)
        .backgroundColor(DeviceInfo.isPc() ? $r('sys.color.ohos_id_color_dialog_bg') : '#000000')
        .padding({
          left: $r('sys.float.padding_level12'),
          right: $r('sys.float.padding_level12'),
          bottom: $r('sys.float.padding_level8')
        })
        .borderRadius($r('sys.float.corner_radius_level8'))
      }
    } else {
      Flex({ justifyContent: FlexAlign.Center }) {
        GridRow(PhoneCustomDialogOperate.getGridRowData(this.isVertical)) {
          GridCol({ span: 12 }) {
            Column() {
              Text(this.customDialogDetails.itemTitle)
                .fontSize($r('sys.float.Title_S'))
                .margin({ top: DeviceInfo.isTablet() ? 15 : 13, bottom: DeviceInfo.isTablet() ? 15 : 13 })
                .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_primary') : '#DBFFFFFF')
                .fontWeight(FontWeight.Bold)
                .key(ComponentIdKeys.SETTING_DIALOG_TITLE + 1)
                .fontFeature('\"ss01\" on')
                .maxLines(2)
                .textOverflow({
                  overflow: TextOverflow.Ellipsis
                })

              GridContainer({ columns: this.localStyle.columns, gutter: 12, margin: 12 }) {
                // 列表最外层布局，用于限制list高度
                Column() {
                  // 用于显示可滑动的list
                  Scroll(){
                    Column() {
                      List() {
                        ForEach(this.customDialogDetails.itemTextList, (itemText: Resource, index: number = 0) => {
                          ListItem() {
                            EntryComponent({
                              itemText: itemText,
                              itemDisable: this.customDialogDetails.disabledValueList[index],
                              itemValue: this.customDialogDetails.itemValueList[index],
                              itemDesc: this.customDialogDetails.itemDescList[index],
                              functionId: this.functionId,
                              renderLocation: this.renderLocation,
                              checkedValue: this.checkedValue
                            }).hitTestBehavior(HitTestMode.Transparent)
                          }
                          .padding({
                            left: $r('sys.float.padding_level6'),
                            right: $r('sys.float.padding_level6'),
                            top: this.isIncludeDesc(index) ? $r('sys.float.padding_level8') : $r('sys.float.padding_level6'),
                            bottom: this.isIncludeDesc(index) ? $r('sys.float.padding_level8') : $r('sys.float.padding_level6')
                          })
                          .backgroundColor(Color.Transparent)
                          .stateStyles({
                            pressed: {
                              .backgroundColor(DeviceInfo.isPc() ? $r('sys.color.interactive_click') : '#19FFFFFF')
                              .borderRadius($r('sys.float.corner_radius_level8'))
                            }
                          })
                          .accessibilityGroup(true)
                          .accessibilityText(this.getAccessibilityText(index, itemText))
                          .accessibilityDescription(this.getAccessibilityDescription(index))
                          .onClick(() => {
                            this.itemClick(index);
                          })
                          .width('100%')
                        })
                        ListItem() {
                          Column() {
                            Row() {
                              Text(this.dialogDescription)
                                .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_secondary') : '#99FFFFFF')
                                .fontSize($r('sys.float.Body_M'))
                                .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
                                .fontWeight(FontWeight.Regular)
                                .lineHeight(16)
                                .backgroundColor(Color.Transparent)
                                .accessibilityGroup(true)
                                .accessibilityText(ResGetter.getStringSafe(this.dialogDescription))
                                .visibility(Visibility.None)
                                .padding({
                                  left: $r('sys.float.padding_level6'),
                                  right: $r('sys.float.padding_level6'),
                                  top: $r('sys.float.padding_level8'),
                                  bottom: $r('sys.float.padding_level8')
                                })
                                .hitTestBehavior(HitTestMode.Transparent)
                                .width('100%')
                            }
                          }
                        }
                      }
                      .padding({
                        left: $r('sys.float.padding_level4'),
                        right: $r('sys.float.padding_level4')
                      })
                      .listDirection(Axis.Vertical)
                      .divider({
                        strokeWidth: px2vp(1),
                        color: '#33FFFFFF',
                        startMargin: $r('sys.float.padding_level6'),
                        endMargin: $r('sys.float.padding_level6')
                      })
                      // 每行之间的分界线
                      .onAreaChange((oldValue, newValue) => {
                        if (this.listHeight != newValue.height) {
                          this.listHeight = newValue.height;
                        }
                      })
                    }
                  }
                }
                // 如果list总长度大于限制列表的最大高度，则限定列表的高度为限定最大高度，否则则不显示高度
                .height((this.listHeight > this.listMaxHeight) ? this.listMaxHeight : '')
                Column() {
                  Button({ type: ButtonType.Normal }) {
                    Text($r('app.string.cancel'))
                      .fontSize($r('sys.float.Body_L'))
                      .fontColor(this.isHighContrastText ? Color.White : $r('sys.color.brand_font_contrary'))
                      .fontWeight(FontWeight.Medium)
                      .textCase(SystemLanguageUtil.isVietnamese() ? TextCase.Normal : TextCase.UpperCase)
                      .key(ComponentIdKeys.SETTING_DIALOG_CANCEL_TEXT + 1)
                      .fontFeature('\"ss01\" on')
                  }
                  .width('100%')
                  .height('100%')
                  .buttonStyle(ButtonStyleMode.TEXTUAL)
                  .backgroundColor(this.isButtonTouchDown ? '#26ffffff' : Color.Transparent)
                  .borderRadius($r('sys.float.ohos_id_corner_radius_button'))
                  .onTouch((event: TouchEvent) => {
                    if (event.type === TouchType.Down) {
                      this.isButtonTouchDown = true;
                    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                      this.isButtonTouchDown = false;
                    }
                  })
                  .onClick((): void => {
                    HiLog.i(TAG, 'onClick cancel');
                    this.mAction.closeDialog(false);
                    this.controller?.close();
                    this.cancel();
                  })
                  .key(ComponentIdKeys.SETTING_DIALOG_ITEM_CANCEL_1)
                }
                .width('100%')
                .height(HEIGHT_BOTTOM)
                .margin({ top: $r('sys.float.ohos_id_elements_margin_vertical_m') })
                .padding({
                  left: $r('sys.float.padding_level6'),
                  right: $r('sys.float.padding_level6'),
                  bottom: $r('sys.float.padding_level8')
                })
                .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
              }
              .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
              .width('100%')
              .onClick((): void => {
                this.mAction.closeDialog(false);
                this.controller?.close();
                this.cancel();
              })
              .key(ComponentIdKeys.SETTING_DIALOG_ITEM_CANCEL_1)
            }
            .backgroundColor(DeviceInfo.isPc() ? $r('sys.color.ohos_id_color_dialog_bg') : '#202224')
            .padding({ left: $r('sys.float.padding_level2'), right: $r('sys.float.padding_level2') })
            .borderRadius($r('sys.float.corner_radius_level16'))
            .width(this.isShowSemiCollapsed ? DIALOG_WIDTH_LANDSCAPE : '100%')
            .offset({
              x: this.getOffsetX(),
              y: this.isHalfCollapsLEM && this.currentDirection === WindowDirection.TOP ?
                getStates().get<number>('windowReducer', 'windowHeight') / 4 : 0
            })
            .animation(null)
          }
        }
      }
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .width(this.getWidth())
      .rotate({
        angle: this.rotateAngle,
      })
    }
  }

  private isIncludeDesc(index: number): boolean {
    HiLog.i(TAG, `isIncludeDesc： ${this.customDialogDetails.itemDescList[index] != null}`);
    return (this.customDialogDetails.itemDescList[index] != null);
  }
}