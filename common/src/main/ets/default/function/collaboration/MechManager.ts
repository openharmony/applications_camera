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
// @ts-ignore
import mechManager from '@ohos.distributedHardware.mechanicManager';
import lazy { CollaborateControlAction } from '../../../service/collaborateControl/CollaborateControlAction';
import lazy { StoreManager } from '../../../worker/StoreManager';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { simpleStringify } from '../../../utils/SimpleStringify';
import lazy { CollaborateControlService } from '../../../service/collaborateControl/CollaborateControlService';

const TAG = 'MechManager';

export interface FocusCoord {
  x?: number,
  y?: number
}

export interface MechStateParams {
  mechName: string,
  attachState: number,
  yawEnabled: boolean,
  rollEnabled: boolean,
  pitchEnabled: boolean,
  yawLimited: number,
  rollLimited: number,
  pitchLimited: number
}

const INVALID_LIMITED: number = -1;

enum ATTACH_STATE {
  ATTACHED = 0, // 连接
  DETACHED = 1 // 未连接
}

export enum TRACK_STATE {
  UNDEFINED = -1,
  DISABLE = 0, // 关闭
  ENABLE = 1 // 开启
}

/**
 * 机械体控制模块
 */
export class MechManager {
  private static sInstance: MechManager;
  private mMechId: number;
  private mMechName: string;
  // @ts-ignore
  private mAttachState: ATTACH_STATE;
  private mYawEnabled: boolean;
  private mRollEnabled: boolean;
  private mPitchEnabled: boolean;
  // @ts-ignore
  private mYawLimited: mechManager.RotationAxisLimited = INVALID_LIMITED; // 0：未到极限，1：负向极限，2：正向极限
  // @ts-ignore
  private mRollLimited: mechManager.RotationAxisLimited = INVALID_LIMITED;
  // @ts-ignore
  private mPitchLimited: mechManager.RotationAxisLimited = INVALID_LIMITED;
  private mRotateCount: number = 0;
  private mFocusCount: number = 0;
  private mTrackState: TRACK_STATE = TRACK_STATE.UNDEFINED;

  public static getInstance(): MechManager {
    if (!MechManager.sInstance) {
      MechManager.sInstance = new MechManager();
    }
    return MechManager.sInstance;
  }

  /**
   * 对焦事件
   *
   * @param x
   * @param y
   */
  public focusExposure(x: number, y: number): void {
    this.mFocusCount++;
    HiLog.i(TAG, `focusExposure x:${x}, y:${y}`);
    StoreManager.getInstance()?.postMessage(CollaborateControlAction.focus(x, y));
  }

  /**
   * 注册监听
   */
  public subscribe(): void {
    HiLog.i(TAG, 'subscribe start.');
    const mechDevices = this.getMechDevices();
    try {
      if (mechDevices?.length > 0) {
        // @ts-ignore
        this.initMechState(mechDevices[0]?.mechId, mechDevices[0]?.mechName, ATTACH_STATE.ATTACHED);
      }
      // 注册设备连接状态监听
      // @ts-ignore
      mechManager.on('attachStateChange', (data: mechManager.AttachStateChangeInfo) => {
        if (!data) {
          HiLog.w(TAG, 'attachStateChange no data');
          return;
        }
        HiLog.i(TAG, `attach state is ${data.state}, name:${data.mechInfo?.mechName}`);
        HiLog.d(TAG, `data: ${JSON.stringify(data)}`);

        if (data.state === mechManager.AttachState.ATTACHED) {
          this.initMechState(data?.mechInfo?.mechId, data?.mechInfo?.mechName, ATTACH_STATE.ATTACHED);
        } else {
          // 设备下线
          this.mAttachState = ATTACH_STATE.DETACHED;
          this.sendMechStateMsg();
          this.sendTrackState();
        }
      });
      // @ts-ignore
      mechManager.on('rotationAxesStatusChange', (data: mechManager.RotationAxesStateChangeInfo) => {
        if (!data) {
          HiLog.w(TAG, 'rotationAxesStatusChange no data');
          return;
        }
        HiLog.d(TAG, `rotationAxesStatusChange data: ${JSON.stringify(data)}`);

        // 旋转变化，发送给手表
        this.mYawLimited = data.status?.yawLimited;
        this.mRollLimited = data.status?.rollLimited;
        this.mPitchLimited = data.status?.pitchLimited;
        this.mYawEnabled = data.status?.yawEnabled;
        this.mRollEnabled = data.status?.rollEnabled;
        this.mPitchEnabled = data.status?.pitchEnabled;

        this.sendMechStateMsg();
      });
      mechManager.on('trackingStateChange', (data: mechManager.TrackingEventInfo) => {
        if (!data) {
          HiLog.w(TAG, 'trackingStateChange no data');
          return;
        }
        HiLog.i(TAG, `trackingStateChange data:${data.event}`);
        // 智能跟踪状态变化，通知手表
        this.sendTrackState();
      });
    } catch (e) {
      HiLog.e(TAG, `register failed, cause: ${simpleStringify(e)}`);
    }
  }

