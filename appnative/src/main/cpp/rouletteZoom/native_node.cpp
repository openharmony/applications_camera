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

#include "native_node.h"

#define TAG "native_node"
NativeNode* NativeNode::instance;

/**
 * NativeNode单例构造器
 */
NativeNode* NativeNode::GetInstance()
{
    if (NativeNode::instance == nullptr) {
        NativeNode::instance = new NativeNode();
    }
    return NativeNode::instance;
}

/**
 * 获取ZoomState
 */
ZoomStruct* NativeNode::GetZoomState()
{
    return state.get();
}

/**
 * RenderNode节点借助Canvas对象绘制
 */
void NativeNode::NativeOnDraw(OH_Drawing_Canvas *canvas, double curZoomVal, double curZoomAng)
{
    OH_Drawing_Rect *bounds = PrepareDrawState(canvas, curZoomVal, curZoomAng);
    GenerateAllScalePaths();
    FinalizeDraw(bounds);
}

OH_Drawing_Rect* NativeNode::PrepareDrawState(OH_Drawing_Canvas *canvas, double curZoomVal, double curZoomAng)
{
    cCanvas_ = canvas;
    state->curZoomValue = curZoomVal;
    state->curZoomAngle = curZoomAng == INVALID_ZOOM_ANGLE ? ZoomCalculate::CalZoomAngle(GetZoomState())
                                                           : curZoomAng; // 当前变焦对应的角度
    DrawLongCurveAndShadow(); // 顶部卡门线绘制
    DrawPhotoSphereAndShadow(); // 顶部光球绘制
    OH_Drawing_Rect *bounds =
        OH_Drawing_RectCreate(0, 0, state->width * state->densityPixels, state->height * state->densityPixels);
    ZoomTextFadeNewLayer(bounds); // 新建图层实现文字渐影颜色混合滤波
    ZoomScaleScaleNewLayer(bounds); // 新建图层实现焦圈缩放颜色混合滤波
    
    if (state->scaleAllMatteScale > LAYER_OPT_8) {
        OH_Drawing_PathReset(tShadowPath_); // 重置各段Path路径
    }
    OH_Drawing_PathReset(tOuterLinePath_);
    OH_Drawing_PathReset(tShortLinePath_);
    OH_Drawing_PathReset(tQuickLinePath_);
    return bounds;
}

void NativeNode::GenerateAllScalePaths()
{
    for (int i = 0; i < ZOOM_SCALE_COUNT; i++) {
        float curDotAngle = state->curZoomAngle + i * SCALE_GAP_ANGLE; // 当前刻度对应角度
        if (curDotAngle > HALF_SCALE_DRAW_COUNT * SCALE_GAP_ANGLE &&
            curDotAngle < (DRAW_ARC_SWEEP_ANGLE - HALF_SCALE_DRAW_COUNT * SCALE_GAP_ANGLE)) {
            continue; // 绘制性能优化
        }

        // 光学变焦点index,-1代表非光学变焦点
        int selectedOpticalIndex = -1;
        if (state->opticalArrLength > 0 && state->opticalZoomDotIndexArr != nullptr) {
            selectedOpticalIndex =
                ZoomCalculate::FindArrayIndex(state->opticalZoomDotIndexArr, i, state->opticalArrLength);
        }
        bool isCycleClickZoom =
            selectedOpticalIndex != -1 && state->opticalZoomValArr != nullptr
                ? IsZoomValInCycleClickZoom(GetZoomState(), state->opticalZoomValArr[selectedOpticalIndex])
                : false;
        if (state->opticalArrLength > 0 && state->opticalZoomDotIndexArr != nullptr &&
            i <= state->opticalZoomDotIndexArr[state->opticalArrLength - 1]) { // 仅实体点绘制刻度阴影
            if (state->scaleAllMatteScale > LAYER_OPT_8) {
                GeneratePathByPenParam(tShadowPath_, curDotAngle, selectedOpticalIndex, i, state->opticalArrLength);
            }
            GeneratePathByPenParam(selectedOpticalIndex == -1 || isCycleClickZoom ?
                                   tShortLinePath_ : tQuickLinePath_, curDotAngle,
                                   isCycleClickZoom ? -1 : selectedOpticalIndex, i, state->opticalArrLength);
        } else {
            GeneratePathByPenParam(tOuterLinePath_, curDotAngle, selectedOpticalIndex, i, state->opticalArrLength);
        }
        
        if (selectedOpticalIndex != -1 && state->opticalZoomValArr != nullptr) { // 变焦字符、等效焦距绘制
            DrawRatioTextAndShadow(curDotAngle, selectedOpticalIndex);
        }
    }
}

void NativeNode::FinalizeDraw(OH_Drawing_Rect *bounds)
{
    if (state->scaleAllMatteScale > LAYER_OPT_8) {
        DrawZoomShadow(tShadowPath_); // 焦圈阴影绘制
    }
    DrawZoomScale(tOuterLinePath_, tShortLinePath_, tQuickLinePath_); // 变焦刻度绘制
    ZoomScaleScaleSourceAnim(); // 焦圈缩放源数据执行动效
    ZoomTextFadeSourceAnim(); // 文字渐影源数据执行动效
    OH_Drawing_RectDestroy(bounds);
    DrawRedLineTextAndShadow(); // 焦圈中心刻度绘制
}

/**
 * 上述public方法，下述具体绘制方法
 */

/**
 * 新增文字渐影动效图层
 */
void NativeNode::ZoomTextFadeNewLayer(OH_Drawing_Rect *bounds)
{
    OH_Drawing_CanvasSave(cCanvas_);
    OH_Drawing_CanvasSaveLayer(cCanvas_, bounds, nullptr); // 新建图层实现文字渐影颜色混合滤波
}

/**
 * 新增焦圈缩放动效图层
 */
void NativeNode::ZoomScaleScaleNewLayer(OH_Drawing_Rect *bounds)
{
    if (state->animType == 0 || state->carmenLineMatteScale != 1) { // 性能优化
        return;
    }
    OH_Drawing_CanvasSave(cCanvas_);
    OH_Drawing_CanvasSaveLayer(cCanvas_, bounds, nullptr); // 新建图层实现焦圈缩放颜色混合滤波
}

/**
 * 焦圈缩放动效绘制
 */
