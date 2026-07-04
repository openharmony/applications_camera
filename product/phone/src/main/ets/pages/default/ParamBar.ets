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

import lazy { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { Unsubscribe, OhCombinedState, Dispatch } from '@ohos/common/src/main/ets/redux';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import camera from '@ohos.multimedia.camera';
import lazy { ChangeState, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy {
  LongPressDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/LongPressDialogView';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import Configuration from '@system.configuration';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { ConflictManager } from '@ohos/common/src/main/ets/function/core/ConflictManager';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { intl, lottie, AnimationItem } from '@ohos/common/src/main/ets/utils/LazyImportUtil';
import lazy { AbilityChangeData } from '@ohos/common/src/main/ets/utils/types';
import lazy { PhotoFormatMode } from '@ohos/common/src/main/ets/function/enumbase/PhotoFormatMode';
import lazy { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { LogStyleMode } from '@ohos/common/src/main/ets/function/enumbase/LogStyleMode';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import I18n from '@ohos.i18n';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { window } from '@kit.ArkUI';

/* instrument ignore file */
const TAG: string = 'ParamBar';

class StateStruct {
  public xComponentWidth: number = 0;
  public position?: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public mode: ModeType = ModeType.NONE;
  public recordState: RecordingState = RecordingState.READY;
}

class ParamBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public showMacroFocusView(): void {
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.FOCUS));
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public updateIsoRange(max: number): void {
    this.mDispatch(Action.updateIsoRange(max));
  }

  public logModeChange(isOn: boolean): void {
    this.mDispatch(Action.logModeChange(isOn));
  }

  public changeTreasureBox(isOpen: boolean): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(isOpen));
  }
}

interface FunctionConflictParamData {
  id: FunctionId,
  conflictParam: Object
}

export const PARAM_ELEMENT_SIDE_LENGTH: number = 48;

export const PARAM_ELEMENT_SIDE_LENGTH_RTL: number = 64;

export const PARAM_ICON_OFFSET: number = 6;

export const PARAM_ICON_OFFSET_LOG: number = 12;

export const PARAM_ICON_OFFSET_RTL: number = 7;

export const PARAM_BAR_HEIGHT: number = 80;

const ICON_SIZE: number = 20;
const TEXT_SINGLE_LINE_HEIGHT: number = 13;
const SPACE_ICON_TEXT: number = 3;
const ICON_TEXT_TOTAL_HEIGHT: number = (ICON_SIZE + TEXT_SINGLE_LINE_HEIGHT + SPACE_ICON_TEXT);
const MARGIN_TOP_BOTTOM: number = (PARAM_ELEMENT_SIDE_LENGTH - ICON_TEXT_TOTAL_HEIGHT) / 2;
const MINORITY_LANGUAGE_ADD_HEIGHT: number = 20;
const CUSTOM_FILTER_SHOWN_COUNT: number = 3;

/**
 * 参数Bar组件,如大光圈模式光圈调节入口、人像模式效果和美颜调节入口、专业模式专业参数调节入口等;
 * 布局说明：除专业模式外,ParamBar组件与ZoomView重叠布局、仅图标位置差异;
 *         专业模式下,ParamBar位于ModeBar上方、ZoomView位于ParamBar上方;
 * */
