/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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

import { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import {
  ConfirmDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/ConfirmDialogView';
import { Dispatch, OhCombinedState, reduxSubscribe, getStates } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { PcSettingMenuItem } from '@ohos/common/src/main/ets/component/settingview/pc/PcSettingMenuItem';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import camera from '@ohos.multimedia.camera';
import { ChangeState, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import type { Size } from '@ohos/common/src/main/ets/utils/types';
import { SettingViewAction } from '@ohos/common/src/main/ets/component/settingview/SettingViewAction';
import { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import {
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import CommonEventManager, {
  CUSTOM_EVENTS
} from '@ohos/common/src/main/ets/component/commonevent/CommonEventManager';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { FrameLockScene } from '@ohos/common/src/main/ets/utils/FrameLockScene';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';

const TAG: string = 'SettingView';

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public cameraShotKey: string = '';
  public isSecurityCamera: boolean = false;
}

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
}

class SettingViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public showBlur(): void {
    this.mDispatch(Action.uiState(false));
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public updateSettingView(isShow: boolean, isTriggeredByBack: boolean): void {
    this.mDispatch(SettingViewAction.showSettingView(isShow, false));
  }

  public resetSaveModeTimer() {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  }

  public isUpdateAspectRatio(): void {
    this.mDispatch(Action.isUpdateAspectRatio());
  }
}

@Entry
@Component
struct SettingView {
  @State state: StateStruct = new StateStruct();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: SettingViewDispatcher = new SettingViewDispatcher();
  private scroller: Scroller = new Scroller();
  private WH_100_100: string = '100%';
  private isDialogShow: boolean = false;
  @State renderLocationList: RenderLocation[] = [];
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @State recordingState: RecordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');

  @Builder
  PageMap(navigationName: string) {
  }

  confirmDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialogView({
      cancel: () => {
        HiLog.i(TAG, 'ConfirmDialogView cancel.');
        this.mAction.resetSaveModeTimer();
      },
      confirm: () => {
        HiLog.i(TAG, 'ConfirmDialogView confirm.');
        this.restoreValues();
        this.mAction.isUpdateAspectRatio();
        this.mAction.showBlur();
        this.mAction.resetSaveModeTimer();
      },
      description: $r('app.string.confirm_restore_message'),
      cancelText: $r('app.string.cancel'),
      confirmText: $r('app.string.confirm')
    }),
    autoCancel: false,
    customStyle: true,
    alignment: DialogAlignment.Center,
    maskColor: $r('sys.color.mask_fourth'),
  });
  locationConfirmDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialogView({
      cancel: () => {
        this.mAction.resetSaveModeTimer();
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
        HiLog.i(TAG, 'locationConfirmDialogController ConfirmDialogView cancel');
      },
      confirm: () => {
        this.mAction.resetSaveModeTimer();
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, true);
        HiLog.i(TAG, 'locationConfirmDialogController ConfirmDialogView confirm');
      },
      title: $r('app.string.gps_attention_dialog_need_content'),
      description: $r('app.string.gps_attention_dialog_need_summary'),
      cancelText: $r('app.string.gps_attention_dialog_need_disable'),
      confirmText: $r('app.string.gps_attention_dialog_need_enable'),
    }),
    autoCancel: false,
    offset: { dx: 0, dy: -15 },
    customStyle: true,
    alignment: DialogAlignment.Center,
    maskColor: $r('sys.color.mask_fourth'),
  });
  locationToSettingDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialogView({
      cancel: () => {
        HiLog.i(TAG, 'locationToSettingDialogController ConfirmDialogView cancel.');
        this.isDialogShow = false;
        this.mAction.resetSaveModeTimer();
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
      },
      confirm: () => {
        this.isDialogShow = false;
        this.mAction.resetSaveModeTimer();
        PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.IS_JUMP_TO_SETTING, true);
        //拉起设置
        try {
          let want: Want = {
            bundleName: 'com.ohos.settings',
            abilityName: 'com.ohos.settings.MainAbility',
            uri: 'application_info_entry',
            parameters: {
              pushParams: 'com.ohos.camera'
            }
          };
          ContextManager.getInstance().getSettingAbilityContext().startAbility(want).then((data) => {
            HiLog.i(TAG, `Succeed to start ability with data: ${data}`);
          }).catch((error: BusinessError) => {
            HiLog.i(TAG, `Failed to start ability with error: ${error}`);
          });
        } catch (err) {
          HiLog.e(TAG, `start settings err: ${err?.code}`);
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
        }
      },
      title: $r('app.string.fine_location_request_dialog_title'),
      description: $r('app.string.fine_location_request_dialog_content'),
      cancelText: $r('app.string.cancel'),
      confirmText: $r('app.string.permission_dialog_goto_setting_button'),
    }),
    autoCancel: false,
    offset: { dx: 0, dy: -15 },
    customStyle: true,
    alignment: DialogAlignment.Center,
    maskColor: $r('sys.color.mask_fourth'),
    cancel: () => {
      this.isDialogShow = false;
      this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
    }
  });

  private locationDialogShow(): void {
    if (!this.isDialogShow) {
      this.locationToSettingDialogController.open();
      this.isDialogShow = true;
    }
  }

  aboutToAppear(): void {
    FrameLockScene.getInstance().apsSetScene(TAG, true); // 进入页面解除锁帧
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.renderLocationList = [RenderLocation.SETTING_MENU_PHOTO, RenderLocation.SETTING_MENU_VIDEO,
      RenderLocation.SETTING_MENU_COMMON];
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        cameraShotKey: state.get<string>('securityCameraReducer', 'cameraShotKey'),
        isSecurityCamera: state.get<boolean>('securityCameraReducer', 'isSecurityCamera')
      });
      this.recordingState = state.get<RecordingState>('recordReducer', 'recordingState');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on(ActionType.ACTION_LOCATION_PERMISSION_TO_SETTING,
      this.locationDialogShow.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  private restoreValues(): void {
    HiLog.i(TAG, 'restoreValues.');
    let featureManager = FeatureManager.getInstance();
    this.mAction.changeFunctionValue(FunctionId.ASSISTIVE_GRID, featureManager.getFunction(FunctionId.ASSISTIVE_GRID)
      .getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.SOUND_MUTE, featureManager.getFunction(FunctionId.SOUND_MUTE)
      .getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.TIME_LAPSE, featureManager.getFunction(FunctionId.TIME_LAPSE)
      .getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.ASPECT_RATIO, featureManager.getFunction(FunctionId.ASPECT_RATIO)
      .getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.VIDEO_RESOLUTION,
      featureManager.getFunction(FunctionId.VIDEO_RESOLUTION).getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.FRAME_RATE, featureManager.getFunction(FunctionId.FRAME_RATE)
      .getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.MIRROR, featureManager.getFunction(FunctionId.MIRROR)
      .getDefaultValue() as boolean);
    if (!this.state.isSecurityCamera) {
      this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION,
        featureManager.getFunction(FunctionId.SAVE_GEO_LOCATION).getDefaultValue() as boolean);
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mSubscriber.destroy();
    this.mAction.updateSettingView(false, true);
    FrameLockScene.getInstance().apsSetScene(TAG, false); // 退出页面开始锁帧
  }

  private getCurRecordState(): boolean {
    return this.recordingState === RecordingState.RECORDING ||
      this.recordingState === RecordingState.PAUSED || this.recordingState === RecordingState.PAUSING;
  }

  build() {

    Navigation(this.pageInfos) {
      Column() {
        Scroll(this.scroller) {
          Column() {
            Column() {
              List() {
                ForEach(this.renderLocationList, (item: RenderLocation, index: number = 0) => {
                  ListItem() {
                    PcSettingMenuItem({
                      menuLocation: item,
                      recordingState: this.recordingState
                    })
                  }
                })
              }
            }.margin({ left: $r('sys.float.padding_level12'), right: $r('sys.float.padding_level12') })

            Row() {
              Button({ type: ButtonType.Normal, stateEffect: true }) {
                Text($r('app.string.restore_defaults'))
                  .maxFontSize($r('sys.float.Body_L'))
                  .minFontSize($r('sys.float.Body_S'))
                  .fontColor($r('sys.color.comp_background_primary_contrary'))
                  .fontWeight(FontWeight.Regular)
                  .textAlign(TextAlign.Center)
                  .lineHeight(19)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({
                    left: $r('sys.float.padding_level8'),
                    right: $r('sys.float.padding_level8')
                  })
                  .key(ComponentIdKeys.SETTING_DEFAULT_BUTTON_TEXT + 1)
                  .fontFeature('\"ss01\" on')
              }
              .borderRadius($r('sys.float.corner_radius_level4'))
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .height(40)
              .width(272)
              .opacity(this.getCurRecordState() ? AnimSpecifications.ALPHA_HALF
                : AnimSpecifications.ALPHA_OPAQUE)
              .onClick((): void => {
                if (this.getCurRecordState()) {
                  HiLog.i(TAG, 'recording, can not to restore');
                  return;
                }
                this.confirmDialogController.open();
              })
            }.margin({ top: $r('sys.float.padding_level12'), bottom: $r('sys.float.padding_level12') })
            .key(ComponentIdKeys.SETTING_DEFAULT_BUTTON_1)

            Text($r('app.string.camera_privacy_with_cloud_photo'))
              .fontSize($r('sys.float.Body_S'))
              .fontColor('#5291FF')
              .fontWeight(FontWeight.Regular)
              .margin({ bottom: $r('sys.float.padding_level12') })
              .fontFeature('\"ss01\" on')
              .visibility(Visibility.None)//TODO 隐私声明需厂商自行补齐，隐藏入口
              .onClick((): void => { //跳转隐私声明页面公用组件，pageInfos传参避免过多判断
                const pcPolicyViewSIze = AppStorage.get<Size>('PCPrivacyPolicyViewSize');
                this.pageInfos.pushPath({ name: 'PrivacyPolicyView', param: pcPolicyViewSIze });
              })
          }
          .justifyContent(FlexAlign.Start)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .height(this.WH_100_100)
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
  }
}