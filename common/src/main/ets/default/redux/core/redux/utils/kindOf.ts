/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

export function miniKindOf(val: any): string {
    if (val === void 0) return 'undefined'
    if (val === null) return 'null'

    const type = typeof val
    switch (type) {
        case 'boolean':
        case 'string':
        case 'number':
        case 'symbol':
        case 'function':
        {
            return type
        }
    }

    if (Array.isArray(val)) return 'array'
    if (isDate(val)) return 'date'
    if (isError(val)) return 'error'

    const constructorName = ctorName(val)
    switch (constructorName) {
        case 'Symbol':
        case 'Promise':
        case 'WeakMap':
        case 'WeakSet':
        case 'Map':
        case 'Set':
            return constructorName
    }

    // other
    return Object.prototype.toString
        .call(val)
        .slice(8, -1)
        .toLowerCase()
        .replace(/\s/g, '')
}

function ctorName(val: any): string | null {
    return typeof val.constructor === 'function' ? val.constructor.name : null
}

function isError(val: any) {
    return (
        val instanceof Error ||
        (typeof val.message === 'string' &&
        val.constructor &&
        typeof val.constructor.stackTraceLimit === 'number')
    )
}

function isDate(val: any) {
    if (val instanceof Date) return true
    return (
        typeof val.toDateString === 'function' &&
        typeof val.getDate === 'function' &&
        typeof val.setDate === 'function'
    )
}

export function kindOf(val: any) {
    let typeOfVal: string = typeof val

    typeOfVal = miniKindOf(val)

    return typeOfVal
}
