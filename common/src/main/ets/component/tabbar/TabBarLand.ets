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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { OhCombinedState, Dispatch, Unsubscribe, getStates, reduxSubscribe } from '../../redux';
import lazy { PopupButton } from './PopupButton';
import lazy { TipService } from '../tip/TipService';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../../function/core/functionproperty/RenderLocation';
import lazy { FunctionAction } from '../../function/core/FunctionAction';
import lazy { UiElement } from '../../function/core/UiElement';
import lazy { RenderType } from '../../function/core/functionproperty/RenderType';
import lazy { TabBarAction } from './TabBarAction';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import Want from '@ohos.app.ability.Want';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { WindowService } from '../../service/window/WindowService';
import StartOptions from '@ohos.app.ability.StartOptions';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { SettingViewAction } from '../settingview/SettingViewAction';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { ModeListManager } from '../../mode/ModeListManager';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { window } from '@kit.ArkUI';
import lazy { ActionData } from '../../redux/actions/Action';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { getColorString } from '../../utils/ColorUtil';

/* instrument ignore file */
const TAG: string = 'TabBarLand';
// 要拉起的settingAbility窗口的寬高
const windowWidth = 1562;
const windowHeight = 828;

class FunctionRenderType {
  public id: FunctionId = FunctionId.NONE;
  public renderType: RenderType = RenderType.NONE;
}

class FunctionsStruct {
  public icon: Resource | string = '';
  public value: number = 0;
  public desc: Resource | string = '';
  public color: string = '';
  public functionValue: number = 0;
}

class TabBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: number): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public changeTabBarSelector(id: FunctionId, renderLocation: RenderLocation): void {
    this.mDispatch(TabBarAction.changeTabBarSelector(id, renderLocation));
  }
}

