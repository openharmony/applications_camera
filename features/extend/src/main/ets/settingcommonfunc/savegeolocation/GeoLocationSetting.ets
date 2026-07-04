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
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { ConfirmDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/ConfirmDialogView';
import lazy { reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { GeoLocationService } from './GeoLocationService';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';

/* instrument ignore file */
const TAG: 'GeoLocationSetting' = 'GeoLocationSetting';

@Component
export struct GeoLocationSetting {
  private dialogController: CustomDialogController | null = null;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mBase: BaseComponent = new BaseComponent();
  @State mDirection: WindowDirection = WindowDirection.TOP;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
    });

    this.mEventBus.on(ActionType.ACTION_LOCATION_GUIDED_AUTHORIZATION, this.createLocationSettingDialog.bind(this),
      this.mBase.hashCode());

  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  private getRotate(): number {
    HiLog.i(TAG, `mDirection : ${this.mDirection} `);
    switch (this.mDirection) {
      case WindowDirection.TOP:
        return 0;
      case WindowDirection.BOTTOM:
        return 0;
      case WindowDirection.RIGHT:
        return AnimSpecifications.ANIM_ROTATE_90;
      case WindowDirection.LEFT:
        return AnimSpecifications.ANIM_ROTATE_270;
      default:
        return 0;
    }
  }

  private createLocationSettingDialog(): void {
    HiLog.i(TAG, 'createLocationSettingDialog E.');
    this.dialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          HiLog.i(TAG, 'locationSettingDialogController ConfirmDialogView cancel.');
          GeoLocationService.getInstance().requestPermissionDialog(false);
          this.dialogController?.close();
        },
        confirm: () => {
          //拉起设置
          GeoLocationService.getInstance().requestPermissionDialog(true);
          this.dialogController?.close();
        },
        title: $r('app.string.camera_location_request_dialog_title'),
        description: '用于在水印中显示拍照地点信息。', // todo
        cancelText: $r('app.string.cancel'),
        confirmText: $r('app.string.permission_dialog_goto_setting_button'),
        rotateAngle: this.getRotate(),
        currentDirection: this.mDirection,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        GeoLocationService.getInstance().requestPermissionDialog(false);
        this.dialogController?.close();
      },
      alignment: DialogAlignment.Center,
    });
    this.dialogController.open();
  }

  build() {
    Column()
  }
}