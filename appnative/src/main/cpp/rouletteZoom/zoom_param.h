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

#ifndef RENDERNODEGRAPH_ZOOM_PARAM_H
#define RENDERNODEGRAPH_ZOOM_PARAM_H

#include <cstdint>

// 绘制计算参数定义
const int ZOOM_SCALE_COUNT = 225;
const float SCALE_GAP_ANGLE = 1.6;
const int ANGLE_CONVERSION = 180;
const int DRAW_ARC_SWEEP_ANGLE = 360;
const int COLOR_CHANNEL_MAX = 255;
const int COLOR_CHANNEL_RED_NOVA = 10;
const int COLOR_CHANNEL_GREEN_NOVA = 89;
const int COLOR_CHANNEL_BLUE_NOVA = 247;
const int INVALID_ZOOM_ANGLE = 1000;
const float ROTATE_MAPPING_ANGLE = 90.0;
const float POINT_ZOOM_ONE = 1.5;
const float POINT_ZOOM_TWO = 5.625;
const float POINT_ZOOM_THREE = 7.5;

// 多端适配、字体旋转参数定义
const int DIRECTION_LEFT = 270; // LEFT : 0
const int DIRECTION_RIGHT = 90; // RIGHT: 1
const int DIRECTION_TOP = 0; // TOP : 2
const int DIRECTION_BOTTOM = 180; // BOTTOM : 3


// 卡门线区UI参数定义
const int LONG_CURVE_WIDTH = 2;
const int LONG_CURVE_CENTER_2_RED_LINE_TOP = 9;

const int SCALE_ALL_SCALE_WIDTH = 100;
const int LANDSCAPE_SCALE_ALL_SCALE_WIDTH = 120;
const int CARMEN_MASK_FILTER_SIGMA = 20;
const float CARMEN_SHADER_POS_LEFT = 0.5;
const float CARMEN_SHADER_POS_TOP = 0.75;
const float CARMEN_SHADER_POS_LR_GAP = 0.09;


// 光球区UI参数定义
const int PHOTOSPHERE_RADIUS = 4;

const int PHOTOSPHERE_MASK_FILTER_SIGMA = 5;
const int PHOTOSPHERE_COLOR_RED_CHANNEL = 228;
const int PHOTOSPHERE_COLOR_GREEN_CHANNEL = 227;
const int PHOTOSPHERE_COLOR_BLUE_CHANNEL = 226;


// 刻度盘-焦圈区参数UI定义
const int RED_LINE_WIDTH = 2;
const int RED_LINE_HEIGHT = 9;
const int RED_LINE_RADIUS = 1;

const int QUICK_LINE_WIDTH = 2;
const int QUICK_LINE_HEIGHT = 9;
const int QUICK_LINE_RADIUS = 1;

const float SHORT_LINE_WIDTH = 1.5;
const float SHORT_LINE_HEIGHT = 6;
const float SHORT_LINE_RADIUS = 1.5;

const float SCALE_SHADER_POS_LEFT = 0.5;
const float SCALE_SHADER_POS_TOP = 0.75;
const float SCALE_SHADER_POS_LR_GAP = 0.09;
const int SCALE_SHADOW_WIDTH = 2;
const int SCALE_SHADOW_OPACITY = 50;
const float SCALE_OUTER_OPACITY = 0.3;
const float SCALE_SHORT_LINE_OPACITY = 0.6;
const float SCALE_QUICK_LINE_OPACITY = 1;
const int HALF_SCALE_DRAW_COUNT = 45; // 悬浮窗场景45,全屏场景32,正式方案动态计算


// 变焦字符参数UI定义
const int BIG_TEXT_ZOOM_FONT = 24;
const int ZOOM_RATIO_FONT = 10;
const int EQUIVALENT_FOCAL_FONT = 9;
const float EQU_FOCAL_OPACITY = 0.8;
const int EQU_FOCAL_2_RATIO_POS = 12;
const float ZOOM_RATIO_79 = 0.79;
const int ZOOM_RATIO_MAGNIFY_TEN = 10;
const float ZOOM_RATIO_SMALLER_TEN = 10.0;
const int ZOOM_TEXT_HALF_HEIGHT = 7;

const int TEXT_FADE_HALF_WIDTH = 24;
const int LANDSCAPE_TEXT_FADE_HALF_WIDTH = 42;
const int TEXT_FADE_HEIGHT_START = 1;
const int TEXT_FADE_HEIGHT_END = 12;
const float TEXT_FADE_LEFT_TRANSITION = 0.22;
const float TEXT_FADE_RIGHT_TRANSITION = 0.78;

const int TEXT_COLOR_OPACITY = 166;
const int TEXT_MAX_WIDTH = 500;
const float EQU_TEXT_PEN_WIDTH = 1;
const float TEXT_PEN_WIDTH = 2;
const float TEXT_PEN_CYCLE_CLICK_WIDTH = 3;
const float RATIO_TEXT_MASK_FILTER_SIGMA = 0.5;
const int TEXT_STYLE_FONT_WEIGHT = 6;

const int LANDSCAPE_TEXT_OFFSET_Y = 12;
const int LANDSCAPE_ROTATE_OFFSET_Y = 6;
const int LANDSCAPE_RED_ROTATE_OFFSET_Y = 11;
const float INVERTED_RED_DIFF_OFFSET_Y = 1.5;
const float LANDSCAPE_RED_FADE_ROTATE_OFFSET_Y = 4;
const float INVERTED_RED_FADE_DIFF_OFFSET_Y = -10;
const int RED_TEXT_LANDSCAPE_SLIDE_OFFSET = 6;

const float DISPLAY_DIST_THRESHOLD = 0.4;
const int SIMU_EQUIVALENT_DISTANCE = 5;
const int RED_LINE_WIDTH_BIAS = 1;
const int RED_LINE_CYCLE_RADIUS = 2;

// 变焦盘小圆点距离变焦盘的位置
const int DEFAULT_LITTLE_DOT_POSITION_X = 250;
const int DEFAULT_LITTLE_DOT_POSITION_Y = 15;
const int LANDSCAPE_LITTLE_DOT_POSITION_X = 270;
const int LANDSCAPE_LITTLE_DOT_POSITION_Y = 20;

// 无含义常量定义
const int DIVIDE_BY_TWO = 2;
const int DIVIDE_BY_FOUR = 4;
const int DIVIDE_BY_TEN = 10;
const int MULTIPLY_BY_TWO = 2;
const int MULTIPLY_BY_TEN = 10;
const int INVALID_INDEX = -1;
const int ARRAY_ZERO = 0;
const int ARRAY_ONE = 1;
const int ARRAY_TWO = 2;
const int ARRAY_THREE = 3;
const int ANIM_TYPE_ZERO = 0;
const int ANIM_TYPE_ONE = 1;
const int ANIM_TYPE_TWO = 2;
const int ANIM_TYPE_FIVE = 5;

// 性能优化常量定义
const float LAYER_OPT_8 = 0.8;
const float LAYER_OPT_6 = 0.6;

#endif // RENDERNODEGRAPH_ZOOM_PARAM_H
