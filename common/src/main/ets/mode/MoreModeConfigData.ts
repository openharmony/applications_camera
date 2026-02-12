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

import lazy { CameraAppCapability } from '../camera/CameraAppCapability';
import lazy { HiLog } from '../utils/HiLog';
import lazy { ModeType } from './ModeType';

const TAG: string = 'MoreModeConfigData';

// 更多页分帧渲染阶段：提升进入更多响应时延
export enum MorePageFrameStage {
  FIRST_STAGE = 0,
  SECOND_STAGE = 1,
  THIRD_STAGE = 2,
}

export interface GlobalModeListAndName {
  modeList: ModeType[],
  modeName: Object[],
}

//更多页使用的完整数据
export interface MorePageData {
  gridModeData: MoreModeType[],
  barModeData: MoreModeType[],
}

export type MoreModeType = {
  name: Resource,
  img?: Resource,
  isDelete: boolean, // 更多页列表项是否可以删除
  isDisDrag: boolean, // 更多页编辑bar是否禁用拖动
  modeType: ModeType,
};

// 更多页使用的模式名称数据
export interface MorePageType {
  gridModeType: ModeType[],
  barModeType: ModeType[]
}

export interface ModeData {
  name: Resource,
  modeType: ModeType
}

export interface NewAddMode { // CCM新增模式
  mode: ModeType,
  prevMode?: ModeType, // 新增模式前面一个模式
  isBarMode: boolean, // 新增模式是否展示在bar上
}

// TODO：支持模式配置的所有模式数据，添加新模式需配置
export const EditedMoreModeData: Map<ModeType, MoreModeType> = new Map([
  [ModeType.PHOTO, {
    name: $r('app.string.photo_mode'),
    isDelete: false,
    isDisDrag: true,
    modeType: ModeType.PHOTO,
  }],
  [ModeType.VIDEO, {
    name: $r('app.string.video_mode'),
    isDelete: false,
    isDisDrag: true,
    modeType: ModeType.VIDEO,
  }]
]);

const isContainProjectMode = (mode: ModeType): boolean => { // CCM资源中配置本地不存在的模式会导致闪退
  return EditedMoreModeData.has(mode);
};

export const isDisDragEditedMode = (mode: ModeType): boolean => { // 是否是不可拖拽的模式
  return EditedMoreModeData.get(mode)?.isDisDrag;
};

// TODO: 不可添加，仅供v1配置文件使用
const defaultGridMode: ModeType[] = [];
const defaultBarMode: ModeType[] = [
  ModeType.PHOTO,
  ModeType.VIDEO,
];
const defaultFilteredMode: ModeType[] = [];

// pc从配置文件获取存在空指针情况，try catch处理
const getGridMode = (): ModeType[] => { // 更多页网格区模式
  let gridMode: ModeType[] = defaultGridMode;
  try {
    gridMode = (CameraAppCapability.getInstance().getMoreModeList() ||
      defaultGridMode).filter(item => (isContainProjectMode(item)));
  } catch (e) {
    HiLog.e(TAG, 'getGridMode err.');
  }
  return gridMode;
};

const getBarMode = (): ModeType[] => { // 更多页编辑态Bar区模式，除最后一项同模式条一致
  let barMode: ModeType[] = defaultBarMode;
  try {
    barMode = (CameraAppCapability.getInstance().getModeBarList() ||
      defaultBarMode).filter(item => (isContainProjectMode(item)));
  } catch (e) {
    HiLog.e(TAG, 'getBarMode err.');
  }
  return barMode;
};

const getBackAsFrontFilterMode = (): ModeType[] => { // 后当前不要展示的模式
  let backAsFrontMode: ModeType[] = defaultFilteredMode;
  try {
    backAsFrontMode = (CameraAppCapability.getInstance().getFilteredModeList() ||
      defaultFilteredMode).filter(item => (isContainProjectMode(item)));
  } catch (e) {
    HiLog.e(TAG, ' getBackAsFrontFilterMode err.');
  }
  return backAsFrontMode;
};

// TODO: 不可改动，新模式需添加CCM，本地配置文件v2不可添加
export const MorePageDefaultData: MorePageType = { gridModeType: getGridMode(), barModeType: getBarMode() };

export const BackAsFrontFilterModeData: ModeType[] = getBackAsFrontFilterMode();
