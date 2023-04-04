/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import router from '@system.router'

import { Log } from '../../utils/Log'
import { ThumbnailController } from './ThumbnailController'
import { getStore } from '../../redux/store'
import { Action } from '../../redux/actions/Action'
import { EventBus } from '../../worker/eventbus/EventBus'
import { EventBusManager } from '../../worker/eventbus/EventBusManager'
import EventLog from '../../utils/EventLog'

let localState = (state) => {
  return {
    thumbnail: state.CameraInitReducer.thumbnail,
  }
}

let localDispatcher = (dispatch) => {
  return {}
}

class StateStruct {
  thumbnail
}

@Component
export struct ThumbnailView {
  private TAG: string = '[ThumbnailView]:'
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State thumbnailBorder: Object = {}

  @State state: StateStruct = new StateStruct()
  @State thumbnail: Resource = $r('app.media.ic_camera_thumbnail_default_white')
  @State hasThumbnail: boolean = false
  @State scaleValue: number = 1
  @State tempOpacity: number = 1

  private async onThumbnailUpdate(data) {
    Log.info(`${this.TAG} onThumbnailUpdate data: ${JSON.stringify(data)} E`)
    this.thumbnail = (data.thumbnail == null ? $r('app.media.ic_camera_thumbnail_default_white') : data.thumbnail)
    this.hasThumbnail = data.thumbnail != undefined
    if (this.hasThumbnail) {
      this.thumbnailBorder = { width: 1, color: Color.White, style: BorderStyle.Solid }
    } else {
      this.thumbnailBorder = { width: 0 }
    }
    this.scaleValue = 1.5
    this.tempOpacity = 0.0
    animateTo({ duration: 100, curve: Curve.Sharp }, () => {
      this.tempOpacity = 1
    })
    animateTo({ duration: 300, curve: Curve.Sharp }, () => {
      this.scaleValue = 1
    })
    Log.info(`${this.TAG} onThumbnailUpdate this.state.thumbnail: ${JSON.stringify(this.thumbnail)} X`)
  }

  private async onThumbnailLoad(data) {
    Log.info(`${this.TAG} onThumbnailLoad data: ${JSON.stringify(data)} E`)
    this.thumbnail = (data.thumbnail == null ? $r('app.media.ic_camera_thumbnail_default_white') : data.thumbnail)
    this.hasThumbnail = data.thumbnail != undefined
    if (this.hasThumbnail) {
      this.thumbnailBorder = { width: 1, color: Color.White, style: BorderStyle.Solid }
    } else {
      this.thumbnailBorder = { width: 0 }
    }
    this.scaleValue = 1
    this.tempOpacity = 1
    Log.info(`${this.TAG} onThumbnailLoad this.state.thumbnail: ${JSON.stringify(this.thumbnail)} X`)
  }

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    this.appEventBus.on(Action.ACTION_LOAD_THUMBNAIL, this.onThumbnailLoad.bind(this))
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    this.appEventBus.off(Action.ACTION_LOAD_THUMBNAIL, this.onThumbnailLoad.bind(this))
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Column() {
      Stack() {
        Image(this.thumbnail)
          .width('100%').aspectRatio(1).borderRadius(22).objectFit(ImageFit.Fill)
      }
      .width('100%').height('100%')
      .enabled(this.hasThumbnail)
      .onClick(async () => {
        Log.info(`${this.TAG} launch bundle com.ohos.photos`)
        EventLog.write(EventLog.CLICK_THUMBNAIL)
        globalThis.keepCameraZoomRatio = true
        await globalThis.cameraAbilityContext.startAbility({
          parameters: { uri: 'photodetail' },
          bundleName: 'com.ohos.photos',
          abilityName: 'com.ohos.photos.MainAbility'
        })
      })
    }
    .width(44).aspectRatio(1)
    .borderRadius(22).border(this.thumbnailBorder)
    .opacity(this.tempOpacity)
    .scale({ x: this.scaleValue, y: this.scaleValue })
  }
}