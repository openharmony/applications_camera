/*
 * Copyright (c) Huawei Device Co., Ltd. 2025-2025. All rights reserved.
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

#ifndef LOGGER_COMMON_H_
#define LOGGER_COMMON_H_

#include <string>
#include "hilog/log.h"
#include "hitrace/trace.h"
#define APP_LOG_DOMAIN 0x00D00

constexpr const char *PANORAMA_TAG = "panoramaLog";
constexpr const char *DYNAMIC_FILTER_TAG = "DynamicFilter";
constexpr const char *RECORD_FILTER_TAG = "PreviewRecordFilter";
constexpr const char *TIMELAPSE_NATIVE_TAG = "TimelapseNative";
constexpr const char *IMAGE_EFFECT_ENTRY_TAG = "image_effect_entry";
constexpr const char *SET_QOS_TAG = "SetQosNative";

#define LOGD(tag, ...) ((void)OH_LOG_Print(LOG_APP, LOG_DEBUG, APP_LOG_DOMAIN, tag, __VA_ARGS__))
#define LOGI(tag, ...) ((void)OH_LOG_Print(LOG_APP, LOG_INFO, APP_LOG_DOMAIN, tag, __VA_ARGS__))
#define LOGW(tag, ...) ((void)OH_LOG_Print(LOG_APP, LOG_WARN, APP_LOG_DOMAIN, tag, __VA_ARGS__))
#define LOGE(tag, ...) ((void)OH_LOG_Print(LOG_APP, LOG_ERROR, APP_LOG_DOMAIN, tag, __VA_ARGS__))

#define CHECK_RETURN_LOG(cond, ret, fmt, ...)                                                                          \
    do {                                                                                                               \
        if (!(cond)) {                                                                                                 \
            LOGE(DYNAMIC_FILTER_TAG, fmt, ##__VA_ARGS__);                                                              \
            return ret;                                                                                                \
        }                                                                                                              \
    } while (0)

#define CHECK_LOG(cond, fmt, ...)                                                                                      \
    do {                                                                                                               \
        if (!(cond)) {                                                                                                 \
            LOGE(DYNAMIC_FILTER_TAG, fmt, ##__VA_ARGS__);                                                              \
        }                                                                                                              \
    } while (0)

#define LOGE_IF(x, str) \
if ((x) != 0) { \
    OH_LOG_Print(LOG_APP, LOG_INFO, 0X0000, "", "  %{public}s failed in %{public}s for:%{public}s", \
                 #x, __func__, str); \
}

constexpr int THOUSAND = 1000;

class Log {
private:
    long startTime;
    std::string tag;
    std::string message;

public:
    static Log Begin(std::string tagParam, std::string msg)
    {
        OH_HiTrace_StartTrace((tagParam + " " + msg).c_str());
        Log *log = new Log();
        auto start = std::chrono::high_resolution_clock::now();
        // micro seconds
        log->startTime = std::chrono::duration_cast<std::chrono::microseconds>(start.time_since_epoch()).count();
        log->tag = tagParam;
        log->message = msg;
        return *log;
    }

    void End()
    {
        OH_HiTrace_FinishTrace();
        auto end = std::chrono::high_resolution_clock::now();
        // micro seconds
        long endTime = std::chrono::duration_cast<std::chrono::microseconds>(end.time_since_epoch()).count();
        OH_LOG_Print(LOG_APP, LOG_INFO, 0x0000, tag.c_str(), "%{public}s, cost%{public}f ms", message.c_str(),
                     (endTime - startTime) * 1.0f / THOUSAND);
    }
};
#endif // LOGGER_COMMON_H_
