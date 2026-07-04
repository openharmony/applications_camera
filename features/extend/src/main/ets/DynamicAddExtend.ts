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
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { addState } from '@ohos/common/src/main/ets/redux';
import lazy { addReducer } from '@ohos/common/src/main/ets/redux/Store';
import lazy { addAction } from '@ohos/common/src/main/ets/redux/ActionRegistry';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';

// 导入Function
import lazy { FlashFunction } from './commonfunc/flash/FlashFunction';
import lazy { FocusFunction } from './commonfunc/focus/FocusFunction';
import lazy { ExposureFunction } from './commonfunc/exposure/ExposureFunction';
import lazy { AssistiveGridFunction } from './settingcommonfunc/assistivegrid/AssistiveGridFunction';
import lazy { TimeLapseFunction } from './settingcommonfunc/timelapse/TimeLapseFunction';
import lazy { TimedShotFunction } from './settingcommonfunc/timedshot/TimedShotFunction';
import lazy { HorizontalLevelFunction } from './settingcommonfunc/horizontallevel/HorizontalLevelFunction';
import lazy { MirrorFunction } from './settingcommonfunc/mirror/MirrorFunction';
import lazy { SaveGeoLocationFunction } from './settingcommonfunc/savegeolocation/SaveGeoLocationFunction';
import lazy { SoundMuteFunction } from './settingcommonfunc/soundmute/SoundMuteFunction';
import lazy { FloatingShutterFunction } from './settingcommonfunc/floatingShutter/FloatingShutterFunction';
import lazy { EfficientVideoFunction } from './videofunc/efficientVideo/EfficientVideoFunction';
// 导入Action
import lazy { FloatingShutterAction } from './settingcommonfunc/floatingShutter/FloatingShutterAction';

const TAG: string = 'DynamicAddExtend';

/**
 * 按需动态添加扩展特性; 过滤掉该机型所有场景均不支持的特性;
 */
/* instrument ignore file */
export function dynamicAddExtend(): void {
  HiLog.begin(TAG, 'dynamicAddExtend');
  dynamicAddCommonFunc();
  dynamicAddSettingCommonFunc();
  dynamicAddVideoFunc();
  HiLog.end(TAG, 'dynamicAddExtend');
}

function dynamicAddCommonFunc(): void {
  let featureManager = FeatureManager.getInstance();
  featureManager.setExtendFunctionsMap(FunctionId.FLASH, new FlashFunction());
  featureManager.setExtendFunctionsMap(FunctionId.FOCUS, new FocusFunction());
  featureManager.setExtendFunctionsMap(FunctionId.EXPOSURE, new ExposureFunction());
}

function dynamicAddSettingCommonFunc(): void {
  let featureManager = FeatureManager.getInstance();
  featureManager.setExtendFunctionsMap(FunctionId.ASSISTIVE_GRID, new AssistiveGridFunction());
  featureManager.setExtendFunctionsMap(FunctionId.TIME_LAPSE, new TimeLapseFunction());
  featureManager.setExtendFunctionsMap(FunctionId.HORIZONTAL_LEVEL, new HorizontalLevelFunction());

  featureManager.setExtendFunctionsMap(FunctionId.MIRROR, new MirrorFunction());
  featureManager.setExtendFunctionsMap(FunctionId.SAVE_GEO_LOCATION, new SaveGeoLocationFunction());
  featureManager.setExtendFunctionsMap(FunctionId.SOUND_MUTE, new SoundMuteFunction());

  featureManager.setExtendFunctionsMap(FunctionId.FLOATING_SHUTTER, new FloatingShutterFunction());
  addAction('FloatingShutterAction', FloatingShutterAction);
}

function dynamicAddVideoFunc(): void {
  let featureManager = FeatureManager.getInstance();
  featureManager.setExtendFunctionsMap(FunctionId.EFFICIENT_VIDEO, new EfficientVideoFunction());
}