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

#include "zoom_calculate.h"

#define TAG "zoom_calculate"

/**
 * NativeNode对象初始化; width:预览宽; height:150, zoomHeight; drawHeight:43预览高*16%,刻度盘外侧高; densityPixels:屏幕密度
 */
void ZoomCalculate::NativeInitNode(ZoomStruct *state, float mWidth, float mHeight, double mDrawHeight,
                                   double mDensityPixels)
{
    /*
     * 单位分界点,上述形参、变量定义均单位vp,仅drawing侧计算均需转换为px
     */
    state->width = mWidth;
    state->height = mHeight;
    state->drawHeight = mDrawHeight;
    state->densityPixels = mDensityPixels;
    LOGI(TAG, "NativeInitNode width: %{public}f, height: %{public}f, drawHeight: %{public}f, densityPixels: %{public}f",
         mWidth, mHeight, mDrawHeight, mDensityPixels);
    
    state->redLineTopY = state->height - state->drawHeight; // 红线顶部positionY
    state->redLineTopRadius = (state->width * state->width / DIVIDE_BY_FOUR + state->drawHeight * state->drawHeight) /
                       (DIVIDE_BY_TWO * state->drawHeight); // 红线顶部outer圆半径
}

void ZoomCalculate::NativeMultiAdaptParam(ZoomStruct *state, int32_t mCollapsStatus, int32_t mDirectAngle)
{
    state->collapsStatus = mCollapsStatus;
    ZoomCalculate::UpdateDirectionAngle(state, mDirectAngle);
}

void ZoomCalculate::SetQuickZoomArray(ZoomStruct *state, uint32_t mQuickArrLength, double *mQuickZoomValArr,
                                      int32_t *mQuickEquivalentFocalArr)
{
    state->quickArrLength = mQuickArrLength;
    state->quickZoomValArr = mQuickZoomValArr;
    state->quickEquivalentFocalArr = mQuickEquivalentFocalArr;
    state->quickMaxZoomVarW = (mQuickArrLength > 0 && state->quickZoomValArr[0] > 0 && state->quickZoomValArr[0] < 1)
                                  ? state->quickZoomValArr[0]
                                  : ZOOM_RATIO_79;
}

void ZoomCalculate::SetOpticalZoomArray(ZoomStruct *state, uint32_t mOpticalArrLength, double *mOpticalZoomValArr,
                                        int32_t *mOpticalZoomDotIndexArr)
{
    state->opticalArrLength = mOpticalArrLength;
    state->opticalZoomValArr = mOpticalZoomValArr;
    state->opticalZoomDotIndexArr = mOpticalZoomDotIndexArr;
    state->opticalMaxZoomVarW = (mOpticalArrLength > 0 && mOpticalZoomValArr[0] > 0 && mOpticalZoomValArr[0] < 1)
                             ? state->opticalZoomValArr[0]
                             : ZOOM_RATIO_79;
    state->littlePointCnt = getLittlePotCount(state);
}

void ZoomCalculate::SetCycleClickZoomArray(ZoomStruct *state, uint32_t mCycleClickZoomLength,
                                           double *mCycleClickZoomArr)
{
    state->cycleClickZoomLength = mCycleClickZoomLength;
    state->cycleClickZoomValArr = mCycleClickZoomArr;
    state->littlePointCnt = getLittlePotCount(state);
}

void ZoomCalculate::SetLongCurveHalo(ZoomStruct *state, int32_t mAnimType, double haloMatteScale, double haloOpacity)
{
    state->animType = mAnimType;
    state->longCurveHaloMatteScale = haloMatteScale;
    state->longCurveHaloOpacity = haloOpacity;
}

void ZoomCalculate::SetSphereParam(ZoomStruct *state, double position, double scale, double color, double haloOpacity)
{
    state->spherePosition = position;
    state->sphereScale = scale;
    state->sphereColor = color;
    state->sphereHaloOpacity = haloOpacity;
}

void ZoomCalculate::SetScaleAllParam(ZoomStruct *state, double redOpacity, double matteScale, double allOpacity)
{
    state->redLineAndTextOpacity = redOpacity;
    state->scaleAllMatteScale = matteScale;
    state->scaleAllOpacity = allOpacity;
}

