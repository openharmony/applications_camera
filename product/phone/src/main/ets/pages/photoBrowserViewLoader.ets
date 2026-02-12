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

// import { PhotoBrowserView } from '@photobrowser/browserlibrary/src/main/ets/view/PhotoBrowserView';
// import { SubScreenPhotoBrowserView } from '@photobrowser/browserlibrary/src/main/ets/view/SubScreenPhotoBrowserView';

/* instrument ignore file */
@Builder
export function PhotoBrowserViewLoader($$: PhotoBrowserViewLoaderParams) {
  // PhotoBrowserView({
  //   pageStatus: $$.pageStatus,
  //   hidePhotoBrowser: $$.hidePhotoBrowser,
  //   isRunningAnimation: $$.isRunningAnimation,
  //   isShowMenu: $$.isShowMenu,
  //   canPullingUp: $$.canPullingUp,
  //   isShowThumbSource: $$.isShowThumbSource,
  //   isShowImageAnalyzer: $$.isShowImageAnalyzer,
  //   reportStartTime: $$.reportStartTime,
  //   onDeleteAllPhoto: $$.onDeleteAllPhoto,
  // })
}

export interface PhotoBrowserViewLoaderParams {
  pageStatus: boolean,
  hidePhotoBrowser: (isPlayAni: boolean) => void,
  isRunningAnimation: boolean,
  isShowMenu: boolean,
  canPullingUp: boolean,
  isShowThumbSource: boolean,
  isShowImageAnalyzer: boolean,
  reportStartTime: number,
  onDeleteAllPhoto: () => void,
}

@Builder
export function SubScreenPhotoBrowserViewLoader($$: SubScreenPhotoBrowserViewLoaderParams) {
  // SubScreenPhotoBrowserView({
  //   pageStatus: $$.pageStatus,
  //   hidePhotoBrowser: $$.hidePhotoBrowser,
  //   isRunningAnimation: $$.isRunningAnimation,
  //   isShowMenu: $$.isShowMenu,
  //   canPullingUp: $$.canPullingUp,
  //   isShowThumbSource: $$.isShowThumbSource,
  //   isShowImageAnalyzer: $$.isShowImageAnalyzer,
  //   enterCount: $$.enterCount,
  // })
}

export interface SubScreenPhotoBrowserViewLoaderParams {
  pageStatus: boolean,
  hidePhotoBrowser: (isPlayAni: boolean) => void,
  isRunningAnimation: boolean,
  isShowMenu: boolean,
  canPullingUp: boolean,
  isShowThumbSource: boolean,
  isShowImageAnalyzer: boolean,
  enterCount: number,
  onDeleteAllPhoto: () => void,
}