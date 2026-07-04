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
// import apsManager from '@hms.graphic.apsManager';
import lazy { getStates } from '../redux';
import lazy { HiLog } from './HiLog';

const TAG: string = 'FrameLockScene';
const CAMERA_PREVIEW: string = 'CAMERA_PREVIEW'; // 下发给底层的控帧场景,只能是CAMERA_PREVIEW,应用内场景不让底层感知

export class FrameLockScene {
  private static sInstance: FrameLockScene;
  private mDeliveryState: boolean = false; // 记录下发给底层的任务类型,初进相机默认false与不下发任务效果一致;true代表开启相机控帧任务

  public static getInstance(): FrameLockScene {
    if (!FrameLockScene.sInstance) {
      FrameLockScene.sInstance = new FrameLockScene();
    }
    return FrameLockScene.sInstance;
  }

  public backGroundClearScene(): void {
    if (this.mDeliveryState !== true) {
      HiLog.e(TAG, `backGroundClearScene ret: ${this.mDeliveryState}.`);
      return;
    }
    this.setScene(false);
  }

  public apsSetScene(sceneName: string, sceneState: boolean): void {
    if (!getStates().get<boolean>('contextReducer', 'isForeground')) {
      HiLog.e(TAG, `apsSetScene isBackground true ret: ${sceneName}, ${sceneState}.`);
      return; // 应用在后台不再重进任务,仅BackGround时机下发
    }
    let lockSceneName: string = this.getCameraSceneName(sceneName); // 中间层用于防护多场景交错解冲突后任务下发
    let isShowSettingView: boolean = getStates().get<boolean>('settingViewReducer', 'isShowSettingView');
    let isOpenTreasureBox: boolean = getStates().get<boolean>('treasureBoxReducer', 'isOpen');
    let isShowPhotoBrowser: boolean = AppStorage.get<boolean>('isShowPhotoBrowser');
    HiLog.d(TAG, `setApsScene${sceneName},${sceneState}-${isShowSettingView},${isOpenTreasureBox},${isShowPhotoBrowser}|${this.mDeliveryState}.`);

    // 解冲突规则: PREVIEW以下发状态为准,other自身以下发为准其它以实际查询状态为准
    if (lockSceneName === CAMERA_PREVIEW && sceneState && !this.mDeliveryState &&
      (isShowSettingView || isOpenTreasureBox || isShowPhotoBrowser)) {
      return; // 因3个场景,不去下发控帧,sceneState && !this.mDeliveryState
    } // 去重在底层控制,sceneState && this.mDeliveryState
    if (lockSceneName === CAMERA_PREVIEW && !sceneState && this.mDeliveryState &&
      (!isShowSettingView && !isOpenTreasureBox && !isShowPhotoBrowser)) {
      return; // 因非3个场景,不去解除控帧,!sceneState && this.mDeliveryState
    } // 去重在底层控制,!sceneState && !this.mDeliveryState
    if (this.getIsInterruptDelivery(lockSceneName, sceneState, isShowSettingView, isOpenTreasureBox,
      isShowPhotoBrowser)) {
      return;
    }

    let lockSceneState: boolean = lockSceneName === CAMERA_PREVIEW ? sceneState : !sceneState;
    HiLog.d(TAG, `setApsScene start: ${lockSceneName}, ${lockSceneState}.`);
    this.setScene(lockSceneState);
  }

  private getIsInterruptDelivery(lockSceneName: string, sceneState: boolean, isShowSettingView: boolean,
    isOpenTreasureBox: boolean, isShowPhotoBrowser: boolean): boolean {

    if (lockSceneName === 'CAMERA_SETTING_VIEW' && !sceneState && !this.mDeliveryState &&
      (isOpenTreasureBox || isShowPhotoBrowser)) {
      return true; // 因2个场景,不去下发控帧,!sceneState && !this.mDeliveryState
    } // 去重在底层控制,!sceneState && this.mDeliveryState
    // 不return,需要去解除控帧,sceneState && this.mDeliveryState && (!isOpenTreasureBox && !isShowPhotoBrowser)
    // 去重在底层控制,sceneState && !this.mDeliveryState

    if (lockSceneName === 'CAMERA_TREASURE_BOX' && !sceneState && !this.mDeliveryState &&
      (isShowSettingView || isShowPhotoBrowser)) {
      return true; // 因2个场景,不去下发控帧,!sceneState && !this.mDeliveryState
    } // 去重在底层控制,!sceneState && this.mDeliveryState
    // 不return,需要去解除控帧,sceneState && this.mDeliveryState && (!isShowSettingView && !isShowPhotoBrowser)
    // 去重在底层控制,sceneState && !this.mDeliveryState

    if (lockSceneName === 'CAMERA_PHOTO_BROWSER' && !sceneState && !this.mDeliveryState &&
      (isShowSettingView || isOpenTreasureBox)) {
      return true; // 因2个场景,不去下发控帧,!sceneState && !this.mDeliveryState
    } // 去重在底层控制,!sceneState && this.mDeliveryState
    // 不return,需要去解除控帧,sceneState && this.mDeliveryState && (!isShowSettingView && !isOpenTreasureBox)
    // 去重在底层控制,sceneState && !this.mDeliveryState

    return false;
  }

  private setScene(lockSceneState: boolean): void {
    if (this.mDeliveryState === lockSceneState) {
      HiLog.i(TAG, `setScene isSameState true ret: ${lockSceneState}.`);
      return; // 最底层仅防护相同任务重复下发
    }
    try {
      HiLog.i(TAG, `setScene start: ${CAMERA_PREVIEW}, ${lockSceneState}.`);
      // apsManager?.setScene('com.ohos.camera', CAMERA_PREVIEW as never, lockSceneState ? 1 : 0); // 1进入控帧,0退出
      this.mDeliveryState = lockSceneState;
    } catch (error) {
      HiLog.e(TAG, `setScene error: ${error}.`);
    }
  }

  private getCameraSceneName(sceneName: string): string {
    switch (sceneName) {
      case 'PreviewArea':
      case 'PreviewAreaLand':
      case 'CAMERA_PREVIEW':
        return 'CAMERA_PREVIEW'; // 进入相机应用开启控帧
      case 'SettingView':
        return 'CAMERA_SETTING_VIEW'; // 相机内部状态,进入页面需解除控帧
      case 'TreasureBox':
        return 'CAMERA_TREASURE_BOX';
      case 'PhotoBrowser':
      case 'PhotoBrowserLand':
        return 'CAMERA_PHOTO_BROWSER';
      default:
        return '';
    }
  }
}