# Camera 源码说明
## 项目介绍
相机应用是OpenHarmony标准系统中预置的系统应用，为用户提供基础的相机拍摄功能，包括预览、拍照、摄像、缩略图显示、跳转相册。
Camera 采用纯 arkui-ts 语言开发。

### 整体架构

![](./figures/camera-en.png)

Camera应用整体采用了多模块的设计方式，每个模块都遵循上述架构原则。

各层的作用分别如下：
- Product层：区分不同产品，不同屏幕的各形态，含有应用窗口、个性化业务，组件的配置以及个性化资源包。
- Feature层：抽象的公共特性组件集合，每个特性解耦独立可打包为har，可以被每个业务态所引用。
- Common层：负责数据服务、UI组件、工具组、数据持久层、动效层、外部交互层等部件内公共能力，每个应用形态都必须要依赖的模块。


## 目录<a name="section161941989596"></a>

````
camera
├─ product
│  └─ phone
│     └─ src
│        └─ main
│           ├─ ets
│              ├─ Application  # 全局ets逻辑和应用生命周期管理文件
│              ├─ MainAbility  # MainAbility存放目录
│              ├─ pages        # 页面组件存放目录
│              ├─ common        # 基础配置存放目录
│           ├─ resources       # 资源文件存放目录
├─ native                      # 内核native相关代码存放目录
├─ feature                     # 相关模块业务逻辑存放目录
├─ common                      # 通用逻辑存放目录
├─ LICENSE                     # 许可文件
├─ signature                   # 证书文件目录

````
## 相关仓

[**camera**](https://gitcode.com/openharmony/applications_camera)