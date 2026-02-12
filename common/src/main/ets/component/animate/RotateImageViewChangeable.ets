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
import lazy { OhCombinedState, reduxSubscribe, Unsubscribe } from '../../redux';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
/* instrument ignore file */

const TAG: string = 'RotateImageViewChangeable';

@Component
export struct RotateImageViewChangeable {
  @Prop rotateImageWidth: number = 0;
  @Prop rotateImageHeight: number = 0;
  private imgFit: ImageFit = ImageFit.None;
  @Prop defaultImgSrc: Resource;
  private fillColor: ResourceColor = '';
  @State rotateAngle: number = 0;
  private mSubscriber: Unsubscribe | null = null;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
    }, null);
    HiLog.i(TAG, 'aboutToAppear X.');
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
      .rotate({ angle: this.rotateAngle })
      .animation({
        duration: this.getAnimationDuration(),
        curve: Curve.Friction,
        iterations: 1,
        playMode: PlayMode.Normal,
        onFinish: () => {
          HiLog.i(TAG, 'onFinish');
        },
      })
      .draggable(false)
  }

  private getAnimationDuration(): number {
    return AnimSpecifications.ANIM_DURATION_300;
  }
}