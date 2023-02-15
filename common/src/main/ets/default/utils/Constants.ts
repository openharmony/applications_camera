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

export class Constants {
  static readonly APP_KEY_ASYNC_MANAGER = 'app_key_async_manager'
  static readonly APP_KEY_SETTINGS_UTILS = 'app_key_settings_util'
  static readonly APP_KEY_CAMERA_WORKER = 'APP_KEY_CAMERA_WORKER'
  static readonly APP_KEY_WINDOW_SIZE = 'app_key_window_size'
}

export enum CameraStatus {
  CAMERA_BEFORE_VALUE = 'CAMERA_BEFORE_VALUE',
  CAMERA_BEGIN_INIT = 'CAMERA_BEGIN_INIT',
  CAMERA_INIT_FINISHED = 'CAMERA_INIT_FINISHED',

  CAMERA_BEGIN_PREVIEW = 'CAMERA_BEGIN_PREVIEW',
  CAMERA_PREVIEW_FINISHED = 'CAMERA_PREVIEW_FINISHED',

  CAMERA_RELEASING = 'CAMERA_RELEASING',
  CAMERA_RELEASE_FINISHED = 'CAMERA_RELEASE_FINISHED',

  CAMERA_BEGIN_TAKE_VIDEO = 'CAMERA_BEGIN_TAKE_VIDEO',
  CAMERA_TAKE_VIDEO_FINISHED = 'CAMERA_TAKE_VIDEO_FINISHED'
}

export enum CameraNeedStatus {
  CAMERA_NO_NEED_TO_DO = 'CAMERA_NO_NEED_TO_DO',
  CAMERA_NEED_INIT = 'CAMERA_NEED_INIT',
  CAMERA_NEED_RELEASE = 'CAMERA_NEED_RELEASE'
}