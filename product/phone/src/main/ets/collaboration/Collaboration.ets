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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';

const TAG: string = 'Collaboration';
const TIP_DURING = 3000;
const collaborationOff: string = 'app.media.ic_camera_collaboration_off';
const collaborationOn: string = 'app.media.ic_camera_collaboration_on';

@Component
export struct Collaboration {
  @State @Watch('updateCollaborate') collaborateStatus: string = 'off';
  private collaborateStatusOff: string = 'off';
  private collaborateStatusOn: string = 'on';

  aboutToAppear() {
    HiLog.i(TAG, `init page collaborateStatus = ${this.collaborateStatus}`);
  }

  build() {
    if (this.collaborateStatus === this.collaborateStatusOn) {
      Row() {
        Image($r(collaborationOn))
          .width(24)
          .height(24)
      }
      .onClick((): void => {
        this.collaborateStatusChange();
      })
    } else {
      Row() {
        Image($r(collaborationOff))
          .width(24)
          .height(24)
      }
      .onClick((): void => {
        this.collaborateStatusChange();
      })
    }
  }

  private collaborateStatusChange(): void {
    let collaborateTipKey = 'app.string.collaborate_status_off';
    if (this.collaborateStatus === this.collaborateStatusOff) {
      this.collaborateStatus = this.collaborateStatusOn;
      collaborateTipKey = 'app.string.collaborate_status_on';
    } else {
      this.collaborateStatus = this.collaborateStatusOff;
    }
    HiLog.i(TAG, `collaborateStatusChange:  ${this.collaborateStatus}`);
    TipService.getInstance().showTip($r(collaborateTipKey), TIP_DURING);
  }

  private updateCollaborate(): void {
    HiLog.i(TAG, `collaborateStatusChange:  ${this.collaborateStatus}`);
    if (this.collaborateStatus === this.collaborateStatusOn) {
      // 处理外屏逻辑
      HiLog.d(TAG, 'updateCollaborate:  进入打开外屏逻辑...');
    } else {
      HiLog.d(TAG, 'updateCollaborate:  进入关闭外屏逻辑...');
    }
  }
}