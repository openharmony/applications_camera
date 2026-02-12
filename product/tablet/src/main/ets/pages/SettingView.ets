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

import { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { SettingMenuItem } from '@ohos/common/src/main/ets/component/settingview/phone/SettingMenuItem';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import {
  ConfirmDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/ConfirmDialogView';
import { OhCombinedState, Dispatch } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { ViewRotateTranslate } from '@ohos/common/src/main/ets/utils/ViewRotateTranslate';
import lazy { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { ChangeState, getStates, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import { CustomTransition } from '@ohos/common/src/main/ets/animation/CustomNavigationUtils';
import { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import { BusinessError, screenLock } from '@kit.BasicServicesKit';
import { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import { ExposureData } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import { MeasureText } from '@kit.ArkUI';
import { FocusFunction } from '@ohos/extend/src/main/ets/commonfunc/focus/FocusFunction';
import { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import { DirectionCorrectionService } from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';
import { FrameLockScene } from '@ohos/common/src/main/ets/utils/FrameLockScene';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
// TODO OpenHarmony编译报错，待后续相关kit支持放开
// import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import lazy { apsSetScene } from '@ohos/common/src/main/ets/utils/FrameLockSceneUtil';

const TAG: string = 'SettingView';
const TOP_HOLE: number = 36;
const MENU_ITEM_WIDTH_840: number = 840;
const MENU_ITEM_WIDTH_600: number = 600;
const WH_100_100: string = '100%';
const NUMBER_32: number = 32;
const NUMBER_24: number = 24;
const NUMBER_20: number = 20;
const NUMBER_16: number = 16;
const NUMBER_12: number = 12;
const NUMBER_8: number = 8;
const NUMBER_6: number = 6;
const NUMBER_4: number = 4;
const NUMBER_2: number = 2;
const NUMBER_1: number = 1;
const NUMBER_0: number = 0;


class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
}

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public cameraShotKey: string = '';
  public isSecurityCamera: boolean = false;
  public isShowSettingView: boolean = false;
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

  public restoreDialogConfirm(restoreConfirmFlag: boolean): void {
    this.mDispatch(Action.restoreDialogConfirm(restoreConfirmFlag));
  }

  public resetZoomRatio(): void {
    this.mDispatch(ZoomAction.resetZoomRatio());
  }

  public changeToMode(oldMode: ModeType, newMode: ModeType): void {
    AppStorage.setOrCreate('startOrUserChangeToModeLast', newMode);
    this.mDispatch(CameraAction.changeMode(newMode, false));
    this.mDispatch(Action.updateXComponentShot(oldMode, newMode, false));
  }

  public resetSaveModeTimer() {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  };
}

@Component
export struct SettingView {
  private pageId: number = 0;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mBase: BaseComponent = new BaseComponent();
  @State renderLocationList: RenderLocation[] = [];
  @State isShowLandscape: boolean = false;
  private isFirstTime: boolean = true;
  private mAction: SettingViewDispatcher = new SettingViewDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State @Watch('rotateChange') rotateAngle: number = 0;
  private lastRotateAngle: number = 0;
  @State @Watch('dialogShowChange') isDialogShow: boolean = false;
  private confirmDialogController: CustomDialogController | null = null;
  private readonly ANIMATION_DURATION_420: number = 420;
  private readonly ANIMATION_DURATION_840: number = 840;
  private mTimerId: number = Number.MIN_VALUE;
  @State rotateAngleDuration: number = this.ANIMATION_DURATION_420;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State settingWidth: number = 0;
  @State state: StateStruct = new StateStruct();
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  @Consume('pageInfos') pageInfos: NavPathStack;
  private restoreDialogConfirmTimer: number | null = null;
  @Provide isShowSavePowerModeView: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State isLockRotation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation');

  private initSettingList() {
    const isPicker: boolean = GlobalContext.get().getIsPicker();
    this.renderLocationList = [RenderLocation.SETTING_MENU_PHOTO, RenderLocation.SETTING_MENU_VIDEO,
      RenderLocation.SETTING_MENU_COMMON];
    const modeList = ModeListManager.getInstance().getModeList();
    if (isPicker) {
      let isPhotoSupported: boolean = modeList.includes(ModeType.PHOTO);
      let isVideoSupported: boolean = modeList.includes(ModeType.VIDEO);
      if (isPhotoSupported && !isVideoSupported) {
        this.renderLocationList = [RenderLocation.SETTING_MENU_PHOTO, RenderLocation.SETTING_MENU_COMMON];
      } else if (!isPhotoSupported && isVideoSupported) {
        this.renderLocationList = [RenderLocation.SETTING_MENU_VIDEO, RenderLocation.SETTING_MENU_COMMON];
      }
    }
  }

  aboutToAppear(): void {
    apsSetScene(TAG, true); // 进入页面开始锁帧
    FrameLockScene.getInstance().apsSetScene(TAG, true); // 进入页面解除锁帧
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.initSettingList();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      if (state.get<WindowDirection>('contextReducer', 'direction') !== WindowDirection.BOTTOM) {
        this.mDirection =
          DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
            this.isLockRotation);
        this.rotateAngle = state.get<number>('contextReducer', 'settingAngle');
      }
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        cameraShotKey: state.get<string>('securityCameraReducer', 'cameraShotKey'),
        isSecurityCamera: state.get<boolean>('securityCameraReducer', 'isSecurityCamera'),
        isShowSettingView: state.get<boolean>('settingViewReducer', 'isShowSettingView')
      });
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isShowSavePowerModeView = state.get<boolean>('contextReducer', 'isDuringSavePowerMode');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.mEventBus.on(ActionType.ACTION_CLOSE_SETTING_DIALOG, this.confirmDialogClose.bind(this),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  private restoreDefaults(featureManager: FeatureManager): void {
    this.mAction.changeFunctionValue(FunctionId.ZOOM, {
      zoomRatio: featureManager.getFunction(FunctionId.ZOOM)?.getDefaultValue() as number
    } as ZoomFuncValueStruct);
    this.mAction.changeFunctionValue(FunctionId.ASPECT_RATIO, featureManager.getFunction(FunctionId.ASPECT_RATIO)
    ?.getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.VIDEO_RESOLUTION,
      featureManager.getFunction(FunctionId.VIDEO_RESOLUTION)?.getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.FRAME_RATE, featureManager.getFunction(FunctionId.FRAME_RATE)
    ?.getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.HORIZONTAL_LEVEL,
      featureManager.getFunction(FunctionId.HORIZONTAL_LEVEL)?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.MIRROR, featureManager.getFunction(FunctionId.MIRROR)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.ASSISTIVE_GRID, featureManager.getFunction(FunctionId.ASSISTIVE_GRID)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.SOUND_MUTE, featureManager.getFunction(FunctionId.SOUND_MUTE)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.FLOATING_SHUTTER,
      featureManager.getFunction(FunctionId.FLOATING_SHUTTER)?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.TIME_LAPSE, featureManager.getFunction(FunctionId.TIME_LAPSE)
    ?.getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.FLASH, featureManager.getFunction(FunctionId.FLASH)
    ?.getDefaultValue() as number);
    if (!this.state.isSecurityCamera) {
      this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION,
        featureManager.getFunction(FunctionId.SAVE_GEO_LOCATION)?.getDefaultValue() as boolean);
    }
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.WATERMARK_VIEW, '0010');
    this.mAction.changeFunctionValue(FunctionId.EFFICIENT_VIDEO, featureManager.getFunction(FunctionId.EFFICIENT_VIDEO)
    ?.getDefaultValue() as boolean);
    this.proRestoreDefaults(featureManager);
  }

  private proRestoreDefaults(featureManager: FeatureManager): void {
    this.mAction.changeFunctionValue(FunctionId.PHOTO_FORMAT, featureManager.getFunction(FunctionId.PHOTO_FORMAT)
    ?.getDefaultValue() as number);
  }

  private restoreValues(): void {
    HiLog.i(TAG, 'restoreValues.');
    AppStorage.setOrCreate('restoreFlag', true);
    this.mAction.resetZoomRatio();
    let featureManager = FeatureManager.getInstance();
    this.restoreDefaults(featureManager);
    (featureManager.getFunction(FunctionId.FOCUS) as FocusFunction).resetFocus();
    this.mAction.changeFunctionValue(FunctionId.FLASH, -1);
    this.mAction.changeFunctionValue(FunctionId.SETTING, false);
    AppStorage.setOrCreate('restoreFlag', false);
    if (MoreModeConfig.getInstance().isSupportMorePage()) {
      MoreModeConfig.getInstance().modifyMoreModeListAndName(ModeType.MORE);
    }

    // 将所有Function默认值通过changeMode一次起流配置带下
    if (PickerUtils.getIsPicker()) {
      const want: Want = GlobalContext.get().getCameraAbilityWant();
      const numSupportedModes: number = want?.parameters?.supportMultiMode ? 2 : 1;
      HiLog.i(TAG, `camera picker supports ${numSupportedModes} types of modes.`);
      if (numSupportedModes === 1) {
        this.mAction.changeToMode(this.state.mode, this.state.mode);
        return;
      }
    }
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
      this.mAction.changeToMode(this.state.mode, ModeType.PHOTO);
    } else {
      this.mAction.changeToMode(this.state.mode, ModeType.PHOTO);
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.confirmDialogClose();
    clearTimeout(this.mTimerId);
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear X.');
    apsSetScene(TAG, false); // 退出页面结束锁帧
    FrameLockScene.getInstance().apsSetScene(TAG, false); // 退出页面开始锁帧
  }

  private dialogShowChange(): void {
    GlobalContext.get().setObject('isDialogShow', this.isDialogShow);
  }

  private confirmDialogClose(): void {
    clearTimeout(this.mTimerId);
    this.confirmDialogController?.close();
    this.isDialogShow = false;
  }

  private statusChange(): void {
    if (this.isDialogShow && this.isFirstTime) {
      this.confirmDialogController?.close();
      this.isDialogShow = false;
      this.createDialog();
      this.isFirstTime = false;
      this.mTimerId = setTimeout((): void => {
        this.confirmDialogController?.open();
        this.isDialogShow = true;
        this.isFirstTime = true;
      }, 250)
    }
  }

  private directionChange(): void {
    HiLog.i(TAG, 'directionChange E.');
    if (this.mDirection === WindowDirection.BOTTOM || AppStorage.get('settingAnimationDoing')) {
      return;
    }
    AppStorage.setOrCreate('settingAnimationDoing', true);
    this.statusChange();
    HiLog.i(TAG, 'directionChange X.');
  }

  private rotateChange() {
    HiLog.i(TAG, 'rotateChange E.');
    if ((this.rotateAngle - this.lastRotateAngle) % AnimSpecifications.ANIM_ROTATE_180 === 0) {
      this.rotateAngleDuration = this.ANIMATION_DURATION_840;
    } else {
      this.rotateAngleDuration = this.ANIMATION_DURATION_420;
    }
    this.lastRotateAngle = this.rotateAngle;
    HiLog.i(TAG, 'rotateChange X.');
  }

  private createDialog() {
    HiLog.i(TAG, 'createDialog E.');
    this.confirmDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          HiLog.i(TAG, 'ConfirmDialogView cancel');
          this.isDialogShow = false;
          this.mAction.resetSaveModeTimer();
        },
        confirm: () => {
          if (this.restoreDialogConfirmTimer) {
            return;
          }
          this.mAction.showBlur();
          this.isDialogShow = false;
          this.restoreDialogConfirmTimer = setTimeout((): void => {
            HiLog.i(TAG, 'ConfirmDialogView confirm');
            this.restoreDialogConfirmTimer = null;
            this.restoreValues();
            this.mAction.restoreDialogConfirm(!this.state.isSecurityCamera);
          }, 180);
          this.mAction.resetSaveModeTimer();
        },
        description: $r('app.string.confirm_restore_message'),
        cancelText: $r('app.string.cancel'),
        confirmText: $r('app.string.confirm'),
        rotateAngle: this.rotateAngle,
        currentDirection: this.mDirection,
        isShowLandscape: this.isShowLandscape
      }),
      autoCancel: false,
      customStyle: true,
      cancel: () => {
        this.isDialogShow = false;
      },
      maskColor: '#66000000',
      alignment: DialogAlignment.Center,
    });
    HiLog.i(TAG, 'createDialog X.');
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private getCardColumns(): number {
    HiLog.i(TAG, `getCardColumns this.getViewWidth():${this.getViewWidth()}`)
    if (this.getViewWidth() > MENU_ITEM_WIDTH_840) {
      return NUMBER_12;
    } else if (this.getViewWidth() > MENU_ITEM_WIDTH_600 && this.getViewWidth() <= MENU_ITEM_WIDTH_840) {
      return NUMBER_8;
    } else {
      return NUMBER_4;
    }
  }

  private getCardGutter(): number {
    if (this.getViewWidth() > MENU_ITEM_WIDTH_840) {
      return NUMBER_16;
    } else if (this.getViewWidth() > MENU_ITEM_WIDTH_600 && this.getViewWidth() <= MENU_ITEM_WIDTH_840) {
      return NUMBER_12;
    } else {
      return NUMBER_0;
    }
  }

  private getCardSpan(): number {
    if (this.getViewWidth() > MENU_ITEM_WIDTH_840) {
      return NUMBER_8;
    } else if (this.getViewWidth() > MENU_ITEM_WIDTH_600 && this.getViewWidth() <= MENU_ITEM_WIDTH_840) {
      return NUMBER_6;
    } else {
      return NUMBER_4;
    }
  }

  private getCardOffset(): number {
    if (this.getViewWidth() > MENU_ITEM_WIDTH_840) {
      return NUMBER_2;
    } else if (this.getViewWidth() > MENU_ITEM_WIDTH_600 && this.getViewWidth() <= MENU_ITEM_WIDTH_840) {
      return NUMBER_1;
    } else {
      return NUMBER_0;
    }
  }

  private getCardPadding(): number {
    if (this.getViewWidth() > MENU_ITEM_WIDTH_840) {
      return NUMBER_32;
    } else if (this.getViewWidth() > MENU_ITEM_WIDTH_600 && this.getViewWidth() <= MENU_ITEM_WIDTH_840) {
      return NUMBER_24;
    } else {
      return NUMBER_20;
    }
  }

  private getPageTop(): number {
    return this.isVertical() || this.isLockRotation ? TOP_HOLE : 0;
  }

  private getViewWidth(): number {
    return this.isVertical() || this.isLockRotation ? this.windowWidth : this.windowHeight;
  }

  private getViewHeight(): number {
    return this.isVertical() || this.isLockRotation ? this.windowHeight : this.windowWidth;
  }

  private getTranslateX(): number {
    return this.isVertical() || this.isLockRotation ? 0 :
    ViewRotateTranslate.getTranslateSize(this.windowHeight, this.windowWidth).translateX;
  }

  private getTranslateY(): number {
    return this.isVertical() || this.isLockRotation ? 0 :
    ViewRotateTranslate.getTranslateSize(this.windowHeight, this.windowWidth).translateY;
  }

  @Builder
  listItem(item: RenderLocation) {
    ListItem() {
      GridRow({
        columns: this.getCardColumns(),
        direction: GridRowDirection.Row,
        gutter: this.getCardGutter(),
      }) {
        GridCol({
          span: {
            xs: this.getCardSpan(),
            sm: this.getCardSpan(),
            md: this.getCardSpan(),
            lg: this.getCardSpan()
          },
          offset: {
            xs: this.getCardOffset(),
            sm: this.getCardOffset(),
            md: this.getCardOffset(),
            lg: this.getCardOffset()
          }
        }) {
          SettingMenuItem({
            menuLocation: item
          })
        }
      }
    }
  }

  @Builder
  restoreButton() {
    // 恢复默认值 按钮，适老化适配，根据系统字体大小，展现不同风格
    Button({
      stateEffect: true,
      type: (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) ?
      ButtonType.Normal : ButtonType.Capsule
    }) {
      Text($r('app.string.restore_defaults'))
        .fontSize($r('sys.float.Body_L'))
        .fontColor('#DBFFFFFF')
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Center)
        .lineHeight(17)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontFeature('\"ss01\" on')
    }
    .height(this.getRestoreButtonHeight())
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor('#1AFFFFFF')
    .hoverEffect(HoverEffect.None)
    .margin({
      top: $r('sys.float.padding_level12'),
      bottom: $r('sys.float.padding_level12')
    })
    .padding({
      top: $r('sys.float.padding_level6'),
      bottom: $r('sys.float.padding_level6'),
      left: this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2 ?
      $r('app.float.button_padding_value_16') : $r('app.float.button_padding_value_32'),
      right: this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2 ?
      $r('app.float.button_padding_value_16') : $r('app.float.button_padding_value_32')
    })
    .onClick((): void => {
      this.createDialog();
      this.confirmDialogController?.open();
      this.isDialogShow = true;
    })
    .key(ComponentIdKeys.SETTING_DEFAULT_BUTTON_1)
  }

  @Builder
  privacyText() {
    if (!GlobalContext.get().getIsPicker()) {
      Text($r('app.string.camera_privacy_with_cloud_photo'))
        .fontSize($r('sys.float.Body_S'))
        .fontColor('#5291FF')
        .fontWeight(FontWeight.Regular)
        .visibility(Visibility.None)//TODO 隐私声明需厂商自行补齐，隐藏入口
        .margin({ bottom: $r('sys.float.padding_level12') })
        .onClick((): void => { //跳转隐私声明页面
          if (GlobalContext.get().getT('isSecureMode')) {
            screenLock.unlock().then((data: Boolean) => {
              HiLog.i(TAG, `Succeeded in unlocking the screen. result: ${data}`);
              if (data) {
                this.pageInfos.pushPath({ name: 'PrivacyPolicyView' });
                GlobalContext.get().setObject('privacyPolicyViewShow', true);
              }
            }).catch((err: BusinessError) => {
              HiLog.e(TAG, `Failed to unlock the screen, Code: ${err?.code}`);
            });
          } else {
            this.pageInfos.pushPath({ name: 'PrivacyPolicyView' });
            GlobalContext.get().setObject('privacyPolicyViewShow', true);
          }
        })
        .key(ComponentIdKeys.SETTING_PERMISSION_TEXT)
        .fontFeature('\"ss01\" on')
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Blank().height(56);
          List() {
            ForEach(this.renderLocationList, (item: RenderLocation) => {
              this.listItem(item);
            })
          }
          .scrollBar(BarState.Off)
          .padding({ left: this.getCardPadding(), right: this.getCardPadding() })
          .width(WH_100_100)

          this.restoreButton();
          this.privacyText();
        }
      }
      .width(WH_100_100)
      .height(WH_100_100)
      .flexShrink(1)
      .align(Alignment.TopStart)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .backgroundColor(Color.Black)
      .padding({
        left: this.isVertical() ? $r('sys.float.padding_level2') : 0,
        right: this.isVertical() ? $r('sys.float.padding_level2') : 0,
      })
      .id('settingView')
    }
    // .titleBar({
    //   content: {
    //     title: {
    //       mainTitle: $r('app.string.settings')
    //     },
    //     backIcon: {
    //       componentId: ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1,
    //       action: () => {
    //         this.mAction.changeFunctionValue(FunctionId.SETTING, false);
    //       }
    //     }
    //   },
    //   style: {
    //     originalStyle: {
    //       backgroundStyle: {
    //         backgroundColor: Color.Black,
    //       },
    //       contentStyle: {
    //         titleStyle: {
    //           mainTitleColor: $r('sys.color.ohos_id_color_text_primary_dark')
    //         },
    //         backIconStyle: {
    //           iconColor: $r('sys.color.ohos_id_color_titlebar_icon_dark'),
    //           backgroundColor: '#26FFFFFF'
    //         }
    //       }
    //     },
    //     scrollEffectOpts: {
    //       enableScrollEffect: false
    //     }
    //   }
    // })
    .rotate({
      angle: this.rotateAngle
    })
    .padding({
      top: this.getPageTop(),
    })
    .animation(
      {
        duration: this.rotateAngleDuration,
        curve: Curve.Sharp,
        iterations: 1,
        playMode: PlayMode.Normal,
        onFinish: () => {
          HiLog.i(TAG, 'animation onFinish');
          AppStorage.setOrCreate('settingAnimationDoing', false);
        }
      })
    .translate({
      x: this.getTranslateX(),
      y: this.getTranslateY(),
    })
    .onBackPressed((): boolean => {
      this.mAction.changeFunctionValue(FunctionId.SETTING, false);
      return true;
    })
    .onDisAppear((): void => {
      CustomTransition.getInstance().unRegisterNavParam(this.pageId)
    })
    .width(this.getViewWidth())
    .height(this.getViewHeight())
    .backgroundColor(Color.Black)
  }

  private getRestoreButtonHeight(): number {
    let maxOneLineLength: number = this.getViewWidth() - 2 * (this.isVertical() ? 4 : 0) - 32;
    let restoreTextLength: number = MeasureText.measureText({
      textContent: $r('app.string.restore_defaults'),
      fontSize: $r('sys.float.Body_L'),
      fontWeight: FontWeight.Regular
    });

    if ((px2vp(restoreTextLength) > maxOneLineLength)) {
      return 24 + 32 * this.fontSizeScale;
    } else {
      return 24 + 16 * this.fontSizeScale;
    }
  }
}