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
import display from '@ohos.display';
import featureAbility from '@ohos.ability.featureAbility';
import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets';

function terminateSelfWithResult(getBundleName, getAbilityName) {
  console.info("terminateSelfWithResult start")
  let abilityResult = {
    "resultCode": 200,
    "want": {
      "parameters": {
        "imagePath": this.cameraService.SaveCameraAsset.getPhotoUri()
      },
      "bundleName": getBundleName,
      "abilityName": getAbilityName
    }
  };
  featureAbility.terminateSelfWithResult(abilityResult, (error, data) => {
    if (error) {
      console.error(`Operation failed. Cause: ${error}`);
      return;
    }
    console.info(`Operation succeeded: ${data}`);
  });
}

@Entry
@Component
struct ThirdPreviewView {
  @State marginTop: string = '';
  @State captureSrc: string = '../../../resources/base/media/flash_on.svg';
  private getBundleName: string;
  private getAbilityName: string;
  public cameraService = CameraService.getInstance()

  aboutToAppear() {
    display.getDefaultDisplay().then((dis) => {
      this.marginTop = (dis.height - dis.width / 0.75) / 2 / dis.height * 100 + '%';
    });
    featureAbility.getWant().then((want) => {
      this.getBundleName = want.parameters.paramBundleName;
      this.getAbilityName = `${want.parameters.paramBundleName}.MainAbility`;
    })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween
        }) {
          Image($r('app.media.ic_system_cancel'))
            .width('8.33%')
            .aspectRatio(1)
            .onClick(() => {
              router.push({
                uri: 'pages/index',
              });
            })
          Image($r('app.media.ic_system_confirm'))
            .width('8.33%')
            .aspectRatio(1)
            .onClick(() => {
              terminateSelfWithResult(this.getBundleName, this.getAbilityName)
            })
        }
      }
      .width('100%')
      .height('6.73%')
      .margin({ top: '3.85%' })
      .padding({ left: '6.67%', right: '6.67%' })

      Column() {
        Text('三方相机拍照内容')
          .fontColor('#fff')
          .fontSize(40)
        Image(this.captureSrc)
          .width('100%')
          .height('100%')
      }
      .margin({ top: this.marginTop })
      .width('100%')
      .aspectRatio(1)
      .backgroundColor('#0ff')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000')
  }
}