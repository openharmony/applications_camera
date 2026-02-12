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

import lazy { getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../redux';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { FunctionValueType, PositionType } from '../../utils/types';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import camera from '@ohos.multimedia.camera';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { ActionData } from '../../redux/actions/Action';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
import ResGetter from '../../utils/ResGetter';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { WindowService } from '../../service/window/WindowService';
import window from '@ohos.window';

/* instrument ignore file */
const TAG: string = 'TextInfo';

const TRICOLLAPS_TEXT_INFO_OffSET_Y: number = 115;

@Component
export struct TextInfo {
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State introductoryText: Resource | string = '';
  @State mode: ModeType = ModeType.NONE;
  @State nightSubModeType: number = 0;
  @State mDirection: WindowDirection = 0;
  @Prop textInfoWidth: number = 0;
  @Prop textInfoHeight: number | string = 0;
  @Prop @Watch('showLongExposureInfo') isShowLongExposureInfo: boolean = false;
  @State isShowConstellationInfo: boolean = false;
  @Link isShowTextInfo: boolean;
  @State isShowMorePage: boolean = false;
  @Prop landscapePreviewPosition: PositionType = { x: 0, y: 0 };
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;

  aboutToAppear() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.nightSubModeType = state.get<number>('nightSubModeReducer', 'nightSubMode');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
    }, null);
    this.introductoryText = this.getDefaultTextSrc();
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND,
      this.onBackGround.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_FRAME_SHUTTER, () => this.isShowIntroductoryInfo(true, true),
      this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.changeFunctionValue.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_RESET_EXPOSURE_TIME, CameraActionType.CHANGE_MODE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE, ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END],
      () => this.isShowIntroductoryInfo(false, false), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_END, CameraActionType.STARTED],
      () => this.isShowIntroductoryInfo(true, false), this.mBase.hashCode());
  }

  aboutToDisappear() {
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private onBackGround(): void {
    HiLog.i(TAG, 'onBackGround');
    this.isShowIntroductoryInfo(false, false);
  }

  private showLongExposureInfo(): void {
    if (this.isShowLongExposureInfo && this.mode === ModeType.PHOTO) {
      this.introductoryText = $r('app.string.long_exposure_tips');
    }
  }

  private isShowConstellationTipInfo(data: ActionData): void {
    this.isShowConstellationInfo = data['isShow'] as boolean;
    if (this.isShowConstellationInfo) {
      this.introductoryText = $r('app.string.looking_for_stars');
    }
  }

  private getDefaultTextSrc() {
    this.isShowTextInfo = false;
    return '';
  }

  private isShowIntroductoryInfo(showIntroductoryInfo: boolean, changeIntroductoryInfo: boolean): void {
    HiLog.i(TAG, 'isShowIntroductoryInfo : ' + showIntroductoryInfo);
    this.introductoryText = '';
    this.isShowTextInfo = false;
  }

  private changeFunctionValue(data: FunctionValueType): void {
  }

  private getTextInfoFontSize(): number | Resource {
    if (SystemLanguageUtil.isTibetan()) {
      return 11;
    }
    return $r('sys.float.Body_M');
  }

  private getLineHeight(): number {
    if (SystemLanguageUtil.isTibetan()) {
      return 18;
    }
    return 20;
  }

  private getTextInfoOffsetY(): number {
    const windowStatus: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    if (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN) {
      return 0;
    }
    let isLockRotation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation');
    if (isLockRotation) {
      if (this.mDirection === WindowDirection.LEFT) {
        return TRICOLLAPS_TEXT_INFO_OffSET_Y;
      } else if (this.mDirection === WindowDirection.RIGHT) {
        return -TRICOLLAPS_TEXT_INFO_OffSET_Y;
      }
    }
    return 0;
  }

  @Builder
  TextInfoContentBuilder() {

    Text(this.introductoryText)
      .textAlign(TextAlign.Center)// AI超清 适老化字体
      .fontSize(this.getTextInfoFontSize())
      .maxFontScale(CommonConstants.TEXT_SIZE_EXTRA_LARGE)
      .fontColor(Color.White)
      .textShadow({
        radius: 3,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .fontWeight(FontWeight.Regular)
      .lineHeight((this.fontSizeScale <= CommonConstants.TEXT_SIZE_EXTRA_LARGE) ? this.getLineHeight() : '26vp')
      .maxLines(this.fontSizeScale <= CommonConstants.TEXT_SIZE_EXTRA_LARGE ? 4 : 2)
      .offset({ y: this.getTextInfoOffsetY() })
      .textOverflow({
        overflow: TextOverflow.Ellipsis
      })
      .fontFeature('\"ss01\" on')
      .id('TextInfo_ab_id')
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityText(ResGetter.getStringSafe(this.introductoryText))
  }

  build() {
    if ((this.isShowTextInfo || this.isShowLongExposureInfo || this.isShowConstellationInfo) && this.introductoryText) {
      Row() {
        this.TextInfoContentBuilder();
      }
      .width(this.textInfoWidth)
      .height(this.textInfoHeight)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
  }
}