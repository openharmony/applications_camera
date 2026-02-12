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

#include "zoom_struct.h"
bool ZoomStruct::getIsBlueIcon() const
{
    return isBlueIcon;
}

bool ZoomStruct::getIsSupportedEquivalentFocalBigText() const
{
    return isSupportedEquivalentFocalBigText;
}

void ZoomStruct::setCameraAppCapabilityParams(bool mIsSupportNovaProduct, bool mIsSupportedEquivalentFocalBigText, 
                                              bool mIsSupportedCycleClickZoom)
{
    isBlueIcon = mIsSupportNovaProduct;
    isSupportedEquivalentFocalBigText = mIsSupportedEquivalentFocalBigText;
    isSupportedCycleClickZoom = mIsSupportedCycleClickZoom;
}

bool ZoomStruct::getIsSupportedCycleClickZoom() const
{
    return isSupportedCycleClickZoom;
}

double ZoomStruct::getDisplacementDistance() const
{
    return displacementDistance;
}

void ZoomStruct::setDisplacementDistance(double mDisplacementDistance)
{
    displacementDistance = mDisplacementDistance;
}

int32_t ZoomStruct::getLandscapeSlideZoomIndex() const
{
    return landscapeSlideZoomIndex;
}

void ZoomStruct::setLandscapeSlideZoomIndex(int32_t mLandscapeSlideZoomIndex)
{
    landscapeSlideZoomIndex = mLandscapeSlideZoomIndex;
}

int32_t ZoomStruct::getLandscapeSlideAnimType() const
{
    return landscapeSlideAnimType;
}

void ZoomStruct::setLandscapeSlideAnimType(int32_t mLandscapeSlideAnimType)
{
    landscapeSlideAnimType = mLandscapeSlideAnimType;
}

float ZoomStruct::getRedFadeRotateOffsetY() const
{
    return redFadeRotateOffsetY;
}

void ZoomStruct::setRedFadeRotateOffsetY(float mRedFadeRotateOffsetY)
{
    redFadeRotateOffsetY = mRedFadeRotateOffsetY;
}

float ZoomStruct::getRedTextRotateOffsetY() const
{
    return redTextRotateOffsetY;
}

void ZoomStruct::setRedTextRotateOffsetY(float mRedTextRotateOffsetY)
{
    redTextRotateOffsetY = mRedTextRotateOffsetY;
}

float ZoomStruct::getRotateOffsetY() const
{
    return rotateOffsetY;
}

void ZoomStruct::setRotateOffsetY(float mRotateOffsetY)
{
    rotateOffsetY = mRotateOffsetY;
}

float ZoomStruct::getCurZoomAngle() const
{
    return curZoomAngle;
}

void ZoomStruct::setCurZoomAngle(float mCurZoomAngle)
{
    curZoomAngle = mCurZoomAngle;
}

float ZoomStruct::getRedLineTopRadius() const
{
    return redLineTopRadius;
}

void ZoomStruct::setRedLineTopRadius(float mRedLineTopRadius)
{
    redLineTopRadius = mRedLineTopRadius;
}

float ZoomStruct::getRedLineTopY() const
{
    return redLineTopY;
}

void ZoomStruct::setRedLineTopY(float mRedLineTopY)
{
    redLineTopY = mRedLineTopY;
}

double ZoomStruct::getOpticalMaxZoomVarW() const
{
    return opticalMaxZoomVarW;
}

void ZoomStruct::setOpticalMaxZoomVarW(double mOpticalMaxZoomVarW)
{
    opticalMaxZoomVarW = mOpticalMaxZoomVarW;
}

double ZoomStruct::getQuickMaxZoomVarW() const
{
    return quickMaxZoomVarW;
}

void ZoomStruct::setQuickMaxZoomVarW(double mQuickMaxZoomVarW)
{
    quickMaxZoomVarW = mQuickMaxZoomVarW;
}

int32_t* ZoomStruct::getOpticalZoomDotIndexArr() const
{
    return opticalZoomDotIndexArr;
}

void ZoomStruct::setOpticalZoomDotIndexArr(int32_t* mOpticalZoomDotIndexArr)
{
    int32_t* temp = opticalZoomDotIndexArr;
    opticalZoomDotIndexArr = mOpticalZoomDotIndexArr;
    delete[] temp;
}

double* ZoomStruct::getOpticalZoomValArr() const
{
    return opticalZoomValArr;
}

void ZoomStruct::setOpticalZoomValArr(double* mOpticalZoomValArr)
{
    double* temp = opticalZoomValArr;
    opticalZoomValArr = mOpticalZoomValArr;
    delete[] temp;
}

uint32_t ZoomStruct::getOpticalArrLength() const
{
    return opticalArrLength;
}

void ZoomStruct::setOpticalArrLength(uint32_t mOpticalArrLength)
{
    opticalArrLength = mOpticalArrLength;
}

int32_t* ZoomStruct::getQuickEquivalentFocalArr() const
{
    return quickEquivalentFocalArr;
}

