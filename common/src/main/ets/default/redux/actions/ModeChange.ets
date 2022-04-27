/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

export const ACTION_CHANGE_PREVIEW_SIZE = 'changePreviewSize'

export const ACTION_CHANGE_SHUTTER_BUTTON = 'changeShutterButton'

export const ACTION_CHANGE_TAB_ITEM = 'changeTabItem'

export function changePreviewSize(size) {
  return {
    type: ACTION_CHANGE_PREVIEW_SIZE,
    data: { size: size }
  }
}

export function changeShutterButton(res) {
  return {
    type: ACTION_CHANGE_SHUTTER_BUTTON,
    data: { res: res }
  }
}

export function changeTabItem(mode: string) {
  return {
    type: ACTION_CHANGE_TAB_ITEM,
    data: mode
  }
}