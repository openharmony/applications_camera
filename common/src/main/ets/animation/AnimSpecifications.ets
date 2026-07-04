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
import curves from '@ohos.curves';
import lazy { WindowService } from '../service/window/WindowService';
import lazy { HiLog } from '../utils/HiLog';
import lazy { Size } from '../utils/types';
import lazy { WindowDirection } from '../utils/WindowDirection';
import Curves from '@ohos.curves';
import lazy { getStates } from '../redux/Store';

/* instrument ignore file */
const TAG: string = 'AnimSpecifications';

export class AnimSpecifications {
  // <------------------    组件 透明度 alpha  ----------------------->
  // 完全透明
  public static readonly ALPHA_COMPLETELY_TRANSPARENT = 0.0;
  // 半透明 0.5
  public static readonly ALPHA_HALF = 0.5;
  // 不透明
  public static readonly ALPHA_OPAQUE = 1.0;

  // <------------------    组件 缩放 scale  ----------------------->
  // 原本大小 1.1
  public static readonly SCALE_1_1 = 1.1;
  // 原本大小 1.0
  public static readonly SCALE_ORIGINAL = 1.0;
  // 原本大小 0.9
  public static readonly SCALE_0_9 = 0.9;
  // 比例大小 0.8
  public static readonly SCALE_0_8 = 0.8;
  // 一半大小 0.5
  public static readonly SCALE_HALF = 0.5;
  // 隐藏状态 0.0
  public static readonly SCALE_ZERO = 0.0;

  // <------------------    组件 旋转 rotation  ----------------------->
  // 正向水平  0度
  public static readonly ROTATION_POSITIVE_HORIZONTAL = 0;
  // 垂直     90度
  public static readonly ROTATION_VERTICAL = 90;
  // 反向水平  180度
  public static readonly ROTATION_REVERSES_HORIZONTAL = 180;
  // 旋转轴位置  Y轴起始位置 ---- 0
  public static readonly ROTATION_Y_START = 0;
  // 旋转轴位置  Y轴中间位置 ---- 0.5
  public static readonly ROTATION_Y_HALF = 0.5;

  // <------------------    组件 模糊 blur  ----------------------->
  //模糊半径  100
  public static readonly BLUR_RADIUS_100 = 100;

  // <------------------    动效持续时长  duration  ----------------------->
  //duration  INVALID
  public static readonly ANIM_DURATION_INVALID = 0;
  //duration  10
  public static readonly ANIM_DURATION_10 = 10;
  //duration  50
  public static readonly ANIM_DURATION_50 = 50;
  //duration  100
  public static readonly ANIM_DURATION_100 = 100;
  //duration  150
  public static readonly ANIM_DURATION_150 = 150;
  //duration  200
  public static readonly ANIM_DURATION_200 = 200;

  //duration  250
  public static readonly ANIM_DURATION_250 = 250;
  //duration  300
  public static readonly ANIM_DURATION_300 = 300;
  //duration  350
  public static readonly ANIM_DURATION_350 = 350;
  //duration  400
  public static readonly ANIM_DURATION_400 = 400;
  //duration  450
  public static readonly ANIM_DURATION_450 = 450;
  //duration  500
  public static readonly ANIM_DURATION_500 = 500;
  //duration  500
  public static readonly ANIM_DURATION_LR_LONG_CLICK = 500;
  //duration  600
  public static readonly ANIM_DURATION_600 = 600;
  //duration  750
  public static readonly ANIM_DURATION_750 = 750;
  //duration  800
  public static readonly ANIM_DURATION_800 = 800;

  // <------------------    动效延迟  delay  ----------------------->
  //delay  50
  public static readonly ANIM_DELAY_50 = 50;
  //delay  100
  public static readonly ANIM_DELAY_100 = 100;
  //delay  150
  public static readonly ANIM_DELAY_150 = 150;
  //delay  200
  public static readonly ANIM_DELAY_200 = 200;
  //delay  250
  public static readonly ANIM_DELAY_250 = 250;
  //delay  400
  public static readonly ANIM_DELAY_400 = 400;
  //delay  500
  public static readonly ANIM_DELAY_500 = 500;
  //delay  550
  public static readonly ANIM_DELAY_550 = 550;
  //delay  700
  public static readonly ANIM_DELAY_700 = 700;
  //delay  950
  public static readonly ANIM_DELAY_950 = 950;
  //delay  1000
  public static readonly ANIM_DELAY_1000 = 1000;
  //delay  1500
  public static readonly ANIM_DELAY_1500 = 1500;


