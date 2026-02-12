# Camera<a name="ZH-CN_TOPIC_0000001103554544"></a>

## Introduction<a name="section11660541593"></a>

The Camera app is a system app pre-installed in the OpenHarmony standard system. It enables users to shoot photos with the local or a remote device, preview the shooting effect, view photo thumbnails, and open the camera album.
The Camera is developed using pure arkui-ts language.

### Architecture<a name="section78574815486"></a>

![](./figures/camera-en.png)

The Camera application as a whole adopts a multi-module design approach, and each module follows the above-mentioned architectural principles.

The functions of each layer are as follows:
- Product：Distinguish the various forms of different products and screens, including application Windows, personalized services, component configurations, and personalized resource packages.
- Feature：An abstract collection of common feature components, each feature decoupled independently and packaged as a har, which can be referenced by each business state.
- Common：Responsible for the common capabilities within components such as data services, UI components, tool groups, data persistence layers, motion effect layers, and external interaction layers, which are modules that each application form must rely on.

## Directory Structure<a name="section161941989596"></a>

````
camera
├─ product
│  └─ phone
│     └─ src
│        └─ main
│           ├─ ets
│              ├─ Application  # Global ets logic and application lifecycle management files
│              ├─ MainAbility  # The directory where MainAbility is stored
│              ├─ pages        # The directory where pages is stored
│              ├─ common        # The directory where common is stored
│           ├─ resources       # The directory where resources is stored
├─ native                      # The directory where native is stored
├─ feature                     # The directory where feature is stored
├─ common                      # The directory where common is stored
├─ LICENSE                     # The directory where LICENSE is stored
├─ signature                   # The directory where signature is stored

````

## Repositories Involved<a name="section1371113476307"></a>

[**camera**](https://gitcode.com/openharmony/applications_camera)
