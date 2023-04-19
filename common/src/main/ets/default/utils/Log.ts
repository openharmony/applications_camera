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

import HiLog from "@ohos.hilog"
import hiTraceMeter from '@ohos.hiTraceMeter'

export class Log {
  private static readonly DOMAIN = 0x0200
  private static readonly TAG: string = 'CameraApp'

  private static readonly RECORD_TRACE = true;
  private static readonly TRACE_BASE_INDEX = 10000;

  public static readonly LEVEL_DEBUG = 0;
  public static readonly LEVEL_LOG = 1;
  public static readonly LEVEL_INFO = 2;
  public static readonly LEVEL_WARN = 3;
  public static readonly LEVEL_ERROR = 4;
  public static LOG_LEVEL = Log.LEVEL_LOG;

  static readonly TRACE_LOG_BEGIN: string = ' begin ';
  static readonly TRACE_LOG_END: string = ' end ';
  static readonly STREAM_DISTRIBUTION: string = 'streamDistribution';
  static readonly OPEN_CAMERA: string = 'openCamera';
  static readonly STOP_RECORDING: string = 'stopRecording';
  static readonly UPDATE_PHOTO_THUMBNAIL: string = 'updatePhotoThumbnail';
  static readonly TAKE_PICTURE: string = 'takePicture';
  static readonly UPDATE_VIDEO_THUMBNAIL: string = 'updateVideoThumbnail';
  static readonly APPLICATION_WHOLE_LIFE: string = 'applicationWholeLife';
  static readonly ABILITY_VISIBLE_LIFE: string = 'abilityVisibleLife';
  static readonly ABILITY_FOREGROUND_LIFE: string = 'abilityForegroundLife';
  static readonly ABILITY_WHOLE_LIFE: string = 'abilityWholeLife';
  static readonly X_COMPONENT_LIFE: string = 'XComponentLife';

  public static debug(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_DEBUG) {
      HiLog.debug(this.DOMAIN, this.TAG, message)
    }
  }

  public static log(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_LOG) {
      HiLog.info(this.DOMAIN, this.TAG, message)
    }
  }

  public static info(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_INFO) {
      HiLog.info(this.DOMAIN, this.TAG, message)
    }
  }

  public static warn(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_WARN) {
      HiLog.warn(this.DOMAIN, this.TAG, message)
    }
  }

  public static error(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_ERROR) {
      HiLog.error(this.DOMAIN, this.TAG, message)
    }
  }

  static start(methodName: string) {
    this.info(methodName + this.TRACE_LOG_BEGIN)
    if (!this.RECORD_TRACE) return;
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

  private static init() {
    globalThis.taskIdMap = new Map<string, number>();
    globalThis.traceIndex = this.TRACE_BASE_INDEX;
  }

  static end(methodName: string) {
    this.info(methodName + this.TRACE_LOG_END)
    if (!this.RECORD_TRACE) return;
    if (typeof globalThis.taskIdMap === 'undefined') {
      this.init();
    }
    const taskId = globalThis.taskIdMap.get(methodName);
    if (taskId == undefined) {
      Log.error(`fail to end trace name ${methodName}`)
      return;
    }
    hiTraceMeter.finishTrace(methodName, taskId);
  }
}