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

export enum RenderType {
  NONE = 0,
  POPUP_BUTTON = 1, // TabBar弹出条类型,闪光灯
  TOGGLE_SETTING_ITEM = 2, // 设置页开关类型,自拍镜像、水平仪等
  POPUP_SETTING_ITEM = 3, // 设置页弹窗类型,照片比例、视频分辨率等
  TOGGLE_TREASURE_BOX_ITEM = 4, // 百宝箱开关类型,参考线、运动防抖等
  POPUP_TREASURE_BOX_ITEM = 5, // 百宝箱弹出选项类型,照片比例、闪光灯等
  POPUP_EXTEND_BAR = 6, // 拓展调节Bar内展示
  LINKAGE_TABBAR_BUTTON = 7, // TabBar联动唤起百宝箱类型,滤镜、XMAGE等
  TOGGLE_BUTTON = 8, // TabBar开关类型,运动防抖等
  RADIO = 9, // 单选框
}