void NativeNode::ZoomScaleScaleSourceAnim()
{
    if (state->animType == 0 || state->carmenLineMatteScale == 1) { // 性能优化
        return;
    }
    OH_Drawing_PenReset(cScaleAllPen_);
    OH_Drawing_PenSetWidth(cScaleAllPen_,
                           (state->collapsStatus == 0 ? SCALE_ALL_SCALE_WIDTH : LANDSCAPE_SCALE_ALL_SCALE_WIDTH) *
                               state->densityPixels);
    OH_Drawing_PenSetColor(cScaleAllPen_,
                           OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->scaleAllMatteScale, COLOR_CHANNEL_MAX,
                                                   COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX)); // 焦圈不透明度
    OH_Drawing_Point *tScaleAllPoint_ = OH_Drawing_PointCreate(
        state->width / DIVIDE_BY_TWO * state->densityPixels,
        (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->redLineTopRadius) * state->densityPixels);
    uint32_t tScaleAllColors[] = {0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0xFFFFFFFF, 0x00FFFFFF, 0x00FFFFFF};
    float tScaleAllPos[] = {0,
                            SCALE_SHADER_POS_LEFT,
                            float(SCALE_SHADER_POS_TOP - SCALE_SHADER_POS_LR_GAP * state->carmenLineMatteScale),
                            SCALE_SHADER_POS_TOP,
                            float(SCALE_SHADER_POS_TOP + SCALE_SHADER_POS_LR_GAP * state->carmenLineMatteScale),
                            1};

    OH_Drawing_ShaderEffect *tScaleAllShaderEffect_ = OH_Drawing_ShaderEffectCreateSweepGradient(
        tScaleAllPoint_, tScaleAllColors, tScaleAllPos, sizeof(tScaleAllPos) / sizeof(tScaleAllPos[0]),
        OH_Drawing_TileMode::MIRROR);
    OH_Drawing_PenSetShaderEffect(cScaleAllPen_, tScaleAllShaderEffect_);
    OH_Drawing_PenSetBlendMode(cScaleAllPen_, OH_Drawing_BlendMode::BLEND_MODE_MODULATE);

    OH_Drawing_Rect *tScaleAllRect_ = OH_Drawing_RectCreate(
        (state->width / DIVIDE_BY_TWO - state->redLineTopRadius - LONG_CURVE_CENTER_2_RED_LINE_TOP) *
            state->densityPixels,
        (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->spherePosition) *
            state->densityPixels, // 光球位移
        (state->width / DIVIDE_BY_TWO + state->redLineTopRadius + LONG_CURVE_CENTER_2_RED_LINE_TOP) *
            state->densityPixels,
        (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->redLineTopRadius * MULTIPLY_BY_TWO +
         state->spherePosition) *
            state->densityPixels); // 光球位移

    OH_Drawing_CanvasAttachPen(cCanvas_, cScaleAllPen_);
    OH_Drawing_CanvasDrawArc(cCanvas_, tScaleAllRect_, 0, DRAW_ARC_SWEEP_ANGLE);
    OH_Drawing_CanvasDetachPen(cCanvas_);

    OH_Drawing_PointDestroy(tScaleAllPoint_);
    OH_Drawing_ShaderEffectDestroy(tScaleAllShaderEffect_);
    OH_Drawing_RectDestroy(tScaleAllRect_);

    OH_Drawing_CanvasRestore(cCanvas_);
    OH_Drawing_CanvasSave(cCanvas_);
}

/**
 * 文字渐影动效绘制
 */
void NativeNode::ZoomTextFadeSourceAnim()
{
    OH_Drawing_BrushReset(cZoomTextFadeBrush_);
    if (state->scaleAllMatteScale > LAYER_OPT_8) {
        OH_Drawing_BrushSetAntiAlias(cZoomTextFadeBrush_, true);
    }
    OH_Drawing_BrushSetColor(cZoomTextFadeBrush_, 0xFFFF00FF);
    double textFadeTopPositionY =
        state->redLineTopY + RED_LINE_HEIGHT + state->redFadeRotateOffsetY + state->spherePosition;

    OH_Drawing_Point *tStartPt_ = OH_Drawing_PointCreate(
        (state->width / DIVIDE_BY_TWO - TEXT_FADE_HALF_WIDTH) * state->densityPixels,
        (textFadeTopPositionY + TEXT_FADE_HEIGHT_START) * state->densityPixels);
    OH_Drawing_Point *tEndPt_ = ZoomCalculate::getIsTextParallel2CarmenLine(GetZoomState()) ?
        OH_Drawing_PointCreate(
            (state->width / DIVIDE_BY_TWO + TEXT_FADE_HALF_WIDTH) * state->densityPixels,
            (textFadeTopPositionY + TEXT_FADE_HEIGHT_START) * state->densityPixels) :
        OH_Drawing_PointCreate(
            (state->width / DIVIDE_BY_TWO - TEXT_FADE_HALF_WIDTH) * state->densityPixels,
            (textFadeTopPositionY + LANDSCAPE_TEXT_FADE_HALF_WIDTH) * state->densityPixels);
    
    uint32_t zoomTextFadeColors[] = {0xFFFFFFFF, 0X00FFFFFF, 0X00FFFFFF, 0XFFFFFFFF};
    float zoomTextFadePos[] = {0, TEXT_FADE_LEFT_TRANSITION, TEXT_FADE_RIGHT_TRANSITION, 1};
    OH_Drawing_ShaderEffect *shaderEffect = OH_Drawing_ShaderEffectCreateLinearGradient(
        tStartPt_, tEndPt_, zoomTextFadeColors, zoomTextFadePos, sizeof(zoomTextFadePos) / sizeof(zoomTextFadePos[0]),
        OH_Drawing_TileMode::REPEAT);

    OH_Drawing_BrushSetShaderEffect(cZoomTextFadeBrush_, shaderEffect);
    OH_Drawing_BrushSetBlendMode(cZoomTextFadeBrush_, OH_Drawing_BlendMode::BLEND_MODE_SRC_IN);
    int zoomTextFadeRectY2 = ZoomCalculate::getIsTextParallel2CarmenLine(GetZoomState())
                                 ? TEXT_FADE_HEIGHT_END
                                 : LANDSCAPE_TEXT_FADE_HALF_WIDTH;

    OH_Drawing_Rect *tZoomTextFadeRect_ = OH_Drawing_RectCreate(
        (state->width / DIVIDE_BY_TWO - TEXT_FADE_HALF_WIDTH) * state->densityPixels,
        (textFadeTopPositionY + TEXT_FADE_HEIGHT_START) * state->densityPixels,
        (state->width / DIVIDE_BY_TWO + TEXT_FADE_HALF_WIDTH) * state->densityPixels,
        (textFadeTopPositionY + zoomTextFadeRectY2) * state->densityPixels);

    OH_Drawing_CanvasRotate(
        cCanvas_, state->directionAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
        (textFadeTopPositionY + zoomTextFadeRectY2 / DIVIDE_BY_TWO) * state->densityPixels);
    OH_Drawing_CanvasAttachBrush(cCanvas_, cZoomTextFadeBrush_);
    OH_Drawing_CanvasDrawRect(cCanvas_, tZoomTextFadeRect_);
    OH_Drawing_CanvasDetachBrush(cCanvas_);
    OH_Drawing_CanvasRotate(
        cCanvas_, -state->directionAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
        (textFadeTopPositionY + zoomTextFadeRectY2 / DIVIDE_BY_TWO) * state->densityPixels);

    OH_Drawing_PointDestroy(tStartPt_);
    OH_Drawing_PointDestroy(tEndPt_);
    OH_Drawing_RectDestroy(tZoomTextFadeRect_);

    OH_Drawing_CanvasRestore(cCanvas_);
    OH_Drawing_CanvasSave(cCanvas_);
}


/**
 * 职责：顶部卡门线及光晕绘制
 */
