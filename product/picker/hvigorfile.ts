/*
 * Copyright (c) Huawei Device Co., Ltd. 2022-2023. All rights reserved.
 */
import { hapTasks } from '@ohos/hvigor-ohos-plugin';
// import { sharePlugin } from '../../common/lib/share-plugin';
// import { hvigor, getHvigorNode } from '@ohos/hvigor';
// import { dtPipelinePackagePlugin } from '@ohos/hypium-plugin';

// 模块名获取
// const mModule = getHvigorNode(__filename);
// // 配置需要进行签名 + 测试的模块
// const config = {
//   hvigor: hvigor,
//   packageConfig: {
//     // 自定义测试包的名称，当前与模块名一致
//     appName: 'camera_override',
//     // hvigor 命令行参数
//     commandParams: hvigor.getExtraConfig(),
//     // 当前模块对象
//     module: mModule
//   }
// }


export default {
  /* Built-in plugin of Hvigor. It cannot be modified. */
  system: hapTasks,
  /* 跑DT的product加上 Custom plugin to extend the functionality of Hvigor. */
  // plugins: [sharePlugin(), dtPipelinePackagePlugin(config)]
}