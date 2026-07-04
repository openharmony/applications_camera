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

import type { geoLocationManager } from '@kit.LocationKit';

export type LocationMessage = {
  type: LocationType;
  location?: geoLocationManager.Location;
};

export enum LocationType {
  CURRENT_LOCATION = 'GET_CURRENT_LOCATION',
  LAST_LOCATION = 'GET_LAST_LOCATION',
  NO_PERMISSION = 'NO_PERMISSION',
  FAULTY = 'GET_LOCATION_FAILED'
}