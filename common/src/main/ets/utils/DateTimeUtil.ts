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
/* instrument ignore file */
/**
 * @file: 日期工具
 */
export default class DateTimeUtil {
  private static readonly DATE_TIME_9: number = 9;

  /**
   * 时分秒
   *
   * @return {string} - 返回时分秒
   */
  getTime(): string {
    const DATETIME = new Date();
    const HOURS = DATETIME.getHours();
    const MINUTES = DATETIME.getMinutes();
    const SECONDS = DATETIME.getSeconds();
    return this.concatTime(HOURS, MINUTES, SECONDS);
  }

  /**
   * 年月日
   *
   * @return {string} - 返回年月日
   */
  getDate(): string {
    const DATETIME = new Date();
    const YEAR = DATETIME.getFullYear();
    const MONTH = DATETIME.getMonth() + 1;
    const DAY = DATETIME.getDate();
    return this.concatDate(YEAR, MONTH, DAY);
  }

  /**
   * 日期不足两位补 0
   *
   * @param {string} value - 数据值
   * @return {string} - 日期不足两位补 0
   */
  fill(value): string {
    return (value > DateTimeUtil.DATE_TIME_9 ? '' : '0') + value;
  }

  /**
   * 年月日格式修饰
   *
   * @param {string} year - 年
   * @param {string} month - 月
   * @param {string} date - 日
   * @return {string} - 年月日格式修饰
   */
  concatDate(year, month, date): string {
    return `${year}${this.fill(month)}${this.fill(date)}`;
  }

  /**
   * 时分秒格式修饰
   *
   * @param {string} hours - 时
   * @param {string} minutes - 分
   * @param {string} seconds - 秒
   * @return {string} - 时分秒格式修饰
   */
  concatTime(hours, minutes, seconds): string {
    return `${this.fill(hours)}${this.fill(minutes)}${this.fill(seconds)}`;
  }
}
