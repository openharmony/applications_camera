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
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';

/* instrument ignore file */
const ICON_SIZE_DEFAULT = 14;

export const STRING_PLACE_HOLDER = '%s';

@Component
export struct PictureStringMixText {
  private controller: TextController = new TextController();
  @Prop @Watch('onContentChange') contentString: string | Resource = '';
  @Prop @Watch('onContentChange') imageSrc: ResourceStr = '';
  @State iconSize: number = ICON_SIZE_DEFAULT;
  @State isBlack: boolean = false;
  @State fontColor: Color = Color.White;
  @State textPadding: Padding = {}
  @State fontSize: number | Resource = 12;
  @State isPictureStart: boolean = true;
  @State textAlign: TextAlign = TextAlign.Start;

  aboutToAppear() {
    this.onContentChange()
  }

  private onContentChange() {
    if (this.contentString === null || this.contentString === undefined) {
      return;
    }

    let tempString: string =
      (typeof (this.contentString) === 'string') ? this.contentString : ResGetter.getStringSafe(this.contentString);
    if (tempString === null || tempString === undefined) {
      return;
    }
    let str: MutableStyledString = new MutableStyledString(tempString)
    if (this.imageSrc !== undefined && this.imageSrc !== '') {
      let placeHolderIndex = tempString.indexOf(STRING_PLACE_HOLDER);
      let op: ResourceImageAttachmentOptions = {
        resourceValue: this.imageSrc,
        size: { width: this.iconSize, height: this.iconSize },
        objectFit: ImageFit.Contain,
        verticalAlign: ImageSpanAlignment.CENTER,
        layoutStyle: {
          padding: {
            top: 0,
            bottom: 0,
            left: 0,
            right: 0
          }
        }
      }

      if (placeHolderIndex < 0) {
        //当字符串中没有占位符，且有图标时,根据isPictureStart将图标放到字符串首或尾
        str.insertStyledString((this.isPictureStart || tempString.length === 0) ? 0 :
          tempString.length - 1, new StyledString(new ImageAttachment(op)))
      } else {
        str.replaceStyledString(placeHolderIndex, STRING_PLACE_HOLDER.length,
          new StyledString(new ImageAttachment(op)));
      }
    }
    this.controller.setStyledString(str)
  }

  build() {
    Text(undefined, { controller: this.controller })
      .fontSize(this.fontSize)
      .maxFontScale(CommonConstants.TEXT_SIZE_HUGE)
      .fontColor(this.fontColor)
      .textAlign(this.textAlign)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding(this.textPadding)
      .fontFeature('\"ss01\" on')
  }
}