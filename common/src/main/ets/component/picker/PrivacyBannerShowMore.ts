
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

import permissionManagement from '@hms.security.permissionManagement';
import type common from '@ohos.app.ability.common';
import lazy { HiLog } from '../../utils/HiLog';

const TAG: string = 'PrivacyBannerShowMore';

export function showMoreInfoDialog(context: common.Context): void { // 1进入,0退出
  HiLog.i(TAG, 'picker showMoreInfoDialog');
  try {
    // @ts-ignore
    permissionManagement.showMoreInfoDialog(context,
      // @ts-ignore
      permissionManagement.MoreInfoDialogType.CAMERA_PICKER);
  } catch (err) {
    HiLog.e(TAG, `try to start picker failed ${JSON.stringify(err?.message)}}`);
  }
}