void NativeNode::DrawLongCurveAndShadow()
{
    // 弧线阴影绘制
    OH_Drawing_BrushReset(cLongCurveShadowBrush_);
    OH_Drawing_BrushSetColor(cLongCurveShadowBrush_, OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX,
                                                                             COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX));

    OH_Drawing_Filter *tLongCurveFilter_ = OH_Drawing_FilterCreate();
    OH_Drawing_MaskFilter *tLongCurveMaskFilter_ =
        OH_Drawing_MaskFilterCreateBlur(OH_Drawing_BlurType::OUTER, CARMEN_MASK_FILTER_SIGMA, true);
    OH_Drawing_FilterSetMaskFilter(tLongCurveFilter_, tLongCurveMaskFilter_);
    OH_Drawing_BrushSetFilter(cLongCurveShadowBrush_, tLongCurveFilter_);

    DrawCarmenHalo(cLongCurveShadowBrush_,
                   OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->carmenLineOpacity, COLOR_CHANNEL_MAX,
                                           COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX));

    // 长圆弧绘制
    OH_Drawing_PenReset(cLongCurvePen_);
    OH_Drawing_PenSetAntiAlias(cLongCurvePen_, true);
    OH_Drawing_PenSetWidth(cLongCurvePen_, LONG_CURVE_WIDTH * state->densityPixels);
    OH_Drawing_PenSetColor(cLongCurvePen_,
                           OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->carmenLineOpacity, COLOR_CHANNEL_MAX,
                                                   COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX)); // 卡门线不透明度

    DrawCarmenCurve(cLongCurvePen_, 0xFFFFFFFF);

    OH_Drawing_MaskFilterDestroy(tLongCurveMaskFilter_);
    OH_Drawing_FilterDestroy(tLongCurveFilter_);
}

/**
 * 卡门线光晕绘制
 */
void NativeNode::DrawCarmenHalo(OH_Drawing_Brush *cCurveBrush_, uint32_t topColor)
{
    OH_Drawing_Point *tLongCurvePoint_ = OH_Drawing_PointCreate(
        state->width / DIVIDE_BY_TWO * state->densityPixels,
        (state->redLineTopY - (LONG_CURVE_CENTER_2_RED_LINE_TOP - LONG_CURVE_WIDTH / DIVIDE_BY_TWO) +
         state->redLineTopRadius) *
            state->densityPixels);
    uint32_t tLongCurveColors[] = {0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, topColor, 0x00FFFFFF, 0x00FFFFFF};
    float tLongCurvePos[] = {
        0,
        CARMEN_SHADER_POS_LEFT,
        float(CARMEN_SHADER_POS_TOP - CARMEN_SHADER_POS_LR_GAP * (state->animType == 1 ? state->longCurveHaloMatteScale
                                                                                       : state->carmenLineMatteScale)),
        CARMEN_SHADER_POS_TOP,
        float(CARMEN_SHADER_POS_TOP + CARMEN_SHADER_POS_LR_GAP * (state->animType == 1 ? state->longCurveHaloMatteScale
                                                                                       : state->carmenLineMatteScale)),
        1};

    OH_Drawing_ShaderEffect *tShaderEffect_ = OH_Drawing_ShaderEffectCreateSweepGradient(
        tLongCurvePoint_, tLongCurveColors, tLongCurvePos, sizeof(tLongCurvePos) / sizeof(tLongCurvePos[0]),
        OH_Drawing_TileMode::MIRROR);
    OH_Drawing_BrushSetShaderEffect(cCurveBrush_, tShaderEffect_);

    OH_Drawing_Rect *tLongCurveRect_ = OH_Drawing_RectCreate(
        (state->width / DIVIDE_BY_TWO - state->redLineTopRadius -
         (LONG_CURVE_CENTER_2_RED_LINE_TOP - LONG_CURVE_WIDTH / DIVIDE_BY_TWO)) *
            state->densityPixels,
        (state->redLineTopY - (LONG_CURVE_CENTER_2_RED_LINE_TOP - LONG_CURVE_WIDTH / DIVIDE_BY_TWO) +
         state->spherePosition) *
            state->densityPixels, // 光球位移
        (state->width / DIVIDE_BY_TWO + state->redLineTopRadius +
         (LONG_CURVE_CENTER_2_RED_LINE_TOP - LONG_CURVE_WIDTH / DIVIDE_BY_TWO)) *
            state->densityPixels,
        (state->redLineTopY - (LONG_CURVE_CENTER_2_RED_LINE_TOP - LONG_CURVE_WIDTH / DIVIDE_BY_TWO) +
         state->redLineTopRadius * MULTIPLY_BY_TWO + state->spherePosition) *
            state->densityPixels); // 光球位移

    OH_Drawing_CanvasAttachBrush(cCanvas_, cCurveBrush_);
    OH_Drawing_CanvasDrawArc(cCanvas_, tLongCurveRect_, 0, DRAW_ARC_SWEEP_ANGLE);
    OH_Drawing_CanvasDetachBrush(cCanvas_);

    OH_Drawing_PointDestroy(tLongCurvePoint_);
    OH_Drawing_ShaderEffectDestroy(tShaderEffect_);
    OH_Drawing_RectDestroy(tLongCurveRect_);
}

/**
 * 卡门线形状绘制
 */
void NativeNode::DrawCarmenCurve(OH_Drawing_Pen *cCurvePen_, uint32_t topColor)
{
    OH_Drawing_Point *tLongCurvePoint_ = OH_Drawing_PointCreate(
        state->width / DIVIDE_BY_TWO * state->densityPixels,
        (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->redLineTopRadius) * state->densityPixels);
    uint32_t tLongCurveColors[] = {0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, topColor, 0x00FFFFFF, 0x00FFFFFF};
    float tLongCurvePos[] = {0,
                             CARMEN_SHADER_POS_LEFT,
                             float(CARMEN_SHADER_POS_TOP - CARMEN_SHADER_POS_LR_GAP * state->carmenLineMatteScale),
                             CARMEN_SHADER_POS_TOP,
                             float(CARMEN_SHADER_POS_TOP + CARMEN_SHADER_POS_LR_GAP * state->carmenLineMatteScale),
                             1};

    OH_Drawing_ShaderEffect *tShaderEffect_ = OH_Drawing_ShaderEffectCreateSweepGradient(
        tLongCurvePoint_, tLongCurveColors, tLongCurvePos, sizeof(tLongCurvePos) / sizeof(tLongCurvePos[0]),
        OH_Drawing_TileMode::MIRROR);
    OH_Drawing_PenSetShaderEffect(cCurvePen_, tShaderEffect_);

    OH_Drawing_Rect *tLongCurveRect_ = OH_Drawing_RectCreate(
        (state->width / DIVIDE_BY_TWO - state->redLineTopRadius - LONG_CURVE_CENTER_2_RED_LINE_TOP) *
            state->densityPixels,
        (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->spherePosition) *
            state->densityPixels, // 光球位移
        (state->width / DIVIDE_BY_TWO + state->redLineTopRadius + LONG_CURVE_CENTER_2_RED_LINE_TOP) *
            state->densityPixels,
        (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->redLineTopRadius * MULTIPLY_BY_TWO +
         state->spherePosition) *
            state->densityPixels); // 光球位移

    OH_Drawing_CanvasAttachPen(cCanvas_, cCurvePen_);
    OH_Drawing_CanvasDrawArc(cCanvas_, tLongCurveRect_, 0, DRAW_ARC_SWEEP_ANGLE);
    OH_Drawing_CanvasDetachPen(cCanvas_);

    OH_Drawing_PointDestroy(tLongCurvePoint_);
    OH_Drawing_ShaderEffectDestroy(tShaderEffect_);
    OH_Drawing_RectDestroy(tLongCurveRect_);
}