  // <------------------    旋转动画角度值  delay  ----------------------->
  //rotate 0
  public static readonly ANIM_ROTATE_0 = 0;
  //rotate 90
  public static readonly ANIM_ROTATE_90 = 90;
  //rotate 180
  public static readonly ANIM_ROTATE_180 = 180;
  //rotate 270
  public static readonly ANIM_ROTATE_270 = 270;
  //rotate 360
  public static readonly ANIM_ROTATE_360 = 360;

  // <------------------    预览翻转动效参数   ----------------------->
  // 取景框  缩放比例  0.8
  public static readonly CAMERA_FLIP_SCALE_END = 0.8;

  // 取景框1 终点旋转角度  80
  public static readonly CAMERA_FLIP_BLUR1_ROTATION_END = 80;

  // 取景框2 起点旋转角度  -80
  public static readonly CAMERA_FLIP_BLUR2_ROTATION_START = -80;

  // 摄像头按钮外圈 缩放比例90%
  public static readonly CAMERA_FLIP_SCALE_90 = 0.9;

  // 摄像头按钮外圈 缩放比例150%
  public static readonly CAMERA_FLIP_SCALE_150 = 1.5;
  // <------------------    拍照动效参数  ----------------------->
  // 拍照公用弹簧曲线
  public static readonly ANIM_CAPTURE_CURVE: curves.ICurve = curves.interpolatingSpring(1, 1, 410, 38);
  public static readonly ANIM_CAPTURE_CURVE_STRING: string = 'interpolating-spring(1, 1, 410, 38)';
  public static readonly ANIM_NIGHT_CURVE: curves.ICurve = curves.interpolatingSpring(1, 1, 410, 38);
  // 拍照按钮
  public static readonly ANIM_CAPTURE_BUTTON_DELAY = 0;
  public static readonly ANIM_CAPTURE_BUTTON_UP_DURATION = 200;
  public static readonly ANIM_CAPTURE_BUTTON_SCALE_DOWN: ScaleOptions = { x: 0.8, y: 0.8 };
  public static readonly ANIM_CAPTURE_BUTTON_SCALE_UP: ScaleOptions = { x: 1, y: 1 };
  public static readonly ANIM_CAPTURE_BUTTON_SCALE_UP_FACTOR: number = 1;
  public static readonly ANIM_NIGHT_BUTTON_SCALE_UP: ScaleOptions = { x: 1, y: 1 };
  public static readonly ANIM_AUDIO_CONTROL_CAPTURE_BUTTON_SCALE_DOWN: ScaleOptions = { x: 0.7, y: 0.7 };
  public static readonly ANIM_NIGHT_BUTTON_SCALE_DOWN: ScaleOptions = { x: 0.88, y: 0.88 };
  public static readonly ANIM_NIGHT_BUTTON_ONE_SCALE_DOWN: ScaleOptions = { x: 0.9, y: 0.9 };
  public static readonly ANIM_NIGHT_BUTTON_TWO_SCALE_DOWN: ScaleOptions = { x: 0, y: 0 };
  public static readonly ANIM_NIGHT_BUTTON_WIDTH_START: number = 22;
  public static readonly ANIM_NIGHT_BUTTON_WIDTH_MIDDLE: number = 42;
  public static readonly ANIM_NIGHT_BUTTON_WIDTH_END: number = 48;
  public static readonly ANIM_NIGHT_BUTTON_COLOR_MIDDLE: Color = Color.Gray;
  public static readonly ANIM_NIGHT_BUTTON_COLOR_END: Color = Color.White;
  public static readonly ANIM_NIGHT_BUTTON_RADIUS_START: number = 4;
  public static readonly ANIM_NIGHT_BUTTON_RADIUS_END: number = 24;
  public static readonly ANIM_PANORAMA_BUTTON_WIDTH_END: number = 48;
  public static readonly ANIM_PANORAMA_BUTTON_SCALE_UP: ScaleOptions = { x: 1, y: 1 };
  public static readonly ANIM_PANORAMA_BUTTON_WIDTH_MIDDLE: number = 42;
  public static readonly ANIM_PANORAMA_BUTTON_SCALE_DOWN: ScaleOptions = { x: 0.88, y: 0.88 };
  public static readonly ANIM_PANORAMA_BUTTON_RADIUS_END: number = 24;
  public static readonly ANIM_PANORAMA_BUTTON_ONE_SCALE_DOWN: ScaleOptions = { x: 0.9, y: 0.9 };
  public static readonly ANIM_PANORAMA_BUTTON_WIDTH_START: number = 22;
  public static readonly ANIM_PANORAMA_BUTTON_RADIUS_START: number = 4;
  public static readonly ANIM_PANORAMA_BUTTON_TWO_SCALE_DOWN: ScaleOptions = { x: 0, y: 0 };
  public static readonly ANIM_PANORAMA_BUTTON_COLOR_END: Color = Color.White;
  public static readonly ANIM_PANORAMA_BUTTON_COLOR_MIDDLE: Color = Color.Gray;
  public static readonly ANIM_STITCHING_BUTTON_WIDTH: number = 48;
  public static readonly ANIM_STITCHING_BUTTON_WIDTH_MIDDLE: number = 42;
  public static readonly ANIM_STITCHING_BUTTON_WIDTH_CAPTURE: number = 22;
  public static readonly ANIM_STITCHING_BUTTON_RADIUS: number = 24;
  public static readonly ANIM_STITCHING_BUTTON_RADIUS_CAPTURE: number = 4;
  // 取景框闪黑
  public static readonly ANIM_CAPTURE_FLASH_BLACK_DELAY = 50;
  public static readonly ANIM_CAPTURE_FLASH_BLACK_DURATION = 200;
  public static readonly ANIM_CAPTURE_FLASH_BLACK_OPACITY_FROM = 1;
  public static readonly ANIM_CAPTURE_FLASH_BLACK_OPACITY_TO = 0;
  // 缩略图
  public static readonly ANIM_CAPTURE_THUMBNAIL_OPACITY_FROM = 0;
  public static readonly ANIM_CAPTURE_THUMBNAIL_OPACITY_TO = 1;
  public static readonly ANIM_CAPTURE_THUMBNAIL_SCALE_FROM: ScaleOptions = { x: 1.5, y: 1.5 };
  public static readonly ANIM_CAPTURE_THUMBNAIL_SCALE_TO: ScaleOptions = { x: 1, y: 1 };

