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

import I18n from '@ohos.i18n';

export enum SystemLanguageType {
  HANS_CHINESE = 'zh-Hans', // 简体中文
  HANT_CHINESE = 'zh-Hant', // 繁体中文
  ENGLISH = 'en-Latn-US', // 英文
  TIBETAN = 'bo', // 藏文
  UYGUR = 'ug', //维吾尔语
}

/**
 * @file: 系统语言工具
 */
export class SystemLanguageUtil {

  /**
   * 获取当前语言
   *
   * @return {string} - 获取当前语言
   */
  static getMatchedLanguage(): string {
    let systemLanguage: string = I18n.System.getSimplifiedLanguage(); // 获取系统当前的语言
    let languagesList: string[] = I18n.System.getSystemLanguages(); // 该接口用于获取系统支持的语言列表。
    let matchedLanguage: string = I18n.I18NUtil.getBestMatchLocale(systemLanguage, languagesList);
    return matchedLanguage;
  }

  /**
   * 是否未知语言(当前暂未支持语言)
   *
   * @return {boolean} - 返回
   */
  static isUnKnowLanguage(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === '';
  }

  /**
   * 是否简体中文
   *
   * @return {boolean} - 返回
   */
  static isHansChinese(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'zh-Hans';
  }

  /**
   * 是否繁体中文
   *
   * @return {boolean} - 返回
   */
  static isHantChinese(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'zh-Hant';
  }

  /**
   * 是否英文
   *
   * @return {boolean} - 返回
   */
  static isEnglish(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'en-Latn-US';
  }

  /**
   * 是否藏文
   *
   * @return {boolean} - 返回
   */
  static isTibetan(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'bo';
  }

  /**
   * 是否维吾尔语
   *
   * @return {boolean} - 返回
   */
  static isUygur(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'ug';
  }

  /**
   * 是否中文（不区分繁体简体）
   *
   * @return {boolean} - 返回
   */
  static isChinese(): boolean {
    let isChinese = this.isHansChinese() || this.isHantChinese();
    return isChinese;
  }

  /**
   * 是否从右到左的语言
   *
   * @return {boolean} - 返回
   */
  static isRTL(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return I18n.isRTL(matchedLanguage);
  }

  /**
   * 是否俄语
   *
   * @return {boolean} - 返回
   */
  static isRussian(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'ru';
  }

  /**
   * 是否阿拉伯语
   *
   * @return {boolean} - 返回
   */
  static isArabic(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'ar';
  }

  /**
   * 是否日语
   *
   * @return {boolean} - 返回
   */
  static isJapanese(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'ja';
  }

  /**
   * 是否西班牙语
   *
   * @return {boolean} - 返回
   */
  static isSpanish(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'es';
  }

  /**
   * 是否韩语
   *
   * @return {boolean} - 返回
   */
  static isKorean(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'ko';
  }

  /**
   * 是否越南语
   *
   * @return {boolean} - 返回
   */
  static isVietnamese(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'vi';
  }

  /**
   * 是否法语
   *
   * @return {boolean} - 返回
   */
  static French(): boolean {
    let matchedLanguage = this.getMatchedLanguage();
    return matchedLanguage === 'fr';
  }

  /**
   * 数字格式化
   *
   * @return {string} - 返回
   */
  static NumberFormat(value: number, type: string, maximumFractionDigits: number = 0): string {
    let matchedLanguage = this.getMatchedLanguage();
    let option = {
      style: type,
      maximumFractionDigits: maximumFractionDigits
    }
    try {
      return (new Intl.NumberFormat(matchedLanguage, option).format(value));
    } catch (e) {
      return String(value);
    }
  }
}
