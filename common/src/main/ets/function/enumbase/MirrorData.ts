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

export enum MirrorDataTypeName { // 与手软生成的json文件中的资源类型名称保持一致
  UNSPECIFIED = '', // 魔镜未开启
  PREVIEW = 'preview',
  PICTURE = 'image', // 静态图片
  VIDEO = 'video', // 视频
  MOVING_PHOTO = 'movingPhoto' // 动态照片
};

export enum MirrorDataType {
  UNSPECIFIED = -1, // 魔镜未开启
  PREVIEW = 0,
  PICTURE = 1, // 静态图片
  VIDEO = 2, // 视频
  MOVING_PHOTO = 3, // 动态照片
  MORE = 4 // 更多（跳转至设置）
};

export enum MirrorSelfieFigureID {
  custom = '0', // 自选图片
  digit = '-1' // 数字打卡
  // 其他类型拥有唯一ID，无需定义
};
export type MirrorData = {
  category: string,
  type: MirrorDataType,
  albumUri?: string,
  videoUri?: string,
  name?: string | Resource,
  id?: string, // 自选图片id为'0'，数字打卡图片id为'-1'
  categoryOrder?: string,
  figureOrder?: string,
  iconResource?: Resource // 内屏二级菜单的首尾项
};