@Component
export struct ParamBar {
  private mBase: BaseComponent = new BaseComponent();
  protected mStoreManager: StoreManager = StoreManager.getInstance();
  @State state: StateStruct = new StateStruct();
  private mAction: ParamBarDispatcher = new ParamBarDispatcher();
  @State imgSrc: Resource = $r('app.media.setting');
  @State paramLeftFuncIds: FunctionId[] = [];
  @State paramRightFuncIds: FunctionId[] = [];
  private mSubscriber: Unsubscribe | null = null;
  private mFrequentSubscriber: Unsubscribe | null = null;
  private apertureCache: number = 0;
  private zoomRatioCache: number = 1;
  private uiEnable: boolean = true;
  @State isSupportApertureFunc: boolean = false;
  @State updateView: boolean = false;
  @State isSupportBeautyFunc: boolean = false;
  @State isSupportNightSubModeFunc: boolean = false;
  @State isSupportStitchingFunc: boolean = false;
  @State isSupportRealTimeLapseFunc: boolean = false;
  @State isPicker: boolean = false;
  @State isSupportShutterFunc: boolean = false;
  private apertureParams: Map<string, number> = new Map();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mCameraProxy: CameraProxy = CameraProxy.getInstance();
  @StorageLink('isAperture') isAperture: boolean = true;
  @StorageLink('isApertureShow') isApertureShow: boolean = true;
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true;
  @State shutterSpeedText: Resource | string = '';
  @State nightSubModeText: string = '';
  @State nightSubModeIcon: string = '';
  @State isHighStabilizationValue: boolean = false;
  @State superMacroConflict: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @State isSupport4k: boolean = false;
  @State isSupport60fps: boolean = false;
  @State isFocusModeMF: boolean = false;
  @State beautyPortraitText: Resource | string = '';
  @State isBeautyIconShow: boolean = false;
  @State isVdeLandscape: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @Prop @Watch('changeColorCorrectionVisiWithAnim') isCustomFilterImmersive: boolean = false;
  @StorageLink('onCustomFilterCardActionMenuShow') isShowActionMenu: boolean = false;
  @State isShowStitchingTypeBar: boolean = false;
  @State isShowLogStyleIcon: boolean = false;
  @State isVideoOutput: boolean = false;
  @StorageLink('isLogStyleAssistanceOpen') isLogStyleAssistanceOpen: boolean = PreferencesService.getInstance()
    .getPropValue(PersistType.FOREVER, PropTag.IS_LOG_ASSISTANCE_OPEN, false) as boolean;
  @State LogStyleText: string | Resource = '';
  @State LogStyleIcon: string | Resource = '';
  @State isTimeLapseAuto: boolean = true;
  @StorageLink('systemLanguage') @Watch('onSystemLanguageChanged') systemLanguage: string =
    I18n.System.getSystemLanguage();
  @State customFilterEffectEnable: boolean = false;
  @StorageLink('customFilterIconOffsetY') customFilterIconOffsetY: number = 0;
  @StorageLink('isCustomFilterImmersiveMoving') isCustomFilterImmersiveMoving: boolean = false;
  @State customFilterIconOpacity: number = 0;
  @State colorCorrectionOpacity: number = 0;
  @State colorCorrectionVisibility: Visibility = Visibility.Hidden;
  @Prop isHdr: boolean = false;
  @State windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @Prop isHorizontalFloatingWindow: boolean;
  @State zoomRatio: number = 0;
  @State isShowStyleParamBarPopup: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.superMacroConflict = AppStorage.get('BeautySuperMacroConflict') ?? false;
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        position: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        recordState: state.get<RecordingState>('recordReducer', 'recordingState'),
      });
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isVideoOutput = OutputOperation.isPanVideoOutput(state.get<ModeType>('modeReducer', 'mode'));
      this.isFocusModeMF =
        state.get<camera.FocusMode>('focusExposureReducer', 'focusMode') === camera.FocusMode.FOCUS_MODE_MANUAL;
      this.customFilterEffectEnable = state.get<boolean>('customFilterStyleReducer', 'customFilterEffectEnable');
      this.windowStatus = state.get<number>('windowReducer', 'windowStatus');
      this.isShowStyleParamBarPopup = state.get<boolean>('customFilterStyleReducer', 'paramBarPopupShow');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });

    this.mFrequentSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.zoomRatio = state.get<number>('zoomReducer', 'zoomRatio');
    }, null);
    this.resetParamFunctions();
    this.zoomRatioCache = this.zoomRatio;
    this.mEventBus.on(CameraActionType.STARTED, () => this.resetParamFunctions(), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      (data: ActionData) => this.onFunctionChange(data), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  private changeColorCorrectionVisiWithAnim(): void {
    if (this.isCustomFilterImmersive) {
      this.hideColorCorrectionAnim();
    } else {
      this.showColorCorrectionAnim();
    }
  }

  private showColorCorrectionAnim() {
    this.colorCorrectionVisibility = Visibility.Visible;
    animateToImmediately({
      duration: 150,
      curve: Curve.Sharp
    }, () => {
      this.colorCorrectionOpacity = 1;
    });
  }

  private hideColorCorrectionAnim() {
    animateToImmediately({
      duration: 150,
      curve: Curve.Sharp,
      onFinish: () => {
        this.colorCorrectionVisibility = Visibility.Hidden;
      }
    }, () => {
      this.colorCorrectionOpacity = 0;
    });
  }

  private onFunctionChange(data: ActionData): void {
    this.isShowActionMenu = false;
    if (this.state.position === camera.CameraPosition.CAMERA_POSITION_FRONT || data['id'] !== FunctionId.ZOOM) {
      return;
    }
    this.zoomRatioCache = this.zoomRatio;
  }

  private resetParamFunctions(): void {
    HiLog.i(TAG, `this.isHighStabilizationValue:${this.isHighStabilizationValue}`);
    this.isSupport4k = FeatureManager.getInstance()?.getFunction(FunctionId
      .VIDEO_RESOLUTION)?.getValue() === 1 ? false : true;
    this.isSupport60fps = FeatureManager.getInstance()?.getFunction(FunctionId
      .FRAME_RATE)?.getValue() === 2 ? false : true;
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
    this.mFrequentSubscriber?.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private onBackground() {
    this.isShowStitchingTypeBar = false;
  }

  build() {
    RelativeContainer() {
      ParamBarIconTextRotate({
        defaultImgSrc: $r('app.string.macro_focus_manual'),
        defaultTextSrc: this.beautyPortraitText,
        isBeautyIcon: true
      })
        .id('Beauty')
        .alignRules({
          left: { anchor: '__container__', align: HorizontalAlign.Start },
          center: { anchor: '__container__', align: VerticalAlign.Center },
        })
        .key(ComponentIdKeys.PARAM_BAR_PORTRAIT_BEAUTY)
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .onClick((event) => {
          HiLog.i(TAG, 'isSupportBeautyFunc onClick.');
          if (!this.uiEnable) {
            return;
          }
          if (this.enableScreenReader && !this.isOpenTouchGuide) {
            AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe($r('app.string.portrait_beauty')))
          }
          VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
        })
    }.width('100%').height(this.isVdeLandscape ? 60 : PARAM_BAR_HEIGHT)
  }

  onSystemLanguageChanged() {
  }

  private getCustomFilterIconOffsetX(): number {
    return SystemLanguageUtil.isRTL() ? 0 : -PARAM_ICON_OFFSET;
  }
}