void ZoomCalculate::SetCarmenLine(ZoomStruct *state, double matteScale, double lineOpacity)
{
    state->carmenLineMatteScale = matteScale;
    state->carmenLineOpacity = lineOpacity;
}

/**
 * 更新屏幕横竖屏方向并执行字体旋转动效: 非窗口旋转场景
 */
void ZoomCalculate::UpdateDirectionAngle(ZoomStruct *state, int32_t direct)
{
    state->directionAngle = (direct % DRAW_ARC_SWEEP_ANGLE + DRAW_ARC_SWEEP_ANGLE) % DRAW_ARC_SWEEP_ANGLE;
    
    state->rotateOffsetY = (state->directionAngle % ANGLE_CONVERSION) <= ROTATE_MAPPING_ANGLE
                        ? double(state->directionAngle % ANGLE_CONVERSION) / ROTATE_MAPPING_ANGLE
                        : double(ANGLE_CONVERSION - state->directionAngle % ANGLE_CONVERSION) / ROTATE_MAPPING_ANGLE;
    state->rotateOffsetY *= LANDSCAPE_ROTATE_OFFSET_Y;

    state->redTextRotateOffsetY = state->directionAngle <= ANGLE_CONVERSION
                                      ? state->directionAngle
                                      : DRAW_ARC_SWEEP_ANGLE - state->directionAngle;
    state->redTextRotateOffsetY =
        state->redTextRotateOffsetY <= ROTATE_MAPPING_ANGLE
            ? (double(state->redTextRotateOffsetY) / ROTATE_MAPPING_ANGLE) * LANDSCAPE_RED_ROTATE_OFFSET_Y
            : ((double(state->redTextRotateOffsetY - ROTATE_MAPPING_ANGLE) / ROTATE_MAPPING_ANGLE) *
                   INVERTED_RED_DIFF_OFFSET_Y +
               LANDSCAPE_RED_ROTATE_OFFSET_Y);

    state->redFadeRotateOffsetY = state->directionAngle <= ANGLE_CONVERSION
                                      ? state->directionAngle
                                      : DRAW_ARC_SWEEP_ANGLE - state->directionAngle;
    state->redFadeRotateOffsetY =
        state->redFadeRotateOffsetY <= ROTATE_MAPPING_ANGLE
            ? (double(state->redFadeRotateOffsetY) / ROTATE_MAPPING_ANGLE) * LANDSCAPE_RED_FADE_ROTATE_OFFSET_Y
            : ((double(state->redTextRotateOffsetY - ROTATE_MAPPING_ANGLE) / ROTATE_MAPPING_ANGLE) *
                   INVERTED_RED_FADE_DIFF_OFFSET_Y +
               LANDSCAPE_RED_FADE_ROTATE_OFFSET_Y);
}

/**
 * UpdateLandscapeSlideDistance: 横屏滑动展开动效,归位位移记录
 * zoomIndex关键刻度值下标, displacementDistance位移距离, landscapeAnimType动效类型: 1展开,2收起,0其它
 */
void ZoomCalculate::UpdateLandscapeSlideDistance(ZoomStruct *state, int32_t zoomIndex, double mDisplacementDistance,
                                                 int32_t landscapeAnimType)
{
    state->landscapeSlideAnimType = landscapeAnimType;
    
    // 矫正焦点刻度大小字体参数
    if (state->landscapeSlideAnimType != ARRAY_TWO) {
        state->landscapeSlideZoomIndex = zoomIndex;
    }
    state->displacementDistance = mDisplacementDistance;
}

/**
 * 上述state状态更新计算方法,下述zoom绘制计算方法
 */

/**
 * 获取焦圈中心焦距字符
 */
