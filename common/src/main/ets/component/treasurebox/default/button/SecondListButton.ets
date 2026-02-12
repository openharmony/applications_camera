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

import lazy { AnimSpecifications } from '../../../../animation/AnimSpecifications';
import lazy { BaseFunction } from '../../../../function/core/BaseFunction';
import lazy { FeatureManager } from '../../../../function/core/FeatureManager';
import lazy { FunctionId } from '../../../../function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../../../../function/core/functionproperty/RenderLocation';
import lazy { UiElement } from '../../../../function/core/UiElement';
import lazy { OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../../redux';
import lazy { DirectionToAngleUtil } from '../../../../utils/DirectionToAngleUtil';
import lazy { HiLog } from '../../../../utils/HiLog';
import lazy { WindowDirection } from '../../../../utils/WindowDirection';
import lazy { IconElement } from './icon/IconElement';

/* instrument ignore file */
const TAG: string = 'SecondListButton';

@Component
export struct SecondListButton {
  @State uiElement: UiElement = new UiElement();
  @Prop @Watch('onIsSelectedChanged') isSelected: boolean = false;
  @State isWhiteFont: boolean = false;
  private functionId: FunctionId = FunctionId.NONE;
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State textAngleRotate: number = 0;
  @State iconAngleRotate: number = 0;

  aboutToAppear() {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.textAngleRotate =
        DirectionToAngleUtil.getTwoDirectionTextRotate(state.get<WindowDirection>('contextReducer', 'direction'));
      this.iconAngleRotate = state.get<number>('contextReducer', 'rotateAngle');
    }, null);
    this.isWhiteFont = !this.isSelected;
    this.getUiElement();
  }

  aboutToDisappear(): void {
    this.subscriber.destroy();
  }

  private onIsSelectedChanged(): void {
    this.isWhiteFont = !this.isSelected;
  }

  private getUiElement(): void {
    if (this.functionId === FunctionId.NONE) {
      return;
    }
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(this.functionId);
    if (!functionImpl) {
      return;
    }
    HiLog.i(TAG, 'Button get uiElement by Function id.');
    this.uiElement = Array.from<Object[]>(functionImpl.getUiElements(RenderLocation.TREASURE_BOX))
      .filter(value => value[0] != UiElement.DEFAULT)
      .map((item: Object[]) => item[1] as UiElement)[0];
    HiLog.i(TAG, 'Get button uiElement end.');
  }

  build() {
    IconElement({
      uiElement: this.uiElement,
      isWhiteFont: this.isWhiteFont,
      functionId: this.functionId,
      textAngleRotate: this.textAngleRotate,
      iconAngleRotate: this.iconAngleRotate,
      isFirstListItem: false
    })
  }
}