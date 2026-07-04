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
import lazy { PersistType, PreferencesService } from '../service/preferences/PreferencesService';
import lazy { ModeType } from './ModeType';
import lazy { camera } from '@kit.CameraKit';
import lazy { PropTag } from '../service/preferences/PropTag';
import lazy { ZoomOperation } from '../function/zoombar/ZoomOperation';
import lazy { CameraAction } from '../camera/uithread/CameraAction';
import lazy { Action } from '../redux/actions/Action';
import lazy { WindowAction } from '../service/window/WindowAction';
import lazy { execDispatch } from '../redux';

const TAG = 'ModePosWarmStartUtil';

/**
 * TODO:一般热启动仅能以退出相机时的模式和镜头启动相机，此热启动可以提供热启动的模式和镜头
 * 0、历史背景：模式界面不匹配、先changeMode后warmStart二次起流（如两者拼凑处理此问题）
 * 1、启动起流和切换类起流不同（切换类会释放session），无法在此场景用SwitchCameraAndChangeMode流程活changeMode，（导致黑屏闪退）
 * 2、ui层交互用WARM_START_WITH_MODE_AND_POS装载特性、变更缓存、redux状态
 * 3、ui界面刷新用changeMode，刷新对应模式的ui界面（如果WARM_START_WITH_MODE_AND_POS事件绑定刷新ui界面，添加文件过多，后续功能新增不可控）
 * 4、work起流拿到传递的mode pos走热启动流程
 * */
export class ModePosWarmStartUtil {

  static startWithParams(preMode: ModeType, newMode: ModeType, cameraPos?: camera.CameraPosition): void {
    if (!!cameraPos) {
      PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, cameraPos);
    }
    if (!!newMode) {
      PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, PropTag.MODE, newMode);
    }
    execDispatch(CameraAction.warmStartWithModeAPos(newMode, cameraPos)); // 1、触发新模式的起流流程；2、Redux中state状态
    execDispatch(CameraAction.changeMode(newMode, true)); // 复用changeMode：1、刷新ui（先变状态后刷ui）；2、变更模式缓存
    execDispatch(WindowAction.refresh()); // 变更完缓存模式需要刷新对应size
    ZoomOperation.getInstance().setRemainZoomRatio(false);
    AppStorage.setOrCreate('startOrUserChangeToModeLast', [preMode, newMode]);
    execDispatch(Action.updateXComponentShot(preMode, newMode, false)); // 更新预览尺寸
  }
}