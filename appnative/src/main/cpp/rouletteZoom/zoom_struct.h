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

#ifndef RENDERNODEGRAPH_ZOOM_STRUCT_H
#define RENDERNODEGRAPH_ZOOM_STRUCT_H

#include "zoom_param.h"
#include <cstdint>

/**
 * native侧变焦绘制状态管理
 */
struct ZoomStruct {
    float width = 0;
    float height = 0;
    double drawHeight = 0;
    int32_t collapsStatus = 0; // 设备当前状态: 1展开态/大屏态,2半折态,0全直板态
    int32_t directionAngle = DIRECTION_TOP; // 字体旋转补偿角度
    double densityPixels = 3.25;

    int32_t animType = 0; // 动效状态
    double longCurveHaloMatteScale = 1; // 光晕动效参数
    double longCurveHaloOpacity;
    double spherePosition; // 光球参数
    double sphereScale;
    double sphereColor;
    double sphereHaloOpacity;     // 光球光晕参数
    double redLineAndTextOpacity; // 焦圈中心刻度参数
    double scaleAllMatteScale;    // 焦圈参数
    double scaleAllOpacity;
    double carmenLineMatteScale; // 卡门线参数
    double carmenLineOpacity;
    
    double curZoomValue = 1;
    uint32_t quickArrLength;
    double *quickZoomValArr = nullptr;
    int32_t *quickEquivalentFocalArr = nullptr;
    uint32_t opticalArrLength;
    double *opticalZoomValArr = nullptr;
    int32_t *opticalZoomDotIndexArr = nullptr;
    uint32_t littlePointCnt;
    double *cycleClickZoomValArr = nullptr;
    uint32_t cycleClickZoomLength;

    double quickMaxZoomVarW = ZOOM_RATIO_79; // 快捷变焦点显示W的阈值
    double opticalMaxZoomVarW = ZOOM_RATIO_79; // zoom 展开显示W的阈值

    float redLineTopY = 0; // 红线顶部positionY
    float redLineTopRadius = 0; // 红线顶部outer圆半径
    float curZoomAngle = 0; // 当前变焦对应的角度
    
    float rotateOffsetY = 0; // 横竖屏旋转场景字体自适应偏移
    float redTextRotateOffsetY = 0; // 横竖屏旋转场景红色字体自适应偏移
    float redFadeRotateOffsetY = 0; // 横竖屏旋转场景淡入淡出自适应偏移
    
    int32_t landscapeSlideAnimType = 0; // 横屏滑动动效类型: 1展开动态,2收起动效,5展开暂态,0其它
    int32_t landscapeSlideZoomIndex = 0; // 横屏滑动动效关键刻度索引参数
    double displacementDistance = 0; // 横屏滑动动效位移参数

    bool isBlueIcon = false;
    bool isSupportedEquivalentFocalBigText = false;
    bool isSupportedCycleClickZoom = false;
    
    bool getIsBlueIcon() const;
    bool getIsSupportedEquivalentFocalBigText() const;
    bool getIsSupportedCycleClickZoom() const;
    void setCameraAppCapabilityParams(bool mIsSupportNovaProduct,
                                      bool mIsSupportedEquivalentFocalBigText, bool mIsSupportedCycleClickZoom);
    double getDisplacementDistance() const;
    void setDisplacementDistance(double mDisplacementDistance);
    int32_t getLandscapeSlideZoomIndex() const;
    void setLandscapeSlideZoomIndex(int32_t mLandscapeSlideZoomIndex);
    int32_t getLandscapeSlideAnimType() const;
    void setLandscapeSlideAnimType(int32_t mLandscapeSlideAnimType);
    float getRedFadeRotateOffsetY() const;
    void setRedFadeRotateOffsetY(float mRedFadeRotateOffsetY);
    float getRedTextRotateOffsetY() const;
    void setRedTextRotateOffsetY(float mRedTextRotateOffsetY);
    float getRotateOffsetY() const;
    void setRotateOffsetY(float mRotateOffsetY);
    float getCurZoomAngle() const;
    void setCurZoomAngle(float mCurZoomAngle);
    float getRedLineTopRadius() const;
    void setRedLineTopRadius(float mRedLineTopRadius);
    float getRedLineTopY() const;
    void setRedLineTopY(float mRedLineTopY);
    double getOpticalMaxZoomVarW() const;
    void setOpticalMaxZoomVarW(double mOpticalMaxZoomVarW);
    double getQuickMaxZoomVarW() const;
    void setQuickMaxZoomVarW(double mQuickMaxZoomVarW);
    int32_t* getOpticalZoomDotIndexArr() const;
    void setOpticalZoomDotIndexArr(int32_t* mOpticalZoomDotIndexArr);
    double* getOpticalZoomValArr() const;
    void setOpticalZoomValArr(double* mOpticalZoomValArr);
    uint32_t getOpticalArrLength() const;
    void setOpticalArrLength(uint32_t mOpticalArrLength);
    int32_t* getQuickEquivalentFocalArr() const;
    void setQuickEquivalentFocalArr(int32_t* mQuickEquivalentFocalArr);
    double* getQuickZoomValArr() const;
    void setQuickZoomValArr(double* mQuickZoomValArr);
    uint32_t getQuickArrLength() const;
    void setQuickArrLength(uint32_t mQuickArrLength);
    double getCurZoomValue() const;
    void setCurZoomValue(double mCurZoomValue);
    double getCarmenLineOpacity() const;
    void setCarmenLineOpacity(double mCarmenLineOpacity);
    double getCarmenLineMatteScale() const;
    void setCarmenLineMatteScale(double mCarmenLineMatteScale);
    double getScaleAllOpacity() const;
    void setScaleAllOpacity(double mScaleAllOpacity);
    double getScaleAllMatteScale() const;
    void setScaleAllMatteScale(double mScaleAllMatteScale);
    double getRedLineAndTextOpacity() const;
    void setRedLineAndTextOpacity(double mRedLineAndTextOpacity);
    double getSphereHaloOpacity() const;
    void setSphereHaloOpacity(double mSphereHaloOpacity);
    double getSphereColor() const;
    void setSphereColor(double mSphereColor);
    double getSphereScale() const;
    void setSphereScale(double mSphereScale);
    double getSpherePosition() const;
    void setSpherePosition(double mSpherePosition);
    double getLongCurveHaloOpacity() const;
    void setLongCurveHaloOpacity(double mLongCurveHaloOpacity);
    double getLongCurveHaloMatteScale() const;
    void setLongCurveHaloMatteScale(double mLongCurveHaloMatteScale);
    int32_t getAnimType() const;
    void setAnimType(int32_t mAnimType);
    double getDensityPixels() const;
    void setDensityPixels(double mDensityPixels);
    int32_t getDirectionAngle() const;
    void setDirectionAngle(int32_t mDirectionAngle);
    int32_t getCollapsStatus() const;
    void setCollapsStatus(int32_t mCollapsStatus);
    double getDrawHeight() const;
    void setDrawHeight(double mDrawHeight);
    float getHeight() const;
    void setHeight(float mHeight);
    float getWidth() const;
    void setWidth(float mWidth);
};

#endif // RENDERNODEGRAPH_ZOOM_STRUCT_H
