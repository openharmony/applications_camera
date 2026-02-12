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
import lazy { display, window } from '@kit.ArkUI';
import deviceInfo from '@ohos.deviceInfo';
import lazy { CompassController } from './CompassController';
import lazy { DeviceType } from './DrawUtils';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { CompassElement, LevelElement } from './Element';
import MathUtil from './MathUtil';
import DrawUtils from './DrawUtils';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { CollapsChangeService } from '@ohos/common/src/main/ets/service/collaps/CollapsChangeService';

export enum BreakPointType {
  XS,
  SM,
  MD,
  LG,
  XL,
}

interface BreakPoint {
  type: BreakPointType,
  size: number;
}

const BREAK_POINT_LIST: BreakPoint[] = [
  {
    type: BreakPointType.XS,
    size: 0
  },
  {
    type: BreakPointType.SM,
    size: 320
  },
  {
    type: BreakPointType.MD,
    size: 600
  },
  {
    type: BreakPointType.LG,
    size: 840
  },
  {
    type: BreakPointType.XL,
    size: Number.POSITIVE_INFINITY
  }
];

const GUTTER_MAPPER: Map<BreakPointType, number> = new Map([[BreakPointType.XS, 8], [BreakPointType.SM, 8],
  [BreakPointType.MD, 12], [BreakPointType.LG, 12], [BreakPointType.LG, 12], [BreakPointType.XL, 12]]);


const MARGIN_MAPPER: Map<BreakPointType, number> = new Map([[BreakPointType.XS, 12], [BreakPointType.SM, 16],
  [BreakPointType.MD, 24], [BreakPointType.LG, 24], [BreakPointType.LG, 24], [BreakPointType.XL, 24]]);

const DEFAULT_DRAW_SIZE = 290;

const DEFAULT_SCREEN_WIDTH = 360;

const DEFAULT_SCREEN_HEIGHT = 780;

const STATE_KEY_JWD_SHOW_STATE = 'jwd_show_state';

const COMPASS_DISC_RATIO = 0.727758;

const DEFAULT_RADIUS = 145;

export class DisplayScreen {
  private static readonly TAG = 'DisplayScreen';
  public static scaledDensity: number = 1;
  public static deviceType: DeviceType = DeviceType.PHONE;
  public static deviceWidthPx: number = DisplayService.getInstance().getDisplay().width;
  private static oldDeviceWidthPx: number;
  public static deviceHeightPx: number = DisplayService.getInstance().getDisplay().height;
  // 设备屏幕方向
  private static displayScreenRotation: number = 0;
  private static displayCollapsStatus: display.CollapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
  public static deviceDrawSize: number = DEFAULT_DRAW_SIZE;
  public breakpointType: BreakPointType = BreakPointType.SM;
  public windowStatusType: window.WindowStatusType = window.WindowStatusType.FULL_SCREEN;
  private width: number = 0;
  private height: number = 0;
  public widthPx: number = 0;
  public heightPx: number = 0;
  private cellSize: number = 0;
  public cellSizePx: number = 0;
  private gutter: number = 0;
  public margin: number = 0;
  private directionCardPadding: number = 0;
  private altMagneticCardPadding: number = 0;
  private latLngBlankSize: number = 0;
  public compassSize: CompassSize =
    new CompassSize(CompassController.getInstance().getDrawSize(), window.WindowStatusType.FULL_SCREEN);

  private constructor() {

  }

