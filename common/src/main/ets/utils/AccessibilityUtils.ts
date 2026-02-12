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

import lazy { accessibility } from '@kit.AccessibilityKit';
import lazy { HiLog } from './HiLog';
import lazy { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'AccessibilityUtil';

// 无障碍事件上报接口
/* instrument ignore file */
export class AccessibilityUtils {
  /**
   * 主动聚焦
   * @param elementId： 要聚焦的组件id
   */
  static sendFocusAccessibilityEvent(elementId: string): void {
    if (elementId === '') {
      return;
    }
    let eventInfo: accessibility.EventInfo = {
      type: 'requestFocusForAccessibility',
      bundleName: 'com.ohos.cameraa',
      triggerAction: 'common',
      customId: elementId,
    };
    HiLog.d(TAG, 'elementId: ' + elementId);
    accessibility.sendAccessibilityEvent(eventInfo).then(() => {
      HiLog.d(TAG, `Succeeded in send event ${elementId}`);
    }).catch((err: BusinessError) => {
      HiLog.e(TAG, `Failed to send event ${err?.code}`);
    });
  }

  /**
   * 主动播报
   * @param content： 要播报的内容
   */
  static sendAnnounceAccessibilityEvent(content: string): void {
    let eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.camera',
      triggerAction: 'common',
      textAnnouncedForAccessibility: content,
    };
    HiLog.d(TAG, 'accessibilityContent: ' + content);
    accessibility.sendAccessibilityEvent(eventInfo).then(() => {
      HiLog.d(TAG, `Succeeded in send event ${content}`);
    }).catch((err: BusinessError) => {
      HiLog.e(TAG, `Failed to send event ${err?.code}`);
    });
  }
}