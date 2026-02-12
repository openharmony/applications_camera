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

import lazy { initTreasureBoxStateMap } from '../component/treasurebox/reduce/TreasureBoxReducer';
import lazy { treasureBoxReducer } from '../component/treasurebox/reduce/TreasureBoxReducer';
import lazy { contextReducer, initContextStateMap } from './reducers/ContextReducer';
import lazy { initCameraStateMap } from '../camera/uithread/CameraReducer';
import lazy { cameraReducer } from '../camera/uithread/CameraReducer';
import lazy { initPreviewStateMap } from './reducers/PreviewReducer';
import lazy { previewReducer } from './reducers/PreviewReducer';
import lazy { initCaptureStateMap } from '../function/capture/CaptureReducer';
import lazy { captureReducer } from '../function/capture/CaptureReducer';
import lazy { initWindowStateMap } from '../service/window/WindowReducer';
import lazy { windowReducer } from '../service/window/WindowReducer';
import lazy { initModeStateMap } from './reducers/ModeReducer';
import lazy { modeReducer } from './reducers/ModeReducer';
import lazy { initSettingStateMap } from './reducers/SettingReducer';
import lazy { settingReducer } from './reducers/SettingReducer';
import lazy { initRecordStateMap } from '../function/recordcontrol/RecordReducer';
import lazy { recordReducer } from '../function/recordcontrol/RecordReducer';
import lazy { initThumbnailStateMap } from '../component/thumbnail/ThumbnailReducer';
import lazy { thumbnailReducer } from '../component/thumbnail/ThumbnailReducer';
import lazy { initZoomStateMap } from '../function/zoombar/ZoomReducer';
import lazy { zoomReducer } from '../function/zoombar/ZoomReducer';
import lazy { initTabBarStateMap } from '../component/tabbar/TabBarReducer';
import lazy { tabBarReducer } from '../component/tabbar/TabBarReducer';
import lazy { initFunctionStateMap } from '../function/core/FunctionReducer';
import lazy { functionReducer } from '../function/core/FunctionReducer';
import lazy { initSettingViewStateMap } from '../component/settingview/SettingViewReducer';
import lazy { settingViewReducer } from '../component/settingview/SettingViewReducer';
import lazy { initUiStateMap } from './reducers/UIReducer';
import lazy { uiReducer } from './reducers/UIReducer';
import lazy { initSecurityCameraStateMap } from './reducers/securityCameraReducer';
import lazy { securityCameraReducer } from './reducers/securityCameraReducer';
import lazy { focusExposureReducer, initFocusStateMap } from '../component/focusExposure/FocusExposureReducer';
import lazy { collapsReducer, initCollapsStateMap } from '../service/collaps/CollapsReducer';

export class OhCombinedState {
  private mStates: Map<string, Map<string, object | boolean>>;

  constructor() {
    this.mStates = new Map();
    this.mStates.set('contextReducer', initContextStateMap());
    this.mStates.set('cameraReducer', initCameraStateMap());
    this.mStates.set('previewReducer', initPreviewStateMap());
    this.mStates.set('captureReducer', initCaptureStateMap());
    this.mStates.set('recordReducer', initRecordStateMap());
    this.mStates.set('thumbnailReducer', initThumbnailStateMap());
    this.mStates.set('windowReducer', initWindowStateMap());
    this.mStates.set('modeReducer', initModeStateMap());
    this.mStates.set('settingReducer', initSettingStateMap());
    this.mStates.set('zoomReducer', initZoomStateMap());
    this.mStates.set('tabBarReducer', initTabBarStateMap());
    this.mStates.set('treasureBoxReducer', initTreasureBoxStateMap());
    this.mStates.set('settingViewReducer', initSettingViewStateMap());
    this.mStates.set('functionReducer', initFunctionStateMap());
    this.mStates.set('uiReducer', initUiStateMap());
    this.mStates.set('securityCameraReducer', initSecurityCameraStateMap());
    this.mStates.set('collapsReducer', initCollapsStateMap());
    this.mStates.set('focusExposureReducer', initFocusStateMap());
  }

  public setStateMap(reducerName: string, stateMap: Map<string, object>): void {
    if (!this.mStates.has(reducerName)) {
      this.mStates.set(reducerName, stateMap);
    }
  }

  public getStateMap<T>(reducerName: string): T {
    return this.mStates?.get(reducerName) as T;
  }

  public get<T>(reducerName: string, stateKey: string): T {
    return this.mStates?.get(reducerName)?.get(stateKey) as T;
  }
}


export class OhCombinedReducer {
  private mReduces: Set<Function>;

  constructor() {
    this.mReduces = new Set();
    this.mReduces.add(contextReducer);
    this.mReduces.add(cameraReducer);
    this.mReduces.add(previewReducer);
    this.mReduces.add(captureReducer);
    this.mReduces.add(recordReducer);
    this.mReduces.add(thumbnailReducer);
    this.mReduces.add(windowReducer);
    this.mReduces.add(modeReducer);
    this.mReduces.add(settingReducer);
    this.mReduces.add(zoomReducer);
    this.mReduces.add(tabBarReducer);
    this.mReduces.add(treasureBoxReducer);
    this.mReduces.add(settingViewReducer);
    this.mReduces.add(functionReducer);
    this.mReduces.add(uiReducer);
    this.mReduces.add(securityCameraReducer);
    this.mReduces.add(collapsReducer);
    this.mReduces.add(focusExposureReducer);
  }

  public addReducer(reducer: Function): void {
    this.mReduces.add(reducer);
  }

  public getReducers(): Set<Function> {
    return this.mReduces;
  }
}