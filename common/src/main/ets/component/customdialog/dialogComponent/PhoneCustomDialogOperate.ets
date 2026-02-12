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

import lazy { getStates } from '../../../redux';

/* instrument ignore file */
const TAG: string = 'PhoneCustomDialogOperate';

export const DIALOG_WIDTH_LANDSCAPE: number = 400;

export const DIALOG_WIDTH_TABLET: number = 394;

export const DIALOG_WIDTH_VDE_SEMI_COLLAPSED: number = 315;

export const DIALOG_DEFAULT_MARGIN: number = 32;

const GUTTER: number = 12;
const CARD_COLUMNS: number = 8;
const VERTICAL_CARD_COLUMNS: number = 4;
const LANDSCAPE_GUTTER: number = 24;

class GridRowDataType {
  public columns: number = 0;
  public direction: GridRowDirection = GridRowDirection.Row;
  public gutter: number = GUTTER;
}

/* instrument ignore next */
class GridColDataType {
  public span: GridColColumnOption;
  public offset: GridColColumnOption;

  constructor(isVertical: boolean) {
    this.span = new GridColColumnOption(4);
    this.offset = new GridColColumnOption(isVertical ? 0 : 2);
  }
}

/* instrument ignore next */
class GridColColumnOption {
  public xs: number;
  public sm: number;
  public md: number;
  public lg: number;

  constructor(num: number) {
    this.xs = num;
    this.sm = num;
    this.md = num;
    this.lg = num;
  }
}

export class PhoneCustomDialogOperate {
  public static getGridRowData(isVertical: boolean): GridRowDataType {
    const data: GridRowDataType = new GridRowDataType();
    const isShowLandscape = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    if (isShowLandscape) {
      data.gutter = LANDSCAPE_GUTTER;
      data.columns = CARD_COLUMNS;
      return data;
    }
    data.columns = isVertical ? VERTICAL_CARD_COLUMNS : CARD_COLUMNS;
    return data;
  }

  /* instrument ignore next */
  public static getGridColData(isVertical: boolean): GridColDataType {
    const isShowLandscape = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    if (isShowLandscape) {
      return new GridColDataType(false);
    }
    return new GridColDataType(isVertical);
  }
}