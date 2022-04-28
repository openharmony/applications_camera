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
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'

@Component
export struct AssistiveGridView {
  private TAG: string = '[AssistiveGridView]:'
  @Link XcomponentWidth: string;
  @Link XcomponentHeight: string;
  @Link aspectRatio: number;
  @State lineMarginTop: number = 0
  @State lineMarginLeft: number = 0
  @State Number: String[] = ['0', '1', '2']
  @Link displayInfo: Promise<number>

  public aboutToAppear() {
    CLog.log(this.TAG + " XcomponentWidth" + this.XcomponentWidth+ " XcomponentHeight" + this.XcomponentHeight)
    //横竖屏判断
    CLog.log(this.TAG + " displayInfo:" + JSON.stringify(displayInfo))

    this.lineMarginLeft = Number(this.XcomponentHeight.split('px')[0]) / 3
    this.lineMarginTop = Number(this.XcomponentWidth.split('px')[0]) / 3

    CLog.log(this.TAG + " lineMarginTop" + this.lineMarginTop+ " lineMarginLeft" + this.lineMarginLeft)
  }

  build() {

        Row({ space: 5 }) {
          Grid() {
            ForEach(this.Number, (item: string) => {
              ForEach(this.Number, (item: string) => {
                GridItem() {
                  Text('')
                    .borderWidth(1)
                    .width('100%')
                    .height('100%')
                    .borderColor(Color.White)
                }.opacity(0.5)
              }, item => item)
            }, item => item)
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr')
        }
  }
}