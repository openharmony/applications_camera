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
import lazy { ContextManager } from '../../service/context/ContextManager';

export class UiElement {
  public static readonly DEFAULT: string = 'DEFAULT';
  functionValue: number;
  title: Resource | string;
  icon: Resource;
  desc: Resource | string;
  textIcon: Resource | string; // 使用图标时可能使用文字而不是图片，因为容器不同，所以使用不同的变量方面判断
  itemIcon: Resource; // functionValue对应的图标,滤镜、XMAGE特性的FunctionIcon随FunctionValueIcon变化而变化
  disabled: boolean; // 设置是否可选
  textItemSec: Resource | string; // 设置二级text
  checked: boolean; //当前ui是否被选中
  accessibilityTitle: Resource | string = ''; // 无障碍播报文本 控件名，如闪光灯、动态照片
  accessibilityDescription: Resource | string = ''; // 无障碍播报文本 状态，如自动、打开、关闭, 有可能是空字符串，如设置按钮
  settingDisplayTitle: Resource | string = ''; // 设置页文字和选项文字不一致时，需要特殊设置
  public width: number = 24; // 控件默认宽度24vp
  public height: number = 24; // 控件默认高度24vp

  setValue(functionValue: number): UiElement {
    this.functionValue = functionValue;
    return this;
  }

  setTitle(title: Resource | string): UiElement {
    this.title = title;
    return this;
  }

  setWidth(width: number): UiElement {
    this.width = width;
    return this;
  }

  setHeight(height: number): UiElement {
    this.height = height;
    return this;
  }

  setIcon(icon: Resource): UiElement {
    this.icon = icon;
    return this;
  }

  setDesc(desc: Resource | string): UiElement {
    this.desc = desc;
    return this;
  }

  // 用于英文字母描述转大写
  setUpperDesc(desc: Resource): UiElement {
    this.desc = ContextManager.getInstance().getResourceManager().getStringSync(desc.id).toUpperCase();
    return this;
  }

  setTextIcon(textIcon: Resource | string): UiElement {
    this.textIcon = textIcon;
    return this;
  }

  setItemIcon(itemIcon: Resource): UiElement {
    this.itemIcon = itemIcon;
    return this;
  }

  setDisabled(disabled: boolean): UiElement {
    this.disabled = disabled;
    return this;
  }

  setChecked(checked: boolean): UiElement {
    this.checked = checked;
    return this;
  }

  setTextItemSec(textItemSec: Resource | string): UiElement {
    this.textItemSec = textItemSec;
    return this;
  }

  setAccessibilityTitle(accessibilityTitle: Resource | string): UiElement {
    this.accessibilityTitle = accessibilityTitle;
    return this;
  }

  setAccessibilityDescription(accessibilityDescription: Resource | string): UiElement {
    this.accessibilityDescription = accessibilityDescription;
    return this;
  }

  setSettingDisplayTitle(settingDisplayTitle: Resource | string): UiElement {
    this.settingDisplayTitle = settingDisplayTitle;
    return this;
  }
}