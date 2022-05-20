/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

export class CLog {
  private static readonly TAG: string = '[CameraApp]'

  public static readonly LEVEL_DEBUG = 0;
  public static readonly LEVEL_LOG = 1;
  public static readonly LEVEL_INFO = 2;
  public static readonly LEVEL_WARN = 3;
  public static readonly LEVEL_ERROR = 4;
  public static LOG_LEVEL = CLog.LEVEL_DEBUG;


  public static debug(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_DEBUG) {
      console.debug(`${CLog.TAG} ` + message)
    }
  }

  public static log(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_LOG) {
      console.log(`${CLog.TAG} ` + message)
    }
  }

  public static info(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_INFO) {
      console.info(`${CLog.TAG} ` + message)
    }
  }

  public static warn(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_WARN) {
      console.warn(`${CLog.TAG} ` + message)
    }
  }

  public static error(message: string) {
    if (this.LOG_LEVEL <= this.LEVEL_ERROR) {
      console.error(`${CLog.TAG} ` + message)
    }
  }
}