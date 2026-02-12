@rem
@rem Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem     http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

set HOME=%~dp0
hdc shell mount -o remount,rw /

hdc shell rm system/app/com.ohos.camera/Camera.hap
hdc shell rm system/app/com.ohos.camera/cameraPicke.hap
hdc file send %HOME%product\phone\build\default\outputs\default\phone-default-signed.hap /system/app/com.ohos.camera/Camera.hap
hdc file send %HOME%product\picker\build\default\outputs\default\picker-phone-default-signed.hap /system/app/com.ohos.camera/cameraPicke.hap

hdc shell rm -rf /data/*
hdc shell chown root:root system/app/com.ohos.camera/Camera.hap
hdc shell chown root:root system/app/com.ohos.camera/cameraPicke.hap
hdc shell setenforce 0
hdc shell sync
hdc shell sync /system/bin/udevadm trigger
hdc shell reboot
