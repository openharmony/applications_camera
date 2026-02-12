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

import lazy { OhCombinedState, Unsubscribe, reduxSubscribe } from '../../redux';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { TipService, APPEAR_ANIMATION_DURING } from './TipService';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';
import lazy { Configuration, LengthMetrics, window } from '@kit.ArkUI';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { TipActionType } from '../../redux/actions/TipActionType';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
// import lazy { PickerShieldAnimate, PickerType } from '@ohos/pickersheet';
import lazy { HiLog } from '../../../ets/utils/HiLog';
import lazy { PictureStringMixText, STRING_PLACE_HOLDER } from './PictureStringMixText';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PublicTag } from '../../service/preferences/PropTag';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { storageStatistics } from '@kit.CoreFileKit';
import lazy { MemoryService } from '../../service/Memory/MemoryService';

/* instrument ignore file */
const TAG: string = 'TIP';
const ROTATE_ANGLE_90: number = 90;

const TIP_OFFSET_Y_IN_PRIVACY_SHOW: number = 35;
const FONT_SCALE_LV6: number = 3.2;
const BYTE_UNIT_CARRY = 1024;

export const TIP_COLOR: string = '#664d4d4d';

interface ShowTipData {
  message: string,
  isBlack: boolean,
  imgSrc: ResourceStr,
  isStitching?: boolean,
  isLongText: boolean,
  isPickerShield: boolean
};

export const POSITION_Y_VERTICAL_RECORDING: number = 162;

const TIP_IMG_SIZE: number = DeviceInfo.isTv() ? 22 : 14;
const TIP_IMG_SIZE_MIX: number = 16;

@Component
export struct Tip {
  // 消息事件
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private hideAnimating: boolean = false;
  @State systemLanguage: string = '';
  @State isBlack: boolean = false;
  @State imageOpacity: number = 0;
  @State isVisibility: boolean = false;
  @State message: string = '';
  @State imgSrc: ResourceStr = '';
  @State isPickerShield: boolean = false;
  @State isShowBigText: boolean = false;
  @State isStitching: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @LocalStorageLink('changeCustomFilterImmersive') isCustomFilterImmersive: boolean = false;
  @StorageProp('isBannerVisiblePick') isBannerVisiblePick: boolean = false;
  @State rotateAngle: number = 0;
  @StorageLink('isTipLongText') isTipLongText: boolean = false;
  @State isPrivacyDialogShowWithLv6Font: boolean = false;
  @Prop isHdr: boolean = false;
  @StorageLink('isInBlurAnim') @Watch('onIsInBlurAnimStateChange') isInBlurAnim: boolean = false;
  private callerBundleName: string = '';
  private callerPid: string = '';
  @StorageLink('isChangingModeOrSwitchingCamera') @Watch('onModeChange') isChangingModeOrSwitchingCamera: boolean = false;
  @State isChangeMode: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @StorageLink('isPSDCollaps') isPSDCollapsed: boolean = false;

