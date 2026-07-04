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

export enum FunctionId { // functionId值禁止随意更改，会影响百宝箱一级列表展示顺序
  NONE = 0,
  CAPTURE = 4, // 拍照控制
  RECORD_CONTROL = 5, // 录像流程控制
  ZOOM = 6, // 变焦
  ASPECT_RATIO = 7, // 照片比例
  VIDEO_RESOLUTION = 9, // 视频分辨率
  FRAME_RATE = 10, // 视频帧率
  EFFICIENT_VIDEO = 11, // 高效视频格式
  FLASH = 12, // 后置闪光灯
  FOCUS = 16, // 手动对焦
  MIRROR = 17, // 自拍镜像
  ASSISTIVE_GRID = 19, // 参考线
  CAMERA_SWITCHER = 20, // 相机前后置切换控制
  SOUND_MUTE = 21, // 拍摄静音
  SAVE_GEO_LOCATION = 22, // 地理位置信息
  TIME_LAPSE = 23, // 定时拍摄
  EXPOSURE = 25, // 曝光补偿
  SETTING = 27, // 设置按钮
  HORIZONTAL_LEVEL = 28, // 水平仪
  DIRECTION = 29, // 横竖屏方向
  FLOATING_SHUTTER = 32, // 悬浮快门键
  SOUND_RECORDING_EFFECT = 101, // 录音效果
  TIMED_SHOT = 87, // 间隔定时拍
  PHOTO_FORMAT = 44, //照片格式
}