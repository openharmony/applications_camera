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

//import ability_featureAbility from '@ohos.ability.featureAbility';

//import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import GetPixelMap from '../../../../../../../../../common/src/main/ets/default/Camera/GetPixelMap'
import {ThumbnailController} from './ThumbnailController'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import {EventBus} from '../../../../../../../../../common/src/main/ets/default/Utils/EventBus.ets'
import EventBusManager from '../../../../../../../../../common/src/main/ets/default/Utils/EventBusManager.ets'

let localState = (state) => {
  return {
    thumbnail: state.CameraInitReducer.thumbnail,
    thumbnailScale: state.UiReducer.thumbnailScale,
    thumbnailOpacity: state.UiReducer.thumbnailOpacity,
  }
}

let localDispatcher = (dispatch) => {
  return {}
}

@Component
export struct ThumbnailView {
  private TAG: string = '[ThumbnailView]:'
  private mConnect: any
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private thumbnailBorder: Object = {}

  @State state: any = {}

  private async onThumbnailUpdate(data) {
    CLog.info(`${this.TAG} onThumbnailUpdate data: ${JSON.stringify(data)} E`)
    this.state.thumbnail = data.thumbnail
    this.thumbnailBorder = { width: 1, color: Color.White, style: BorderStyle.Solid }
    CLog.info(`${this.TAG} onThumbnailUpdate this.state.thumbnail: ${JSON.stringify(this.state.thumbnail)} X`)
  }

  private aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Column() {
      Stack() {
        Image(this.state.thumbnail)
          .width('100%').aspectRatio(1).borderRadius(20).objectFit(ImageFit.Fill)
      }
      .width('100%').height('100%')
      .onClick(async () => {
        CLog.info(`${this.TAG} launch bundle com.ohos.photos`)
        await globalThis.cameraAbilityContext.startAbility({
          parameters: { uri: 'photodetail' },
          bundleName: 'com.ohos.photos',
          abilityName: 'com.ohos.photos.MainAbility'
        })
      })
    }
    .width(44).aspectRatio(1)
    .borderRadius(20).border(this.thumbnailBorder)
    .opacity(this.state.thumbnailOpacity)
    .scale({ x: this.state.thumbnailScale, y: this.state.thumbnailScale })
  }
}