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

import {ThumbnailController} from './ThumbnailController.ets'
import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import GetPixelMap from '../../../../../../../../../common/src/main/ets/default/Camera/GetPixelMap'

@Component
export struct ThumbnailView {
  @State thumbnail: string = ''
  @State useThumbnail: boolean = false
  @State tempBorder: Object = { width: 2, color: 0xffffff, style: BorderStyle.Solid }
  private defaultIcon: Resource = $r("app.media.ic_camera_thumbnail_default_white")
  private cameraService = CameraService.getInstance()
  getPixelMap = new GetPixelMap()
  thumbnailController = new ThumbnailController()
  @State scaleValue: number = 1
  @State tempScaleX: number= 1;
  @State tempScaleY: number= 1;
  @State tempOpacity: number= 1;
  @State @Watch("thumbnailUpdate") isThumbnail: boolean = false

  aboutToAppear() {
    this.cameraService.getThumbnail((thumbnail) => {
      if (thumbnail != '' && thumbnail != undefined) {
        this.useThumbnail = true
        this.thumbnail = thumbnail
        this.isThumbnail = !this.isThumbnail
        console.info("ThumbnailView update thumbnail: " + this.thumbnail)
      } else {
        this.useThumbnail = false
        this.tempBorder = {};
        console.info("ThumbnailView update thumbnail fail: " + this.thumbnail)
      }
    })

    this.thumbnailController.getParam()
  }

  public thumbnailUpdate() {

    this.scaleValue = 1.5
    this.tempOpacity = 0.0
    animateTo({ duration: 100, curve: Curve.Sharp }, () => {
      this.tempOpacity = 1
    })
    animateTo({ duration: 300, curve: Curve.Sharp }, () => {
      this.scaleValue = 1
    })
  }

  build() {
    Column() {
      Stack() {
        Image(this.useThumbnail ? this.thumbnail : this.defaultIcon)
          .width('100%')
          .aspectRatio(1)
          .borderRadius(20)
          .objectFit(ImageFit.Fill)
      }
      .onClick(async () => {
        console.log('startAbility start')
        await globalThis.cameraAbilityContext.startAbility({
          parameters: {uri: 'photodetail'},
          bundleName: "com.ohos.photos",
          abilityName: "com.ohos.photos.MainAbility",
        })
      })
      .width('100%')
      .height('100%')
    }
    .borderRadius(20)
    .border(this.tempBorder)
    .opacity(this.tempOpacity)
    .width(40)
    .aspectRatio(1)
    .scale({ x: this.scaleValue, y: this.scaleValue })
  }
}