/**
 * 顶部光球及光球-光晕绘制
 */
void NativeNode::DrawPhotoSphereAndShadow()
{
    // 光球发光效果绘制
    OH_Drawing_BrushReset(cPhotoSphereShadowBrush_);
    OH_Drawing_BrushSetColor(cPhotoSphereShadowBrush_, OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX,
                                                                               COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX));

    OH_Drawing_Filter *tPhotoSphereFilter_ = OH_Drawing_FilterCreate();
    OH_Drawing_MaskFilter *tPhotoSphereMaskFilter_ =
        OH_Drawing_MaskFilterCreateBlur(OH_Drawing_BlurType::OUTER, PHOTOSPHERE_MASK_FILTER_SIGMA, true);
    OH_Drawing_FilterSetMaskFilter(tPhotoSphereFilter_, tPhotoSphereMaskFilter_);
    OH_Drawing_BrushSetFilter(cPhotoSphereShadowBrush_, tPhotoSphereFilter_);

    OH_Drawing_Point *tPhotoSphereShaderPoint_ =
        OH_Drawing_PointCreate(state->width / DIVIDE_BY_TWO * state->densityPixels,
                               (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->spherePosition) *
                                   state->densityPixels); // 光球位移

    OH_Drawing_CanvasAttachBrush(cCanvas_, cPhotoSphereShadowBrush_);
    OH_Drawing_CanvasDrawCircle(cCanvas_, tPhotoSphereShaderPoint_,
                                PHOTOSPHERE_RADIUS * state->densityPixels * state->sphereScale); // 光球scale
    OH_Drawing_CanvasDetachBrush(cCanvas_);

    // 光球本体
    OH_Drawing_BrushReset(cPhotoSphereBrush_);
    if (state->scaleAllMatteScale > LAYER_OPT_8) {
        OH_Drawing_BrushSetAntiAlias(cPhotoSphereBrush_, true);
    }
    OH_Drawing_BrushSetColor(
        cPhotoSphereBrush_,
        OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX,
                                (COLOR_CHANNEL_MAX - PHOTOSPHERE_COLOR_RED_CHANNEL) * state->sphereColor +
                                    PHOTOSPHERE_COLOR_RED_CHANNEL,
                                (COLOR_CHANNEL_MAX - PHOTOSPHERE_COLOR_GREEN_CHANNEL) * state->sphereColor +
                                    PHOTOSPHERE_COLOR_GREEN_CHANNEL,
                                (COLOR_CHANNEL_MAX - PHOTOSPHERE_COLOR_BLUE_CHANNEL) * state->sphereColor +
                                    PHOTOSPHERE_COLOR_BLUE_CHANNEL)); // 光球color

    OH_Drawing_Point *tPhotoSpherePoint_ =
        OH_Drawing_PointCreate(state->width / DIVIDE_BY_TWO * state->densityPixels,
                               (state->redLineTopY - LONG_CURVE_CENTER_2_RED_LINE_TOP + state->spherePosition) *
                                   state->densityPixels); // 光球位移

    OH_Drawing_CanvasAttachBrush(cCanvas_, cPhotoSphereBrush_);
    OH_Drawing_CanvasDrawCircle(cCanvas_, tPhotoSpherePoint_,
                                PHOTOSPHERE_RADIUS * state->densityPixels * state->sphereScale); // 光球scale
    OH_Drawing_CanvasDetachBrush(cCanvas_);

    OH_Drawing_FilterDestroy(tPhotoSphereFilter_);
    OH_Drawing_MaskFilterDestroy(tPhotoSphereMaskFilter_);
    OH_Drawing_PointDestroy(tPhotoSphereShaderPoint_);

    OH_Drawing_PointDestroy(tPhotoSpherePoint_);
}

/**
 * 按画笔参数维度执行path生成
 */
void NativeNode::GeneratePathByPenParam(OH_Drawing_Path *tPath_, float curDotAngle, int selectedOpticalIndex, int index,
                                        int opticalZoomLength)
{
    float outerX = state->width / DIVIDE_BY_TWO * state->densityPixels +
                   state->redLineTopRadius * sin(curDotAngle * M_PI / ANGLE_CONVERSION) * state->densityPixels;
    float outerY = state->redLineTopY * state->densityPixels +
                   state->spherePosition * state->densityPixels + // 光球位移
                   state->redLineTopRadius * (1 - cos(curDotAngle * M_PI / ANGLE_CONVERSION)) * state->densityPixels;

    float innerX = state->width / DIVIDE_BY_TWO * state->densityPixels +
                   (state->redLineTopRadius - (selectedOpticalIndex == -1 ? SHORT_LINE_HEIGHT : QUICK_LINE_HEIGHT)) *
                       sin(curDotAngle * M_PI / ANGLE_CONVERSION) * state->densityPixels;
    float innerY = state->redLineTopY * state->densityPixels + state->redLineTopRadius * state->densityPixels +
                   state->spherePosition * state->densityPixels - // 光球位移
                   (state->redLineTopRadius - (selectedOpticalIndex == -1 ? SHORT_LINE_HEIGHT : QUICK_LINE_HEIGHT)) *
                       cos(curDotAngle * M_PI / ANGLE_CONVERSION) * state->densityPixels;

    OH_Drawing_PathMoveTo(tPath_, outerX, outerY);
    OH_Drawing_PathLineTo(tPath_, innerX, innerY);
}

/**
 * 焦圈阴影绘制
 */
void NativeNode::DrawZoomShadow(OH_Drawing_Path *tShadowPath_)
{
    OH_Drawing_PenReset(cZoomScaleShadowPen_);
    OH_Drawing_PenSetWidth(cZoomScaleShadowPen_, SCALE_SHADOW_WIDTH * state->densityPixels);
    OH_Drawing_PenSetColor(cZoomScaleShadowPen_, OH_Drawing_ColorSetArgb(SCALE_SHADOW_OPACITY * state->scaleAllOpacity,
                                                                         0, 0, 0)); // 阴影-焦圈不透明度
    OH_Drawing_Filter *tZoomScaleFilter_ = OH_Drawing_FilterCreate();
    OH_Drawing_MaskFilter *tZoomScaleMaskFilter_ = OH_Drawing_MaskFilterCreateBlur(OUTER, 2, true);
    OH_Drawing_FilterSetMaskFilter(tZoomScaleFilter_, tZoomScaleMaskFilter_);
    OH_Drawing_PenSetFilter(cZoomScaleShadowPen_, tZoomScaleFilter_);

    OH_Drawing_CanvasAttachPen(cCanvas_, cZoomScaleShadowPen_);
    OH_Drawing_CanvasDrawPath(cCanvas_, tShadowPath_);
    OH_Drawing_CanvasDetachPen(cCanvas_);
    
    OH_Drawing_FilterDestroy(tZoomScaleFilter_);
    OH_Drawing_MaskFilterDestroy(tZoomScaleMaskFilter_);
}

/**
 * 变焦刻度绘制
 */
