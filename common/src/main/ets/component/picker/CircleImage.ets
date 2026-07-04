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
import lazy { OhCombinedState, Unsubscribe, reduxSubscribe } from '../../redux';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import ResGetter from '../../utils/ResGetter';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { RotateImageView } from '../animate/RotateImageView';
import lazy { CircleImageOutRim } from './CircleImageOutRim.ts';

/* instrument ignore file */
const TAG: string = 'CircleImage';

@Component
export struct CircleImage {
  private keyValue: string = ComponentIdKeys.THIRDPARTYCALL_BACK_1;
  private onCircleImageClicked: Function = () => {
  };
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe | null = null;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private circleImageRes: Resource | string = '';
  @Prop isCancelViewVisibility: boolean = false;
  private abText: Resource | string = '';
  @State isShowRingLightView: boolean = false;
  @State showPicker: boolean = false;
  @State isVdeCollapsed: boolean = false;

  aboutToAppear() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.showPicker = state.get<boolean>('uiReducer', 'showPicker');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
    }, null);
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
  }

  build() {
    if (this.isCancelViewVisibility || PickerUtils.getIsPicker()) {
      Stack({ alignContent: Alignment.Center }) {
        CircleImageOutRim({
          fillColor: Color.White,
        });

        RotateImageView({
          rotateImageWidth: this.isVdeCollapsed ? 18 : 24,
          rotateImageHeight: this.isVdeCollapsed ? 18 : 24,
          imgFit: ImageFit.Cover,
          fillColor: Color.White,
          defaultImgSrc: this.circleImageRes,
        })
      }
      .key(this.keyValue)
      .visibility(this.isCancelViewVisibility ? Visibility.Visible : Visibility.Hidden)
      .width(this.isVdeCollapsed ? 28 : 44)
      .height(this.isVdeCollapsed ? 28 : 44)
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityGroup(true)
      .accessibilityText(ResGetter.getStringSafe(this.abText))
      .onClick((): void => {
        this.onCircleImageClicked();
      })
    }
  }
}