@Component
export struct TabBarLand {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State isThirdPartyCall: boolean = false;
  @State @Watch('clearTimerId') selector: number = 0;
  @State @Watch('clearTimerId') selectorLocation: RenderLocation = RenderLocation.NONE;
  @State functionIds: Set<FunctionId> = new Set();
  @State mCloseTabbar: boolean = true;
  @State resetPopupIcon: number = 0;
  @State xComponentWidth: number = 0;
  @State isRecordingStateReady: boolean = true;
  @State pcSettingColor: ResourceColor = '#FFFFFF';
  @State pcSettingOpacity: number = 1;
  @State isHover: boolean = false;
  private mAction: TabBarDispatcher = new TabBarDispatcher();
  private timerId: number = Number.MIN_VALUE;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mPreFunctions: FunctionsStruct[] = [];

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.tabBarLandOnStarted();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isRecordingStateReady = (state.get<RecordingState>('recordReducer', 'recordingState') === RecordingState.READY);
      this.selector = state.get<FunctionId>('tabBarReducer', 'tabBarSelector');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.selectorLocation = state.get<RenderLocation>('tabBarReducer', 'tabBarSelectorLocation');
      this.isThirdPartyCall = state.get<boolean>('contextReducer', 'isThirdPartyCall');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on([FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, CameraActionType.CHANGE_MODE,
      CameraActionType.CHANGE_OUTPUT_TYPE], this.setSelectorNone.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.tabBarLandOnStarted.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.getPcSettingIconColor.bind(this),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  private setSelectorNone(): void {
    this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
    this.resetPopupIcon += 1;
  }

  aboutToDisappear() {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  private tabBarLandOnStarted(): void {
    HiLog.i(TAG, 'reset tabBar funcIds array.');
    const set = getStates()
      .get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap')
      .get(RenderLocation.TAB_BAR_RIGHT) || new Set();
    this.functionIds = set;
    let str: string = '';
    set.forEach((id: FunctionId) => {
      if (str === '') {
        str = `${JSON.stringify(id)}`;
      } else {
        str = `${str},${JSON.stringify(id)}`;
      }
    });
    HiLog.i(TAG, `functionIds: ${str}.`);
  }

  private getPcSettingIconColor(data: ActionData): void {
    if (data['windowStageEventType'] === window.WindowStageEventType.INACTIVE) {
      this.pcSettingColor = '#f3f3f1';
      this.pcSettingOpacity = 0.4;
    } else if (data['windowStageEventType'] === window.WindowStageEventType.ACTIVE) {
      this.pcSettingColor = '#f8f8f8';
      this.pcSettingOpacity = 0.9;
    }
  }

  private clearTimerId() {
    HiLog.d(TAG, 'clearTimerId invoke.');
    if (this.selector === FunctionId.NONE && Number.MIN_VALUE !== this.timerId) {
      clearTimeout(this.timerId);
    }
    animateToImmediately({
      duration: 500,
      curve: Curve.Friction
    }, () => {
      if (this.selector === FunctionId.NONE) {
        this.mCloseTabbar = true;
      } else {
        this.mCloseTabbar = false;
      }
    })
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
      if (this.mCloseTabbar) {
        ForEach(Array.from(this.functionIds).map((item: FunctionId) => {
          let renderType = FeatureManager.getInstance().getFunction(item).getRenderType(RenderLocation.TAB_BAR_RIGHT);
          let res: FunctionRenderType = { id: item, renderType: renderType };
          return res;
        }), (item: FunctionRenderType) => {
          Column() {
            if (item.renderType === RenderType.POPUP_BUTTON) {
              PopupButton({
                mFunctionId: item.id,
                functionOpacity:new Map<FunctionId, number>(),
                renderLocation: RenderLocation.TAB_BAR_RIGHT,
                onPopupButtonClicked: (): void => this.onPopupButtonClicked(item.id),
                resetIcon: this.resetPopupIcon
              })
                .geometryTransition('tabbar')
                .transition(
                  TransitionEffect.asymmetric(
                    TransitionEffect.IDENTITY,
                    TransitionEffect.IDENTITY))
            }
          }.width(20).height('100%').margin({ right: 27 })
        })

        if (this.isRecordingStateReady) {
          Column() {
            Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
              Image($r('app.media.setting'))
                .width(this.isHover ? 22 : 20)
                .height(this.isHover ? 22 : 20)
                .key(ComponentIdKeys.CAMERA_SETTING_1)
                .draggable(false)
                .fillColor(this.pcSettingColor)
                .opacity(this.pcSettingOpacity)
                .onHover((isHover: boolean, event: HoverEvent) => {
                  this.isHover = isHover;
                })
            }
            .width('100%')
            .height('100%')
          }
          .margin({ right: 138 })
          .width(40)
          .borderRadius(this.isHover ? 4 : '')
          .backgroundColor(this.isHover ? '#19FFFFFF' : Color.Transparent)
          .height('100%')
          .onClick(async () => {
            HiLog.i(TAG, 'launch bundle com.ohos.camera.SettingAbility.');
            StoreManager.getInstance().postMessage(SettingViewAction.showSettingView(true, false));
            await this.startSettingAbility();
          })
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.IDENTITY,
              TransitionEffect
                .scale({ x: AnimSpecifications.SCALE_0_8, y: AnimSpecifications.SCALE_0_8 })
                .animation({ duration: AnimSpecifications.ANIM_DURATION_350, curve: Curve.Friction })
            ))
        }
      } else {
        Row() {
          ForEach(this.getFunctions(), (item: FunctionsStruct, index: number = 0) => {
            Column() {
              Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
                if (item.color === getColorString()) {
                  Image(item.icon)
                    .width(20)
                    .height(20)
                    .fillColor(item.color)
                    .draggable(false)
                    .key(ComponentIdKeys.getInstance()
                      .getKey('TabBar', RenderLocation.TAB_BAR_RIGHT, FunctionId.FLASH,
                        item.functionValue))
                    .geometryTransition('tabbar')
                    .transition(
                      TransitionEffect.asymmetric(
                        TransitionEffect.IDENTITY,
                        TransitionEffect.IDENTITY))
                } else {
                  Image(item.icon)
                    .width(20)
                    .height(20)
                    .fillColor(item.color)
                    .draggable(false)
                    .key(ComponentIdKeys.getInstance()
                      .getKey('TabBar', RenderLocation.TAB_BAR_RIGHT, FunctionId.FLASH,
                        item.functionValue))
                    .transition(
                      TransitionEffect.asymmetric(
                        TransitionEffect
                          .opacity(0)
                          .animation({
                            duration: AnimSpecifications.ANIM_DURATION_50,
                            curve: Curve.Sharp,
                            delay: (index * 50 + 150)
                          })
                          .combine(
                            TransitionEffect
                              .scale({ x: AnimSpecifications.SCALE_ZERO, y: AnimSpecifications.SCALE_ZERO })
                              .animation({
                                duration: AnimSpecifications.ANIM_DURATION_300,
                                curve: Curve.Friction,
                                delay: (index * 50 + 150)
                              })
                          ),
                        TransitionEffect
                          .opacity(0)
                          .animation({
                            duration: AnimSpecifications.ANIM_DURATION_100,
                            curve: Curve.Sharp,
                            delay: AnimSpecifications.ANIM_DELAY_50
                          })
                      )
                    )
                }
              }.width('100%').height('100%')
            }
            .width(20)
            .height('100%')
            .margin({ left: 27, right: 27 })
            .onClick((): void => {
              this.mAction.changeFunctionValue(this.selector, item.value);
              TipService.getInstance().showTip(item.desc, 3000);
              if (Number.MIN_VALUE !== this.timerId) {
                clearTimeout(this.timerId);
              }
            })
          })
        }
        .justifyContent(FlexAlign.End)
        .margin({ right: this.isRecordingStateReady ? 74 : 0 })
        .transition(
          TransitionEffect.asymmetric(
            TransitionEffect.IDENTITY,
            TransitionEffect
              .scale({ x: 0.8, y: 0.8 })
              .animation({ duration: 350, curve: Curve.Friction })
          )
        )
      }
    }
  }

  private onPreviewClicked() {
    HiLog.d(TAG, 'onPreviewClicked invoke E.');
    if (Number.MIN_VALUE !== this.timerId) {
      clearTimeout(this.timerId);
    }
    HiLog.d(TAG, 'onPreviewClicked invoke X.');
  }

  private onPopupButtonClicked(funcId: FunctionId) {
    this.mAction.changeTabBarSelector(funcId, RenderLocation.TAB_BAR_RIGHT);
    this.timerId = setTimeout((): void => {
      this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
    }, 5000);
  }

  private getFunctions(): FunctionsStruct[] {
    let array = FeatureManager.getInstance().getFunction(this.selector)?.getUiElements(this.selectorLocation).values();
    if (this.selector === FunctionId.NONE) {
      if (this.mPreFunctions.length === 0) {
        return this.mPreFunctions;
      } else {
        return [];
      }
    } else {
      if (array === undefined) {
        return [];
      } else {
        let resultArray: FunctionsStruct[] = Array.from(array).map((item: UiElement) => {
          let functionValue: number = FeatureManager.getInstance().getFunction(this.selector).getValue();
          let functionColor = '#FFFFFF';
          if (functionValue === item.functionValue) {
            functionColor = getColorString();
          }
          let res: FunctionsStruct = {
            icon: item.icon,
            value: item.functionValue,
            desc: item.desc,
            color: functionColor,
            functionValue: functionValue
          };
          return res;
        });
        this.mPreFunctions = resultArray;
        return resultArray;
      }
    }
  }

  private buildCameraAbilityWant(): Want {
    let abilityName: string;
    let params: Record<string, object | ModeType> = {};
    if (GlobalContext.get().getIsPicker()) {
      abilityName = 'PickerSettingAbility';
      params = {
        'modeList': ModeListManager.getInstance().getModeList(),
        'curMode': getStates().get<ModeType>('modeReducer', 'mode')
      }
    } else {
      abilityName = 'SettingAbility';
    }
    let res: Want = {
      bundleName: 'com.ohos.camera',
      abilityName: abilityName,
      parameters: params,
    };
    return res;
  }

  public async startSettingAbility(): Promise<void> {
    const offSetX = WindowService.getInstance().getWindowRect().left +
      (WindowService.getInstance().getWindowRect().width / 2 - windowWidth / 2);
    const offSetY = WindowService.getInstance().getWindowRect().top +
      (WindowService.getInstance().getWindowRect().height / 2 - windowHeight / 2);

    let options: StartOptions = {
      windowLeft: offSetX,
      windowTop: offSetY,
      windowWidth: windowWidth,
      windowHeight: windowHeight
    };
    await ContextManager.getInstance().getUiContext().startAbility(this.buildCameraAbilityWant(),
      options as StartOptions);
  }
}