  aboutToAppear() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowBigText = state.get<boolean>('modeReducer', 'isShowBigText');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.windowStatus = state.get<window.WindowStatusType>('windowReducer', 'windowStatus');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
    }, null);
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      () => this.hideTip(), this.mBase.hashCode());
    this.mEventBus.on(TipActionType.ACTION_SHOW_TIP, this.handleTipVisibility, this.mBase.hashCode());
    this.mEventBus.on(TipActionType.ACTION_HIDE_TIP, this.handleTipInVisibility, this.mBase.hashCode());
    this.callerBundleName =
      GlobalContext.get().getCameraAbilityWant()?.parameters?.['ohos.aafwk.param.callerBundleName'] as string;
    this.callerPid = GlobalContext.get().getCameraAbilityWant()?.parameters?.['ohos.aafwk.param.callerPid'] as string;
    HiLog.i(TAG, `pickersheeet callerBundleName: ${this.callerBundleName} , callerPid: ${this.callerPid}`);
    AppStorage.setOrCreate('isTipComponentReady', true);
  }

  onDidBuild(): void {
    if (!this.isLemCollaps && !this.isPSDCollapsed && !GlobalContext.get().getIsPicker()) {
      // 相机冷启动时判断空间是否不足10GB
      try {
        MemoryService.getInstance().checkStorageStatus(false);
      } catch (error) {
        const faultReason = `getFreeSize failed because: ${error.message}`;
        HiLog.e(TAG, faultReason);
      }
    }
  }

  aboutToDisappear() {
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
    AppStorage.setOrCreate('isTipComponentReady', false);
  }

  private hideTip() :void {
    // picker星盾动效切模式不立刻消失，使其做正常3秒消失逻辑
    if (!this.isPickerShield) {
      TipService.getInstance().hideTip();
    }
  }

  private onModeChange(): void {
    if (AppStorage.get('restoreFlag')) {
      return;
    }
    if (this.isChangingModeOrSwitchingCamera) {
      this.isChangeMode = true;
    }
  }

  private onIsInBlurAnimStateChange(): void {
    if (this.isInBlurAnim) {
      return;
    }
    this.isChangeMode = false;
  }

  private handleTipVisibility = (data: ShowTipData): void => {
    // 如果当前处于关怀模式大6档且显示安全弹窗, 调整组件Y轴偏移量
    this.isPrivacyDialogShowWithLv6Font = false;
    let isPrivacyDialogLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.PICKER_IS_BANNER_LOADED, false) as boolean;
    if (!isPrivacyDialogLoaded && Math.abs(this.fontSizeScale - FONT_SCALE_LV6) < 1e-6) {
      this.isPrivacyDialogShowWithLv6Font = true;
    }

    this.message = data.message;
    this.isBlack = data.isBlack;
    this.imgSrc = data?.imgSrc;
    this.isTipLongText = data?.isLongText;
    this.isPickerShield = data.isPickerShield
    if (data?.isStitching) {
      this.isStitching = data.isStitching;
    }
    if (this.hideAnimating) {
      this.imageOpacity = 1;
      this.hideAnimating = false;
    }
    if (this.isVisibility) {
      return;
    }
    this.isVisibility = true;
    this.imageOpacity = 0;
    animateToImmediately({
      duration: APPEAR_ANIMATION_DURING,
      curve: Curve.Sharp,
    }, () => {
      this.imageOpacity = 1;
    });
  }
  private handleTipInVisibility = (): void => {
    this.hideAnimating = true;
    animateToImmediately(
      {
        duration: APPEAR_ANIMATION_DURING,
        curve: Curve.Sharp,
        onFinish: () => {
          if (this.hideAnimating) {
            this.isVisibility = false;
            if (this.isPickerShield && !this.isLemCollaps && !this.isPSDCollapsed) {
              // picker冷启动时判断空间是否不足10GB，显示时机在“安全访问”之后
              try {
                MemoryService.getInstance().checkStorageStatus(false);
              } catch (error) {
                const faultReason = `getFreeSize failed because: ${error.message}`;
                HiLog.e(TAG, faultReason);
              }
            }
            this.isPickerShield = false;
          }
        }
      },
      () => {
        this.imageOpacity = 0;
      })
  }

  @Builder
  TipContent() {
    if (this.isPickerShield) {
      Row() {
        this.PickerShieldbuilder()
      }
      .height(DeviceInfo.isTv() ? 64 : undefined)
      .padding(DeviceInfo.isTv() ? undefined : {
        left: !this.imgSrc ? 0 : this.isBlack ? $r('sys.float.padding_level8') : $r('sys.float.padding_level3'),
        right: SystemLanguageUtil.isRTL() ? $r('sys.float.padding_level3') : 0
      })
      .offset({ y: DeviceInfo.isTv() ? -254 : (this.isVdeCollapsed ? 0 : (this.isCustomFilterImmersive ? 18 : 0)) })
      .opacity(this.imageOpacity)
      .key(ComponentIdKeys.TIP)
      .margin((this.isBannerVisiblePick && (this.systemLanguage === 'en-Latn-US' || this.systemLanguage === 'bo' ||
        this.systemLanguage === 'ug')) ? { top: this.isVertical() ? 17 : 32 } : undefined)
    } else {
      Row({ space: DeviceInfo.isTv() ? 8 : 4 }) {
        if (this.imgSrc) {
          Image(this.imgSrc)
            .size({ width: TIP_IMG_SIZE, height: TIP_IMG_SIZE })
            .fillColor(DeviceInfo.isTv() ? ColorContent.ORIGIN : (this.isBlack ? Color.White : Color.Black))
            .margin(DeviceInfo.isTv() ? { start: LengthMetrics.vp(22) } : undefined)
        }
        Text(this.message)
        //适老化适配，tip字体最大倍数为初始值的1.45倍
          .fontWeight(DeviceInfo.isTv() ? FontWeight.Medium : undefined)
          .fontSize(DeviceInfo.isTv() ? 22 :
            !this.isVdeCollapsed && SystemLanguageUtil.isRTL() ? 12 : $r('sys.float.Body_S'))
          .maxFontScale(this.isVdeCollapsed && this.getIconLength(this.message) > 30 ? CommonConstants.TEXT_SIZE_NORMAL :
          CommonConstants.TEXT_SIZE_HUGE)
          .fontColor(this.isBlack ? Color.White : Color.Black)
          .textAlign(DeviceInfo.isTv() ? TextAlign.Center : TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding(DeviceInfo.isTv() ? undefined : {
            left: this.imgSrc ? 0 : this.isBlack ? $r('sys.float.padding_level8') : $r('sys.float.padding_level3'),
            right: this.isBlack ? $r('sys.float.padding_level8') : $r('sys.float.padding_level3'),
            top: this.isBlack ? $r('sys.float.padding_level4') : $r('sys.float.padding_level3'),
            bottom: this.isBlack ? $r('sys.float.padding_level4') : $r('sys.float.padding_level3')
          })
          .lineHeight(DeviceInfo.isTv() ? 26 : undefined)
          .fontFeature('\"ss01\" on')
          .margin(DeviceInfo.isTv() ? { end: LengthMetrics.vp(22) } : undefined)
      }
      .height(DeviceInfo.isTv() ? 64 : undefined)
      .backgroundColor(this.isBlack ? (DeviceInfo.isTv() ? '#FF3C3C3C' : TIP_COLOR) : Color.White)
      .shadow(DeviceInfo.isTv() ? ShadowStyle.OUTER_DEFAULT_MD : {
        radius: 3,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .borderRadius(this.isBlack ? (DeviceInfo.isTv() ? 16 : $r('sys.float.corner_radius_level9')) :
      $r('sys.float.ohos_id_corner_radius_mark'))
      .padding(DeviceInfo.isTv() ? undefined : {
        left: !this.imgSrc ? 0 : this.isBlack ? $r('sys.float.padding_level8') : $r('sys.float.padding_level3'),
        right: SystemLanguageUtil.isRTL() ? $r('sys.float.padding_level3') : 0
      })
      .offset({ y: DeviceInfo.isTv() ? -254 : (this.isVdeCollapsed ? 0 : (this.isCustomFilterImmersive ? 18 :
        (this.isPrivacyDialogShowWithLv6Font && !this.isStitching ? TIP_OFFSET_Y_IN_PRIVACY_SHOW :0))) })
      .opacity( this.isChangeMode ? 0 : this.imageOpacity) // 切换模式时让其在模糊动效结束后再出现
      .key(ComponentIdKeys.TIP)
      .margin((this.isBannerVisiblePick && (SystemLanguageUtil.isEnglish() || SystemLanguageUtil.isTibetan() ||
      SystemLanguageUtil.isUygur())) ? { top: this.isVertical() ? 17 : 32 } : undefined)
    }
  }

  @Builder
  PickerShieldbuilder(): void {
    // PickerShieldAnimate({
    //   pickerType: PickerType.CAMERA_PICKER,
    //   callerBundleName: this.callerBundleName,
    //   callerPid: this.callerPid,
    //   onAnimateStateChange: (animateState) => {
    //     HiLog.i(TAG, `animateState:${animateState}`);
    //   }
    // })
  }

  @Builder
  MixPictureStringTip() {
    Row({ space: 4 }) {
      PictureStringMixText(
        {
          contentString: this.message,
          fontSize: Configuration.getLocale().dir === 'rtl' ? 12 : $r('sys.float.Body_S'),
          fontColor: this.isBlack ? Color.White : Color.Black,
          isPictureStart: true,
          imageSrc: this.imgSrc,
          iconSize: TIP_IMG_SIZE_MIX,
          textPadding: {
            left: this.imgSrc ? 0 : this.isBlack ? $r('sys.float.padding_level8') : $r('sys.float.padding_level3'),
            right: this.isBlack ? $r('sys.float.padding_level8') : $r('sys.float.padding_level3'),
            top: this.isBlack ? $r('sys.float.padding_level4') : $r('sys.float.padding_level3'),
            bottom: this.isBlack ? $r('sys.float.padding_level4') : $r('sys.float.padding_level3')
          }
        }
      )
    }
    .backgroundColor(this.isBlack ? TIP_COLOR : Color.White)
    .shadow({
      radius: 3,
      color: '#33000000',
      offsetX: 0,
      offsetY: 0
    })
    .borderRadius(this.isBlack ? $r('sys.float.ohos_id_corner_radius_dialog') :
    $r('sys.float.ohos_id_corner_radius_mark'))
    .padding({
      left: !this.imgSrc ? 0 : this.isBlack ? $r('sys.float.padding_level8') : $r('sys.float.padding_level3'),
      right: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.padding_level3') : 0
    })
    .offset({ y: this.isVdeCollapsed ? 0 : (this.isCustomFilterImmersive ? 18 : 0) })
    .opacity(this.imageOpacity)
    .key(ComponentIdKeys.TIP)
  }

  private isVertical(): boolean {
    return (Math.abs(this.rotateAngle) / ROTATE_ANGLE_90) % 2 === 0;
  }

  private showMixTip(): boolean {
    if (!this.message || !this.imgSrc) {
      return false;
    }
    if (typeof (this.message) === 'string') {
      return this.message.indexOf(STRING_PLACE_HOLDER) >= 0 && this.imgSrc !== ''
    } else {
      return ResGetter.getStringSafe(this.message).indexOf(STRING_PLACE_HOLDER) >= 0 && this.imgSrc !== ''
    }
  }

  build() {
    if (this.isVisibility) {
      if (this.showMixTip()) {
        this.MixPictureStringTip();
      } else {
        this.TipContent();
      }
    }
  }

  private getIconLength(val: Resource | string): number {
    return ResGetter.getStringSafe(val).length;
  }
}