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

import lazy { HiLog } from '../../utils/HiLog';
import type { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { CameraBasicOperation } from '../../camera/uithread/CameraBasicOperation';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';

const TAG: string = 'ThumbnailService';
const WAIT_SAVE_PICTURE: number = 2;
const WAIT_AVAILABLE_PHOTO_RELEASE_OUTPUT: number = 1000;

export class ThumbnailService {
  private mBase: BaseComponent = new BaseComponent();
  private static sInstanceCapability: ThumbnailService;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mDeregisterUriList: Set<string> = new Set();
  private mPictureWaitRefreshCount: number = 0; // 分段式80分图/单段式真图 拍照后待落盘完成的次数,用于拇指图拍照后是否使能可点击
  private mThumbnailWaitRefreshCount: number = 0; // 左下角拇指图拍照后待刷新的次数
  private mLastCapturePhotoMediaUri: string = ''; // 拍照后延迟落盘后最新uri记录
  private mIsNeedWaitReleasePhotoOutput: boolean = false; // 防丢图机制: 是否等待上图落盘后再执行重启流操作
  private mMaxWaitReleasePhotoOutputTimer: number = Number.MIN_VALUE; // 重启流防丢图机制最长等待时间定时器
  private offlineSupported: boolean = false; // 是否支持离线拍照

  public static getInstance(): ThumbnailService {
    if (!ThumbnailService.sInstanceCapability) {
      ThumbnailService.sInstanceCapability = new ThumbnailService();
    }
    return ThumbnailService.sInstanceCapability;
  }

  constructor() {
    this.mEventBus.on([CaptureActionType.CAPTURE, ActionType.ACTION_START_STITCHING_CAPTURE], this.onCapture.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.resetPictureAndThumbnailCount.bind(this), this.mBase.hashCode());
  }

  public getPictureWaitRefreshCount(): number {
    return this.mPictureWaitRefreshCount;
  }

  public getThumbnailWaitRefreshCount(): number {
    return this.mThumbnailWaitRefreshCount;
  }

  public isDeregisterUri(uri: string): boolean {
    const isDeregisterUri: boolean = this.mDeregisterUriList.has(uri);
    HiLog.i(TAG, `SHOT2SEE isDeregisterUri: ${isDeregisterUri}, uri: ${uri}.`);
    return isDeregisterUri;
  }

  public deregisterUri(uri: string): void {
    HiLog.i(TAG, `SHOT2SEE deregisterUri, uri: ${uri}.`);
    this.mDeregisterUriList.add(uri);
  }

  public onCaptureAbort(count: number = 1): void { // 拍照动作下发时即报不允许拍照,直接取消当前计数
    this.mPictureWaitRefreshCount = this.mPictureWaitRefreshCount >= count ? this.mPictureWaitRefreshCount - count : 0;
    this.mThumbnailWaitRefreshCount =
      this.mThumbnailWaitRefreshCount >= count ? this.mThumbnailWaitRefreshCount - count : 0;
    HiLog.i(TAG, `onCaptureAbort picture: ${this.mPictureWaitRefreshCount} thumb: ${this.mThumbnailWaitRefreshCount}`);
  }

  private onCapture(): void { // 拍照动作下发时机
    this.mPictureWaitRefreshCount++;
    this.mThumbnailWaitRefreshCount++;
    HiLog.i(TAG, `onCapture picture:${this.mPictureWaitRefreshCount}, thumb: ${this.mThumbnailWaitRefreshCount}.`);
  }

  public pictureSaved(count: number = 1): void { // 拍照存图落盘完成时机
    this.mPictureWaitRefreshCount = this.mPictureWaitRefreshCount >= count ? this.mPictureWaitRefreshCount - count : 0;
    HiLog.i(TAG, `pictureSaved picture: ${this.mPictureWaitRefreshCount}.`);
    if (this.mIsNeedWaitReleasePhotoOutput && (this.mPictureWaitRefreshCount === this.mThumbnailWaitRefreshCount)) {
      this.execReleasePhotoOutputAndRestartAfterSaved();
    }
  }

  public isPictureAcquireOrStoreTimeOut(report: boolean = true): boolean { // 图片上报或落盘耗时,是否不阻塞拍照下发
    HiLog.i(TAG, `isPictureAcquireOrStoreTimeOut picture: ${this.mPictureWaitRefreshCount}.`);
    let isPictureStoreTimeOut = this.mPictureWaitRefreshCount > WAIT_SAVE_PICTURE;
    if (isPictureStoreTimeOut && report) {
    }
    return isPictureStoreTimeOut;
  }

  public onBurstCapture(): void {
    HiLog.i(TAG, 'onBurstCapture');
    this.resetPictureAndThumbnailCount();
  }

  public thumbnailUpdate(count: number = 1): void { // 拇指图刷新完成时机
    this.mThumbnailWaitRefreshCount =
      this.mThumbnailWaitRefreshCount >= count ? this.mThumbnailWaitRefreshCount - count : 0;
    HiLog.i(TAG, `thumbnailUpdate thum: ${this.mThumbnailWaitRefreshCount}.`);
  }

  public isNeedGivePixelMap2Browser(): boolean { // 点击拇指图跳转大图时是否传递PixelMap去显示
    return this.mPictureWaitRefreshCount > 0;
  }

  private resetPictureAndThumbnailCount(): void { // 重启流后重置状态
    this.mPictureWaitRefreshCount = 0;
    this.mThumbnailWaitRefreshCount = 0;
    this.clearLastCaptureMediaUri();
  }

  public isEnableCanShowPhotoBrowser(): boolean { // 使能可点击拇指图跳转大图浏览——新方案优化为拇指图是否已更新完成
    HiLog.i(TAG, `isEnableCanShowPhotoBrowser mThumbnailWaitRefreshCount: ${this.mThumbnailWaitRefreshCount}.`);
    return this.mThumbnailWaitRefreshCount === 0;
  }

  public isSetCapturePhotoMediaUri(uri: string): boolean { // PixelMap后是否给大图组件传递uri
    HiLog.i(TAG, `isSetCapturePhotoMediaUri mThumbnailWaitRefreshCount: ${this.mThumbnailWaitRefreshCount}, mPictureWaitRefreshCount: ${this.mPictureWaitRefreshCount}, uri: ${uri}, mLastCapturePhotoMediaUri: ${this.mLastCapturePhotoMediaUri}.`);
    return this.mThumbnailWaitRefreshCount === 0 && this.mPictureWaitRefreshCount === 1 &&
      uri === this.mLastCapturePhotoMediaUri;
  }

  public isWaitingLastCaptureMediaUri(): boolean {
    return this.mPictureWaitRefreshCount === 1;
  }

  public setLastCaptureMediaUri(mediaUri: string): void {
    HiLog.i(TAG, `setLastCaptureMediaUri mediaUri: ${mediaUri}.`);
    this.mLastCapturePhotoMediaUri = mediaUri;
  }

  public clearLastCaptureMediaUri(): void {
    if (this.mLastCapturePhotoMediaUri !== '') {
      this.mLastCapturePhotoMediaUri = '';
    }
  }

  public isOfflineSupported(): boolean {
    HiLog.i(TAG, `isOfflineSupported: ${this.offlineSupported}`);
    return this.offlineSupported;
  }

  public updateOfflineSupport(isSupport: boolean): void {
    this.offlineSupported = isSupport;
  }

  /*
   * 获取用户重启流操作时,是否需启动防丢图机制
   * 规格: 缩略图已更新,80分图还未上报/落盘完成时启动
   */
  public getIsNeedWaitReleasePhotoOutput(): boolean {
    if (this.offlineSupported) {
      HiLog.i(TAG, 'offlineSupported,noNeedWaitReleasePhotoOutput');
      return false;
    }
    let isNeedWait = this.mPictureWaitRefreshCount > this.mThumbnailWaitRefreshCount;
    if (isNeedWait) {
      this.clearOutputTimer();
      this.mIsNeedWaitReleasePhotoOutput = true;
      HiLog.i(TAG, `getIsNeedWaitReleasePhotoOutput: ${this.mPictureWaitRefreshCount}, ${this.mThumbnailWaitRefreshCount}, ${this.mIsNeedWaitReleasePhotoOutput}.`);
      this.mMaxWaitReleasePhotoOutputTimer = setTimeout(() => {
        this.mThumbnailWaitRefreshCount = 0;
        this.mPictureWaitRefreshCount = 0;
        this.execReleasePhotoOutputAndRestartAfterSaved();
      }, WAIT_AVAILABLE_PHOTO_RELEASE_OUTPUT);
    } else {
      this.clearOutputTimerAndClearData();
    }
    return isNeedWait;
  }

  private clearOutputTimer(): void {
    if (this.mMaxWaitReleasePhotoOutputTimer !== Number.MIN_VALUE) {
      clearTimeout(this.mMaxWaitReleasePhotoOutputTimer);
      this.mMaxWaitReleasePhotoOutputTimer = Number.MIN_VALUE;
    }
  }

  // 清空最长等待时间定时器,清空缓存数据
  public clearOutputTimerAndClearData(): void {
    this.clearOutputTimer();
    if (this.mIsNeedWaitReleasePhotoOutput) {
      this.mIsNeedWaitReleasePhotoOutput = false;
    }
    CameraBasicOperation.clearReconfigFlowActionAndData();
  }

  /*
   * 待80分图落盘与缩略图刷新匹配一致后,触发用户重启流操作接续执行
   */
  private execReleasePhotoOutputAndRestartAfterSaved(): void {
    this.clearOutputTimer();
    this.mIsNeedWaitReleasePhotoOutput = false;
    let isNeedReconfigFlowAction = CameraBasicOperation.getNeedExecReconfigFlowAction();
    HiLog.i(TAG, `execReleasePhotoOutputAndRestartAfterSaved: ${isNeedReconfigFlowAction} E.`);
    if (isNeedReconfigFlowAction) {
      StoreManager.getInstance().postMessage(CameraAction.releaseAndRestartAfterPhotoSaved(isNeedReconfigFlowAction,
        CameraBasicOperation.getExecReconfigFlowDataAndClearQueue()));
    }
  }
}