void NativeNode::DrawZoomScale(OH_Drawing_Path *tOuterLinePath_, OH_Drawing_Path *tShortLinePath_,
                               OH_Drawing_Path *tQuickLinePath_)
{
    OH_Drawing_PenReset(cZoomScalePen_);
    OH_Drawing_PenSetWidth(cZoomScalePen_, SHORT_LINE_WIDTH * state->densityPixels);
    if (state->scaleAllMatteScale > LAYER_OPT_8) {
        OH_Drawing_PenSetAntiAlias(cZoomScalePen_, true);
    }
    OH_Drawing_PenSetColor(cZoomScalePen_,
                           OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->scaleAllOpacity * SCALE_OUTER_OPACITY,
                                                   COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX,
                                                   COLOR_CHANNEL_MAX)); // 虚点-焦圈不透明度
    OH_Drawing_CanvasAttachPen(cCanvas_, cZoomScalePen_);
    OH_Drawing_CanvasDrawPath(cCanvas_, tOuterLinePath_);
    OH_Drawing_CanvasDetachPen(cCanvas_);

    OH_Drawing_PenSetColor(
        cZoomScalePen_, OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->scaleAllOpacity * SCALE_SHORT_LINE_OPACITY,
                                                COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX,
                                                COLOR_CHANNEL_MAX)); // 非关键刻度-焦圈不透明度
    OH_Drawing_CanvasAttachPen(cCanvas_, cZoomScalePen_);
    OH_Drawing_CanvasDrawPath(cCanvas_, tShortLinePath_);
    OH_Drawing_CanvasDetachPen(cCanvas_);

    OH_Drawing_PenSetWidth(cZoomScalePen_, QUICK_LINE_WIDTH * state->densityPixels);
    OH_Drawing_PenSetColor(
        cZoomScalePen_, OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->scaleAllOpacity * SCALE_QUICK_LINE_OPACITY,
                                                COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX,
                                                COLOR_CHANNEL_MAX)); // 光学变焦点-焦圈不透明度
    OH_Drawing_CanvasAttachPen(cCanvas_, cZoomScalePen_);
    OH_Drawing_CanvasDrawPath(cCanvas_, tQuickLinePath_);
    OH_Drawing_CanvasDetachPen(cCanvas_);
}

/**
 * 变焦刻度Ratio、等效焦距文字及阴影绘制
 */
void NativeNode::DrawRatioTextAndShadow(float curDotAngle, int selectedOpticalIndex)
{
    int diff = ZoomCalculate::getFocalIndexDiff(GetZoomState(), state->opticalZoomValArr[selectedOpticalIndex],
                                                state->littlePointCnt);
    int quickLength = (state->isSupportedEquivalentFocalBigText || state->isSupportedCycleClickZoom)
    ? (state->quickArrLength + diff) : state->quickArrLength;
    OH_Drawing_CanvasSave(cCanvas_);
    // 扇形旋转
    OH_Drawing_CanvasRotate(cCanvas_, curDotAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
                            (state->redLineTopY + state->redLineTopRadius) * state->densityPixels);
    // 横竖屏旋转
    OH_Drawing_CanvasRotate(
        cCanvas_, state->directionAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
        (state->redLineTopY + RED_LINE_HEIGHT + LANDSCAPE_TEXT_OFFSET_Y +
         (selectedOpticalIndex < quickLength &&
                  !ZoomCalculate::isLittlePoint(GetZoomState(), state->opticalZoomValArr[selectedOpticalIndex], diff)
              ? state->rotateOffsetY
              : 0) +
         state->spherePosition) *
            state->densityPixels);

    // 定义并申请变焦刻度Ratio字体相关操作
    NativeNode::DrawZoomTextAndShadow(selectedOpticalIndex, diff);

    // 定义并申请等效焦距字体相关操作

    if (selectedOpticalIndex < quickLength) {
        NativeNode::DrawEquivalentFocalTextAndShadow(selectedOpticalIndex, curDotAngle, diff);
    }

    OH_Drawing_CanvasRotate(
        cCanvas_, -state->directionAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
        (state->redLineTopY + RED_LINE_HEIGHT + LANDSCAPE_TEXT_OFFSET_Y +
         (selectedOpticalIndex < quickLength &&
                  !ZoomCalculate::isLittlePoint(GetZoomState(), state->opticalZoomValArr[selectedOpticalIndex], diff)
              ? state->rotateOffsetY
              : 0) +
         state->spherePosition) *
            state->densityPixels);

    OH_Drawing_CanvasRotate(cCanvas_, -curDotAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
                            (state->redLineTopY + state->redLineTopRadius) * state->densityPixels);
}

/**
 * ZoomRatio文字及阴影绘制
 */
void NativeNode::DrawZoomTextAndShadow(int selectedOpticalIndex, int diff)
{
    double roundZoomVal = state->opticalZoomValArr[selectedOpticalIndex];
    bool isLittle = ZoomCalculate::isLittlePoint(GetZoomState(), roundZoomVal, diff);
    roundZoomVal = floor(state->opticalZoomValArr[selectedOpticalIndex] * MULTIPLY_BY_TEN) / DIVIDE_BY_TEN;
    if (roundZoomVal == floor(state->opticalZoomValArr[selectedOpticalIndex])) {
        roundZoomVal = floor(state->opticalZoomValArr[selectedOpticalIndex]);
    }
    std::stringstream ss;
    ss << roundZoomVal;
    std::string tempStr = isLittle ? "·"
                                   : (state->opticalZoomValArr[selectedOpticalIndex] <= state->opticalMaxZoomVarW
                                          ? "W" : (ss.str() + "x")); // 避免前置第二个焦段
    OH_Drawing_Typography *mTypography_ = GetTypography(
        tempStr, TEXT_MAX_WIDTH, isLittle ? EQU_FOCAL_OPACITY * state->scaleAllOpacity : state->scaleAllOpacity, false,
        ZOOM_RATIO_FONT);

    OH_Drawing_Filter *tRatioTextFilter_;
    OH_Drawing_MaskFilter *tRatioTextMaskFilter_;
    if (state->scaleAllMatteScale > LAYER_OPT_6) {
        OH_Drawing_PenReset(cRatioTextPen_);
        OH_Drawing_PenSetWidth(cRatioTextPen_, TEXT_PEN_WIDTH);
        OH_Drawing_PenSetJoin(cRatioTextPen_, LINE_ROUND_JOIN);
        OH_Drawing_PenSetColor(cRatioTextPen_,
                               OH_Drawing_ColorSetArgb(TEXT_COLOR_OPACITY * state->scaleAllOpacity, 0, 0, 0)); // 焦圈不透明度
        
        tRatioTextFilter_ = OH_Drawing_FilterCreate();
        tRatioTextMaskFilter_ = OH_Drawing_MaskFilterCreateBlur(OUTER, RATIO_TEXT_MASK_FILTER_SIGMA, true);
        OH_Drawing_FilterSetMaskFilter(tRatioTextFilter_, tRatioTextMaskFilter_);
        OH_Drawing_PenSetFilter(cRatioTextPen_, tRatioTextFilter_);
    }
    double *position = new double[ARRAY_TWO];
    position[ARRAY_ZERO] = (state->width / DIVIDE_BY_TWO) * state->densityPixels - TEXT_MAX_WIDTH / DIVIDE_BY_TWO;
    position[ARRAY_ONE] = (state->redLineTopY + RED_LINE_HEIGHT + state->rotateOffsetY + state->spherePosition) *
                          state->densityPixels; // 光球位移
    if (IsZoomValInCycleClickZoom(GetZoomState(), roundZoomVal)) {
        SetCycleClickZoomPenAttribute(position[ARRAY_ZERO], position[ARRAY_ONE]);
    } else {
        if (state->scaleAllMatteScale > LAYER_OPT_6) {
            OH_Drawing_CanvasAttachPen(cCanvas_, cRatioTextPen_);
        }
        OH_Drawing_TypographyPaint(mTypography_, cCanvas_, position[ARRAY_ZERO], position[ARRAY_ONE]);
        if (state->scaleAllMatteScale > LAYER_OPT_6) {
            OH_Drawing_CanvasDetachPen(cCanvas_);
        }
    }

    delete[] position;
    OH_Drawing_DestroyTypography(mTypography_);
    if (state->scaleAllMatteScale > LAYER_OPT_6) {
        OH_Drawing_FilterDestroy(tRatioTextFilter_);
        OH_Drawing_MaskFilterDestroy(tRatioTextMaskFilter_);
    }
}

