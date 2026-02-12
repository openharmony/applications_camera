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

const TAG: string = 'ViewRotateTranslate';
const LANDSCAPE_2: number = 2;

class TranslateSize {
  translateX: number = 0;
  translateY: number = 0;
}

/**
 * @file: 当组件宽高不一致时根据组件宽高获取组件绕自身中心点旋转90/270度的偏移量
 */
/* instrument ignore file */
export class ViewRotateTranslate {
  private static groupTranslate: TranslateSize = new TranslateSize();

  /**
   *  根据容器组件宽高获取组件绕自身中心点旋转90/270度的偏移量
   *
   */
  static getTranslateSize(groupHeight: number, groupWidth: number): TranslateSize {
    if (groupHeight === 0 || groupWidth === 0) {
      ViewRotateTranslate.groupTranslate.translateX = 0;
      ViewRotateTranslate.groupTranslate.translateY = 0;
      return ViewRotateTranslate.groupTranslate;
    }
    ViewRotateTranslate.groupTranslate.translateX = -(groupHeight - groupWidth) / LANDSCAPE_2;
    ViewRotateTranslate.groupTranslate.translateY = (groupHeight - groupWidth) / LANDSCAPE_2;
    return ViewRotateTranslate.groupTranslate;
  }
}