  private static initDisplayScreen(screenSize: DisplayScreen) {
    let deviceType = deviceInfo.deviceType;
    DisplayScreen.deviceType = deviceType as DeviceType;
    screenSize.breakpointType = DisplayScreen.getBreakpointType(screenSize.width);
    DisplayScreen.displayCollapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
    screenSize.gutter = GUTTER_MAPPER.get(screenSize.breakpointType) ?? 0;
    screenSize.margin = MARGIN_MAPPER.get(screenSize.breakpointType) ?? 0;

    screenSize.cellSize =
      DrawUtils.getCellSize(screenSize.breakpointType, screenSize.width, screenSize.gutter, screenSize.margin);
    // 计算尺寸margin与gutter对换
    screenSize.cellSizePx =
      DrawUtils.getCellSize(screenSize.breakpointType, screenSize.widthPx, screenSize.margin, screenSize.gutter);

    if (screenSize.breakpointType === BreakPointType.XS || screenSize.breakpointType === BreakPointType.SM) {
      screenSize.altMagneticCardPadding = screenSize.margin;
      screenSize.latLngBlankSize = screenSize.gutter;
      screenSize.directionCardPadding = screenSize.margin;
    } else {
      screenSize.altMagneticCardPadding = screenSize.cellSize + screenSize.gutter + screenSize.margin;
      screenSize.latLngBlankSize = screenSize.cellSize + 2 * screenSize.gutter;
      screenSize.directionCardPadding = screenSize.altMagneticCardPadding;
    }
    if (DisplayScreen.oldDeviceWidthPx !== DisplayScreen.deviceWidthPx) {
      let deviceBreakpointType =
        DisplayScreen.getBreakpointType(DrawUtils.pxToVp(DisplayScreen.deviceWidthPx, DisplayScreen.scaledDensity));
      DisplayScreen.deviceDrawSize =
        DrawUtils.getOriginDrawSize(deviceBreakpointType, DisplayScreen.deviceType, DisplayScreen.deviceWidthPx,
          screenSize.gutter, screenSize.margin);
      DisplayScreen.oldDeviceWidthPx = DisplayScreen.deviceWidthPx;
    }
    let sysHeight = DisplayService.getInstance().getDisplay().height;
    let dataHeight: number | undefined = AppStorage.get('winHeight');
    HiLog.d(DisplayScreen.TAG,
      `verde initDisplayScreen sysHeight ${sysHeight} dataHeight ${dataHeight}`)
    try {
      window.getLastWindow(getContext(), (err, win) => {
        if (window.Orientation.AUTO_ROTATION) {
          const sysDisplay: display.Display = DisplayService.getInstance().getDisplay();
          // 获取当前屏幕的枚举值
          let rotation: number = sysDisplay.orientation
          HiLog.i(DisplayScreen.TAG,
            `verde getLastWindow sysHeight  orientation ${rotation}`)
          DisplayScreen.displayScreenRotation = rotation
          if (rotation === 0) {
            // 竖屏 verde 竖屏
            if (sysDisplay.width === sysDisplay.height) {
              AppStorage.set(STATE_KEY_JWD_SHOW_STATE, false);
            } else {
              AppStorage.set(STATE_KEY_JWD_SHOW_STATE, DisplayScreen.getIsShowJwd(sysHeight, dataHeight));
            }
          } else if (rotation === 1) {
            //反向横屏 使用宽计算比例
            let sysWidth = sysDisplay.width;
            let dataWidth: number | undefined = AppStorage.get('winWidth');
            AppStorage.set(STATE_KEY_JWD_SHOW_STATE, DisplayScreen.getIsShowJwd(sysWidth, dataWidth));
          } else if (rotation === 2) {
            //反向竖屏
            AppStorage.set(STATE_KEY_JWD_SHOW_STATE, DisplayScreen.getIsShowJwd(sysHeight, dataHeight));
          } else if (rotation === 3) {
            // rotation = 3 显示内容与横屏模式方向相反
            // 竖屏 verde 竖屏
            if (sysDisplay.width === sysDisplay.height) {
              AppStorage.set(STATE_KEY_JWD_SHOW_STATE, false);
            } else {
              //横屏 使用宽计算比例
              let sysWidth = sysDisplay.width;
              let dataWidth: number | undefined = AppStorage.get('winWidth');
              AppStorage.set(STATE_KEY_JWD_SHOW_STATE, DisplayScreen.getIsShowJwd(sysWidth, dataWidth));
            }
          }
        }
      })
    } catch (e) {
      HiLog.e(DisplayScreen.TAG, 'initDisplayScreen error');
    }

    screenSize.compassSize =
      CompassSize.createCompassSize(DrawUtils.getDrawSize(screenSize), screenSize.widthPx, screenSize.heightPx,
        screenSize.windowStatusType);
  }

  static createDisplayScreen(widthVp: number, heightVp: number,
    windowStatusType: window.WindowStatusType): DisplayScreen {
    let defaultDisplay = DisplayService.getInstance().getDisplay();
    DisplayScreen.scaledDensity = defaultDisplay.scaledDensity;
    DisplayScreen.deviceWidthPx = defaultDisplay.width;
    DisplayScreen.deviceHeightPx = defaultDisplay.height;
    let screenSize = new DisplayScreen();
    screenSize.width = widthVp;
    screenSize.height = heightVp;
    screenSize.widthPx = DrawUtils.vpToPx(widthVp, DisplayScreen.scaledDensity);
    screenSize.heightPx = DrawUtils.vpToPx(heightVp, DisplayScreen.scaledDensity);
    screenSize.windowStatusType = windowStatusType;
    DisplayScreen.initDisplayScreen(screenSize);
    CompassController.getInstance().setDrawSize(DrawUtils.getDrawSize(screenSize))
    return screenSize;
  }

  static createDisplayScreenByPX(widthPX: number, heightPX: number,
    windowStatusType: window.WindowStatusType): DisplayScreen {
    let defaultDisplay = DisplayService.getInstance().getDisplay();
    DisplayScreen.scaledDensity = defaultDisplay.scaledDensity;
    let screenSize = new DisplayScreen();
    screenSize.widthPx = widthPX;
    screenSize.heightPx = heightPX;
    screenSize.width = DrawUtils.pxToVp(widthPX, DisplayScreen.scaledDensity);
    screenSize.height = DrawUtils.pxToVp(heightPX, DisplayScreen.scaledDensity);
    screenSize.windowStatusType = windowStatusType;
    DisplayScreen.initDisplayScreen(screenSize);
    return screenSize;
  }

