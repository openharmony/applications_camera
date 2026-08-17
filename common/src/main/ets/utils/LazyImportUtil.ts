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
// TODO OpenHarmony编译报错，待后续相关kit支持放开
// import lazy { detectBarcode, scanBarcode, scanCore as scanCore } from '@kit.ScanKit';
import lazy { intl } from '@kit.LocalizationKit';
import vibrator from '@ohos.vibrator';
import lazy { buffer } from '@kit.ArkTS';
import performanceMonitor from '@ohos.arkui.performanceMonitor';
import lazy { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import wantConstant from '@ohos.ability.wantConstant';
import sensor from '@ohos.sensor';
import lazy { privacyManager } from '@kit.AbilityKit';
import lazy { distributedDeviceManager } from '@kit.DistributedServiceKit';
// @ts-ignore
import lazy abilityConnectionManager from '@ohos.distributedsched.abilityConnectionManager';
import fileio from '@ohos.fileio';
import image from '@ohos.multimedia.image';
// import CameraProfilesJsonUtilV1 from './jsonparseutil/CameraProfilesJsonUtilV1';
import CameraProfilesJsonUtilV2 from './jsonparseutil/CameraProfilesJsonUtilV2';
import DateTimeUtil from './DateTimeUtil';
import lazy { rpc } from '@kit.IPCKit';
import pasteboard from '@ohos.pasteboard';
import observer from '@ohos.arkui.observer';
import effectKit from '@ohos.effectKit';
import systemDateTime from '@ohos.systemDateTime';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import MediaLibraryUiService from '../service/medialibrary/MediaLibraryUiService';
import MediaLibraryOperation from '../service/medialibrary/MediaLibraryOperation';
// import lazy TimelapseNative from 'libTimelapseNative.so';
import VideoOutputWrap from '../camera/childthread/modules/video/VideoOutputWrap';
import configPolicy from '@ohos.configPolicy';
import fs from '@ohos.file.fs';
import fileIO from '@ohos.fileio';
import dataObserver from './dataObserver';

import audio from '@ohos.multimedia.audio';
import lottie, { AnimationItem } from '@ohos/lottie';
// @ts-ignore
import Motion from '@ohos.multimodalAwareness.motion';
import storageManager from '@ohos.file.statvfs';
import util from '@ohos.util';

// TODO OpenHarmony编译报错，待后续相关kit支持放开
// export { detectBarcode, scanBarcode, scanCore };

export { intl };

export { vibrator };

export { buffer };

export { performanceMonitor };

export { backgroundTaskManager };

export { wantConstant };

export { sensor };

export { privacyManager };

export { distributedDeviceManager };

export { abilityConnectionManager };

export { fileio };

export { image };

export { /*CameraProfilesJsonUtilV1, */CameraProfilesJsonUtilV2 };

export { DateTimeUtil };

export { rpc };

export { pasteboard };

export { observer };

export { effectKit };

export { systemDateTime };

export { dataSharePredicates };

export { MediaLibraryUiService };

export { MediaLibraryOperation };

// export { TimelapseNative };

export { VideoOutputWrap };

export { configPolicy };

export { fs };

export { fileIO };

export { dataObserver };


export { audio };

export { lottie, AnimationItem };

export { Motion };

export { storageManager };

export { util };