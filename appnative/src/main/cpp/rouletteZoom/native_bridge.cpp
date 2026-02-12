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

#include "native_bridge.h"

#define TAG "native_bridge"

/**
 * InitNode: RenderNode节点数据初始化
 */
napi_value NativeBridge::InitNode(napi_env env, napi_callback_info info)
{
    size_t argc = SUBSCRIPT_TWELVE;
    napi_value args[SUBSCRIPT_TWELVE] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t id;
    napi_get_value_int32(env, args[SUBSCRIPT_ZERO], &id);

    double width;
    napi_get_value_double(env, args[SUBSCRIPT_ONE], &width);

    double height;
    napi_get_value_double(env, args[SUBSCRIPT_TWO], &height);

    double drawHeight;
    napi_get_value_double(env, args[SUBSCRIPT_THREE], &drawHeight);

    int32_t collapsStatus;
    napi_get_value_int32(env, args[SUBSCRIPT_FOUR], &collapsStatus);

    int32_t directionAngle;
    napi_get_value_int32(env, args[SUBSCRIPT_FIVE], &directionAngle);

    double densityPixels;
    napi_get_value_double(env, args[SUBSCRIPT_SIX], &densityPixels);

    ZoomCalculate::NativeInitNode(NativeNode::GetInstance()->GetZoomState(), width, height, drawHeight, densityPixels);
    ZoomCalculate::NativeMultiAdaptParam(NativeNode::GetInstance()->GetZoomState(), collapsStatus, directionAngle);

    NativeBridge::ReceiveQuickZoomArray(env, args[SUBSCRIPT_SEVEN], args[SUBSCRIPT_EIGHT]);
    NativeBridge::ReceiveOpticalZoomArray(env, args[SUBSCRIPT_NINE], args[SUBSCRIPT_TEN]);
    NativeBridge::ReceiveCycleClickZoomArray(env, args[SUBSCRIPT_ELEVEN]);

    return nullptr;
}

/**
 * 传递快捷变焦ZoomArray数据
 */
void NativeBridge::ReceiveQuickZoomArray(napi_env env, napi_value argQuickArr, napi_value argQuickEquivalentFocalArr)
{
    uint32_t quickArrLength = 0;
    double *quickZoomValArr = new double[2];
    int32_t *quickEquivalentFocalArr = new int32_t[2];

    quickArrLength = GetDoubleArrayFromNapiValue(env, argQuickArr, &quickZoomValArr);

    GetInt32ArrayFromNapiValue(env, argQuickEquivalentFocalArr, &quickEquivalentFocalArr);

    ZoomCalculate::SetQuickZoomArray(NativeNode::GetInstance()->GetZoomState(), quickArrLength, quickZoomValArr,
                                     quickEquivalentFocalArr);
}

uint32_t NativeBridge::GetDoubleArrayFromNapiValue(napi_env env, napi_value argArray, double **dstUpdateArray)
{
    bool isArray = false;
    uint32_t arrLength = 0;
    napi_is_array(env, argArray, &isArray);
    if (!isArray) {
        LOGI(TAG, "GetDoubleArrayFromNapiValue isArray %{public}b", isArray);
        return 0;
    }
    
    napi_get_array_length(env, argArray, &arrLength);
    double* temp = *dstUpdateArray;
    *dstUpdateArray = new double[arrLength];
    delete[] temp; // 主动释放内存
    for (uint32_t i = 0; i < arrLength; i++) {
        napi_value element;
        double num = 0.0;
        napi_get_element(env, argArray, i, &element);
        napi_get_value_double(env, element, &num);
        (*dstUpdateArray)[i] = num;
    }
    return arrLength;
}

void NativeBridge::GetInt32ArrayFromNapiValue(napi_env env, napi_value argArray, int32_t **dstUpdateArray)
{
    bool isArray = false;
    uint32_t arrLength = 0;
    napi_is_array(env, argArray, &isArray);
    if (!isArray) {
        LOGI(TAG, "GetInt32ArrayFromNapiValue isArray %{public}b", isArray);
        return;
    }
    
    napi_get_array_length(env, argArray, &arrLength);
    int32_t* temp = *dstUpdateArray;
    *dstUpdateArray = new int32_t[arrLength];
    delete[] temp; // 主动释放内存
    for (uint32_t i = 0; i < arrLength; i++) {
        napi_value element;
        int32_t num = 0;
        napi_get_element(env, argArray, i, &element);
        napi_get_value_int32(env, element, &num);
        (*dstUpdateArray)[i] = num;
    }
}

/**
 * 传递光学变焦ZoomArray数据
 */
