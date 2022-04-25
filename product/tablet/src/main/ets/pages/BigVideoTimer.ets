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

import display from '@ohos.display';

@Component
export struct BigVideoTimer {
  @State bigVideoTime: number = 1
  @State spotVisibility: boolean = true
  @State timer: number = 0
  @State timeNumber: number = 0
  @Link isSmallVideoTimerVisible: boolean
  @Link isBigVideoTimerVisible: boolean
  @Link @Watch("watchIsResumeVideo") isResumeVideo: boolean
  @Link @Watch("watchIscContinueVideo") iscContinueVideo: boolean
  @State timerPosition: number= 0

  private aboutToAppear() {
    this.setIntervalBigVideoTime()
    display.getDefaultDisplay().then((dis) => {
      this.timerPosition = px2vp(dis.height ) * (4 / 3)
    })
  }

  setIntervalBigVideoTime() {
    clearInterval(this.timer)
    this.timer = setInterval(() => {
      this.timeNumber++
      if (this.timeNumber % 2 === 0) {
        if (this.bigVideoTime <= 2) {
          this.bigVideoTime++
        }
        if (this.bigVideoTime > 2) {
          clearInterval(this.timer)
          this.isSmallVideoTimerVisible = true
          this.isBigVideoTimerVisible = false
        }
      }
      this.spotVisibility = !this.spotVisibility
    }, 500)
  }

  watchIsResumeVideo() {
    if(this.isResumeVideo){
      clearInterval(this.timer)
    }
  }

  watchIscContinueVideo() {
    if(this.iscContinueVideo && this.bigVideoTime<= 2){
      this.setIntervalBigVideoTime()
    }
  }

  private aboutToDisappear() {
    clearInterval(this.timer)
  }

  build() {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Text('').layoutWeight(1)
          if(this.isResumeVideo){
            Image($r('app.media.ic_video_recording'))
              .width(12)
              .height(12)
              .fillColor(Color.White)
            }else{
            if (this.spotVisibility) {
              Column() {
              }
              .width(12)
              .height(12)
              .backgroundColor('#FF0000')
              .borderRadius(6)
              .visibility(Visibility.Visible)
            } else {
              Column() {
              }
              .width(12)
              .height(12)
              .backgroundColor('#FF0000')
              .borderRadius(6)
              .visibility(Visibility.Hidden)
            }
          }
          Text(`00:0${this.bigVideoTime}`)
            .margin({ left: 8, right: 8 })
            .fontSize('50fp')
            .fontWeight(FontWeight.Lighter)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
          Text('').width(12).height(12)
          Text('').layoutWeight(1)
        }
      .width(this.timerPosition)
      .height(96)
  }
}