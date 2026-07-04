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
import lazy { CameraAppCapability } from '../camera/CameraAppCapability';
import lazy { DeviceInfo } from '../component/deviceinfo/DeviceInfo';

const TAG: string = 'ColorUtil';

export function getColorString(): string {
    /* instrument ignore if */
    if (CameraAppCapability.getInstance().getIsNovaProduct() || DeviceInfo.isTablet()) {
        return '#0A59F7';
    }
    return '#FF0000';
}

export function getAutoOnIconString(): string {
    /* instrument ignore if */
    if (CameraAppCapability.getInstance().getIsNovaProduct()) {
        return 'app.media.timelapse_auto_on_nova';
    }
    return 'app.media.timelapse_auto_on';
}