  // <------------------    长按左滑右滑连拍动效参数    ----------------------->
  public static readonly ANIM_INNER_BUTTON_RADIUS: number = 12;
  public static readonly ANIM_INNER_BUTTON_DIAMETER: number = AnimSpecifications.ANIM_INNER_BUTTON_RADIUS * 2;
  public static readonly ANIM_FOLLOW_HAND_BUTTON_RADIUS: number = 24;
  public static readonly ANIM_FOLLOW_HAND_BUTTON_DIAMETER: number =
    AnimSpecifications.ANIM_FOLLOW_HAND_BUTTON_RADIUS * 2;
  // 恢复跟手圆大小到快门大小
  public static readonly ANIM_FOLLOW_HAND_CIRCLE_SCALE_UP_CURVE: curves.ICurve =
    curves.interpolatingSpring(0, 1, 450, 25);
  public static readonly ANIM_FOLLOW_HAND_CIRCLE_SCALE_UP_CURVE_STRING: string = 'interpolating-spring(0, 1, 450, 25)';
  // 跟手曲线
  public static readonly ANIM_FOLLOW_HAND_MOVE_CURVE: curves.ICurve = curves.responsiveSpringMotion(0.15, 0.86, 0.25);
  // 中心圆跟手曲线
  public static readonly ANIM_INNER_FOLLOW_HAND_MOVE_CURVE: curves.ICurve = curves.responsiveSpringMotion(0.397, 1.01);
  // 离手曲线
  public static readonly ANIM_LEAVE_HAND_MOVE_CURVE: curves.ICurve = curves.interpolatingSpring(0, 1, 350, 23);
  // 跟手圆大小
  public static readonly ANIM_CAPTURE_BUTTON_SCALE_LR_SWIPE: ScaleOptions = { x: 0.667, y: 0.667 };
  public static readonly ANIM_CAPTURE_BUTTON_SCALE_LR_SWIPE_FACTOR: number = 0.667;

