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

const PREFIX: string = 'PICKER_ACTION_';

export class PickerActionType {
  public static readonly EXIT_PICKER_WITHOUT_RESULTS = PREFIX + 'EXIT_PICKER_WITHOUT_RESULTS';
  public static readonly EXIT_PICKER_WITH_RESULTS = PREFIX + 'EXIT_PICKER_WITH_RESULTS';
  public static readonly LEARN_MORE_SECURITY_CAMERA = PREFIX + 'LEARN_MORE_SECURITY_CAMERA';
  public static readonly EXTENSION_PICKER_CLOSE = PREFIX + 'EXTENSION_PICKER_CLOSE';
  public static readonly SHOW_PICKER_VIEW = PREFIX + 'SHOW_PICKER_VIEW';
  public static readonly PHOTO_RECEIVED = PREFIX + 'PHOTO_RECEIVED';
}