std::string ZoomCalculate::GetRedText(const ZoomStruct* state)
{
    if (state->quickArrLength == 0 || state->quickZoomValArr == nullptr) {
        double zoomVal = floor(state->curZoomValue * ZOOM_RATIO_MAGNIFY_TEN) / ZOOM_RATIO_MAGNIFY_TEN;
        std::stringstream ss;
        ss << std::fixed << std::setprecision(1) << zoomVal;
        return ss.str() + "x";
    }
    bool firstQuickIsOneDecimalPlace =
        state->quickZoomValArr[0] == std::floor(state->quickZoomValArr[0] * MULTIPLY_BY_TEN) / DIVIDE_BY_TEN;
    if (state->quickZoomValArr[0] <= state->quickMaxZoomVarW &&
        (firstQuickIsOneDecimalPlace ?
            std::floor(state->curZoomValue * MULTIPLY_BY_TEN) / MULTIPLY_BY_TEN <= state->quickZoomValArr[0] :
            (state->curZoomValue == state->quickZoomValArr[0] ||
                state->curZoomValue < std::ceil(state->quickZoomValArr[0] * MULTIPLY_BY_TEN) / DIVIDE_BY_TEN))) {
        return "W";
    }
    double zoomVal = floor(state->curZoomValue * ZOOM_RATIO_MAGNIFY_TEN) / ZOOM_RATIO_MAGNIFY_TEN;
    std::stringstream ss;
    ss << std::fixed << std::setprecision(1) << zoomVal;
    return ss.str() + "x";
}

/**
 * 获取光学变焦点index,-1代表非光学变焦点
 */
int ZoomCalculate::FindArrayIndex(const int arr[], int num, int arrLength)
{
    for (int i = 0; i < arrLength; i++) {
        if (num == arr[i]) {
            return i;
        }
    }
    return -1;
}

/**
 * zoom点索引是否越界
 */
bool ZoomCalculate::isIndexLegal(int arrayLength, int index)
{
    return index >= ARRAY_ZERO && index < arrayLength;
}

/**
 * 计算当前zoom对应的angle,规则：state->opticalZoomValArr[0]对应0°
 */
float ZoomCalculate::CalZoomAngle(const ZoomStruct* state)
{
    if (state->opticalArrLength == 0 || state->opticalZoomValArr == nullptr ||
        state->opticalZoomDotIndexArr == nullptr) {
        return 0;
    }
    if (state->curZoomValue <= state->opticalZoomValArr[0]) {
        return 0;
    } else if (state->curZoomValue >= state->opticalZoomValArr[state->opticalArrLength - 1]) {
        return -SCALE_GAP_ANGLE * state->opticalZoomDotIndexArr[state->opticalArrLength - 1];
    }
    float resultAngle = 0;
    int index = 0;
    while (index < state->opticalArrLength && state->opticalZoomValArr[index] <= state->curZoomValue) {
        index++;
    }
    index--;
    resultAngle = -SCALE_GAP_ANGLE * state->opticalZoomDotIndexArr[index]; // 前序大刻度角度
    float smallAngle = -SCALE_GAP_ANGLE * (state->curZoomValue - state->opticalZoomValArr[index]) /
                       (state->opticalZoomValArr[index + 1] - state->opticalZoomValArr[index]) *
                       (state->opticalZoomDotIndexArr[index + 1] - state->opticalZoomDotIndexArr[index]);
    resultAngle += smallAngle;
    return resultAngle;
}

/**
 * 获取设备当前状态、旋转状态 是否为 字体与卡门线平行(即卡门线、刻度环、关键刻度字体、等效焦距字体4行平行状态)
 */
bool ZoomCalculate::getIsTextParallel2CarmenLine(const ZoomStruct* state)
{
    if ((state->collapsStatus == ANIM_TYPE_ZERO || state->collapsStatus == ANIM_TYPE_TWO) &&
        (state->directionAngle == 0 || state->directionAngle == ANGLE_CONVERSION)) {
        return true;
    }
    if (state->collapsStatus == ANIM_TYPE_ONE &&
        (state->directionAngle == 0 || state->directionAngle == ANGLE_CONVERSION)) {
        return true;
    }
    return false;
}

/**
 * 获取当前模式的zoom小圆点数量
 */
int ZoomCalculate::getLittlePotCount(const ZoomStruct* state)
{
    int count = ARRAY_ZERO;
    if (!state->isSupportedEquivalentFocalBigText && !state->isSupportedCycleClickZoom) {
        return count;
    }
    if (state->isSupportedCycleClickZoom) {
        return ZoomCalculate::getLittlePotCountInCycleClickZoom(state);
    }
    if (state->opticalArrLength == 0 || state->opticalZoomValArr == nullptr) {
        return count;
    }
    for (int i = 0; i < state->opticalArrLength; i++) {
        if (state->opticalZoomValArr[i] == POINT_ZOOM_ONE || state->opticalZoomValArr[i] == POINT_ZOOM_THREE ||
            (state->opticalZoomValArr[i] == POINT_ZOOM_TWO && i != state->opticalArrLength - 1)) {
            count++;
        }
    }
    return count;
}

