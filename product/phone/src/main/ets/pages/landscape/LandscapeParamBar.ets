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
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ParamBarService } from '../paramBar/ParamBarService';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { ChangeState, Dispatch, execDispatch, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { display } from '@kit.ArkUI';
import lazy { ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy {
  LongPressDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/LongPressDialogView';
import camera from '@ohos.multimedia.camera';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { FunctionConflictParamData } from '@ohos/common/src/main/ets/component/treasurebox/common/DataType';
import lazy { ConflictManager } from '@ohos/common/src/main/ets/function/core/ConflictManager';

type Callback = (isShow: boolean) => void;

interface CollapsData {
  collapsStatus: display.FoldStatus
}

/* instrument ignore file */
const TAG: string = 'LandscapeParamBar';

class StateStruct {
  public xComponentWidth: number = 0;
  public position?: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public zoomRatio: number = 0;
  public mode: ModeType = ModeType.NONE;
  public recordState: RecordingState = RecordingState.READY;
}

export const GAP_WITH_MODE_BAR = 12;

const POSITION_Y_CENTER_THIRD = -36;
const POSITION_Y_TOP = 0;
const POSITION_Y_CENTER = 36;
const POSITION_Y_BOTTOM = 72;
const POSITION_Y_BOTTOM_THIRD = 108;

class ParamBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public showNightSubModeView(): void {
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public updatePopupShow(popupShow: boolean): void {
  }
}


export const PARAM_ELEMENT_SIDE_LENGTH: number = 48;

export const PARAM_ELEMENT_SIDE_LENGTH_RTL: number = 64;

export const PARAM_ICON_OFFSET: number = 12;

export const PARAM_ICON_OFFSET_RTL: number = 7;

export const PARAM_BAR_HEIGHT: number = 80;

const ICON_SIZE: number = 20;
const TEXT_SINGLE_LINE_HEIGHT: number = 13;
const SPACE_ICON_TEXT: number = 3;
const ICON_TEXT_TOTAL_HEIGHT: number = (ICON_SIZE + TEXT_SINGLE_LINE_HEIGHT + SPACE_ICON_TEXT);
const MARGIN_TOP_BOTTOM: number = (PARAM_ELEMENT_SIDE_LENGTH - ICON_TEXT_TOTAL_HEIGHT) / 2;

@Component
export struct LandscapeParamBar {
  @State superMacroPositionY: number = POSITION_Y_CENTER;
  @State watchMoonPositionY: number = POSITION_Y_CENTER;
  @State effectSuggestionPositionY: number = POSITION_Y_CENTER;
  @State beautyPositionY: number = POSITION_Y_CENTER;
  @State aperturePositionY: number = POSITION_Y_CENTER;
  @State shutterPositionY: number = POSITION_Y_CENTER;
  @State stitchingPositionY: number = POSITION_Y_CENTER;
  @State motionFrameRatePositionY: number = POSITION_Y_CENTER;
  @State macroFocusPositionY: number = POSITION_Y_CENTER;
  @State lightPaintingPositionY: number = POSITION_Y_CENTER;
  @State nightSubModePositionY: number = POSITION_Y_CENTER;
  @State timeLapsePositionY: number = POSITION_Y_CENTER;
  @State longExposureY: number = POSITION_Y_CENTER;
  @State customFilterY: number = POSITION_Y_CENTER;
  @State mode: ModeType = ModeType.NONE;
  @State isShowSemiCollapsed: boolean = false;
  @State isDepthFusionShow: boolean = false;
  @State nightSubModeText: string = '';
  @State nightSubModeIcon: string = '';
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @State state: StateStruct = new StateStruct();
  @State isSupportNightSubModeFunc: boolean = false;
  @State superMacroConflict: boolean = false;
  private uiEnable: boolean = true;
  private mSubscriber: Unsubscribe | null = null;
  private paramBarService: ParamBarService = ParamBarService.getInstance();
  private isAnimation: boolean = false;
  private middleCBQueue: (() => void)[] = []; // 位移动效队列
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private modeChangeResolve: (() => void) | null = null;
  @Prop isHdr: boolean = false;
  private mAction: ParamBarDispatcher = new ParamBarDispatcher();

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E');
    this.superMacroConflict = AppStorage.get('BeautySuperMacroConflict') ?? false;
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        position: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        zoomRatio: state.get<number>('zoomReducer', 'zoomRatio'),
        recordState: state.get<RecordingState>('recordReducer', 'recordingState')
      });
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isDepthFusionShow = state.get<boolean>('depthFusionReducer', 'isVisible');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.updateNightSubModeValue();

    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      this.handleModeChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      (data: ActionData) => this.onFunctionChange(data), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, () => this.resetParamFunctions(), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      this.superMacroConflictManage.bind(this), this.mBase.hashCode());

    this.updateFunctionIconsPosition(true);
    this.resetParamFunctions();
    HiLog.i(TAG, 'aboutToAppear X');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E');
    this.handleModeChange();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
  }

  private handleMacroModeIcon(data: ActionData): void {
    return;
    const isDepthFusionVisibility: boolean = data['isConflicted'];
    if (isDepthFusionVisibility) {
      this.executePositionChange(FunctionId.FOCUS, POSITION_Y_TOP, false);
    } else {
      this.executePositionChange(FunctionId.FOCUS, POSITION_Y_CENTER, false);
    }
  }

  // 重置展示图标和位置
  private handleModeChange(): void {
    HiLog.i(TAG, `handleModeChange CurrentVisibilityFunctions: ${this.paramBarService.getCurrentVisibilityFunctions()
      .toString()}`);
    new Promise<void>((resolve: () => void) => {
      if (this.middleCBQueue.length || this.paramBarService.getCurrentVisibilityFunctions().length) {
        this.modeChangeResolve = resolve;
      } else {
        resolve();
      }
      HiLog.i(TAG, 'handleModeChange assign value.');
    }).then(() => {
      HiLog.i(TAG, 'handleModeChange clear');
      this.modeChangeResolve = null;
    });
  }

  private handleCollapsStateChange(data: CollapsData) {
    const collapsStatus: display.FoldStatus = data.collapsStatus;
    HiLog.i(TAG, `handleCollapsStateChange collapsState: ${collapsStatus}`);
    if (collapsStatus === display.FoldStatus.FOLD_STATUS_FOLDED) {
      this.handleModeChange();
    }
  }

  private updateFunctionIconsPosition(noAnimation: boolean, visibility = false, callback?: Callback,
    functionId?: FunctionId): void {
    const currentVisibilityFunctions = this.paramBarService.getCurrentVisibilityFunctions();
    const length = currentVisibilityFunctions.length;
    HiLog.i(TAG, `updateSuggestionPosition currentVisibilityFunctions: ${currentVisibilityFunctions.toString()}`);
    callback && callback(visibility);
    if (length === 1) {
      HiLog.i(TAG, `handle depthfusion conflict, mode: ${this.mode}, output: ${OutputSwitcher.getInstance().getOutput()}
        , depthFusionVisibility: ${this.isDepthFusionShow}}`);
      this.executePositionChange(currentVisibilityFunctions[0], POSITION_Y_CENTER, noAnimation);
    } else if (length === 2) {
      this.executePositionChange(currentVisibilityFunctions[0], POSITION_Y_TOP, noAnimation);
      this.executePositionChange(currentVisibilityFunctions[1], POSITION_Y_BOTTOM, true);
    } else if (length === 3) {
      this.executePositionChange(currentVisibilityFunctions[0], POSITION_Y_CENTER_THIRD, noAnimation);
      this.executePositionChange(currentVisibilityFunctions[1], POSITION_Y_CENTER, noAnimation);
      this.executePositionChange(currentVisibilityFunctions[2], POSITION_Y_BOTTOM_THIRD, true);
    } else {
      this.executePositionChangeQueue();
    }
  }

  private executePositionWithCustom(length: number, currentVisibilityFunctions: FunctionId[],
    noAnimation: boolean): void {
    if (length === 2) {
      this.executePositionChange(currentVisibilityFunctions[0], POSITION_Y_TOP, true);
      this.executePositionChange(currentVisibilityFunctions[1], POSITION_Y_BOTTOM, noAnimation);
    } else if (length === 3) {
      this.executePositionChange(currentVisibilityFunctions[0], POSITION_Y_CENTER_THIRD, true);
      this.executePositionChange(currentVisibilityFunctions[1], POSITION_Y_CENTER, noAnimation);
      this.executePositionChange(currentVisibilityFunctions[2], POSITION_Y_BOTTOM_THIRD, noAnimation);
    }
  }

  private handleFunctionIconsUpdate = (noAnimation: boolean, visibility: boolean,
    functionId: FunctionId, callback: Callback, replacedFunctionId?: FunctionId) => (): void => {

    const isSuccess = this.paramBarService.updateVisibilityFunction(functionId, visibility, replacedFunctionId);
    if (!isSuccess) {
      callback && callback(visibility);
      this.executePositionChangeQueue();
      HiLog.w(TAG, 'handleFunctionIconsChange no update.');
      return;
    }

    this.updateFunctionIconsPosition(noAnimation, visibility, callback, functionId);
  }
  // 处理功能图标的显示，变更，删除/隐藏
  private handleFunctionIconsChange = (functionId: FunctionId) =>
  (visibility: boolean, callback: Callback, replacedFunctionId?: FunctionId): void => {
    HiLog.i(TAG, `handleFunctionIconsChange functionId: ${functionId}, visibility: ${visibility}`);

    const noAnimation: boolean = !!this.modeChangeResolve || ParamBarService.getInstance().isStaticFunction(functionId);
    HiLog.i(TAG, `handleFunctionIconsChange noAnimation: ${noAnimation}`);
    const middleCB = this.handleFunctionIconsUpdate(noAnimation, visibility, functionId, callback, replacedFunctionId);
    if (!this.isAnimation || noAnimation) {
      middleCB();
    } else {
      this.middleCBQueue.push(middleCB);
    }
  }

  private setPosition(functionId: FunctionId, to: number): void {
    HiLog.i(TAG, `setPosition functionId: ${functionId}, to: ${to}`);
    if (functionId === FunctionId.FOCUS) {
      this.macroFocusPositionY = to;
    }
  }

  private executePositionChangeQueue(): void {
    HiLog.i(TAG, `executePositionChangeQueue length: ${this.middleCBQueue.length}, isAnimation: ${this.isAnimation}`);
    if (this.isAnimation) {
      return;
    }
    if (this.middleCBQueue.length) {
      this.middleCBQueue.shift()?.();
    } else {
      this.modeChangeResolve?.();
    }
  }

  private executePositionChange(functionId: FunctionId, to: number, noAnimation: boolean): void {
    if (noAnimation) {
      this.setPosition(functionId, to);
      return;
    }
    this.isAnimation = true;
    HiLog.i(TAG, `executePositionChange start functionId: ${functionId}`);
    animateTo({
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        this.isAnimation = false;
        HiLog.i(TAG, 'executePositionChange end');
        this.executePositionChangeQueue();
      }
    }, () => {
      this.setPosition(functionId, to);
    });
  }

  private updateNightSubModeValue(): void {
  }

  private onFunctionChange(data: ActionData): void {
  }

  private resetParamFunctions(): void {
  }

  private isShowNightSubModeIcon(): boolean {
    const mode: ModeType = this.state.mode;
    const cameraPosition: camera.CameraPosition | undefined = this.state.position;
    if (this.isSupportNightSubModeFunc) {
      return false;
    }
    return false;
  }

  private superMacroConflictManage(data: FunctionConflictParamData): void {
  }

  build() {
    RelativeContainer() {
      Column() {
        if (this.isShowNightSubModeIcon()) {
          // 新夜景特性入口
          Column() {
            ParamBarIconTextRotate({
              defaultImgSrc: $r(this.nightSubModeIcon),
              defaultTextSrc: $r(this.nightSubModeText),
              abTextSrc: ResGetter.getStringByName($r(this.nightSubModeText))
            })
              .id('NightSubMode')
              .key(ComponentIdKeys.PARAM_BAR_NIGHT_SUB_MODE)
              .offset({
                y: this.nightSubModePositionY
              })
              .visibility(Visibility.Hidden)
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .onClick((event) => {
                HiLog.i(TAG, 'isSupportNightSubModeFunc onClick.');
                if (!this.uiEnable) {
                  return;
                }
                if (this.enableScreenReader && !this.isOpenTouchGuide) {
                  AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringByName($r(this.nightSubModeText)))
                }
                this.mAction.updatePopupShow(false);
                this.mAction.showNightSubModeView();
                VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
              })
          }
        }
      }
      .width('100%')
      .height(120)
      .id('LandDynamicSuggestion')
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        center: { anchor: '__container__', align: VerticalAlign.Center },
      })
    }
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
  private static BEAUTY_PORTRAIT_TEXT_WIDTH: number = 70;
  private static TEXT_WIDTH: number = 58;

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
      .width(this.superNightTextWidth())
      .height(TEXT_SINGLE_LINE_HEIGHT * 2)// 美颜 适老化字体
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
      return PARAM_ELEMENT_SIDE_LENGTH_RTL
    }
    if (this.isBeautyIcon) {
      return ParamBarIconTextRotate.BEAUTY_PORTRAIT_TEXT_WIDTH
    }
    if (this.isMinorityLanguage()) {
      return PARAM_ELEMENT_SIDE_LENGTH_RTL + 10
    }
    return ParamBarIconTextRotate.TEXT_WIDTH
  }

  private isMinorityLanguage(): boolean { //日语|俄语|韩语
    return SystemLanguageUtil.isJapanese() || SystemLanguageUtil.isRussian() || SystemLanguageUtil.isKorean()
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