/**
 * 变焦等效焦距文字及阴影绘制
 */
void NativeNode::SetOpticalTextPenAttribute() {
    OH_Drawing_PenReset(cOpticalTextPen_);
    OH_Drawing_PenSetWidth(cOpticalTextPen_, EQU_TEXT_PEN_WIDTH);
    OH_Drawing_PenSetJoin(cOpticalTextPen_, LINE_ROUND_JOIN);
    OH_Drawing_PenSetColor(cOpticalTextPen_,
                           OH_Drawing_ColorSetArgb(TEXT_COLOR_OPACITY * state->scaleAllOpacity, 0, 0, 0));
}
/**
 * 循环点切数组对应的小圆点的绘制
 */
void NativeNode::SetCycleClickZoomPenAttribute(float PositionX, float PositionY) {
    if (state->collapsStatus == 0) {
        PositionX = PositionX + DEFAULT_LITTLE_DOT_POSITION_X;
        PositionY = PositionY + DEFAULT_LITTLE_DOT_POSITION_Y;
    } else {
        PositionX = PositionX + LANDSCAPE_LITTLE_DOT_POSITION_X;
        PositionY = PositionY + LANDSCAPE_LITTLE_DOT_POSITION_Y;
    }
    OH_Drawing_Pen *circlePen_ = OH_Drawing_PenCreate();
    OH_Drawing_PenSetWidth(circlePen_, TEXT_PEN_CYCLE_CLICK_WIDTH);
    OH_Drawing_PenSetJoin(circlePen_, LINE_ROUND_JOIN);
    OH_Drawing_PenSetAntiAlias(circlePen_, true);
    OH_Drawing_PenSetColor(circlePen_,
                           OH_Drawing_ColorSetArgb(TEXT_COLOR_OPACITY * state->scaleAllOpacity, 255, 255, 255));
    OH_Drawing_Brush *cPhotoSphereBrush_ = OH_Drawing_BrushCreate();
    OH_Drawing_BrushSetAntiAlias(cPhotoSphereBrush_, true);
    OH_Drawing_BrushSetColor(cPhotoSphereBrush_, OH_Drawing_ColorSetArgb(255, 255, 255, 255));
    OH_Drawing_Point *point_ = OH_Drawing_PointCreate(PositionX, PositionY);

    if (state->scaleAllMatteScale > LAYER_OPT_6) {
        OH_Drawing_CanvasAttachPen(cCanvas_, cRatioTextPen_);
    }
    OH_Drawing_CanvasAttachBrush(cCanvas_, cPhotoSphereBrush_);
    OH_Drawing_CanvasDrawCircle(cCanvas_, point_, TEXT_PEN_CYCLE_CLICK_WIDTH);
    OH_Drawing_CanvasDetachBrush(cCanvas_);

    OH_Drawing_BrushDestroy(cPhotoSphereBrush_);
    OH_Drawing_PenDestroy(circlePen_);
    OH_Drawing_PointDestroy(point_);
}

/**
 * 当前焦距的值是否在循环点切的数组里面
 */
bool NativeNode::IsZoomValInCycleClickZoom(const ZoomStruct *state, double zoomValue) {
    if (!state->isSupportedCycleClickZoom) {
        return false;
    }
    for (int i = 0; i < state->cycleClickZoomLength; i++) {
        if (zoomValue == state->cycleClickZoomValArr[i]) {
            return true;
        }
    }
    return false;
}

void NativeNode::DrawEquivalentFocalTextAndShadow(int selectedOpticalIndex, float curDotAngle, int diff) {
    if ((state->isSupportedEquivalentFocalBigText || state->isSupportedCycleClickZoom) && 
        ZoomCalculate::isIndexLegal(state->opticalArrLength, selectedOpticalIndex)) {
        double roundZoomVal = state->opticalZoomValArr[selectedOpticalIndex];
        if (ZoomCalculate::isLittlePoint(GetZoomState(), roundZoomVal, diff)) {
            return;
        } else if (diff > ARRAY_ZERO) {
            selectedOpticalIndex = selectedOpticalIndex - diff;
        }
    }
    if (!ZoomCalculate::isIndexLegal(state->opticalArrLength, selectedOpticalIndex)) {
        return;
    }
    std::stringstream ss2;
    ss2 << state->quickEquivalentFocalArr[selectedOpticalIndex];
    std::string tempStr2 = ss2.str() + "mm";
    bool isRedFont = curDotAngle >= -SCALE_GAP_ANGLE / DIVIDE_BY_TWO && curDotAngle <= SCALE_GAP_ANGLE / DIVIDE_BY_TWO;

    OH_Drawing_Typography *mTypographyOptical_ =
        GetTypography(tempStr2, TEXT_MAX_WIDTH, isRedFont ? 1 : EQU_FOCAL_OPACITY * state->scaleAllOpacity, isRedFont,
                      EQUIVALENT_FOCAL_FONT);

    OH_Drawing_Filter *tOpticalTextFilter_;
    OH_Drawing_MaskFilter *tOpticalTextMaskFilter_;
    if (state->scaleAllMatteScale > LAYER_OPT_6) {
        SetOpticalTextPenAttribute(); // 焦圈不透明度

        tOpticalTextFilter_ = OH_Drawing_FilterCreate();
        tOpticalTextMaskFilter_ = OH_Drawing_MaskFilterCreateBlur(OUTER, RATIO_TEXT_MASK_FILTER_SIGMA, true);
        OH_Drawing_FilterSetMaskFilter(tOpticalTextFilter_, tOpticalTextMaskFilter_);
        OH_Drawing_PenSetFilter(cOpticalTextPen_, tOpticalTextFilter_);
    }

    double *opticalPos = new double[ARRAY_TWO];
    opticalPos[ARRAY_ZERO] = (state->width / DIVIDE_BY_TWO) * state->densityPixels - TEXT_MAX_WIDTH / DIVIDE_BY_TWO;
    opticalPos[ARRAY_ONE] = (state->redLineTopY + RED_LINE_HEIGHT + state->rotateOffsetY + LANDSCAPE_TEXT_OFFSET_Y +
                             state->spherePosition) *
                            state->densityPixels; // 光球位移

    if (isRedFont || state->scaleAllMatteScale <= LAYER_OPT_6) {
        OH_Drawing_TypographyPaint(mTypographyOptical_, cCanvas_, opticalPos[ARRAY_ZERO], opticalPos[ARRAY_ONE]);
    } else {
        OH_Drawing_CanvasAttachPen(cCanvas_, cOpticalTextPen_);
        OH_Drawing_TypographyPaint(mTypographyOptical_, cCanvas_, opticalPos[ARRAY_ZERO], opticalPos[ARRAY_ONE]);
        OH_Drawing_CanvasDetachPen(cCanvas_);
    }

    delete[] opticalPos;
    OH_Drawing_DestroyTypography(mTypographyOptical_);
    if (state->scaleAllMatteScale > LAYER_OPT_6) {
        OH_Drawing_FilterDestroy(tOpticalTextFilter_);
        OH_Drawing_MaskFilterDestroy(tOpticalTextMaskFilter_);
    }
}

