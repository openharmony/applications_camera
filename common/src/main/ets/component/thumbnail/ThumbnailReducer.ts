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

import lazy { OhCombinedState } from '../../redux';
import type { ActionData } from '../../redux/actions/Action';
import lazy { ThumbnailActionType } from '../../redux/actions/ThumbnailActionType';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';

export type ThumbnailState = {
  photoBrowserStatus: boolean, // 大图是否打开
  photoBrowserTouchStatus: boolean // 大图是否被touch
};

const TAG: string = 'thumbnailReducer';

const thumbnailStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initThumbnailStateMap(): Map<string, object> {
  const initState: ThumbnailState = {
    photoBrowserStatus: false,
    photoBrowserTouchStatus: false
  };
  return initReduxStateMap(initState, thumbnailStateMap);
}

const thumbnailReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setThumbnailReducerMap(): void {
  thumbnailReducerMap.set(ThumbnailActionType.PHOTOBROWSER_STATUS, (action: ActionData) => {
    return {
      photoBrowserStatus: action.data.photoBrowserStatus
    };
  });

  thumbnailReducerMap.set(ThumbnailActionType.PHOTOBROWSER_TOUCH_STATUS, (action: ActionData) => {
    return {
      photoBrowserTouchStatus: action.data.photoBrowserTouchStatus
    };
  });
}

export function thumbnailReducer(state: OhCombinedState, action: ActionData): string[] {
  if (thumbnailReducerMap.size <= 0) {
    setThumbnailReducerMap();
  }
  return execReduxReducer(state, action, thumbnailReducer.name, thumbnailReducerMap, initThumbnailStateMap);
}