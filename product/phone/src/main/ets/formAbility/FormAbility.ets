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

import formInfo from '@ohos.app.form.formInfo';
import formBindingData from '@ohos.app.form.formBindingData';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import Want from '@ohos.app.ability.Want';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';

/* instrument ignore file */
const TAG: string = 'FormAbility';

export default class FormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    HiLog.i(TAG, 'FormAbility onAddForm');
    let formData = '';
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    HiLog.i(TAG, 'FormAbility onCastToNormalForm formId=' + formId);
  }

  onUpdateForm(formId: string) {
    HiLog.i(TAG, 'FormAbility onUpdateForm');
  }

  onChangeFormVisibility(newStatus: Record<string, number>) {
    HiLog.i(TAG, 'FormAbility onChangeFormVisibility');
  }

  onFormEvent(formId: string, message: string) {
    HiLog.i(TAG, 'FormAbility onFormEvent');
  }

  onRemoveForm(formId: string) {
    HiLog.i(TAG, 'FormAbility onRemoveForm');
  }

  onAcquireFormState(want: Want) {
    HiLog.i(TAG, 'FormAbility onAcquireFormState');
    return formInfo.FormState.READY;
  }
};