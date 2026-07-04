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
import type { ActionData } from '../../redux/actions/Action';
import type { FunctionId } from './functionproperty/FunctionId';
import type { RenderLocation } from './functionproperty/RenderLocation';
import type { ConflictParam } from './ConflictParam';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';

export class FunctionAction {

  public static initFunctionValue(id: FunctionId, value: unknown): ActionData {
    return {
      isEvent: true,
      type: FunctionActionType.ACTION_INIT_FUNCTION_VAL,
      data: { id: id, value: value }
    };
  }

  // 该回调的值并不能正确代表function的value，请不要直接使用。尽量使用对应function的getValue方法。
  public static changeFunctionValue(id: FunctionId, value: unknown, renderLocation?: RenderLocation): ActionData {
    return {
      isEvent: true,
      type: FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      data: { id: id, value: value, renderLocation: renderLocation }
    };
  }

  public static addFunction(id: FunctionId, location: RenderLocation): ActionData {
    return {
      type: FunctionActionType.ACTION_ADD_FUNCTION,
      data: { id: id, location: location }
    };
  }

  public static removeFunction(id: FunctionId, location: RenderLocation): ActionData {
    return {
      type: FunctionActionType.ACTION_REMOVE_FUNCTION,
      data: { id: id, location: location }
    };
  }

  public static setFunctionConflictParam(id: FunctionId, conflictParam: ConflictParam, isEvent?: boolean): ActionData {
    return {
      type: FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      data: { id: id, conflictParam: { disabled: conflictParam.disabled, limitedValue : conflictParam.limitedValue} },
      isEvent,
    };
  }
}