/**
 * 获取字体引擎操作对象
 */
OH_Drawing_Typography *NativeNode::GetTypography(std::string tempStr, int maxWidth, double opacityChannel,
                                                 bool isRedChannel, int fontSize)
{
    OH_Drawing_TypographyStyle *mTypoStyle_ = OH_Drawing_CreateTypographyStyle();
    OH_Drawing_SetTypographyTextAlign(mTypoStyle_, OH_Drawing_TextAlign::TEXT_ALIGN_CENTER); // 文字居中对齐

    OH_Drawing_TextStyle *mTxtStyle_ = OH_Drawing_CreateTextStyle();
    double mFontSize = fontSize * state->densityPixels;
    OH_Drawing_SetTextStyleFontSize(mTxtStyle_, mFontSize);
    OH_Drawing_SetTextStyleFontWeight(mTxtStyle_, TEXT_STYLE_FONT_WEIGHT);
    OH_Drawing_SetTextStyleColor(
        mTxtStyle_, state->isBlueIcon
                        ? OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * opacityChannel,
                                                  isRedChannel ? COLOR_CHANNEL_RED_NOVA : COLOR_CHANNEL_MAX,
                                                  isRedChannel ? COLOR_CHANNEL_GREEN_NOVA : COLOR_CHANNEL_MAX,
                                                  isRedChannel ? COLOR_CHANNEL_BLUE_NOVA : COLOR_CHANNEL_MAX)
                        : OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * opacityChannel, COLOR_CHANNEL_MAX,
                                                  isRedChannel ? 0 : COLOR_CHANNEL_MAX,
                                                  isRedChannel ? 0 : COLOR_CHANNEL_MAX)); // 焦圈不透明度

    OH_Drawing_TextShadow *mTextShadow_ = OH_Drawing_CreateTextShadow();
    OH_Drawing_TextStyleAddShadow(mTxtStyle_, mTextShadow_);

    OH_Drawing_FontCollection *mFontCollection_ = OH_Drawing_CreateFontCollection();
    OH_Drawing_TypographyCreate *mHandler_ = OH_Drawing_CreateTypographyHandler(mTypoStyle_, mFontCollection_);
    OH_Drawing_TypographyHandlerPushTextStyle(mHandler_, mTxtStyle_);
    const char *textStr = tempStr.c_str();
    OH_Drawing_TypographyHandlerAddText(mHandler_, textStr);

    OH_Drawing_Typography *mTypography_ = OH_Drawing_CreateTypography(mHandler_);
    OH_Drawing_TypographyLayout(mTypography_, maxWidth);
    
    OH_Drawing_DestroyTypographyStyle(mTypoStyle_);
    OH_Drawing_DestroyTextStyle(mTxtStyle_);
    OH_Drawing_DestroyTextShadow(mTextShadow_);
    OH_Drawing_DestroyTypographyHandler(mHandler_);
    OH_Drawing_DestroyFontCollection(mFontCollection_);
    return mTypography_;
}

/**
 * 焦圈中心刻度、当前焦距字符、阴影绘制
 */
void NativeNode::DrawRedLineTextAndShadow()
{
    float outerX = state->width / DIVIDE_BY_TWO * state->densityPixels;
    float outerY = state->redLineTopY * state->densityPixels + state->spherePosition * state->densityPixels; // 光球位移
    float innerX = state->width / DIVIDE_BY_TWO * state->densityPixels;
    float innerY = state->redLineTopY * state->densityPixels + state->redLineTopRadius * state->densityPixels +
                   state->spherePosition * state->densityPixels -
                   (state->redLineTopRadius - RED_LINE_HEIGHT) * state->densityPixels; // 光球位移

    // 焦圈中心刻度绘制
    OH_Drawing_PenReset(cRedLinePen_);
    double redLineWidth = RED_LINE_WIDTH * state->densityPixels + RED_LINE_WIDTH_BIAS;
    OH_Drawing_PenSetWidth(cRedLinePen_, redLineWidth);
    // 焦圈中心刻度不透明度
    OH_Drawing_PenSetColor(cRedLinePen_, state->isBlueIcon
        ? OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->redLineAndTextOpacity,
            COLOR_CHANNEL_RED_NOVA, COLOR_CHANNEL_GREEN_NOVA, COLOR_CHANNEL_BLUE_NOVA)
        : OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->redLineAndTextOpacity, COLOR_CHANNEL_MAX, 0, 0));

    OH_Drawing_CanvasAttachPen(cCanvas_, cRedLinePen_);
    outerY = outerY + RED_LINE_CYCLE_RADIUS;
    innerY = innerY - RED_LINE_CYCLE_RADIUS;
    OH_Drawing_CanvasDrawLine(cCanvas_, outerX, outerY, innerX, innerY);
    OH_Drawing_CanvasDetachPen(cCanvas_);
    DrawRedLineCycle(outerX, outerY, innerY, redLineWidth);
    double roundZoomVal = floor(state->curZoomValue * MULTIPLY_BY_TEN) / DIVIDE_BY_TEN;
    if (roundZoomVal == floor(state->curZoomValue)) {
        roundZoomVal = floor(state->curZoomValue);
    }
    std::stringstream ss;
    ss << roundZoomVal;
    std::string tempStr = ZoomCalculate::GetRedText(GetZoomState());
    double maxWidth = TEXT_MAX_WIDTH; // 设置页面最大宽度
    OH_Drawing_Typography *mTypography_ =
        GetTypography(tempStr, maxWidth, state->redLineAndTextOpacity, true, ZOOM_RATIO_FONT);
    
    bool isLandscapeSlideAnim = ZoomCalculate::isLandscapeSlideAnim(GetZoomState());
    // 红色焦距字符绘制
    double position[ARRAY_TWO] = {
        (state->width / DIVIDE_BY_TWO) * state->densityPixels - maxWidth / DIVIDE_BY_TWO,
        (state->redLineTopY + RED_LINE_HEIGHT + state->redTextRotateOffsetY + state->spherePosition -
         (isLandscapeSlideAnim ? state->displacementDistance * RED_TEXT_LANDSCAPE_SLIDE_OFFSET : 0)) *
            state->densityPixels};

    // 横竖屏旋转
    OH_Drawing_CanvasRotate(cCanvas_, state->directionAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
                            (state->redLineTopY + RED_LINE_HEIGHT + LANDSCAPE_TEXT_OFFSET_Y / DIVIDE_BY_TWO +
                             state->redTextRotateOffsetY + state->spherePosition) *
                                state->densityPixels);
    OH_Drawing_TypographyPaint(mTypography_, cCanvas_, position[ARRAY_ZERO], position[ARRAY_ONE]);
    if (isLandscapeSlideAnim) {
        NativeNode::DrawLandscapeSlideSimuEquivalentFocal(); // 横屏滑动关键刻度动效模拟等效焦距
    }
    OH_Drawing_CanvasRotate(cCanvas_, -state->directionAngle, state->width / DIVIDE_BY_TWO * state->densityPixels,
                            (state->redLineTopY + RED_LINE_HEIGHT + LANDSCAPE_TEXT_OFFSET_Y / DIVIDE_BY_TWO +
                             state->redTextRotateOffsetY + state->spherePosition) * state->densityPixels);

    OH_Drawing_DestroyTypography(mTypography_);
}