  // <------------------    录制动效参数  ----------------------->
  public static readonly ANIM_VIDEO_CURVE: curves.ICurve = curves.interpolatingSpring(1, 1, 410, 38);
  // 录制按钮
  public static readonly ANIM_VIDEO_BUTTON_DELAY = 0;
  public static readonly ANIM_VIDEO_START_DURATION = 50;
  public static readonly ANIM_VIDEO_START_TRANSLATE_DURATION = 100;
  public static readonly ANIM_VIDEO_BUTTON_SCALE_UP: ScaleOptions = { x: 1, y: 1 };
  public static readonly ANIM_VIDEO_BUTTON_1_SCALE_DOWN: ScaleOptions = { x: 0.9, y: 0.9 };
  public static readonly ANIM_VIDEO_BUTTON_2_SCALE_DOWN: ScaleOptions = { x: 0, y: 0 };
  public static readonly ANIM_VIDEO_BUTTON_WIDTH_START: number = 22;
  public static readonly VDE_ANIM_VIDEO_BUTTON_WIDTH_START: number = 21;
  public static readonly ANIM_VIDEO_BUTTON_WIDTH_END: number = 48;
  public static readonly ANIM_CONTINUUM_VIDEO_BUTTON_WIDTH_END: number = 64;
  public static readonly VDE_ANIM_VIDEO_BUTTON_WIDTH_END: number = 40;
  public static readonly ANIM_VIDEO_BUTTON_RADIUS_START: number = 4;
  public static readonly ANIM_VIDEO_BUTTON_RADIUS_END: number = 24;
  public static readonly ANIM_VIDEO_BUTTON_COLOR_START: Color = Color.Red;
  public static readonly ANIM_VIDEO_BUTTON_COLOR_END: Color = Color.White;

  // <------------------    模式切换动效参数  ----------------------->
  public static readonly ANIM_MODE_SWITCH_CURVE = curves.interpolatingSpring(0, 1, 228, 30);
  public static readonly ANIM_MODE_SWITCH_BLUR = 80;

  // <------------------    预览区上下移动动效参数   ----------------------->
  public static readonly ANIM_PREVIEW_AREA_UP_OR_DOWN: curves.ICurve = curves.interpolatingSpring(0, 1, 439, 41);

  // paramBar 图标消失出现动效
  public static readonly ANIM_PARAM_BAR_APPEAR_OR_DISAPPEAR: TransitionEffect =
    TransitionEffect.asymmetric(TransitionEffect.OPACITY.animation({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp
    }), TransitionEffect.OPACITY.animation({ duration: 150, curve: Curve.Sharp }));

  // 大字体动效
  public static readonly ANIM_BIG_TEXT_APPEAR_OR_DISAPPEAR: TransitionEffect =
    TransitionEffect.asymmetric(
      TransitionEffect // 大字体进场动效
        .scale({ x: 0.9, y: 0.9 })
        .animation({
          duration: 500,
          curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
        })
        .combine(TransitionEffect.OPACITY
          .animation({
            duration: 100,
            curve: Curve.Sharp
          })),
      TransitionEffect // 大字体退场动效
        .scale({ x: 0.9, y: 0.9 })
        .animation({
          duration: 200,
          curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
        })
        .combine(TransitionEffect.OPACITY
          .animation({
            duration: 200,
            curve: curves.cubicBezierCurve(0, 0, 0, 1)
          }))
    );

  // <------------------    缩略图及大图组件动效参数  ----------------------->
  public static readonly ANIM_PB_SHARE_OPEN_CURVE: curves.ICurve = curves.interpolatingSpring(0, 1, 228, 25);
  public static readonly ANIM_PB_SHARE_CLOSE_CURVE: curves.ICurve = curves.interpolatingSpring(0, 1, 450, 42);
  public static readonly ANIM_PB_SHARE_DURATION = 300;
  public static readonly GEOMETRY_TRANSITION_ID_THUMBNAIL = 'Thumbnail_GeometryTransitionId';

  // <------------------    设置页入场动效参数  ----------------------->
  public static readonly NUM_4: number = 4;

