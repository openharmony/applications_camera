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
import lazy { SensorData } from './HorizontalLevelOperation';
import lazy { Usage, VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { display } from '@kit.ArkUI';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ChangeState, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';

/* instrument ignore file */
const LINE_LENGTH: number = 24;
const LINE_WIDTH: number = 1;
export const MOVABLE_CRUCIFIX_SHADOW_RADIUS: number = 4;
export const MOVABLE_CRUCIFIX_COLOR: string = '#F7CE00';
const FIXED_CRUCIFIX_COLOR: string = '#FFFEFE';
const SHADOW_COLOR: string = '#40000000';
const MAX_LENGTH: number = 24; // 手机偏移15°时光标到原点的距离
const rate: number = 9.46212; // 重力加速度在xy平面投影MAX_LENGTH / (G * sin15°) 手机偏移15°后隐藏十字光标
const VIBRATOR_USAGE_PHYSIC: Usage = 'physicalFeedback';
const THRESHOLD: number = 2 // 十字光标吸附阈值, 平板10, 手机5
const OVERLOOKING_GRAVITY_OF_Z_AXIS: number = 9.466; //屏幕与水平面夹角小于15°时, 显示垂直水平仪(G * cos15°)
const OFFSET_OF_Z_AXIS: number = DeviceInfo.isRk3568() ? 4 : (DeviceInfo.isUis7885() ? 1 : 0); // 适配 RK3568
const RATE_OF_X_AXIS: number = DeviceInfo.isUis7885() ? - 50000 : 1; // 适配 RK7885
const RATE_OF_Y_AXIS: number = DeviceInfo.isUis7885() ? - 50000 : 1;
const RATE_OF_Z_AXIS: number = DeviceInfo.isUis7885() ? 100000 : 1;
export const DURATION: number = 150;
const FIX_CRUCIFIX_TIMER_DURATION: number = 100;
interface mSensorData {
  sensorX: number;
  sensorY: number;
}

@Component
export struct HorizontalCrucifix {
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private fillColor: string = FIXED_CRUCIFIX_COLOR;
  private shadowRadius: number = 2;
  private isMovable: boolean = false;
  @State positionX: number = 0;
  @State positionY: number = 0;
  private prevPositionX: number = Number.MAX_SAFE_INTEGER;
  private prevPositionY: number = Number.MAX_SAFE_INTEGER;
  @StorageLink('sensorData') @Watch('senSorDataChange') sensorData: SensorData = { x: 0, y: 0, z: 0 };
  private firstMove: boolean = true;
  @StorageLink('showHorizontalCrucifixView') showHorizontalCrucifixView: boolean = false;
  @StorageLink('showHorizontalLevelView') showHorizontalLevelView: boolean = false;
  @State isHorizontalCrucifixAtCenter: boolean = false;
  private fixCrucifixOpacityTimer: number = -1;
  @Prop @Watch('hiddenCrucifix') isHorizontalCrucifixVisible: boolean = false;
  @StorageLink('showPhotoBrowserAction') @Watch('hiddenCrucifix') showPhotoBrowserAction: boolean = false;
  @Prop mode: ModeType = ModeType.NONE;
  @State isHdr: boolean = false;

  aboutToAppear(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isHdr = state.get<boolean>('settingReducer', 'isHdrOpen');
    }, null);
    this.showHorizontalCrucifixView = false;
  }

  aboutToDisappear(): void {
    this.mSubscriber?.destroy();
    this.showHorizontalCrucifixView = false;
  }

  private hiddenCrucifix(): void {
    this.showHorizontalCrucifixView = false;
    this.firstMove = true;
  }

  getSensorXAndSensorY(): mSensorData {
    let orientation: number = DisplayService.getInstance().getDisplay().orientation;
    if (orientation === display.Orientation.PORTRAIT) {
      return { sensorX: this.sensorData.x, sensorY: -this.sensorData.y };
    }
    if (orientation === display.Orientation.LANDSCAPE) {
      return { sensorX: -this.sensorData.y, sensorY: -this.sensorData.x };
    }
    if (orientation === display.Orientation.PORTRAIT_INVERTED) {
      return { sensorX: -this.sensorData.x, sensorY: this.sensorData.y };
    }
    if (orientation === display.Orientation.LANDSCAPE_INVERTED) {
      return { sensorX: this.sensorData.y, sensorY: this.sensorData.x };
    }
    return { sensorX: 0, sensorY: 0 };
  }

  private senSorDataChange(): void {
    if (this.isMovable && !this.showPhotoBrowserAction) {
      if (Math.abs(this.sensorData.z * RATE_OF_Z_AXIS + OFFSET_OF_Z_AXIS) < OVERLOOKING_GRAVITY_OF_Z_AXIS &&
        !this.showHorizontalCrucifixView) {
        // 旋转15°且十字光标隐藏后不再计算
        this.firstMove = true;
        return;
      }
      let sensorData: mSensorData = this.getSensorXAndSensorY();
      // 适配不同设备
      if (DeviceInfo.isRk3568() || DeviceInfo.isUis7885()) {
        let temp = sensorData.sensorX;
        sensorData.sensorX = sensorData.sensorY;
        sensorData.sensorY = temp;
      }
      let positionX: number = sensorData.sensorX * rate * RATE_OF_X_AXIS;
      let positionY: number = sensorData.sensorY * rate * RATE_OF_Y_AXIS;
      let isNearCenter: boolean = Math.abs(positionX) < THRESHOLD && Math.abs(positionY) < THRESHOLD;
      positionX = isNearCenter ? 0 : positionX;
      positionY = isNearCenter ? 0 : positionY;
      if (this.prevPositionX === positionX && this.prevPositionY === positionY) {
        return;
      }
      let distanceToZero: number = Math.hypot(positionX, positionY);
      if (this.firstMove) {
        // 切换模式场景首次接收到传感器数据时直接将光标移动到对应位置, 不然可能会出现光标先显示再隐藏的现象
        this.positionX = positionX;
        this.positionY = positionY;
        this.isHorizontalCrucifixAtCenter = this.positionY === 0 && this.positionX === 0;
        animateToImmediately({
          duration: DURATION,
          curve: Curve.Sharp
        }, () => {
          this.showHorizontalCrucifixView = distanceToZero < MAX_LENGTH;
        });
        this.firstMove = false;
        this.prevPositionX = this.positionX;
        this.prevPositionY = this.positionY;
      } else {
        if (positionX !== 0 && positionY !== 0 && this.prevPositionX === 0 && this.prevPositionY === 0) {
          // 十字光标由重叠到分开场景，立刻将固定十字光标显示出来
          this.isHorizontalCrucifixAtCenter = false;
        }
        animateToImmediately({
          duration: DURATION,
          curve: Curve.Sharp,
          onFinish: () => {
            clearTimeout(this.fixCrucifixOpacityTimer);
            // 十字光标移动到重叠时将固定十字光标隐藏, 用定时器解决在重叠之前固定十字光标就隐藏的问题
            this.fixCrucifixOpacityTimer = setTimeout(() => {
              this.isHorizontalCrucifixAtCenter = this.positionX === 0 && this.positionY === 0;
            }, FIX_CRUCIFIX_TIMER_DURATION);
            this.prevPositionX = this.positionX;
            this.prevPositionY = this.positionY;
          }
        }, () => {
          this.positionX = positionX;
          this.positionY = positionY;
          this.showHorizontalCrucifixView = distanceToZero < MAX_LENGTH;
        });
      }
    }
  }

  build() {
    Stack() {
      Column() {
      }
      .width(LINE_WIDTH)
      .height(LINE_LENGTH)
      .position({ x: '50%', y: 0 })
      .markAnchor({ x: '50%', y: 0 })
      .backgroundColor(this.fillColor)
      .shadow({ radius: this.shadowRadius, color: SHADOW_COLOR })

      Column() {
      }
      .width(LINE_LENGTH)
      .height(LINE_WIDTH)
      .position({ x: 0, y: '50%' })
      .markAnchor({ x: 0, y: '50%' })
      .backgroundColor(this.fillColor)
      .shadow({ radius: this.shadowRadius, color: SHADOW_COLOR })
    }
    .visibility(this.isMovable ? (this.showHorizontalCrucifixView ? Visibility.Visible : Visibility.Hidden) :
      (this.showHorizontalCrucifixView && !this.isHorizontalCrucifixAtCenter ? Visibility.Visible : Visibility.Hidden))
    .translate({ x: -this.positionX, y: -this.positionY })
    .height(LINE_LENGTH)
    .width(LINE_LENGTH)
  }
}