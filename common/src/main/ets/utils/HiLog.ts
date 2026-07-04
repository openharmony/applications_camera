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

import hilog from '@ohos.hilog';
import hiTraceMeter from '@ohos.hiTraceMeter';
import lazy { WorkerTask } from '../camera/WorkerTask';
import lazy { ActionType } from '../redux/actions/ActionType';
import lazy { FunctionActionType } from '../redux/actions/FunctionActionType';
import lazy { CameraActionType } from '../redux/actions/CameraActionType';
import lazy { FocusExposureActionType } from '../redux/actions/FocusExposureActionType';

const DOMAIN: number = 0x00D00;

// 频繁传递的事件，在通用事件打印处一直打印,处理为Debug级别
// 降低i级别日志丢失率
export const FREQUENT_HILOG_EVENT: string[] = [ // 可考虑更高效数据类型替换string[]降低指令数?
  FunctionActionType.ACTION_INIT_FUNCTION_VAL,
  FunctionActionType.ACTION_ADD_FUNCTION,
  FunctionActionType.ACTION_REMOVE_FUNCTION,
  WorkerTask.ON_ESTIMATED_CAPTURE_DURATION,
  WorkerTask.EYE_FOCUS,
  WorkerTask.ON_FACE_METADATA_OBJECT,
  WorkerTask.ON_FLASH_STATUS,
  WorkerTask.ON_UPDATE_EXPOSURE_RECOVERY_FLAG,
  WorkerTask.ON_CAMERA_STATUS,
  WorkerTask.ON_UPDATE_ISO_DURATION,
  WorkerTask.ON_UPDATE_EXPOSURE_DURATION,
  WorkerTask.UPDATE_FOCUS_STATE,
  WorkerTask.ACTION_SET_FOCUS,
  ActionType.ACTION_ESTIMATED_CAPTURE_DURATION,
  ActionType.ACTION_UPDATE_EYE_FOCUS_VIEW,
  ActionType.ACTION_UPDATE_FACE_DETECTION_VIEW,
  ActionType.ACTION_ON_LUMINATION_STATUS_CHANGED,
  ActionType.ACTION_ON_SKETCH_STATUS_CHANGED,
  ActionType.ACTION_UPDATE_SUPER_ISO_VALUE,
  ActionType.ACTION_UPDATE_ISO_VALUE,
  ActionType.ACTION_ON_PROFESSION_SHUTTER_STATUS_CHANGED,
  ActionType.ACTION_UPDATE_PRO_PARAMETERS_VALUE,
  ActionType.TIME_LAPSE_ACTION_RATE_SLIDER,
  CameraActionType.ON_CAMERA_STATUS,
  FocusExposureActionType.ACTION_UPDATE_FOCUS_STATE,
  FocusExposureActionType.ACTION_SET_FOCUS_MODE,
  WorkerTask.ON_UPDATE_FOCUS_TRACKING_INFO
];

/**
 * HiLog Util
 *
 * standard :
 * 1. define TAG, recommend class name。
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 */
export class HiLog {
  private static readonly IS_DEBUG_ON: boolean = false;
  private static readonly TRACE_LOG_BEGIN: string = ' begin.';
  private static readonly TRACE_LOG_END: string = ' end.';
  private static readonly TRACE_LOG_SEPARATE: string = '::';
  private static keyMap: Map<string, number> = new Map();
  private static traceTaskMap: Map<string, number> = new Map(); // 用于存储trace_name和task_id的映射

  /**
   * 开始trace打点
   * @param tag 组件标识
   * @param methodName trace名
   * @param level 日志等级 hiTraceMeter.HiTraceOutputLevel
   */
  static begin(tag: string, methodName: string,
    level: hiTraceMeter.HiTraceOutputLevel = hiTraceMeter.HiTraceOutputLevel.INFO,): void {
    hilog.info(DOMAIN, tag, methodName + this.TRACE_LOG_BEGIN);
    const traceName: string = `${tag}${this.TRACE_LOG_SEPARATE}${methodName}`;
    hiTraceMeter.startAsyncTrace(level, traceName, this.generateAndSetTaskId(traceName), '');
  }

  /**
   * 结束 trace打点
   * @param tag 组件标识
   * @param methodName trace名
   * @param level 日志等级 hiTraceMeter.HiTraceOutputLevel
   */
  static end(tag: string, methodName: string,
    level: hiTraceMeter.HiTraceOutputLevel = hiTraceMeter.HiTraceOutputLevel.INFO): void {
    hilog.info(DOMAIN, tag, methodName + this.TRACE_LOG_END);
    const traceName: string = `${tag}${this.TRACE_LOG_SEPARATE}${methodName}`;
    hiTraceMeter.finishAsyncTrace(level, traceName, this.getAndClearTaskId(traceName));
  }