  public static getSettingTransition(direction: WindowDirection, windowSize: Size): TransitionEffect {
    let options: TranslateOptions;
    switch (direction) {
      case WindowDirection.TOP:
        options = { x: windowSize.width / AnimSpecifications.NUM_4 };
        break;
      case WindowDirection.LEFT:
        options = { y: -windowSize.height / AnimSpecifications.NUM_4 };
        break;
      case WindowDirection.RIGHT:
        options = { y: windowSize.height / AnimSpecifications.NUM_4 };
        break;
      default:
        let angel = WindowService.getInstance().getUiContext()?.getComponentUtils()
          .getRectangleById('settingView').rotate.angle;
        HiLog.i(TAG, `angel: ${angel}`);
        if (!angel) {
          options = { x: windowSize.width / AnimSpecifications.NUM_4 };
          break;
        }
        if (angel % 360 === 0) {
          options = { x: windowSize.width / AnimSpecifications.NUM_4 };
        } else if (angel > 0) {
          if (angel % 270 === 0) {
            options = { y: -windowSize.height / AnimSpecifications.NUM_4 };
          } else {
            options = { y: windowSize.height / AnimSpecifications.NUM_4 };
          }
        } else {
          if (angel % 270 === 0) {
            options = { y: windowSize.height / AnimSpecifications.NUM_4 };
          } else {
            options = { y: -windowSize.height / AnimSpecifications.NUM_4 };
          }
        }
        break;
    }
    if (getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed')) {
      options = { y: windowSize.height / AnimSpecifications.NUM_4 };
    }
    return TransitionEffect.asymmetric(
      TransitionEffect.translate(options)
        .animation({ duration: AnimSpecifications.ANIM_DURATION_300, curve: Curve.Friction })
        .combine(TransitionEffect.OPACITY.animation({ duration: AnimSpecifications.ANIM_DELAY_150,
          curve: Curve.Sharp })),
      TransitionEffect.translate(options)
        .animation({ duration: AnimSpecifications.ANIM_DURATION_200, curve: Curve.Friction })
        .combine(TransitionEffect.OPACITY.animation({ duration: AnimSpecifications.ANIM_DURATION_100,
          curve: Curve.Sharp })))
  }

  public static getOffset(direction: WindowDirection, windowSize: Size, num: number): Position {
    let options: Position;
    switch (direction) {
      case WindowDirection.TOP:
        options = { x: windowSize.width / num };
        break;
      case WindowDirection.LEFT:
        options = { y: -windowSize.height / num };
        break;
      case WindowDirection.RIGHT:
        options = { y: windowSize.height / num };
        break;
      default:
        let angel = WindowService.getInstance().getUiContext()?.getComponentUtils()
          .getRectangleById('settingView').rotate.angle;
        HiLog.i(TAG, `angel: ${angel}`);
        if (!angel) {
          options = { x: windowSize.width / num };
          break;
        }
        if (angel % 360 === 0) {
          options = { x: windowSize.width / num };
        } else if (angel > 0) {
          if (angel % 270 === 0) {
            options = { y: -windowSize.height / num };
          } else {
            options = { y: windowSize.height / num };
          }
        } else {
          if (angel % 270 === 0) {
            options = { y: windowSize.height / num };
          } else {
            options = { y: -windowSize.height / num };
          }
        }
        break;
    }
    if (getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed')) {
      options = { y: windowSize.height / num };
    }
    return options;
  }
  // <------------------    屏百宝箱动效参数  ----------------------->
  public static readonly START_AND_GRADIANT_COLORS: [ResourceColor, number][] = [
    ['rgba(255,255,255,0)', 0],
    ['rgba(255,255,255,1)', 0.2],
    ['rgba(255,255,255,1)', 0.93],
    ['rgba(255,255,255,0)', 1]
  ];
  public static readonly ONLY_START_GRADIANT_COLORS: [ResourceColor, number][] = [
    ['rgba(255,255,255,0)', 0],
    ['rgba(255,255,255,1)', 0.07]
  ];
  public static readonly ONLY_END_GRADIANT_COLORS: [ResourceColor, number][] = [
    ['rgba(255,255,255,1)', 0.93],
    ['rgba(255,255,255,0)', 1]
  ];
  public static readonly NONE_GRADIANT_COLORS: [ResourceColor, number][] = [
    ['rgba(255,255,255,1)', 0],
    ['rgba(255,255,255,1)', 1]
  ];

