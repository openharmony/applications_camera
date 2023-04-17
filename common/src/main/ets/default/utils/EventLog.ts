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

import { Log } from './Log'
import hiSysEvent from '@ohos.hiSysEvent'

export default class EventLog {
    static readonly OPEN_FAIL = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "OPEN_FAIL",
            MSG: "Failed to open camera"
        }
    }
    static readonly CAMERA_ERROR = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "CAMERA_ERROR",
            MSG: "Error in camera operation"
        }
    }
    static readonly CAPTURE_FAIL = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "CAPTURE_FAIL",
            MSG: "Abnormal photographing"
        }
    }
    static readonly SAVE_FAIL = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "SAVE_FAIL",
            MSG: "Abnormal media drop"
        }
    }
    static readonly SWITCH_TIMEOUT = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "SWITCH_TIMEOUT",
            MSG: "Switch camera timeout"
        }
    }
    static readonly START_RECORD_TIMEOUT = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "RECORD_TIMEOUT",
            MSG: "Recording start timeout"
        }
    }
    static readonly FINISH_RECORD_TIMEOUT = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "RECORD_TIMEOUT",
            MSG: "Recording stop timeout"
        }
    }
    static readonly START_TIMEOUT = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "START_TIMEOUT",
            MSG: "Startup timeout"
        }
    }
    static readonly CAPTURE_TIMEOUT = {
        domain: "CAMERA_APP",
        name: "CAMERA_FAULT",
        eventType: hiSysEvent.EventType.FAULT,
        params: {
            FAULT_ID: "CAPTURE_TIMEOUT",
            MSG: "Photo taking timeout"
        }
    }

    static readonly CAPTURE = {
        domain: "CAMERA_APP",
        name: "CAMERA_BEHAVIOR",
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: {
            BEHAVIOR_ID: "CAPTURE",
            MSG: "take a picture"
        }
    }
    static readonly VIDEO_RECORD = {
        domain: "CAMERA_APP",
        name: "CAMERA_BEHAVIOR",
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: {
            BEHAVIOR_ID: "VIDEO_RECORD",
            MSG: "recording"
        }
    }
    static readonly STOP_RECORD = {
        domain: "CAMERA_APP",
        name: "CAMERA_BEHAVIOR",
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: {
            BEHAVIOR_ID: "STOP_RECORD",
            MSG: "Stop recording"
        }
    }
    static readonly SWITCH_MODE = {
        domain: "CAMERA_APP",
        name: "CAMERA_BEHAVIOR",
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: {
            BEHAVIOR_ID: "SWITCH_MODE",
            MSG: "Switch mode"
        }
    }
    static readonly SWITCH_CAMERA = {
        domain: "CAMERA_APP",
        name: "CAMERA_BEHAVIOR",
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: {
            BEHAVIOR_ID: "SWITCH_CAMERA",
            MSG: "Switch camera"
        }
    }
    static readonly CLICK_THUMBNAIL = {
        domain: "CAMERA_APP",
        name: "CAMERA_BEHAVIOR",
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: {
            BEHAVIOR_ID: "CLICK_THUMBNAIL",
            MSG: "Click thumbnail"
        }
    }
    static readonly CLICK_SETTINGS = {
        domain: "CAMERA_APP",
        name: "CAMERA_BEHAVIOR",
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: {
            BEHAVIOR_ID: "CLICK_SETTINGS",
            MSG: "Enter Settings"
        }
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

    static writeFaultLog(error) {
        const sysEventInfo = {
            domain: "CAMERA_APP",
            name: "CAMERA_FAULT",
            eventType: hiSysEvent.EventType.FAULT,
            params: {
                FAULT_ID: error?.code,
                MSG: error?.message
            }
        }
        hiSysEvent.write(sysEventInfo, (err, val) => {
            if (err) {
                Log.error(`fail to return hiSysEvent.`)
                return;
            }
        })
    }
}