const rotateTAG: string = 'ParamBarIconTextRotate';

@Component
export struct ParamBarIconTextRotate {
  @Prop defaultImgSrc: Resource | string = '';
  @Prop defaultTextSrc: Resource | string = '';
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @Prop propText: string | null = '';
  @State rotateAngle: number = 0;
  private mSubscriber: Unsubscribe | null = null;
  @State modeType: String = ModeType.NONE;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private customDialogViewController?: CustomDialogController;
  @State abTextSrc: string = '';
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isShowRingLightView: boolean = false;
  private isBeautyIcon: boolean = false;
  private static BEAUTY_PORTRAIT_TEXT_WIDTH: number = 72;
  private static TEXT_WIDTH: number = 60;

  aboutToAppear() {
    HiLog.i(rotateTAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.modeType = state.get<ModeType>('modeReducer', 'mode');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, null);
    HiLog.i(rotateTAG, 'aboutToAppear X.');
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
  }

  private getIconOffsetY(): number {
    let offsetY: number = MARGIN_TOP_BOTTOM + ICON_SIZE - PARAM_ELEMENT_SIDE_LENGTH / 2;
    return offsetY;
  }

  build() {
    // 屏幕朗读关闭 弹窗事件
    if (this.enableScreenReader) {
      this.screenReadBuilder();
    } else {
      this.commonBuilder();
    }
  }

