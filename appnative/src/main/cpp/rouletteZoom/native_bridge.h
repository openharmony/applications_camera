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

#ifndef RENDERNODEGRAPH_NATIVE_BRIDGE_H
#define RENDERNODEGRAPH_NATIVE_BRIDGE_H

#include "napi/native_api.h"
#include <native_window/external_window.h>
#include <native_drawing/drawing_bitmap.h>
#include <native_drawing/drawing_color.h>
#include <native_drawing/drawing_canvas.h>
#include <native_drawing/drawing_pen.h>
#include <native_drawing/drawing_brush.h>
#include <native_drawing/drawing_path.h>
#include "napi/native_api.h"
#include <multimedia/image_framework/image_pixel_map_mdk.h>
#include <multimedia/image_framework/image_pixel_map_napi.h>
#include <native_drawing/drawing_pixel_map.h>
#include <native_window/external_window.h>
#include <native_drawing/drawing_bitmap.h>
#include <native_drawing/drawing_color.h>
#include <native_drawing/drawing_canvas.h>
#include <native_drawing/drawing_pen.h>
#include <native_drawing/drawing_brush.h>
#include <native_drawing/drawing_path.h>
#include "native_node.h"
#include "zoom_calculate.h"
#include "zoom_struct.h"

const int SUBSCRIPT_ZERO = 0;
const int SUBSCRIPT_ONE = 1;
const int SUBSCRIPT_TWO = 2;
const int SUBSCRIPT_THREE = 3;
const int SUBSCRIPT_FOUR = 4;
const int SUBSCRIPT_FIVE = 5;
const int SUBSCRIPT_SIX = 6;
const int SUBSCRIPT_SEVEN = 7;
const int SUBSCRIPT_EIGHT = 8;
const int SUBSCRIPT_NINE = 9;
const int SUBSCRIPT_TEN = 10;
const int SUBSCRIPT_ELEVEN = 11;
const int SUBSCRIPT_TWELVE = 12;

class NativeBridge {
public:
    static napi_value InitNode(napi_env env, napi_callback_info info);

    static napi_value UpdateDirection(napi_env env, napi_callback_info info);
    
    static napi_value SetCameraAppCapabilityParams(napi_env env, napi_callback_info info);
    
    static napi_value ExecLandscapeSlideAnim(napi_env env, napi_callback_info info);
    
    static napi_value OnDraw(napi_env env, napi_callback_info info);
    
private:
    static void ReceiveQuickZoomArray(napi_env env, napi_value argQuickArr, napi_value argQuickEquivalentFocalArr);
    
    static void ReceiveOpticalZoomArray(napi_env env, napi_value argOpticalArr, napi_value argOptZoomDotIndexArr);
    
    static uint32_t GetDoubleArrayFromNapiValue(napi_env env, napi_value argArray, double **dstUpdateArray);
    
    static void GetInt32ArrayFromNapiValue(napi_env env, napi_value argArray, int32_t **dstUpdateArray);

    static void ReceiveLongCurveHalo(napi_env env, napi_value argAnimParam);
    
    static void ReceiveSphereParam(napi_env env, napi_value argAnimParam);
    
    static void ReceiveScaleAllParam(napi_env env, napi_value argAnimParam);
    
    static void ReceiveCarmenLine(napi_env env, napi_value argAnimParam);
    
    static void ReceiveCycleClickZoomArray(napi_env env, napi_value argCycleClickArr);
};

#endif // RENDERNODEGRAPH_NATIVE_BRIDGE_H
