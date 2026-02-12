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
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';

export enum FlashMode {
  OFF = <number> camera.FlashMode.FLASH_MODE_CLOSE,
  ON = <number> camera.FlashMode.FLASH_MODE_OPEN,
  AUTO = <number> camera.FlashMode.FLASH_MODE_AUTO,
  ALWAYS_OPEN = <number> camera.FlashMode.FLASH_MODE_ALWAYS_OPEN,
  TORCH = 4,
}

export interface FlashCloseScene {
  isEntry: boolean,
  isQuitBack?: boolean
}

export interface FlashModeInfo {
  flashMode: FlashMode;
  treasureBoxIcon: string,
  tabBarIcon: string,
  desc: Resource,
  title: string,
  // 增加accessibilityDescription的必要性是 因为通过context.resourceManager.getStringSync($r(title)) 会导致crash
  accessibilityDescription: Resource
}

export const FLASH_MODE_AUTO: FlashModeInfo = {
  flashMode: FlashMode.AUTO,
  treasureBoxIcon: 'app.media.treasure_box_flash_auto',
  tabBarIcon: 'app.media.flash_auto',
  desc: $r('app.string.flash_mode_auto'),
  title: 'app.string.treasure_box_flash_auto',
  accessibilityDescription: $r('app.string.treasure_box_flash_auto')
};

export const FLASH_MODE_OFF: FlashModeInfo = {
  flashMode: FlashMode.OFF,
  treasureBoxIcon: 'app.media.treasure_box_flash_off',
  tabBarIcon: 'app.media.flash_off',
  desc: $r('app.string.flash_mode_off'),
  title: 'app.string.treasure_box_flash_off',
  accessibilityDescription: $r('app.string.treasure_box_flash_off')
};

export const FLASH_MODE_ON: FlashModeInfo = {
  flashMode: FlashMode.ON,
  treasureBoxIcon: 'app.media.treasure_box_flash_on',
  tabBarIcon: 'app.media.flash_on',
  desc: $r('app.string.flash_mode_on'),
  title: 'app.string.treasure_box_flash_on',
  accessibilityDescription: $r('app.string.treasure_box_flash_on')
};

export const FLASH_MODE_ALWAYS_OPEN: FlashModeInfo = {
  flashMode: FlashMode.ALWAYS_OPEN,
  treasureBoxIcon: 'app.media.treasure_box_flash_open',
  tabBarIcon: 'app.media.flash_always_on',
  desc: $r('app.string.flash_mode_torch'),
  title: 'app.string.treasure_box_flash_always_on',
  accessibilityDescription: $r('app.string.treasure_box_flash_always_on')
};

// 通用单相机流的闪光灯模式
export const SINGLE_OUTPUT_MAPPING_FLASH_MODE: Map<OutputType, FlashModeInfo[]> = new Map([
  [OutputType.PHOTO_OUTPUT, [FLASH_MODE_AUTO, FLASH_MODE_OFF, FLASH_MODE_ON, FLASH_MODE_ALWAYS_OPEN]],
  [OutputType.VIDEO_OUTPUT, [FLASH_MODE_OFF, FLASH_MODE_ALWAYS_OPEN]],
]);

// 双相机流模式下的特殊闪光灯模式
export const MULTIPLE_OUTPUT_TYPE_MAPPING_FLASH_MODE: Map<string, FlashModeInfo[]> = new Map([
]);

const SUPPORT_FLASH_MODE_ARR: ModeType[] =
  [ModeType.PHOTO, ModeType.VIDEO];

export const isSupportFlashMode: (curMode: ModeType) => boolean = (curMode: ModeType) => {
  return SUPPORT_FLASH_MODE_ARR.includes(curMode);
};