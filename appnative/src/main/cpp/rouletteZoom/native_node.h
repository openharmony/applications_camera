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

#ifndef RENDERNODEGRAPH_NATIVE_NODE_H
#define RENDERNODEGRAPH_NATIVE_NODE_H

#include <native_window/external_window.h>
#include <native_drawing/drawing_bitmap.h>
#include <native_drawing/drawing_brush.h>
#include <native_drawing/drawing_canvas.h>
#include <native_drawing/drawing_color.h>
#include <native_drawing/drawing_color_filter.h>
#include <native_drawing/drawing_filter.h>
#include <native_drawing/drawing_font.h>
#include <native_drawing/drawing_font_collection.h>
#include <native_drawing/drawing_image.h>
#include <native_drawing/drawing_mask_filter.h>
#include <native_drawing/drawing_matrix.h>
#include <native_drawing/drawing_memory_stream.h>
#include <native_drawing/drawing_path.h>
#include <native_drawing/drawing_path_effect.h>
#include <native_drawing/drawing_pen.h>
#include <native_drawing/drawing_point.h>
#include <native_drawing/drawing_rect.h>
#include <native_drawing/drawing_round_rect.h>
#include <native_drawing/drawing_sampling_options.h>
#include <native_drawing/drawing_shader_effect.h>

#include <native_drawing/drawing_text_blob.h>
#include <native_drawing/drawing_text_declaration.h>
#include <native_drawing/drawing_text_typography.h>
#include <native_drawing/drawing_typeface.h>
#include <native_drawing/drawing_types.h>
#include <native_drawing/drawing_rect.h>
#include <multimedia/image_framework/image_pixel_map_mdk.h>
#include <multimedia/image_framework/image_pixel_map_napi.h>
#include <native_drawing/drawing_pixel_map.h>

#include <native_buffer/native_buffer.h>
#include "./zoom_param.h"
#include "./zoom_struct.h"
#include "common/Log.h"
#include "zoom_calculate.h"

#include <string>
#include <cstdint>
#include <cmath>
#include <algorithm>
#include <iostream>
#include <unistd.h>
#include <thread>
#include <cstdio>
#include <fcntl.h>
#include <map>
#include <vector>
#include <sstream>
#include "iostream"
#include "mutex"
#include <iomanip>
#include <memory>

class NativeNode {
public:
    static NativeNode* GetInstance();

    ZoomStruct* GetZoomState();
    
    void NativeOnDraw(OH_Drawing_Canvas *canvas, double curZoomVal, double curZoomAng);
    
    ~NativeNode()
    {
        OH_Drawing_PathDestroy(tShadowPath_);
        OH_Drawing_PathDestroy(tOuterLinePath_);
        OH_Drawing_PathDestroy(tShortLinePath_);
        OH_Drawing_PathDestroy(tQuickLinePath_);
        
        OH_Drawing_PenDestroy(cScaleAllPen_);
        OH_Drawing_BrushDestroy(cZoomTextFadeBrush_);
        OH_Drawing_BrushDestroy(cLongCurveShadowBrush_);
        OH_Drawing_PenDestroy(cLongCurvePen_);
        OH_Drawing_BrushDestroy(cPhotoSphereShadowBrush_);
        OH_Drawing_BrushDestroy(cPhotoSphereBrush_);
        OH_Drawing_PenDestroy(cZoomScaleShadowPen_);
        OH_Drawing_PenDestroy(cZoomScalePen_);
        OH_Drawing_PenDestroy(cRatioTextPen_);
        OH_Drawing_PenDestroy(cOpticalTextPen_);
        OH_Drawing_PenDestroy(cRedLinePen_);
        OH_Drawing_PenDestroy(cSimuRedTextPen_);
    }
    
    std::shared_ptr<ZoomStruct> state = nullptr; // 变焦状态缓存器

    OH_Drawing_Canvas* cCanvas_ = nullptr;
    OH_Drawing_Path* tShadowPath_ = nullptr;
    OH_Drawing_Path* tOuterLinePath_ = nullptr;
    OH_Drawing_Path* tShortLinePath_ = nullptr;
    OH_Drawing_Path* tQuickLinePath_ = nullptr;
    
