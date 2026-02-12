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
import lazy { BusinessError } from '@ohos.base';
import media from '@ohos.multimedia.media';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { fs, image } from '../../utils/LazyImportUtil';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';

/* instrument ignore file */
export interface AVPlayerOptions {
  surfaceId: string,
  loop: boolean,
  autoPlay: boolean,
  onPlayingCallback: () => void;
}

const TAG = 'AVPlayerService';

export class AVPlayerService {
  private static mAVPlayerService: AVPlayerService = null;
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private avPlayers: Map<string, media.AVPlayer> = new Map();

  constructor() {
  }

  public init(): void {
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onBackground(), this.mBase.hashCode());
  }

  public clearEventBus(): void {
    this.mEventBus.clear(this.mBase.hashCode());
  }

  public static getInstance(): AVPlayerService {
    if (AVPlayerService.mAVPlayerService) {
      return AVPlayerService.mAVPlayerService;
    }
    AVPlayerService.mAVPlayerService = new AVPlayerService();
    return AVPlayerService.mAVPlayerService;
  }

  private onBackground(): void {
    const size: number = this.avPlayers.size;
    if (size > 0) {
      this.avPlayers.forEach((item: media.AVPlayer)=>{
        item.pause();
        item.seek(0);
      });
    }
  }

  public releaseAllAVPlayers(): void {
    HiLog.i(TAG, 'release all avPlayers.');
    const size: number = this.avPlayers.size;
    if (size > 0) {
      this.avPlayers.forEach((item: media.AVPlayer, key: string)=>{
        item.release();
        this.avPlayers.delete(key);
      });
    }
  }

  public async releaseBySurfaceId(surfaceId: string): Promise<void> {
    HiLog.i(TAG, 'release avPlayer by surfaceId');
    await this.avPlayers.get(surfaceId)?.release();
    this.avPlayers.delete(surfaceId);
  }

  public async createAVPlayerByPath(path: string, avPlayerOptions: AVPlayerOptions): Promise<media.AVPlayer> {
    let avPlayer: media.AVPlayer = await media.createAVPlayer();
    AVPlayerService.getInstance().setAVPlayerCallback(avPlayer, avPlayerOptions);
    let file: fs.File;
    try {
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      avPlayer.fdSrc = file;
      this.avPlayers.set(avPlayerOptions.surfaceId, avPlayer);
    } catch (e) {
      HiLog.e(TAG, `createAVPlayer error: ${JSON.stringify(e)}`);
    }
    return avPlayer;
  }

  public setAVPlayerCallback(avPlayer: media.AVPlayer, avPlayerOptions: AVPlayerOptions): void {
    avPlayer.on('error', (e: BusinessError) => {
      HiLog.e(TAG, `AVPlayer error: ${JSON.stringify(e)}`);
      avPlayer.reset();
    });
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case 'idle':
          HiLog.i(TAG, 'AVPlayer stateChange: idle.');
          break;
        case 'initialized':
          HiLog.i(TAG, 'AVPlayer stateChange: initialized.');
          avPlayer.surfaceId = avPlayerOptions.surfaceId;
          avPlayer.prepare();
          break;
        case 'prepared':
          HiLog.i(TAG, 'AVPlayer stateChange: prepared.');
          if (avPlayerOptions.autoPlay) {
            avPlayer.play();
          } else {
            avPlayer.seek(0);
          }
          break;
        case 'playing':
          avPlayerOptions.onPlayingCallback();
          HiLog.i(TAG, 'AVPlayer stateChange: playing.');
          break;
        case 'paused':
          HiLog.i(TAG, 'AVPlayer stateChange: paused.');
          break;
        case 'completed':
          HiLog.i(TAG, 'AVPlayer stateChange: completed.');
          if (avPlayerOptions.loop) {
            avPlayer.play();
          } else {
            avPlayer.stop();
          }
          break;
        case 'stopped':
          HiLog.i(TAG, 'AVPlayer stateChange: stopped.');
          break;
        case 'released':
          HiLog.i(TAG, 'AVPlayer stateChange: released.');
          break;
        default:
          HiLog.i(TAG, 'AVPlayer stateChange: unknown.');
          break;
      }
    });
  }

  public async getAVMetaDataByPath(path: string): Promise<media.AVMetadata> {
    let avMetadataExtractor: media.AVMetadataExtractor = await media.createAVMetadataExtractor();
    let file: fs.File;
    let metadata: media.AVMetadata;
    try {
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      avMetadataExtractor.fdSrc = file;
      metadata = await avMetadataExtractor.fetchMetadata();
    } catch (e) {
      HiLog.i(TAG, `getAVMetaData error: ${JSON.stringify(e)}`);
    } finally {
      fs.closeSync(file);
    }
    return metadata;
  }

  public async readPreviewPicture(previewUri: string): Promise<image.PixelMap> {
    let pixelMap: image.PixelMap;
    HiLog.i(TAG, 'readFile E' + previewUri);
    let file: fs.File;
    try {
      file = fs.openSync(previewUri, fs.OpenMode.READ_ONLY);
      const imageSourceApi: image.ImageSource = image.createImageSource(file.fd);
      pixelMap = await imageSourceApi.createPixelMap();
      imageSourceApi.release();
    } catch (error) {
      HiLog.i(TAG, `readFile error ${error}`);
    } finally {
      if (file) {
        fs.closeSync(file);
      }
    }
    HiLog.i(TAG, 'readFile X');
    return pixelMap;
  }
}