  /**
   * 云台已连接且支持跟踪
   *
   * @returns
   */
  public isGimbalAttachedAndTracking(): boolean {
    const mechDevices = this.getMechDevices();
    if (mechDevices && mechDevices.length > 0 && MechManager.getInstance().isTrackingEnable()) {
      for (let mechDevice of mechDevices) {
        HiLog.i(TAG, `mechDeviceType:${mechDevice?.mechDeviceType}`);
        // Gimbal类型，云台设备
        if (mechDevice?.mechDeviceType === mechManager.MechDeviceType.GIMBAL_DEVICE) {
          HiLog.i(TAG, 'gimbal is attached and tracking.');
          return true;
        }
      }
    }
    HiLog.i(TAG, 'gimbal is not attached and tracking.');
    return false;
  }

  // @ts-ignore
  private getMechDevices(): mechManager.MechInfo[] | undefined {
    let mechDevices = undefined;
    try {
      // @ts-ignore
      mechDevices = mechManager.getAttachedMechDevices();
      HiLog.i(TAG, `mechDevices length: ${mechDevices?.length}`);
    } catch (e) {
      HiLog.e(TAG, `getMechDevices fail, error: ${simpleStringify(e)}`);
    }
    return mechDevices;
  }

  public isTrackingEnable(): boolean {
    let isTrackingEnable: boolean = false;
    try {
      isTrackingEnable = mechManager.getCameraTrackingEnabled();
      HiLog.i(TAG, `camera tracking enabled is ${isTrackingEnable}`);
    } catch (e) {
      HiLog.e(TAG, `getCameraTrackingEnabled fail, err: ${simpleStringify(e)}`);
    }
    return isTrackingEnable;
  }

  // @ts-ignore
  private initMechState(mechId: number, mechName: string, attachState: ATTACH_STATE): void {
    HiLog.i(TAG, 'initMechState.');
    this.mMechId = mechId;
    this.mMechName = mechName;
    this.mAttachState = attachState;
    const rotationAxesStatus = this.getRotationAxesStatus();
    // 支架状态，包括当前角度和角度限位值，发送给手表
    this.mYawEnabled = rotationAxesStatus?.yawEnabled;
    this.mRollEnabled = rotationAxesStatus?.rollEnabled;
    this.mPitchEnabled = rotationAxesStatus?.pitchEnabled;
    this.mYawLimited = rotationAxesStatus?.yawLimited;
    this.mRollLimited = rotationAxesStatus?.rollLimited;
    this.mPitchLimited = rotationAxesStatus?.pitchLimited;
    this.sendMechStateMsg();
    this.sendTrackState();
  }

  /**
   * 解注册监听
   */
  public unSubscribe(): void {
    try {
      // 去注册设备连接状态监听
      // @ts-ignore
      mechManager.off('attachStateChange');
      // @ts-ignore
      mechManager.off('rotationAxesStatusChange');
    } catch (e) {
      HiLog.e(TAG, `unregister failed, cause: ${simpleStringify(e)}`);
    }
  }

  /**
   * 设置云台智能跟踪状态
   *
   * @param tackingEnable
   */
  public setTrackingState(tackingEnable: boolean): void {
    try {
      HiLog.i(TAG, `setCameraTrackingEnabled: ${tackingEnable}`);
      mechManager.setCameraTrackingEnabled(tackingEnable);
      this.sendTrackState();
    } catch (e) {
      HiLog.e(TAG, `setCameraTrackingEnabled fail, err: ${e}`);
      // 接口失败，给报错回调
      CollaborateControlService.getInstance().sendMechTrackState(TRACK_STATE.UNDEFINED);
    }
  }

  /**
   * 普通旋转
   *
   * @param yaw
   * @param roll
   * @param pitch
   * @param duration
   */
  public rotate(yaw: number, roll: number, pitch: number, duration: number): void {
    this.mRotateCount++;
    try {
      // @ts-ignore
      const degree: mechManager.RotationAngles = {
        yaw: yaw,
        roll: roll,
        pitch: pitch
      };
      HiLog.i(TAG, `rotate, yaw:${yaw}, roll:${roll}, pitch:${pitch}, duration:${duration}`);
      // 操作设备旋转
      // @ts-ignore
      mechManager.rotate(this.mMechId, degree, duration).then((result) => {
        HiLog.i(TAG, `execute result:${result}`);
      });
    } catch (e) {
      HiLog.e(TAG, `rotate operation failed, cause: ${simpleStringify(e)}`);
    }
  }

