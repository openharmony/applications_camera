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

export enum ModeType {
  NONE = 'NULL',

  // 相机应用层代码架构拍摄模式-命名建议与用户可见英文保持一致;
  PHOTO = 'PHOTO', // 拍照模式
  VIDEO = 'VIDEO', // 录像模式

  MORE = 'MORE',

  // 配置文件差异场景模式,禁止乱用;
  VIDEO_SNAPSHOT = 'VIDEO SNAPSHOT', // 录像抓拍场景
}

export const VdeCollapsedFilterModeType: ModeType[] = [ModeType.PHOTO, ModeType.VIDEO];