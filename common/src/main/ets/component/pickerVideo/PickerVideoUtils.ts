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
import lazy { AVPlayerService } from '../../service/AVPlayerService/AVPlayerService';
import lazy { HiLog } from '../../utils/HiLog';
import media from '@ohos.multimedia.media';

const TAG: string = 'PickerVideoUtils';

export default class PickerVideoUtils {
  public static async queryVideoDuration(uri: string): Promise<number> {
    const videoMetadata: media.AVMetadata = await AVPlayerService.getInstance().getAVMetaDataByPath(uri);
    const duration = videoMetadata.duration;
    HiLog.i(TAG, `queryVideoDuration:${duration}`);
    return parseInt(duration);
  }

  public static formatVideoTime(timeInMS: number, isCurrentTime?: boolean): string {
    let seconds: number;
    if (timeInMS >= 1000 || isCurrentTime) {
      seconds = Math.floor(timeInMS / 1000);
    } else {
      seconds = Math.ceil(timeInMS / 1000);
    }
    let minutes: number = 0;
    let hours: number = 0;
    if (seconds >= 60) {
      minutes = Math.floor(seconds / 60);
      seconds = seconds - minutes * 60;
    }
    if (minutes >= 60) {
      hours = Math.floor(minutes / 60);
      minutes = minutes - hours * 60;
    }
    const seconds2Str: string = seconds.toString().padStart(2, '0');
    const minutes2Str: string = minutes.toString().padStart(2, '0');
    const hours2Str: string = hours.toString().padStart(2, '0');
    const outputTime: string =
      hours > 0 ? `${hours2Str}:${minutes2Str}:${seconds2Str}` : `${minutes2Str}:${seconds2Str}`;
    return outputTime;
  }
}