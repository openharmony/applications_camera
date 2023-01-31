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

import byTrace from '@ohos.bytrace'
import {Log} from './Log'
import hiSysEvent from '@ohos.hiSysEvent'

export default class Trace {
    static readonly STREAM_DISTRIBUTION = 'streamDistribution';
    static readonly OPEN_CAMERA = 'openCamera';
    static readonly STOP_RECORDING = 'stopRecording';
    static readonly UPDATE_PHOTO_THUMBNAIL = 'updatePhotoThumbnail';
    static readonly TAKE_PICTURE = 'takePicture';
    static readonly UPDATE_VIDEO_THUMBNAIL = 'updateVideoThumbnail';
    static readonly APPLICATION_WHOLE_LIFE = 'applicationWholeLife';
    static readonly APPLICATION_VISIBLE_LIFE = 'applicationVisibleLife';
    static readonly APPLICATION_FOREGROUND_LIFE = 'applicationForegroundLife';
    static readonly ABILITY_VISIBLE_LIFE = 'abilityVisibleLife';
    static readonly ABILITY_FOREGROUND_LIFE = 'abilityForegroundLife';
    static readonly ABILITY_WHOLE_LIFE = 'abilityWholeLife';
    static readonly X_COMPONENT_LIFE = 'XComponentLife';
    static readonly OPEN_FAIL= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "OPEN_FAIL",
            MSG: "打开相机失败"
        }
    }
    static readonly CAMERA_ERROR= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "CAMERA_ERROR",
            MSG: "相机运行时出错"
        }
    }
    static readonly CAPTURE_FAIL= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "CAPTURE_FAIL",
            MSG: "拍照异常"
        }
    }
    static readonly SAVE_FAIL= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "SAVE_FAIL",
            MSG: "媒体落盘异常"
        }
    }
    static readonly SWITCH_TIMEOUT= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "SWITCH_TIMEOUT",
            MSG: "切换摄像头超时"
        }
    }
    static readonly START_RECORD_TIMEOUT= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "RECORD_TIMEOUT",
            MSG: "录像启动超时"
        }
    }
    static readonly FINISH_RECORD_TIMEOUT= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "RECORD_TIMEOUT",
            MSG: "录像停止超时"
        }
    }
    static readonly START_TIMEOUT= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "START_TIMEOUT",
            MSG: "启动超时"
        }
    }
    static readonly CAPTURE_TIMEOUT= {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "CAPTURE_TIMEOUT",
            MSG: "拍照超时"
        }
    }
    private static readonly RECORD_TRACE = true;
    private static readonly TRACE_LIMIT= 2000;
    private static readonly TRACE_BASE_INDEX= 10000;

    static start(methodName: string) {
        if (!Trace.RECORD_TRACE) return;
        if (typeof globalThis.taskIdMap === 'undefined' || typeof globalThis.traceIndex === 'undefined') {
            Trace.init();
        }
        let taskId = globalThis.taskIdMap.get(methodName);
        if (taskId == undefined) {
            taskId = globalThis.traceIndex;
            globalThis.traceIndex++;
            globalThis.taskIdMap.set(methodName, taskId);
        }
        byTrace.startTrace(methodName, taskId, Trace.TRACE_LIMIT);
    }

    private static init() {
        globalThis.taskIdMap = new Map<string, number>();
        globalThis.traceIndex = Trace.TRACE_BASE_INDEX;
    }

    static end(methodName: string) {
        if (!Trace.RECORD_TRACE) return;
        if (typeof globalThis.taskIdMap === 'undefined') {
            Trace.init();
        }
        const taskId = globalThis.taskIdMap.get(methodName);
        if (taskId == undefined) {
            Log.error(`fail to end trace name ${methodName}`)
            return;
        }
        byTrace.finishTrace(methodName, taskId);
    }

    static write(event: any) {
        if (event) {
            hiSysEvent.write(event, (err, val) => {
                if (err) {
                    Log.error(`fail to return hiSysEvent.`)
                    return;
                }
            })
        }
    }
}