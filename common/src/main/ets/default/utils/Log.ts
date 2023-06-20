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

import HiLog from '@ohos.hilog';
import hiTraceMeter from '@ohos.hiTraceMeter';

const DOMAIN = 0x0200;
const TAG: string = 'CameraApp';

const RECORD_TRACE = true;
const TRACE_BASE_INDEX = 10000;

const LEVEL_DEBUG = 0;
const LEVEL_LOG = 1;
const LEVEL_INFO = 2;
const LEVEL_WARN = 3;
const LEVEL_ERROR = 4;
const LOG_LEVEL = LEVEL_DEBUG;

const TRACE_LOG_BEGIN: string = ' begin ';
const TRACE_LOG_END: string = ' end ';

export class Log {
  public static readonly STREAM_DISTRIBUTION: string = 'streamDistribution';
  public static readonly OPEN_CAMERA: string = 'openCamera';
  public static readonly STOP_RECORDING: string = 'stopRecording';
  public static readonly UPDATE_PHOTO_THUMBNAIL: string = 'updatePhotoThumbnail';
  public static readonly TAKE_PICTURE: string = 'takePicture';
  public static readonly UPDATE_VIDEO_THUMBNAIL: string = 'updateVideoThumbnail';
  public static readonly APPLICATION_WHOLE_LIFE: string = 'applicationWholeLife';
  public static readonly ABILITY_VISIBLE_LIFE: string = 'abilityVisibleLife';
  public static readonly ABILITY_FOREGROUND_LIFE: string = 'abilityForegroundLife';
  public static readonly ABILITY_WHOLE_LIFE: string = 'abilityWholeLife';
  public static readonly X_COMPONENT_LIFE: string = 'XComponentLife';

  public static debug(message: string): void {
    if (LOG_LEVEL <= LEVEL_DEBUG) {
      HiLog.debug(DOMAIN, TAG, message);
    }
  }

  public static log(message: string): void {
    if (LOG_LEVEL <= LEVEL_LOG) {
      HiLog.info(DOMAIN, TAG, message);
    }
  }

  public static info(message: string): void {
    if (LOG_LEVEL <= LEVEL_INFO) {
      HiLog.info(DOMAIN, TAG, message);
    }
  }

  public static warn(message: string): void {
    if (LOG_LEVEL <= LEVEL_WARN) {
      HiLog.warn(DOMAIN, TAG, message);
    }
  }

  public static error(message: string): void {
    if (LOG_LEVEL <= LEVEL_ERROR) {
      HiLog.error(DOMAIN, TAG, message);
    }
  }

  static start(methodName: string): void {
    this.info(methodName + TRACE_LOG_BEGIN);
    if (!RECORD_TRACE) {
      return;
    }
    if (typeof globalThis.taskIdMap === 'undefined' || typeof globalThis.traceIndex === 'undefined') {
      this.init();
    }
    let taskId = globalThis.taskIdMap.get(methodName);
    if (taskId == undefined) {
      taskId = globalThis.traceIndex;
      globalThis.traceIndex++;
      globalThis.taskIdMap.set(methodName, taskId);
    }
    hiTraceMeter.startTrace(methodName, taskId);
  }

  private static init(): void {
    globalThis.taskIdMap = new Map<string, number>();
    globalThis.traceIndex = TRACE_BASE_INDEX;
  }

  static end(methodName: string): void {
    this.info(methodName + TRACE_LOG_END);
    if (!RECORD_TRACE) {
      return;
    }
    if (typeof globalThis.taskIdMap === 'undefined') {
      this.init();
    }
    const taskId = globalThis.taskIdMap.get(methodName);
    if (taskId == undefined) {
      Log.error(`fail to end trace name ${methodName}`);
      return;
    }
    hiTraceMeter.finishTrace(methodName, taskId);
  }
}