  @Builder
  commonBuilder() {
    RelativeContainer() {
      this.itemBuilder()
    }
    .width(this.superNightTextWidth())
    .height(this.isMinorityLanguage() ? PARAM_ELEMENT_SIDE_LENGTH + MINORITY_LANGUAGE_ADD_HEIGHT :
      PARAM_ELEMENT_SIDE_LENGTH)
    .rotate({ angle: this.rotateAngle })
    .animation({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        HiLog.i(rotateTAG, 'onFinish');
      },
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            this.createLongPressDialog(this.defaultImgSrc, this.propText || this.defaultTextSrc);
            this.customDialogViewController?.open();
          }
        })
    )
    .onTouch((event) => {
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.customDialogViewController?.close();
      }
    })
    .transition(AnimSpecifications.ANIM_PARAM_BAR_APPEAR_OR_DISAPPEAR)
  }

  @Builder
  screenReadBuilder() {
    RelativeContainer() {
      this.itemBuilder()
    }
    .width(SystemLanguageUtil.isRTL() ? PARAM_ELEMENT_SIDE_LENGTH_RTL : PARAM_ELEMENT_SIDE_LENGTH)
    .height(PARAM_ELEMENT_SIDE_LENGTH)
    .rotate({ angle: this.rotateAngle })
    .animation({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        HiLog.i(rotateTAG, 'onFinish');
      },
    })
    .transition(AnimSpecifications.ANIM_PARAM_BAR_APPEAR_OR_DISAPPEAR)
  }

  @Builder
  itemBuilder() {
    Image(this.defaultImgSrc)
      .id('defaultImgSrc')
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        bottom: { anchor: '__container__', align: VerticalAlign.Center },
      })
      .width(20)
      .height(20)
      .offset({ y: this.getIconOffsetY() })
      .objectFit(ImageFit.Contain)
      .aspectRatio(1)
      .borderRadius(10)
      .fillColor(Color.White)
      .draggable(false)
      .syncLoad(true)
    Text(this.propText || this.defaultTextSrc)
      .id('defaultTextSrc')
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: 'defaultImgSrc', align: VerticalAlign.Bottom },
      })
      .offset({
        y: this.getIconOffsetY() + SPACE_ICON_TEXT
      })
      .direction(Direction.Auto)
      .width('100%')
      .height(this.isMinorityLanguage() ? TEXT_SINGLE_LINE_HEIGHT * 2.4 : TEXT_SINGLE_LINE_HEIGHT * 2)// 美颜 适老化字体
      .fontSize(!this.isShowRingLightView ? 11 : SystemLanguageUtil.isRTL() ? '10vp' :
        SystemLanguageUtil.isTibetan() ? '9vp' : 11)
      .maxFontScale(1)
      .fontColor(Color.White)
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Center)
      .align(Alignment.Top)
      .textShadow({
        radius: 5,
        color: '#4d000000',
        offsetX: 0,
        offsetY: 0
      })
      .fontFeature('\"ss01\" on')
      .accessibilityText(this.abTextSrc || ResGetter.getStringSafe(this.defaultTextSrc))
  }

  private superNightTextWidth(): number {
    if (SystemLanguageUtil.isRTL()) {
      return PARAM_ELEMENT_SIDE_LENGTH_RTL;
    }
    if (this.isBeautyIcon) {
      return ParamBarIconTextRotate.BEAUTY_PORTRAIT_TEXT_WIDTH;
    }
    if (this.isMinorityLanguage()) {
      return PARAM_ELEMENT_SIDE_LENGTH_RTL + 10;
    }
    if (SystemLanguageUtil.isSpanish()) {
      return ParamBarIconTextRotate.BEAUTY_PORTRAIT_TEXT_WIDTH;
    }
    return ParamBarIconTextRotate.TEXT_WIDTH;
  }

  private isMinorityLanguage(): boolean { //日语|俄语|法语|阿拉伯语
    return SystemLanguageUtil.isJapanese() || SystemLanguageUtil.isRussian() || SystemLanguageUtil.French() ||
    SystemLanguageUtil.isArabic()
  }

  private createLongPressDialog(iconRes: ResourceStr, label?: ResourceStr, isOnlyShowText: boolean = false): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm: () => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true,
          label: label
        },
        textRes: label,
        isOnlyShowText: isOnlyShowText
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }
}