  /**
   *  生成trace task id 并存储至map中
   * @param traceName trace名
   * @returns task id
   */
  static generateAndSetTaskId(traceName: string): number {
    try {
      const taskId: number = Date.now();
      this.traceTaskMap.set(traceName, taskId);
      return taskId;
    } catch (err) {
      this.e('HiLog', `${traceName} generate task fail. ${err?.code}`);
      return 1;
    }
  }

  /**
   * 从 map中取出task id 并删除对应traceName
   * @param traceName trace 名
   * @returns task id
   */
  static getAndClearTaskId(traceName: string): number {
    if (this.traceTaskMap.has(traceName)) {
      const taskId: number = this.traceTaskMap.get(traceName);
      this.traceTaskMap.delete(traceName);
      return taskId;
    }
    this.e('HiLog', `${traceName} is not trigger begin, but trigger end.`);
    return 1;
  }

  static d(tag: string, msg: string, ...args: string[]): void {
    if (this.IS_DEBUG_ON) {
      hilog.info(DOMAIN, tag, msg, args);
    } else {
      hilog.debug(DOMAIN, tag, msg, args);
    }
  }

  static i(tag: string, msg: string, ...args: string[]): void {
    hilog.info(DOMAIN, tag, msg, args);
  }

  // 打印URI时做匿名处理。
  static iWithUri(tag: string, msg: string, ...args: string[]): void {
    hilog.info(DOMAIN, tag, anonymousUri(msg), args);
  }

  static w(tag: string, msg: string, ...args: string[]): void {
    hilog.warn(DOMAIN, tag, msg, args);
  }

  static e(tag: string, msg: string, ...args: string[]): void {
    hilog.error(DOMAIN, tag, msg, args);
  }

  static f(tag: string, msg: string, ...args: string[]): void {
    hilog.fatal(DOMAIN, tag, msg, args);
  }

  // 公用处频繁日志打印
  static iFreq(tag: string, msg: string, isFreq: boolean, ...args: string[]): void {
    if (isFreq) {
      hilog.debug(DOMAIN, tag, msg, args);
    } else {
      hilog.info(DOMAIN, tag, msg, args);
    }
  }

  static beginTraceFreq(tag: string, methodName: string, isFreq: boolean): void {
    if (!isFreq) {
      hilog.info(DOMAIN, tag, methodName + this.TRACE_LOG_BEGIN);
      hiTraceMeter.startTrace(tag + this.TRACE_LOG_SEPARATE + methodName, 1);
    }
  }

  static endTraceFreq(tag: string, methodName: string, isFreq: boolean): void {
    if (!isFreq) {
      hilog.info(DOMAIN, tag, methodName + this.TRACE_LOG_END);
      hiTraceMeter.finishTrace(tag + this.TRACE_LOG_SEPARATE + methodName, 1);
    }
  }

  // 限制频繁打印，但是又需要查看i级别的日志，每隔一段时间打印一次
  // TODO：每个频繁打印的mapKey一定要唯一
  static limitLog(tag: string, msg: string, mapKey: string, freqTime: number = 2): void {
    const preTime: number = this.keyMap.get(mapKey) ?? 0;
    const time: number = Date.now();
    const intervalTime: number = freqTime * 1000;
    if (this.keyMap.has(mapKey) && time - preTime < intervalTime) {
      return;
    }
    this.keyMap.set(mapKey, time);
    hilog.info(DOMAIN, tag, msg);
  }
}

function anonymousUri(uri: string): string {
  // Find the position of the last '/' and the first '.'
  const lastSlashIndex = uri.lastIndexOf('/');
  const firstDotIndex = uri.indexOf('.');

  // Ensure both indices are valid
  if (lastSlashIndex === -1 || firstDotIndex === -1 || lastSlashIndex >= firstDotIndex) {
    return uri; // Return the original string if conditions are not met
  }

  // Replace the substring between last '/' and first '.'
  const before = uri.substring(0, lastSlashIndex + 1);
  const mid = uri.substring(lastSlashIndex + 1, firstDotIndex);
  const replacement = `${mid[0]}xxxxxx${mid[mid.length - 1]}`;
  const after = uri.substring(firstDotIndex);
  return before + replacement + after;
}