  /**
   * 定速旋转
   *
   * @param yawSpeed
   * @param rollSpeed
   * @param pitchSpeed
   * @param duration
   */
  public rotateBySpeed(yawSpeed: number, rollSpeed: number, pitchSpeed: number, duration: number): void {
    this.mRotateCount++;
    try {
      // @ts-ignore
      const rotationSpeed: mechManager.RotationSpeed = {
        yawSpeed: yawSpeed,
        rollSpeed: rollSpeed,
        pitchSpeed: pitchSpeed
      }
      HiLog.i(TAG, `yawSpeed:${yawSpeed}, rollSpeed:${rollSpeed}, pitchSpeed:${pitchSpeed}, duration:${duration}`);
      // @ts-ignore
      mechManager.rotateBySpeed(this.mMechId, rotationSpeed, duration).then((result) => {
        HiLog.i(TAG, `execute result:${result}`);
      });
    } catch (e) {
      HiLog.e(TAG, `rotateBySpeed fail, error: ${simpleStringify(e)}`);
    }
  }

  /**
   * 停止旋转
   */
  public stopRotate(): void {
    HiLog.i(TAG, 'stopRotate.');
    try {
      // @ts-ignore
      mechManager.stopMoving(this.mMechId);
    } catch (e) {
      HiLog.e(TAG, `stopMoving fail, err: ${simpleStringify(e)}`);
    }
  }

  /**
   * 获取云台跟踪状态
   *
   * @returns
   */
  private getTrackState(): TRACK_STATE {
    let trackState = TRACK_STATE.UNDEFINED;
    try {
      const isTrackingEnabled = mechManager.getCameraTrackingEnabled();
      HiLog.i(TAG, `getCameraTrackingEnabled: ${isTrackingEnabled}`);
      trackState = isTrackingEnabled ? TRACK_STATE.ENABLE : TRACK_STATE.DISABLE;
    } catch (e) {
      HiLog.e(TAG, `getCameraTrackingEnabled err: ${e}`);
    }
    return trackState;
  }

  /**
   * 查询设备旋转角度限位值
   */
  // @ts-ignore
  private getRotationAxesStatus(): mechManager.RotationAxesStatus | undefined {
    let rotationAxesStatus = undefined;
    try {
      // @ts-ignore
      rotationAxesStatus = mechManager.getRotationAxesStatus(this.mMechId);
      HiLog.i(TAG, `rotationAxesStatus:${JSON.stringify(rotationAxesStatus)}`);
    } catch (e) {
      HiLog.e(TAG, `get Rotation axes status failed, cause: ${simpleStringify(e)}`);
    }
    return rotationAxesStatus;
  }

  /**
   * 发送云台智能跟踪状态
   */
  private sendTrackState(): void {
    this.mTrackState = this.getTrackState();
    CollaborateControlService.getInstance().sendMechTrackState(this.mTrackState);
  }

  /**
   * 发送云台状态
   *
   * @param mechState
   */
  private sendMechStateMsg(): void {
    const mechState: MechStateParams = {
      mechName: this.mMechName,
      attachState: this.mAttachState,
      yawEnabled: this.mYawEnabled,
      rollEnabled: this.mRollEnabled,
      pitchEnabled: this.mPitchEnabled,
      yawLimited: this.mYawLimited,
      rollLimited: this.mRollLimited,
      pitchLimited: this.mPitchLimited
    }
    if (mechState === null || mechState === undefined) {
      return;
    }
    HiLog.d(TAG, `mechState = ${JSON.stringify(mechState)}`);
    const mechInfo = `${mechState.mechName}_${mechState.attachState}`;
    const enabled = `${mechState.yawEnabled ? 1 : 0}_${mechState.rollEnabled ? 1 : 0}_${mechState.pitchEnabled ? 1 : 0}`;
    const limited = `${mechState.yawLimited}_${mechState.rollLimited}_${mechState.pitchLimited}`;
    CollaborateControlService.getInstance().sendMechState(`mech_state:${mechInfo}_${enabled}_${limited}`);
  }

  /**
   * 用户行为打点上报
   *
   */
  public reportUserEvent(): void {
    this.mRotateCount = 0;
    this.mFocusCount = 0;
  }
}