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
/* instrument ignore file */
import lazy { HiLog } from '../../utils/HiLog';
import lazy { OhCombinedState, Unsubscribe, getStates } from '../../redux';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { LongPressDialogView } from '../customdialog/dialogComponent/LongPressDialogView';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { Animator, AnimatorOptions, AnimatorResult } from '@kit.ArkUI';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { reduxSubscribe } from '../../redux/Store';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId'

/* instrument ignore file */
const TAG: string = 'RotateImageView';

@Component
export struct RotateImageView {
  @Prop rotateImageWidth: number = 0;
  @Prop rotateImageHeight: number = 0;
  private imgFit: ImageFit = ImageFit.Contain;
  private defaultImgSrc: Resource | string = '';
  @Prop fillColor: ResourceColor = '';
  @State rotateAngle: number = getStates().get<number>('contextReducer', 'rotateAngle');
  @State @Watch('onRotateAngleChanged') contextRotateAngle: number = getStates().get<number>('contextReducer', 'rotateAngle');
  private mSubscriber: Unsubscribe | null = null;
  private customDialogViewController?: CustomDialogController;
  private selector: number = 0;
  private value: number = 0;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private mStateChangeAnimator: AnimatorResult | null = null;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.contextRotateAngle = state.get<number>('contextReducer', 'rotateAngle');
    }, null);
    if (this.rotateImageWidth === 0) {
      this.rotateImageWidth = this.selector === FunctionId.PHOTO_FORMAT ? 28 : 20;
    }
    if (this.rotateImageHeight === 0) {
      this.rotateImageHeight = this.selector === FunctionId.PHOTO_FORMAT ? 16 : 20;
    }
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  onRotateAngleChanged() {
    this.mStateChangeAnimator?.pause();
    let options: AnimatorOptions = {
      duration: this.getAnimationDuration(),
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: this.rotateAngle,
      end: this.contextRotateAngle
    };
    if (this.mStateChangeAnimator) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.i(TAG, `mStateChangeAnimator reset: ${error}.`);
      }
    } else {
      this.mStateChangeAnimator = Animator.create(options);
    }
    this.mStateChangeAnimator.onFinish = () => {
      HiLog.d(TAG, 'mStateChangeAnimator onfinish');
      this.mStateChangeAnimator = null;
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      HiLog.d(TAG, 'mStateChangeAnimator onFrame');
      this.rotateAngle = value;
    };
    this.mStateChangeAnimator?.play();
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
  }

  build() {
    Image(this.defaultImgSrc)
      .width(this.rotateImageWidth)
      .height(this.rotateImageHeight)
      .objectFit(this.imgFit)
      .aspectRatio(1)
      .fillColor(this.fillColor)
      .rotate({ angle: DeviceInfo.isPc() ? 0 : this.rotateAngle })
      .id(`${ComponentIdKeys.getInstance()
        .getKey(ComponentIdKeys.getInstance().getKey('TabBar', this.selector), this.value)}`)
      .draggable(false)
      .enabled(true)
      .gesture(
        LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
          .onAction((event) => {
            if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
              this.createLongPressDialog(this.defaultImgSrc);
              this.customDialogViewController?.open();
            }
          })
      )
      .onTouch((event) => {
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.customDialogViewController?.close();
        }
      })
  }

  private getAnimationDuration(): number {
    return AnimSpecifications.ANIM_DURATION_300;
  }

  private createLongPressDialog(iconRes: ResourceStr): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm:() => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true
        },
        needFillColor: true
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }
}