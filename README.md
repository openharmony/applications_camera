# Camera<a name="ZH-CN_TOPIC_0000001103554544"></a>

## Introduction<a name="section11660541593"></a>

The Camera app is a system app pre-installed in the OpenHarmony standard system. It enables users to shoot photos with the local or a remote device, preview the shooting effect, view photo thumbnails, and open the camera album.
The Camera is developed using pure arkui-ts language.

### Core Features
1. **Basic Photography**: Supports rear basic photography, including functions such as shutter, photo review, mode switching, and toolbox. Also supports front basic photography.

2. **Camera Launch and System Adaptation**: Supports multiple camera entry methods, including launching from the desktop and ShortCut launching of specific modes (e.g., directly entering video/photo mode). Supports system feature adaptation, including screen rotation auto-adaptation.

3. **Camera Settings Page**: Provides a rich set of shooting setting options, including: grid lines, level gauge, timer shooting, silent shooting, and floating shutter button.

4. **Toolbox (Shooting Assistant Features Summary)**: Consolidates commonly used shooting assistant features, including: grid lines, settings entry, and more.

5. **Basic Video Recording**: Supports rear basic video recording, including the ability to capture photos while recording. Also supports front basic video recording, including the ability to capture photos while recording.

6. **Camera Picker**: Provides system-level camera picker capabilities, supporting modes such as photo picker.

### Architecture<a name="section78574815486"></a>

![](./figures/camera-en.png)

The Camera application as a whole adopts a multi-module design approach, and each module follows the above-mentioned architectural principles.

The functions of each layer are as follows:
- **Product**：Distinguish the various forms of different products and screens, including application Windows, personalized services, component configurations, and personalized resource packages.
- **Feature**：An abstract collection of common feature components, each feature decoupled independently and packaged as a har, which can be referenced by each business state.
- **Common**：Responsible for the common capabilities within components such as data services, UI components, tool groups, data persistence layers, motion effect layers, and external interaction layers, which are modules that each application form must rely on.

## Directory Structure<a name="section161941989596"></a>

````
applications_camera
├─ AppScope/                       # Application scope configuration (project level)
├─ product/                        
│  ├─ phone/
│  │  └─ src/main
│  │     ├─ ets/
│  │     │  ├─ Application/         # Application-level AbilityStage / global initialization
│  │     │  ├─ MainAbility/         # Main Ability
│  │     │  ├─ pages/               # Pages (UI page entry, page orchestration)
│  │     │  ├─ common/              # Phone 
│  │     │  ├─ ServiceExtensionAbility/
│  │     │  ├─ UIExtensionAbility/
│  │     │  ├─ formAbility/
│  │     │  ├─ camerawidget/
│  │     │  ├─ collaboration/
│  │     │  ├─ Calibration/
│  │     │  └─ res/                 # ETS-side resources/encapsulation
│  │     └─ resources/              # Phone resources (media/element/profile/rawfile, etc.)
│  ├─ picker/ ...
│
├─ common/                          # Shared module (cross-product/cross-feature reuse)
│  ├─ src/main
│  │  ├─ ets/
│  │  │  ├─ camera/                 # Camera core common (childthread/uithread/modules, etc.)
│  │  │  ├─ component/              # Common components (settingview, xcomponent, thumbnail, etc.)
│  │  │  ├─ service/                # Common services (UIAdaptive, medialibrary, etc.)
│  │  │  ├─ function/               # Common functional blocks (capture, recordcontrol, etc.)
│  │  │  ├─ mode/                   # Mode/transformation
│  │  │  ├─ redux/                  # Redux actions/reducer/store
│  │  │  ├─ worker/                 # Worker/eventbus, etc.
│  │  │  ├─ utils/                  # Utilities
│  │  │  ├─ statistics/             # Statistics/telemetry
│  │  │  ├─ animation/ restore/ rpcclient/ default/
│  │  │  └─ ...
│  │  └─ resources/                 # Common module resources
│  ├─ lib/                          # Common module libraries/build outputs
│  └─ oh_modules/                   # Module dependencies
│
├─ features/                        # Feature module collection (extend/photo/video)
│  ├─ photo/
│  │  ├─ src/                       # Photo business source code (photo capture domain)
│  │  └─ oh_modules/
│  ├─ video/
│  │  ├─ src/                       # Video business source code (video recording domain)
│  │  └─ oh_modules/
│  └─ extend/
│     ├─ src/                       # Extension capabilities (UIExtensionAbility, extension points, etc.)
│     └─ oh_modules/
│
├─ signature/                       # Certificate directory
├─ open_source/                     # Open source dependencies / notices
├─ LICENSE  README.md  README_zh.md # Documentation

````

## Repositories Involved<a name="section1371113476307"></a>

[**camera**](https://gitcode.com/openharmony/applications_camera)