void NativeBridge::ReceiveOpticalZoomArray(napi_env env, napi_value argOpticalArr, napi_value argOptZoomDotIndexArr)
{
    uint32_t opticalArrLength = 0;
    double *opticalZoomValArr = new double[2];
    int32_t *opticalZoomDotIndexArr = new int32_t[2];

    opticalArrLength = GetDoubleArrayFromNapiValue(env, argOpticalArr, &opticalZoomValArr);
    
    GetInt32ArrayFromNapiValue(env, argOptZoomDotIndexArr, &opticalZoomDotIndexArr);

    ZoomCalculate::SetOpticalZoomArray(NativeNode::GetInstance()->GetZoomState(), opticalArrLength, opticalZoomValArr,
                                       opticalZoomDotIndexArr);
}

void NativeBridge::ReceiveCycleClickZoomArray(napi_env env, napi_value argCycleClickZoomArr)
{
    uint32_t cycleClickZoomArrLength = 0;
    double *cycleClickZoomArr = new double[2];
    cycleClickZoomArrLength = GetDoubleArrayFromNapiValue(env, argCycleClickZoomArr, &cycleClickZoomArr);
    ZoomCalculate::SetCycleClickZoomArray(NativeNode::GetInstance()->GetZoomState(),
                                          cycleClickZoomArrLength,cycleClickZoomArr);
}


/**
 * UpdateDirection: 更新横竖屏旋转状态,执行字体旋转动效
 */
napi_value NativeBridge::UpdateDirection(napi_env env, napi_callback_info info)
{
    size_t argc = SUBSCRIPT_ONE;
    napi_value args[SUBSCRIPT_ONE] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t direction;
    napi_get_value_int32(env, args[SUBSCRIPT_ZERO], &direction);

    ZoomCalculate::UpdateDirectionAngle(NativeNode::GetInstance()->GetZoomState(), direction);

    return nullptr;
}

/**
 * SetCameraAppCapabilityParams: 设置CCM配置项
 */
napi_value NativeBridge::SetCameraAppCapabilityParams(napi_env env, napi_callback_info info)
{
    size_t argc = SUBSCRIPT_THREE;
    napi_value args[SUBSCRIPT_THREE] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    bool mIsSupportNovaProduct = false;
    napi_get_value_bool(env, args[SUBSCRIPT_ZERO], &mIsSupportNovaProduct);
    
    bool mIsSupportedEquivalentFocalBigText = false;
    napi_get_value_bool(env, args[SUBSCRIPT_ONE], &mIsSupportedEquivalentFocalBigText);
    
    bool mIsSupportedCycleClickZoom = false;
    napi_get_value_bool(env, args[SUBSCRIPT_TWO], &mIsSupportedCycleClickZoom);

    NativeNode::GetInstance()->GetZoomState()->setCameraAppCapabilityParams(mIsSupportNovaProduct,
                                                                            mIsSupportedEquivalentFocalBigText,
                                                                            mIsSupportedCycleClickZoom
                                                                            );

    return nullptr;
}

/**
 * ExecLandscapeSlideAnim: 按场景执行横屏滑动展开/归位动效
 */
napi_value NativeBridge::ExecLandscapeSlideAnim(napi_env env, napi_callback_info info)
{
    size_t argc = SUBSCRIPT_THREE;
    napi_value args[SUBSCRIPT_THREE] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t zoomIndex;
    napi_get_value_int32(env, args[SUBSCRIPT_ZERO], &zoomIndex);
    
    double displacementDistance;
    napi_get_value_double(env, args[SUBSCRIPT_ONE], &displacementDistance);
    
    int32_t animType;
    napi_get_value_int32(env, args[SUBSCRIPT_TWO], &animType);

    ZoomCalculate::UpdateLandscapeSlideDistance(NativeNode::GetInstance()->GetZoomState(), zoomIndex,
                                                displacementDistance, animType);
    
    return nullptr;
}

/**
 * OnDraw: 实时数据传递,RenderNode节点刷新并绘制
 */
napi_value NativeBridge::OnDraw(napi_env env, napi_callback_info info)
{
    size_t argc = SUBSCRIPT_FIVE;
    napi_value args[SUBSCRIPT_FIVE] = { nullptr };
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t id;
    napi_get_value_int32(env, args[SUBSCRIPT_ZERO], &id);
    
    void *mCanvas = nullptr;
    napi_unwrap(env, args[SUBSCRIPT_ONE], &mCanvas);
    OH_Drawing_Canvas *canvas = reinterpret_cast<OH_Drawing_Canvas *>(mCanvas);
    
    double curZoomVal;
    napi_get_value_double(env, args[SUBSCRIPT_TWO], &curZoomVal);

    double curZoomAngle;
    napi_get_value_double(env, args[SUBSCRIPT_THREE], &curZoomAngle);

    NativeBridge::ReceiveLongCurveHalo(env, args[SUBSCRIPT_FOUR]);
    
    NativeBridge::ReceiveSphereParam(env, args[SUBSCRIPT_FOUR]);

    NativeBridge::ReceiveScaleAllParam(env, args[SUBSCRIPT_FOUR]);

    NativeBridge::ReceiveCarmenLine(env, args[SUBSCRIPT_FOUR]);

    NativeNode::GetInstance()->NativeOnDraw(canvas, curZoomVal, curZoomAngle);
    
    return nullptr;
}

