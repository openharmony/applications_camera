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

#ifndef RENDERNODEGRAPH_ZOOM_CALCULATE_H
#define RENDERNODEGRAPH_ZOOM_CALCULATE_H

#include "zoom_struct.h"
#include "common/Log.h"
#include <string>
#include "iostream"
#include <iomanip>
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
#include "mutex"
#include <memory>

class ZoomCalculate {
public:
    static void NativeInitNode(ZoomStruct *state, float mWidth, float mHeight, double mDrawHeight,
                               double mDensityPixels);

    static void NativeMultiAdaptParam(ZoomStruct *state, int32_t mCollapsStatus, int32_t mDirectAngle);

    static void SetQuickZoomArray(ZoomStruct *state, uint32_t mQuickArrLength, double *mQuickZoomValArr,
                                  int32_t *mQuickEquivalentFocalArr);

    static void SetOpticalZoomArray(ZoomStruct *state, uint32_t mOpticalArrLength, double *mOpticalZoomValArr,
                                    int32_t *mOpticalZoomDotIndexArr);

    static void SetCycleClickZoomArray(ZoomStruct *state, uint32_t mCycleClickZoomLength, double *mCycleClickZoomArr);

    static void SetLongCurveHalo(ZoomStruct *state, int32_t mAnimType, double haloMatteScale, double haloOpacity);

    static void SetSphereParam(ZoomStruct *state, double position, double scale, double color, double haloOpacity);

    static void SetScaleAllParam(ZoomStruct *state, double redOpacity, double matteScale, double allOpacity);

    static void SetCarmenLine(ZoomStruct *state, double matteScale, double lineOpacity);

    static void UpdateDirectionAngle(ZoomStruct *state, int32_t direct);

    static void UpdateLandscapeSlideDistance(ZoomStruct *state, int32_t zoomIndex, double mDisplacementDistance,
                                             int32_t landscapeAnimType);

    static std::string GetRedText(const ZoomStruct *state);

    static float CalZoomAngle(const ZoomStruct *state);

    static int FindArrayIndex(const int arr[], int num, int arrLength);

    static bool isIndexLegal(int arrayLength, int index);

    static bool getIsTextParallel2CarmenLine(const ZoomStruct *state);
    
    static int getLittlePotCount(const ZoomStruct *state);
    
    static int getFocalIndexDiff(const ZoomStruct *state, double zoomValue, int count);
    
    static bool isLittlePoint(const ZoomStruct *state, double zoomValue, int diff);
    
    static bool isLandscapeSlideAnim(const ZoomStruct *state);
    
    static int getLittlePotCountInCycleClickZoom(const ZoomStruct *state);
    
    static bool isShowLittlePointInCycleZoom(const ZoomStruct *state, double zoomValue);
    
};

#endif // RENDERNODEGRAPH_ZOOM_CALCULATE_H
