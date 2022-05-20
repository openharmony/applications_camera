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

import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import GetPixelMap from '../../../../../../../../../common/src/main/ets/default/Camera/GetPixelMap'
import {ThumbnailController} from './ThumbnailController'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import {EventBus} from '../../../../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import router from '@system.router'

let localState = (state) => {
  return {
    thumbnail: state.CameraInitReducer.thumbnail,
    videoUri: state.CameraInitReducer.videoUri,
    mode: state.ModeReducer.mode,
    resourceUri: state.CameraInitReducer.resourceUri,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    xComponentWidth: state.PreviewReducer.xComponentWidth,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
    scaleValue: 1,
    tempOpacity: 1
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
  @State hasThumbnail: boolean = false

  private async onThumbnailUpdate(data) {
    CLog.info(`${this.TAG} onThumbnailUpdate data: ${JSON.stringify(data)} E`)
    this.state.thumbnail = data.thumbnail
    this.hasThumbnail = data.thumbnail == null ? false : true
    this.state.scaleValue = 1.5
    this.state.tempOpacity = 0.0
    animateTo({ duration: 100, curve: Curve.Sharp }, () => {
      this.state.tempOpacity = 1
    })
    animateTo({ duration: 300, curve: Curve.Sharp }, () => {
      this.state.scaleValue = 1
    })
    CLog.info(`${this.TAG} onThumbnailUpdate resourceUri= ${JSON.stringify(this.state.resourceUri)} E`)
    CLog.info(`${this.TAG} onThumbnailUpdate isThirdPartyCall= ${this.state.isThirdPartyCall} E`)
    CLog.info(`${this.TAG} onThumbnailUpdate videoUri= ${this.state.videoUri} E`)
    if (this.state.isThirdPartyCall) {
      CLog.info(`${this.TAG} onThumbnailUpdate start router to ThirdPreviewView`)
      router.push({
        uri: "pages/ThirdPreviewView",
        params: {
          width: this.state.xComponentWidth,
          height: this.state.xComponentHeight,
          mode: this.state.mode,
          uri: this.state.resourceUri,
          videoUri: this.state.videoUri
        }
      })
    }
    CLog.info(`${this.TAG} onThumbnailUpdate this.state.thumbnail: ${JSON.stringify(this.state.thumbnail)} X`)
  }

  private async onThumbnailLoad(data) {
    CLog.info(`${this.TAG} onThumbnailLoad data: ${JSON.stringify(data)} E`)
    this.state.thumbnail = data.thumbnail
    this.thumbnailBorder = { width: 1, color: Color.White, style: BorderStyle.Solid }
    CLog.info(`${this.TAG} onThumbnailLoad this.state.thumbnail: ${JSON.stringify(this.state.thumbnail)} X`)
  }

  private aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    this.appEventBus.on(Action.ACTION_LOAD_THUMBNAIL, this.onThumbnailLoad.bind(this))
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_UPDATE_THUMBNAIL, this.onThumbnailUpdate.bind(this))
    this.appEventBus.off(Action.ACTION_LOAD_THUMBNAIL, this.onThumbnailLoad.bind(this))
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Column() {
      Stack() {
        Image(this.state.thumbnail)
          .width('100%').aspectRatio(1).borderRadius(22).objectFit(ImageFit.Fill)
      }
      .width(44).height(44)
      .enabled(this.hasThumbnail)
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
    .opacity(this.state.tempOpacity)
    .scale({ x: this.state.scaleValue, y: this.state.scaleValue })
  }
}