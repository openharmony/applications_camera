/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';

import { Log } from '@ohos/common/src/main/ets/default/utils/Log';

const TAG: string = '[FormAbility]';

export default class FormAbility extends FormExtensionAbility {
  onCreate(want) {
    Log.info(`${TAG} form onCreate. want ${JSON.stringify(want)}`);
    return null;
  }

  onCastToNormal(formId): void {
    Log.info(`${TAG} onCastToNormal, formId: ${formId}`);
  }

  onUpdate(formId): void {
    Log.info(`${TAG} onUpdate, formId: ${formId}`);
  }

  onVisibilityChange(newStatus): void {
    Log.info(`${TAG} onVisibilityChange, newStatus: ${JSON.stringify(newStatus)}`);
  }

  onEvent(formId, message): void {
    Log.info(`${TAG} onEventA, formId: ${formId}, msg: ${message}`);
  }

  onDestroy() {
    Log.info(`${TAG} onDestroy`);
  }
};