/**
 * 获取当前模式的zoom在循环点切下的小圆点数量
 */
int ZoomCalculate::getLittlePotCountInCycleClickZoom(const ZoomStruct* state)
{
    int count = ARRAY_ZERO;
    if (state->opticalArrLength < ARRAY_TWO || state->opticalZoomValArr == nullptr ||
        state->cycleClickZoomValArr == nullptr) {
        return count;
    }
    for (int i = 0; i < static_cast<int>(state->opticalArrLength) - 1; i++) {
        for (int j = 0; j < static_cast<int>(state->cycleClickZoomLength); j++) {
            if (state->opticalZoomValArr[i] == state->cycleClickZoomValArr[j]) {
                count++;
                break;
            }
        }
    }
    return count;
}


/**
 * 获取当前模式的等效焦距数组index与变焦点数组index的差
 */
int ZoomCalculate::getFocalIndexDiff(const ZoomStruct* state, double zoomValue, int count)
{
    int diff = ARRAY_ZERO;
    if (state->isSupportedCycleClickZoom && count != ARRAY_ZERO) {
        if (state->cycleClickZoomLength == 1 && zoomValue >= state->cycleClickZoomValArr[0]) {
            return diff + 1;
        }
        for (int i = 0;i < state->cycleClickZoomLength; i++) {
            if (zoomValue >= state->cycleClickZoomValArr[i]) {
              diff++;
            }
        }
        return diff;
    }
    if (!state->isSupportedEquivalentFocalBigText || count == ARRAY_ZERO) {
        return diff;
    }
    if (count == ARRAY_ONE) {
        if (zoomValue < POINT_ZOOM_ONE) {
            return diff;
        } else {
            return diff + ARRAY_ONE;
        }
    }
    if (count == ARRAY_THREE) {
        if (zoomValue < POINT_ZOOM_ONE) {
            return diff;
        } else if (zoomValue >= POINT_ZOOM_ONE && zoomValue < POINT_ZOOM_TWO) {
            return diff + ARRAY_ONE;
        } else if (zoomValue >= POINT_ZOOM_TWO && zoomValue < POINT_ZOOM_THREE) {
            return diff + ARRAY_TWO;
        } else if (zoomValue >= POINT_ZOOM_THREE) {
            return diff + ARRAY_THREE;
        }
    }
}

/**
 * 支持循环点切时，获取当前zoom点是否是zoom小圆点
 */
bool ZoomCalculate::isShowLittlePointInCycleZoom(const ZoomStruct *state, double zoomValue)
{
    for(int i = 0; i < state->cycleClickZoomLength; i++) {
        if (zoomValue == state->cycleClickZoomValArr[i]) {
            return true;
        }
    }
    return false;
}

/**
 * 获取当前zoom点是否是zoom小圆点
 */
bool ZoomCalculate::isLittlePoint(const ZoomStruct* state, double zoomValue, int diff)
{
    if (state->isSupportedCycleClickZoom) {
        return ZoomCalculate::isShowLittlePointInCycleZoom(state,zoomValue);
    }
    if (!state->isSupportedEquivalentFocalBigText) {
        return false;
    }
    if (diff == ARRAY_ONE && zoomValue == POINT_ZOOM_ONE) {
        return true;
    }
    if (diff > ARRAY_ONE &&
        (zoomValue == POINT_ZOOM_ONE || zoomValue == POINT_ZOOM_TWO || zoomValue == POINT_ZOOM_THREE)) {
        return true;
    }
    return false;
}

bool ZoomCalculate::isLandscapeSlideAnim(const ZoomStruct* state)
{
    int diff = 0;
    if ((state->isSupportedEquivalentFocalBigText || state->isSupportedCycleClickZoom) &&
        state->opticalArrLength > 0 &&
        isIndexLegal(state->opticalArrLength, state->landscapeSlideZoomIndex)) {
        diff =
            getFocalIndexDiff(state, state->opticalZoomValArr[state->landscapeSlideZoomIndex], state->littlePointCnt);
    }
    return state->landscapeSlideAnimType != 0 && (state->landscapeSlideZoomIndex - diff) < state->quickArrLength &&
           !isLittlePoint(state, state->curZoomValue, diff) && !getIsTextParallel2CarmenLine(state);
}

