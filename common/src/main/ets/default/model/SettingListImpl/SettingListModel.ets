/**
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

import {CLog} from '../../Utils/CLog'
import AspectRatio from '../../setting/AspectRatio'
import AssistiveGrid from '../../setting/AssistiveGrid'
import Resolution from '../../setting/Resolution'
/**
 * app setting homepage service class
 */
export class SettingListModel {
  constructor() {
  }

  private settingsList = [
    {
      settingTitle: $r('app.string.photo_mode'),
      settingChildren: [{
                          imagePath: $r("app.media.ic_camera_setting_resolution_photo"),
                          settingName: $r('app.string.aspect_ratio'),
                          checkedName: "4:3",
                          settingAlias: AspectRatio.ALIAS,
                          selectType: "radio",
                          radio: [{
                                    "itemValue": "4:3"
                                  },
                                  {
                                    "itemValue": "1:1"
                                  },
                                  {
                                    "itemValue": "16:9"
                                  }]
                        }
      ]
    }, {
      settingTitle: $r('app.string.video_mode'),
      settingChildren: [{
                          imagePath: $r("app.media.ic_camera_setting_resolution_video"),
                          settingName: $r('app.string.video_resolution'),
                          settingAlias: Resolution.ALIAS,
                          checkedName: "[16:9] 720p",
                          selectType: "radio",
                          radio: [{
                                    "itemValue": "[16:9] 4k"
                                  },
                                  {
                                    "itemValue": "[16:9] 1080p"
                                  },
                                  {
                                    "itemValue": "[16:9] 720p"
                                  }]
                        }]
    }, {
      settingTitle: $r('app.string.general'),
      settingChildren: [{
                          imagePath: $r("app.media.ic_camera_setting_resolution_video"),
                          settingName: $r('app.string.assistive_grid'),
                          settingAlias: AssistiveGrid.ALIAS,
                          checkedName: false,
                          selectType: "toggle",
                          toggle: true
                        }, {
                          imagePath: $r("app.media.ic_camera_setting_resolution_video"),
                          settingName: $r('app.string.video_resolution'),
                          settingAlias: Resolution.ALIAS,
                          checkedName: "[16:9] 720p",
                          selectType: "radio",
                          radio: [{
                                    "itemValue": "[16:9] 1080p"
                                  },
                                  {
                                    "itemValue": "[16:9] 720p"
                                  }]
                        }
      ]
    }
  ]

  getSettingList() {
    return this.settingsList;
  }
}

let settingListModel = new SettingListModel();

export default settingListModel as SettingListModel;