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
const TAG: string = 'PreviewCustomFilterMasking';

@Component
export struct PreviewCustomFilterMasking {
  // 蒙层高度
  @State maskWidth: number = 0;
  @Prop maskHeight: number = 0;
  @State isLeft: boolean = true;

  build() {
    Column() {
    }
    .alignItems(HorizontalAlign.Start)
    .height(this.maskHeight)
    .width('100%')
    .linearGradient({
      direction: this.isLeft ? GradientDirection.Left : GradientDirection.Right,
      colors: [[Color.Transparent, 0.0], [Color.Black, 1.0]]
    })
    .enabled(false)
    .position({ x : this.isLeft ? 0 : this.maskWidth * -1 })
  }
}
