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

const PREFIX: string = 'THUMBNAIL_ACTION_';

export class ThumbnailActionType {
  public static readonly REFRESH = PREFIX + 'REFRESH';
  public static readonly RECEIVED = PREFIX + 'RECEIVED';
  public static readonly ANIMATION = PREFIX + 'ANIMATION';
  public static readonly PHOTOBROWSER_STATUS = PREFIX + 'PHOTOBROWSER_STATUS';
  public static readonly PHOTOBROWSER_TOUCH_STATUS = PREFIX + 'PHOTOBROWSER_TOUCH_STATUS';
  public static readonly SAVE_THUMBNAIL = PREFIX + 'SAVE_THUMBNAIL';
  public static readonly ROLL_BACK = PREFIX + 'ROLL_BACK';
  public static readonly BROWSER_ADD_THUMBNAIL = PREFIX + 'BROWSER_ADD_THUMBNAIL';
  public static readonly BROWSER_UPDATE_THUMBNAIL_ASSET = PREFIX + 'BROWSER_UPDATE_THUMBNAIL_ASSET';
  public static readonly CHANGE_THUMBNAIL = PREFIX + 'CHANGE_THUMBNAIL';
  public static readonly PC_PICKER_RECEIVED = PREFIX + 'PC_PICKER_RECEIVED';

}