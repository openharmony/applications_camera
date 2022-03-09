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

import router from '@system.router';
import { CameraService } from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets'

function terminateSelfWithResult(getBundleName, getAbilityName, photoUri) {
  console.info("terminateSelfWithResult start")
  let abilityResult = {
    "resultCode": 200,
    "want": {
      "parameters": {
        "imagePath": photoUri
      },
      "bundleName": getBundleName,
      "abilityName": getAbilityName
      }
  };
}

@Entry
@Component
struct ThirdPreviewView {
  private getBundleName: string;
  private getAbilityName: string;
  public cameraService = CameraService.getInstance()
  @State photoUri: any = this.cameraService.getPhotoUri()

  aboutToAppear() {
    this.getBundleName = globalThis.cameraAbilityWant.bundleName
    this.getAbilityName = globalThis.cameraAbilityWant.abilityName
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }){
        Column() {
          Flex({
            direction: FlexDirection.Row,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceBetween
          }) {
            Image($r('app.media.ic_system_cancel'))
              .width(24)
              .aspectRatio(1)
              .onClick(() => {
                router.back()
              })
            Image($r('app.media.ic_system_confirm'))
              .width(24)
              .aspectRatio(1)
              .onClick(() => {
                terminateSelfWithResult(this.getBundleName, this.getAbilityName, this.photoUri)
              })
          }
        }
        .width('100%')
          .height(48)
          .margin({ top: '24vp' })
          .padding({ top: '12vp', left: '24vp', right: '24vp' })

        Column() {
          Image(this.photoUri)
            .width('100%')
            .height('100%')
        }
        .margin({ top: '100vp' })
          .width('100%')
          .height(400)
            }
      .width('100%')
        .height('100%')
    }
    .width('100%')
      .height('100%')
      .backgroundColor('#000')
  }
}