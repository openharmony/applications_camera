/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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

import mediaLibrary from '@ohos.multimedia.mediaLibrary';

import {AsyncManager} from '../../../../../common/src/main/ets/default/Utils/AsyncManager'
import {CameraPlatformCapability} from '../../../../../common/src/main/ets/default/Camera/CameraPlatformCapability'
import {CameraService} from '../../../../../common/src/main/ets/default/Camera/CameraService'
import {CLog} from '../../../../../common/src/main/ets/default/Utils/CLog'

const TAG: string = '[app]:'
//let cameraService = CameraService.getInstance()

export default {
  onCreate() {
    CLog.info(`${TAG} Application onCreate`)
    this.subscribe()
    // 创建后台线程
  },

  onDestroy() {
    CLog.info(`${TAG} Application onDestroy`)
    this.unsubscribe()
  },

  async subscribe() {
    // TODO 调用一下否则worker 线程调用失败
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_IMAGE);
    publicPath = `${publicPath}Camera/`
    CLog.info(`${TAG} publicPath = ${publicPath}`)
    await CameraService.getInstance().initCamera()
    // todo 订阅PA PermissionGrantResultAbility
  },

  async unsubscribe() {
    // todo 取消订阅PA
  }
}