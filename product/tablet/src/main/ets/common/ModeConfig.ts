/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

export class ModeConfig {
  private photoPadding: PaddingData = { top: 48, bottom: 154 }
  private videoPadding: PaddingData = { top: 48, bottom: 0 }


  public getPaddingConfig(mode: string): PaddingData {
    switch (mode) {
    case 'PHOTO':
      return this.photoPadding
    case 'VIDEO':
      return this.videoPadding
    }
  }
}

export class PaddingData {
  top = 48
  bottom = 154
}