    OH_Drawing_Pen* cScaleAllPen_ = nullptr;
    OH_Drawing_Brush* cZoomTextFadeBrush_ = nullptr;
    OH_Drawing_Brush* cLongCurveShadowBrush_ = nullptr;
    OH_Drawing_Pen* cLongCurvePen_ = nullptr;
    OH_Drawing_Brush* cPhotoSphereShadowBrush_ = nullptr;
    OH_Drawing_Brush* cPhotoSphereBrush_ = nullptr;
    OH_Drawing_Pen* cZoomScaleShadowPen_ = nullptr;
    OH_Drawing_Pen* cZoomScalePen_ = nullptr;
    OH_Drawing_Pen* cRatioTextPen_ = nullptr;
    OH_Drawing_Pen* cOpticalTextPen_ = nullptr;
    OH_Drawing_Pen* cRedLinePen_ = nullptr;
    OH_Drawing_Pen* cSimuRedTextPen_ = nullptr;
    
private:
    static NativeNode* instance;

    NativeNode()
    {
        state = std::make_shared<ZoomStruct>();
        tShadowPath_ = OH_Drawing_PathCreate();
        tOuterLinePath_ = OH_Drawing_PathCreate();
        tShortLinePath_ = OH_Drawing_PathCreate();
        tQuickLinePath_ = OH_Drawing_PathCreate();
        
        cScaleAllPen_ = OH_Drawing_PenCreate();
        cZoomTextFadeBrush_ = OH_Drawing_BrushCreate();
        cLongCurveShadowBrush_ = OH_Drawing_BrushCreate();
        cLongCurvePen_ = OH_Drawing_PenCreate();
        cPhotoSphereShadowBrush_ = OH_Drawing_BrushCreate();
        cPhotoSphereBrush_ = OH_Drawing_BrushCreate();
        cZoomScaleShadowPen_ = OH_Drawing_PenCreate();
        cZoomScalePen_ = OH_Drawing_PenCreate();
        cRatioTextPen_ = OH_Drawing_PenCreate();
        cOpticalTextPen_ = OH_Drawing_PenCreate();
        cRedLinePen_ = OH_Drawing_PenCreate();
        cSimuRedTextPen_ = OH_Drawing_PenCreate();
    } // 构造函数私有化
    
    void ZoomTextFadeNewLayer(OH_Drawing_Rect *bounds);
    
    void ZoomScaleScaleNewLayer(OH_Drawing_Rect *bounds);

    void ZoomScaleScaleSourceAnim();
    
    void ZoomTextFadeSourceAnim();

    void DrawLongCurveAndShadow();

    void DrawCarmenHalo(OH_Drawing_Brush *cCurveBrush_, uint32_t topColor);

    void DrawCarmenCurve(OH_Drawing_Pen *cCurvePen_, uint32_t topColor);

    void DrawPhotoSphereAndShadow();
    
    void GeneratePathByPenParam(OH_Drawing_Path *tPath_, float curDotAngle, int selectedOpticalIndex, int index,
                                int opticalZoomLength);

    void DrawZoomShadow(OH_Drawing_Path *tShadowPath_);
    
    void DrawZoomScale(OH_Drawing_Path *tOuterLinePath_, OH_Drawing_Path *tShortLinePath_,
                                        OH_Drawing_Path *tQuickLinePath_);

    void DrawRatioTextAndShadow(float curDotAngle, int selectedOpticalIndex);

    void DrawZoomTextAndShadow(int selectedOpticalIndex, int diff);

    void SetOpticalTextPenAttribute();
    
    void DrawEquivalentFocalTextAndShadow(int selectedOpticalIndex, float curDotAngle, int diff);

    OH_Drawing_Typography *GetTypography(std::string tempStr, int maxWidth, double opacityChannel, bool isRedChannel,
                                         int fontSize);

    void DrawRedLineTextAndShadow();
    
    void DrawLandscapeSlideSimuEquivalentFocal();
    
    void SetCycleClickZoomPenAttribute(float x, float y);
    
    bool IsZoomValInCycleClickZoom(const ZoomStruct* state, double zoomValue);
    
    void DrawRedLineCycle(int outerX, int outerY, int innerY, double redLineWidth);
};

#endif // RENDERNODEGRAPH_NATIVE_NODE_H