  // <------------------    风格大师动效参数    ----------------------->
  public static readonly HUE_SELECT_RANGE: number = 21; // 色温 - > matrix列数/宽
  public static readonly SATURATION_SELECT_RANGE: number = 11; // 饱和度  - > matrix行数/高
  public static readonly TONE_SELECT_RANGE: number = 11; // 光影  - > slider高

  public static readonly CUSTOM_FILTER_STYLE_DOT_COLOR_OPACITY: number = 0.4;
  public static readonly CUSTOM_FILTER_STYLE_DOT_UNSELECT_RADIUS: number = 1.5;
  public static readonly CUSTOM_FILTER_STYLE_DOT_ORIGIN_RADIUS: number = 1.5;
  public static readonly CUSTOM_FILTER_STYLE_DOT_ORIGIN_RIM_WIDTH: number = 1;
  public static readonly CUSTOM_FILTER_STYLE_DOT_SELECT_RADIUS: number = 5;
  public static readonly GRID_SPACING_HEIGHT: number =
    5.7 + AnimSpecifications.CUSTOM_FILTER_STYLE_DOT_UNSELECT_RADIUS * 2;
  public static readonly SLIDER_HEIGHT: number = 90;
  public static readonly SELECT_SLIDER_HEIGHT: number = 86;
  public static readonly SLIDER_WIDTH: number = 30;
  public static readonly SELECT_SLIDER_WIDTH: number = 26;
  public static readonly SLIDER_BORDER_RADIUS: number = 15;
  public static readonly SELECT_SLIDER_BORDER_RADIUS: number = 13;
  public static readonly SLIDER_TO_MATRIX_DIST: number = 16;
  public static readonly CARD_TO_SCREEN_SIDE_MARGIN: number = 15.5;
  public static readonly MATRIX_BACKGROUND_HEIGHT: number = 114;
  public static readonly MATRIX_BACKGROUND_TO_CARD_SIDE_MARGIN: number = 12;
  public static readonly MATRIX_AND_SLIDE_BAR_TO_MATRIX_BACKGROUND_SIDE_MARGIN: number = 12;
  public static readonly SWITCH_STYLE_150_MS: number = 150;
  public static readonly SWITCH_STYLE_CURVE: Curve | string | ICurve = Curves.cubicBezierCurve(0.8, 0.2, 0.8, 0.2);
  public static readonly SWITCH_STYLE_SHOW_CURVE: Curve | string | ICurve = Curve.Linear;
  public static readonly SWITCH_STYLE_HIDE_CURVE: Curve | string | ICurve = Curve.Linear;
  public static readonly STYLE_NAME_TEXT_SIZE: number = 16;
  public static readonly STYLE_TEXT_MAX_LENGTH: number = 8.5;// 目前名字长度最大支持8.5个字
  public static readonly CUSTOM_FILTER_SLIDER_ICON_WIDTH_HEIGHT: number = 18;
  public static readonly CUSTOM_FILTER_SLIDER_ICON_LEFT_RIGHT_BOTTOM_MARGIN: number = 6;
  public static readonly CUSTOM_FILTER_SLIDER_ICON_TOP_MARGIN: number = 66;
  public static readonly CUSTOM_FILTER_CARD_COLOR: ResourceColor = '#FF191B1D';

  public static readonly ADD_TEMPLATE_150_MS: number = 150;
  public static readonly ADD_TEMPLATE_300_MS: number = 300;
  public static readonly ADD_TEMPLATE_SHOW_OPACITY_CURVE: Curve | string | ICurve = Curve.Sharp;
  public static readonly ADD_TEMPLATE_SHOW_SCALE_CURVE: Curve | string | ICurve = Curve.Friction;
  public static readonly ADD_TEMPLATE_HIDE_OPACITY_CURVE: Curve | string | ICurve = Curve.Sharp;
  public static readonly ADD_TEMPLATE_MOVE_CURVE: Curve | string | ICurve = Curve.Friction;

  public static readonly NEW_FLOAT_WINDOW_TOP_OFFSET: number = 52;
  public static readonly NEW_FLOAT_WINDOW_RATIO: number = 1.55;
}