void ZoomStruct::setQuickEquivalentFocalArr(int32_t* mQuickEquivalentFocalArr)
{
    int32_t* temp = quickEquivalentFocalArr;
    quickEquivalentFocalArr = mQuickEquivalentFocalArr;
    delete[] temp;
}

double* ZoomStruct::getQuickZoomValArr() const
{
    return quickZoomValArr;
}

void ZoomStruct::setQuickZoomValArr(double* mQuickZoomValArr)
{
    double* temp = quickZoomValArr;
    quickZoomValArr = mQuickZoomValArr;
    delete[] temp;
}

uint32_t ZoomStruct::getQuickArrLength() const
{
    return quickArrLength;
}

void ZoomStruct::setQuickArrLength(uint32_t mQuickArrLength)
{
    quickArrLength = mQuickArrLength;
}

double ZoomStruct::getCurZoomValue() const
{
    return curZoomValue;
}

void ZoomStruct::setCurZoomValue(double mCurZoomValue)
{
    curZoomValue = mCurZoomValue;
}

double ZoomStruct::getCarmenLineOpacity() const
{
    return carmenLineOpacity;
}

void ZoomStruct::setCarmenLineOpacity(double mCarmenLineOpacity)
{
    carmenLineOpacity = mCarmenLineOpacity;
}

double ZoomStruct::getCarmenLineMatteScale() const
{
    return carmenLineMatteScale;
}

void ZoomStruct::setCarmenLineMatteScale(double mCarmenLineMatteScale)
{
    carmenLineMatteScale = mCarmenLineMatteScale;
}

double ZoomStruct::getScaleAllOpacity() const
{
    return scaleAllOpacity;
}

void ZoomStruct::setScaleAllOpacity(double mScaleAllOpacity)
{
    scaleAllOpacity = mScaleAllOpacity;
}

double ZoomStruct::getScaleAllMatteScale() const
{
    return scaleAllMatteScale;
}

void ZoomStruct::setScaleAllMatteScale(double mScaleAllMatteScale)
{
    scaleAllMatteScale = mScaleAllMatteScale;
}

double ZoomStruct::getRedLineAndTextOpacity() const
{
    return redLineAndTextOpacity;
}

void ZoomStruct::setRedLineAndTextOpacity(double mRedLineAndTextOpacity)
{
    redLineAndTextOpacity = mRedLineAndTextOpacity;
}

double ZoomStruct::getSphereHaloOpacity() const
{
    return sphereHaloOpacity;
}

void ZoomStruct::setSphereHaloOpacity(double mSphereHaloOpacity)
{
    sphereHaloOpacity = mSphereHaloOpacity;
}

double ZoomStruct::getSphereColor() const
{
    return sphereColor;
}

void ZoomStruct::setSphereColor(double mSphereColor)
{
    sphereColor = mSphereColor;
}

double ZoomStruct::getSphereScale() const
{
    return sphereScale;
}

void ZoomStruct::setSphereScale(double mSphereScale)
{
    sphereScale = mSphereScale;
}

double ZoomStruct::getSpherePosition() const
{
    return spherePosition;
}

void ZoomStruct::setSpherePosition(double mSpherePosition)
{
    spherePosition = mSpherePosition;
}

double ZoomStruct::getLongCurveHaloOpacity() const
{
    return longCurveHaloOpacity;
}

void ZoomStruct::setLongCurveHaloOpacity(double mLongCurveHaloOpacity)
{
    longCurveHaloOpacity = mLongCurveHaloOpacity;
}

double ZoomStruct::getLongCurveHaloMatteScale() const
{
    return longCurveHaloMatteScale;
}

void ZoomStruct::setLongCurveHaloMatteScale(double mLongCurveHaloMatteScale)
{
    longCurveHaloMatteScale = mLongCurveHaloMatteScale;
}

int32_t ZoomStruct::getAnimType() const
{
    return animType;
}

void ZoomStruct::setAnimType(int32_t mAnimType)
{
    animType = mAnimType;
}

double ZoomStruct::getDensityPixels() const
{
    return densityPixels;
}

void ZoomStruct::setDensityPixels(double mDensityPixels)
{
    densityPixels = mDensityPixels;
}

int32_t ZoomStruct::getDirectionAngle() const
{
    return directionAngle;
}

void ZoomStruct::setDirectionAngle(int32_t mDirectionAngle)
{
    directionAngle = mDirectionAngle;
}

int32_t ZoomStruct::getCollapsStatus() const
{
    return collapsStatus;
}

void ZoomStruct::setCollapsStatus(int32_t mCollapsStatus)
{
    collapsStatus = mCollapsStatus;
}

double ZoomStruct::getDrawHeight() const
{
    return drawHeight;
}

void ZoomStruct::setDrawHeight(double mDrawHeight)
{
    drawHeight = mDrawHeight;
}

float ZoomStruct::getHeight() const
{
    return height;
}

void ZoomStruct::setHeight(float mHeight)
{
    height = mHeight;
}

float ZoomStruct::getWidth() const
{
    return width;
}

void ZoomStruct::setWidth(float mWidth)
{
    width = mWidth;
}
