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
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { RotateImageViewChangeable } from '../animate/RotateImageViewChangeable';
import lazy { CircleImageOutRim } from './CircleImageOutRim.ts';

/* instrument ignore file */
@Component
export struct CircleImageDimVersion {
  private onCircleImageClicked: Function = () => {}
  @Prop circleImageRes: Resource;
  @Prop isCancelViewVisibility: boolean = false;
  @Prop outRimOpacity:number = 0.4;
  @Prop fillColor : ResourceColor = '';

  build() {
    Stack({ alignContent: Alignment.Center }) {
      CircleImageOutRim({
        fillColor: this.fillColor,
      })
        .opacity(this.outRimOpacity);

      RotateImageViewChangeable({
        rotateImageWidth: 24,
        rotateImageHeight: 24,
        imgFit: ImageFit.Cover,
        fillColor: this.fillColor,
        defaultImgSrc: this.circleImageRes,
      })
    }
    .visibility(this.isCancelViewVisibility ? Visibility.Visible : Visibility.Hidden)
    .width(44)
    .height(44)
    .onClick(() => {
      this.onCircleImageClicked();
    })
  }
}