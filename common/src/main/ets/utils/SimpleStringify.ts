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

const PRIVACY_KEYWORD: string[] = [
  'location',
  'uri',
  'url',
  'physicalApertures',
  'customText',
  'FILTER_STICKER_LOCATION',
  'FILTER_STICKER_DEFINITION',
  'captureLocationValue'
];

const HIDE_KEYS: string[] = [
  'rotationAngle'
];

export function simpleStringify(obj: unknown): string {
  if (obj === undefined || obj === null) {
    return 'undefined';
  }
  const type = typeof obj;
  if (type === 'string') {
    return obj as string;
  }
  if (type === 'number') {
    return obj.toString();
  }
  if (type === 'boolean') {
    return <boolean> obj ? 'true' : 'false';
  }
  if (Array.isArray(obj)) {
    return `[${obj.map(item => simpleStringify(item)).join(', ')}]`;
  }
  if (type !== 'object') {
    return '';
  }
  const keys = Object.keys(obj);
  const result = '{' + keys.map(key => {
    let value = undefined;
    if (PRIVACY_KEYWORD.includes(key)) {
      value = '******';
    } else if (HIDE_KEYS.some(item => key.includes(item))) {
      value = simpleStringify(obj[key]);
      key = '******';
    } else {
      value = simpleStringify(obj[key]);
    }
    return `"${key}":${value}`;
  }).join(',') + '}';
  return result;
}