  public static getBreakpointType(width: number): BreakPointType {
    // 平板超大字体断点适配
    if (DisplayScreen.deviceType === DeviceType.TABLET && width < 600) {
      return BreakPointType.LG;
    }
    for (let index = BREAK_POINT_LIST.length - 1; index >= 0; index--) {
      const element = BREAK_POINT_LIST[index];
      if (width >= element.size) {
        return element.type;
      }
    }
    return BreakPointType.SM;
  }


  static createDefaultScreenSize(): DisplayScreen {
    let screenSize = new DisplayScreen();
    screenSize.width = DEFAULT_SCREEN_WIDTH;
    screenSize.height = DEFAULT_SCREEN_HEIGHT;
    screenSize.compassSize =
      new CompassSize(CompassController.getInstance().getDrawSize(), window.WindowStatusType.FULL_SCREEN);
    screenSize.cellSize = 0;
    screenSize.altMagneticCardPadding = 0;
    return screenSize;
  }

  static getIsShowJwd(sysHeight: number, dataHeight: number | undefined): boolean {
    HiLog.d(DisplayScreen.TAG, `verde getIsShowJwd sysHeight ${sysHeight} dataHeight ${dataHeight}}`)
    let i = sysHeight / 3;
    let ii = i * 2;
    let k = sysHeight / 2;
    if (dataHeight && dataHeight <= i) {
      //1:2
      return false;
    } else if (dataHeight && dataHeight > i && dataHeight <= k) {
      //1:1
      return false;
    } else if (dataHeight && dataHeight <= ii && dataHeight > k) {
      //2:1
      return true;
    } else {
      return true;
    }
  }

  //获取分屏比例
  static getSplitScreenState(sysHeight: number, dataHeight: number | undefined): number {
    let i = sysHeight / 3;
    let ii = i * 2;
    let k = sysHeight / 2;
    if (dataHeight && dataHeight <= i) {
      //1:2
      return 1;
    } else if (dataHeight && dataHeight > i && dataHeight <= k) {
      //1:1
      return 2;
    } else if (dataHeight && dataHeight <= ii && dataHeight > k) {
      //2:1
      return 3;
    } else {
      return 0;
    }
  }

  // 是否verde 外屏
  public static getVerdeExternalScreen(): boolean {
    const verdeTrue = DeviceInfo.isVerde() && DisplayScreen.deviceWidthPx === DisplayScreen.deviceHeightPx;
    HiLog.d(DisplayScreen.TAG, `getVerdeExternalScreen  ${verdeTrue}`);
    return verdeTrue;
  }
}

export class CompassSize {
  public static MAX_WIDTH: number = 320;
  public drawSizePx: number = 0;
  public radiusPx: number = 0;
  public drawSizeVp: number = 0;
  public radiusVp: number = 0;
  public scaledDensity: number = 1;
  public compassElement: CompassElement;
  public levelElement: LevelElement;
  public elementRatio: number = 1;
  public fontRatio: number = 1;
  public lineRatio: number = 1;
  public isShowCompass: boolean = true;
  public discImgSize: number = 0;

  constructor(drawSizePx: number, windowStatusType: window.WindowStatusType) {
    this.drawSizePx = Math.min(drawSizePx, CompassSize.MAX_WIDTH * DisplayScreen.scaledDensity);
    this.radiusPx = this.drawSizePx / 2;
    this.drawSizeVp = DrawUtils.pxToVp(this.drawSizePx, DisplayScreen.scaledDensity);
    this.discImgSize = this.drawSizeVp / COMPASS_DISC_RATIO;
    this.radiusVp = this.drawSizeVp / 2;
    this.scaledDensity = DisplayScreen.scaledDensity;
    if (windowStatusType === window.WindowStatusType.SPLIT_SCREEN) {
      this.elementRatio =
        MathUtil.toFixedNumber(this.drawSizePx / this.scaledDensity / DEFAULT_DRAW_SIZE, 1, 10);
      if (this.elementRatio > 1) {
        this.elementRatio = 1;
      }
    }
    this.lineRatio = this.radiusPx / DEFAULT_RADIUS;
    this.compassElement = new CompassElement(this);
    this.levelElement = new LevelElement(this);
  }


  static createCompassSize(drawSizePx: number, widthPx: number, heightPx: number,
    windowStatusType: window.WindowStatusType): CompassSize {
    let compassSize = new CompassSize(drawSizePx, windowStatusType);
    if (widthPx !== DisplayScreen.deviceWidthPx) {
      compassSize.fontRatio = DrawUtils.getFontRatio(widthPx / DisplayScreen.deviceWidthPx);
    }
    return compassSize;
  }
}