/**
 * 传递动效类型、光晕动效参数
 */
void NativeBridge::ReceiveLongCurveHalo(napi_env env, napi_value argAnimParam)
{
    napi_value napiProperty;
    bool isPresent = false;
    
    napi_has_named_property(env, argAnimParam, "animType", &isPresent);
    int32_t animType = 0;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "animType", &napiProperty);
        napi_get_value_int32(env, napiProperty, &animType);
    }

    napi_has_named_property(env, argAnimParam, "longCurveHaloMatteScale", &isPresent);
    double longCurveHaloMatteScale = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "longCurveHaloMatteScale", &napiProperty);
        napi_get_value_double(env, napiProperty, &longCurveHaloMatteScale);
    }

    napi_has_named_property(env, argAnimParam, "longCurveHaloOpacity", &isPresent);
    double longCurveHaloOpacity = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "longCurveHaloOpacity", &napiProperty);
        napi_get_value_double(env, napiProperty, &longCurveHaloOpacity);
    }

    ZoomCalculate::SetLongCurveHalo(NativeNode::GetInstance()->GetZoomState(), animType, longCurveHaloMatteScale,
                                    longCurveHaloOpacity);
}

/**
 * 传递光球-光晕动效参数
 */
void NativeBridge::ReceiveSphereParam(napi_env env, napi_value argAnimParam)
{
    napi_value napiProperty;
    bool isPresent = false;
    
    napi_has_named_property(env, argAnimParam, "spherePosition", &isPresent);
    double spherePosition = 0;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "spherePosition", &napiProperty);
        napi_get_value_double(env, napiProperty, &spherePosition);
    }

    napi_has_named_property(env, argAnimParam, "sphereScale", &isPresent);
    double sphereScale = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "sphereScale", &napiProperty);
        napi_get_value_double(env, napiProperty, &sphereScale);
    }

    napi_has_named_property(env, argAnimParam, "sphereColor", &isPresent);
    double sphereColor = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "sphereColor", &napiProperty);
        napi_get_value_double(env, napiProperty, &sphereColor);
    }

    napi_has_named_property(env, argAnimParam, "sphereHaloOpacity", &isPresent);
    double sphereHaloOpacity = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "sphereHaloOpacity", &napiProperty);
        napi_get_value_double(env, napiProperty, &sphereHaloOpacity);
    }

    ZoomCalculate::SetSphereParam(NativeNode::GetInstance()->GetZoomState(), spherePosition, sphereScale, sphereColor,
                                  sphereHaloOpacity);
}

/**
 * 传递变焦刻度-焦圈动效参数
 */
void NativeBridge::ReceiveScaleAllParam(napi_env env, napi_value argAnimParam)
{
    napi_value napiProperty;
    bool isPresent = false;
    
    napi_has_named_property(env, argAnimParam, "redLineAndTextOpacity", &isPresent);
    double redLineAndTextOpacity = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "redLineAndTextOpacity", &napiProperty);
        napi_get_value_double(env, napiProperty, &redLineAndTextOpacity);
    }

    napi_has_named_property(env, argAnimParam, "scaleAllMatteScale", &isPresent);
    double scaleAllMatteScale = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "scaleAllMatteScale", &napiProperty);
        napi_get_value_double(env, napiProperty, &scaleAllMatteScale);
    }

    napi_has_named_property(env, argAnimParam, "scaleAllOpacity", &isPresent);
    double scaleAllOpacity = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "scaleAllOpacity", &napiProperty);
        napi_get_value_double(env, napiProperty, &scaleAllOpacity);
    }

    ZoomCalculate::SetScaleAllParam(NativeNode::GetInstance()->GetZoomState(), redLineAndTextOpacity,
                                    scaleAllMatteScale, scaleAllOpacity);
}

/**
 * 传递卡门线动效参数
 */
void NativeBridge::ReceiveCarmenLine(napi_env env, napi_value argAnimParam)
{
    napi_value napiProperty;
    bool isPresent = false;
    
    napi_has_named_property(env, argAnimParam, "carmenLineMatteScale", &isPresent);
    double carmenLineMatteScale = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "carmenLineMatteScale", &napiProperty);
        napi_get_value_double(env, napiProperty, &carmenLineMatteScale);
    }

    napi_has_named_property(env, argAnimParam, "carmenLineOpacity", &isPresent);
    double carmenLineOpacity = 1;
    if (isPresent == 1) {
        napi_get_named_property(env, argAnimParam, "carmenLineOpacity", &napiProperty);
        napi_get_value_double(env, napiProperty, &carmenLineOpacity);
    }

    ZoomCalculate::SetCarmenLine(NativeNode::GetInstance()->GetZoomState(), carmenLineMatteScale, carmenLineOpacity);
}
