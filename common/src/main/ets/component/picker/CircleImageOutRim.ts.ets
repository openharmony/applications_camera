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

@Component
export struct CircleImageOutRim {
  @Prop fillColor: ResourceColor = '';

  build() {
    Stack() {
      Column()
        .width(44)
        .aspectRatio(1)
        .border({ color: this.fillColor ? this.fillColor : Color.White, width: 1.5, radius: 22 })
      Column()
        .width(42)
        .aspectRatio(1)
        .border({ color: Color.Transparent, width: 0, radius: 21 })
        .backgroundColor('#334d4d4d')
    }
  }
}