/**
 * 焦圈中心刻度上下增加圆角
 */
void NativeNode::DrawRedLineCycle(int outerX, int outerY, int innerY, double redLineWidth)
{
    OH_Drawing_Brush *cRedLineCycle_ = OH_Drawing_BrushCreate();
    OH_Drawing_BrushSetAntiAlias(cRedLineCycle_, true);
    OH_Drawing_BrushSetColor(cRedLineCycle_, state->isBlueIcon
        ? OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->redLineAndTextOpacity,
            COLOR_CHANNEL_RED_NOVA, COLOR_CHANNEL_GREEN_NOVA, COLOR_CHANNEL_BLUE_NOVA)
        : OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX * state->redLineAndTextOpacity, COLOR_CHANNEL_MAX, 0, 0));
    OH_Drawing_Point *tRedLineCycle_ =
        OH_Drawing_PointCreate(outerX, outerY); 

    OH_Drawing_CanvasAttachBrush(cCanvas_, cRedLineCycle_);
    OH_Drawing_CanvasDrawCircle(cCanvas_, tRedLineCycle_, redLineWidth / 2); 
    OH_Drawing_CanvasDetachBrush(cCanvas_);
    OH_Drawing_PointDestroy(tRedLineCycle_);
    
    tRedLineCycle_ = OH_Drawing_PointCreate(outerX, innerY); 
    OH_Drawing_CanvasAttachBrush(cCanvas_, cRedLineCycle_);
    OH_Drawing_CanvasDrawCircle(cCanvas_, tRedLineCycle_, redLineWidth / 2); 
    OH_Drawing_CanvasDetachBrush(cCanvas_);

    OH_Drawing_PointDestroy(tRedLineCycle_);
    OH_Drawing_BrushDestroy(cRedLineCycle_);
}
/**
 * 横屏滑动关键刻度动效模拟当前变焦等效焦距
 */
void NativeNode::DrawLandscapeSlideSimuEquivalentFocal()
{
    int index = ResolveLandscapeSlideIndex();
    if (index == INVALID_INDEX) {
        return;
    }
    std::stringstream ss2;
    ss2 << state->quickEquivalentFocalArr[index];
    std::string tempStr2 = ss2.str() + "mm";

    float opacityChannel = state->displacementDistance < DISPLAY_DIST_THRESHOLD ? 0 :
        ((state->displacementDistance - DISPLAY_DIST_THRESHOLD) / (1 - DISPLAY_DIST_THRESHOLD));
    OH_Drawing_Typography *mTypographyOptical_ =
        GetTypography(tempStr2, TEXT_MAX_WIDTH, opacityChannel, true, EQUIVALENT_FOCAL_FONT);

    OH_Drawing_Filter *tOpticalTextFilter_ = nullptr;
    OH_Drawing_MaskFilter *tOpticalTextMaskFilter_ = nullptr;
    SetSimuRedTextPenAttribute(&tOpticalTextFilter_, &tOpticalTextMaskFilter_);

    double *opticalPos = new double[ARRAY_TWO];
    opticalPos[ARRAY_ZERO] = (state->width / DIVIDE_BY_TWO) * state->densityPixels - TEXT_MAX_WIDTH / DIVIDE_BY_TWO;
    opticalPos[ARRAY_ONE] =
        (state->redLineTopY + RED_LINE_HEIGHT + state->rotateOffsetY + LANDSCAPE_TEXT_OFFSET_Y + state->spherePosition +
         (state->curZoomValue == state->opticalZoomValArr[index]
              ? (state->displacementDistance - 1) * SIMU_EQUIVALENT_DISTANCE
              : 0)) *
        state->densityPixels; // 光球位移

    OH_Drawing_CanvasAttachPen(cCanvas_, cSimuRedTextPen_);
    OH_Drawing_TypographyPaint(mTypographyOptical_, cCanvas_, opticalPos[ARRAY_ZERO], opticalPos[ARRAY_ONE]);
    OH_Drawing_CanvasDetachPen(cCanvas_);

    delete[] opticalPos;
    OH_Drawing_DestroyTypography(mTypographyOptical_);
    OH_Drawing_FilterDestroy(tOpticalTextFilter_);
    OH_Drawing_MaskFilterDestroy(tOpticalTextMaskFilter_);
}

int NativeNode::ResolveLandscapeSlideIndex()
{
    int index = state->landscapeSlideZoomIndex;
    if (!ZoomCalculate::isIndexLegal(state->opticalArrLength, state->landscapeSlideZoomIndex) ||
        state->opticalZoomValArr == nullptr) {
        return INVALID_INDEX;
    }
    if ((state->isSupportedEquivalentFocalBigText || state->isSupportedCycleClickZoom)) {
        double roundZoomVal = state->opticalZoomValArr[state->landscapeSlideZoomIndex];
        int diff = ZoomCalculate::getFocalIndexDiff(GetZoomState(), roundZoomVal, state->littlePointCnt);
        if (ZoomCalculate::isLittlePoint(GetZoomState(), roundZoomVal, diff)) {
            return INVALID_INDEX;
        } else if (diff > ARRAY_ZERO) {
            index = index - diff;
        }
    }
    if (!ZoomCalculate::isIndexLegal(state->quickArrLength, index) || state->quickEquivalentFocalArr == nullptr) {
        return INVALID_INDEX;
    }
    return index;
}

void NativeNode::SetSimuRedTextPenAttribute(OH_Drawing_Filter **outFilter, OH_Drawing_MaskFilter **outMaskFilter)
{
    OH_Drawing_PenReset(cSimuRedTextPen_);
    OH_Drawing_PenSetWidth(cSimuRedTextPen_, EQU_TEXT_PEN_WIDTH);
    OH_Drawing_PenSetJoin(cSimuRedTextPen_, LINE_ROUND_JOIN);
    OH_Drawing_PenSetColor(cSimuRedTextPen_,
                           state->isBlueIcon
                               ? OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX, COLOR_CHANNEL_RED_NOVA,
                                                         COLOR_CHANNEL_GREEN_NOVA, COLOR_CHANNEL_BLUE_NOVA)
                               : OH_Drawing_ColorSetArgb(COLOR_CHANNEL_MAX, COLOR_CHANNEL_MAX, 0, 0));

    *outFilter = OH_Drawing_FilterCreate();
    *outMaskFilter = OH_Drawing_MaskFilterCreateBlur(OUTER, RATIO_TEXT_MASK_FILTER_SIGMA, true);
    OH_Drawing_FilterSetMaskFilter(*outFilter, *outMaskFilter);
    OH_Drawing_PenSetFilter(cSimuRedTextPen_, *outFilter);
}
