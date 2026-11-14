import { BusinessError } from '@ohos.base';
import { inputConsumer } from '@kit.InputKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import QAbilityStage from '../qabilitystage/QAbilityStage';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import Window from '@ohos.window'
import hilog from '@ohos.hilog';
import qpa from 'libqohos.so';
import {LOG_DOMAIN, LOG_TAG} from '../common/QtAppConstants';

interface SnowShotNativeModule {
  rejectHotkeyRegistration(portableText: string, errorCode: number): void;
  takePendingUserFileExports(): Array<NativeUserFileExport>;
  completeUserFileExport(id: number, succeeded: boolean, error?: string): boolean;
  takePendingUserFileSavePickers(): Array<NativeUserFileSavePickerRequest>;
  completeUserFileSavePicker(id: number, uri: string, suffixIndex: number, error?: string): boolean;
  getRegisteredHotkeys(): Array<NativeHotkeyRegistration>;
  activateHotkey(portableText: string): void;
  parseShortcut(portableText: string): NativeHotkeyRegistration | null;
}

interface NativeHotkeyRegistration {
  portableText: string;
  preKeys: number[];
  finalKey: number;
}

interface NativeUserFileExport {
  id: number;
  sourcePath: string;
  uri: string;
}

interface NativeUserFileSavePickerRequest {
  id: number;
  suggestedName: string;
  suffixChoices: Array<string>;
}

interface ArkHotkeySubscription {
  options: inputConsumer.HotkeyOptions;
  callback: (options: inputConsumer.HotkeyOptions) => void;
}

interface PersistedShortcutBinding {
  portable: string;
}

interface PersistedShortcutConfig {
  global_shortcuts?: Record<string, Array<PersistedShortcutBinding>>;
}

export default class QAbility extends UIAbility {

  private static shortcutBridgeOwner: QAbility | null = null;
  private static shortcutBridgeCandidates: Set<QAbility> = new Set<QAbility>();
  private static foregroundPickerAbility: QAbility | null = null;

  private localStorage: LocalStorage | null = null;
  private permissionRequest?: Promise<void>;
  private snowShotNative: SnowShotNativeModule | null = null;
  private pendingHotkeyActivations: Set<string> = new Set<string>();
  private shortcutSyncTimer?: number;
  private shortcutSubscriptions: Map<string, ArkHotkeySubscription> = new Map();
  private failedShortcutTexts: Map<string, number> = new Map();
  private shortcutRegistrySeen: boolean = false;
  private earlyShortcutsRegistered: boolean = false;
  private earlyShortcutsRetryCount: number = 0;
  private static readonly earlyShortcutsMaxRetries: number = 12;
  private static readonly earlyShortcutsRetryDelayMs: number = 150;
  private activeUserFileExports: Set<number> = new Set<number>();
  private activeUserFileSavePickers: Set<number> = new Set<number>();
  private queuedUserFileSavePickers: Array<NativeUserFileSavePickerRequest> =
    new Array<NativeUserFileSavePickerRequest>();

  private async presentUserFileSavePicker(request: NativeUserFileSavePickerRequest): Promise<void> {
    let uri: string = '';
    let suffixIndex: number = -1;
    let errorMessage: string = '';
    try {
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [request.suggestedName];
      options.fileSuffixChoices = request.suffixChoices;
      const documentPicker = new picker.DocumentViewPicker(this.context);
      const results: Array<string> = await documentPicker.save(options);
      if (results.length > 0) {
        uri = results[0];
        suffixIndex = documentPicker.getSelectedIndex();
      } else {
        errorMessage = 'The user-file save picker returned no document';
      }
    } catch (error) {
      const e = error as BusinessError;
      errorMessage = e.message;
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'USER_FILE_SAVE_PICKER_FAILED ' + request.id + ' ' + e.code);
    } finally {
      this.activeUserFileSavePickers.delete(request.id);
      try {
        this.snowShotNative?.completeUserFileSavePicker(
          request.id, uri, suffixIndex, errorMessage);
      } catch (error) {
        const e = error as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG,
          'USER_FILE_SAVE_PICKER_COMPLETION_FAILED ' + request.id + ' ' + e.code);
      }
      this.startNextUserFileSavePicker();
    }
  }

  private startNextUserFileSavePicker(): void {
    if (this.activeUserFileSavePickers.size > 0 || this.queuedUserFileSavePickers.length === 0) {
      return;
    }
    const request: NativeUserFileSavePickerRequest | undefined =
      this.queuedUserFileSavePickers.shift();
    if (request === undefined || this.activeUserFileSavePickers.has(request.id)) {
      return;
    }
    this.activeUserFileSavePickers.add(request.id);
    this.presentUserFileSavePicker(request);
  }

  private startPendingUserFileSavePickers(): void {
    if (this.snowShotNative === null) {
      return;
    }
    try {
      const pending: Array<NativeUserFileSavePickerRequest> =
        this.snowShotNative.takePendingUserFileSavePickers();
      pending.forEach((request: NativeUserFileSavePickerRequest) => {
        if (this.activeUserFileSavePickers.has(request.id) ||
            this.queuedUserFileSavePickers.some((queued: NativeUserFileSavePickerRequest) =>
              queued.id === request.id)) {
          return;
        }
        this.queuedUserFileSavePickers.push(request);
      });
      this.startNextUserFileSavePicker();
    } catch (error) {
      const e = error as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG,
        'USER_FILE_SAVE_PICKER_POLL_FAILED ' + e.code + ' ' + e.message);
    }
  }

  private async publishUserFileExport(request: NativeUserFileExport): Promise<void> {
    let source: fileIo.File | undefined;
    let destination: fileIo.File | undefined;
    let succeeded: boolean = false;
    let errorMessage: string = '';
    try {
      source = fileIo.openSync(request.sourcePath, fileIo.OpenMode.READ_ONLY);
      destination = fileIo.openSync(request.uri,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.truncateSync(destination.fd, 0);
      const bufferSize: number = 256 * 1024;
      for (;;) {
        const buffer: ArrayBuffer = new ArrayBuffer(bufferSize);
        const readSize: number = fileIo.readSync(source.fd, buffer);
        if (readSize === 0) {
          break;
        }
        const writeSize: number = fileIo.writeSync(destination.fd, buffer, {length: readSize});
        if (writeSize !== readSize) {
          throw new Error('Short write while publishing the selected user file');
        }
        await new Promise<void>((resolve: () => void) => setTimeout(resolve, 0));
      }
      succeeded = true;
    } catch (error) {
      const e = error as BusinessError;
      errorMessage = e.message;
      hilog.error(LOG_DOMAIN, LOG_TAG,
        'USER_FILE_EXPORT_FAILED ' + request.id + ' ' + e.code + ' ' + e.message);
    } finally {
      if (destination !== undefined) {
        try {
          fileIo.closeSync(destination.fd);
        } catch (error) {
          const e = error as BusinessError;
          if (succeeded) {
            succeeded = false;
            errorMessage = e.message;
          }
        }
      }
      if (source !== undefined) {
        try {
          fileIo.closeSync(source.fd);
        } catch (error) {
          const e = error as BusinessError;
          if (succeeded) {
            succeeded = false;
            errorMessage = e.message;
          }
        }
      }
      try {
        const completed: boolean = this.snowShotNative?.completeUserFileExport(
          request.id, succeeded, errorMessage) ?? false;
        if (!completed) {
          hilog.warn(LOG_DOMAIN, LOG_TAG, 'USER_FILE_EXPORT_LATE_COMPLETION ' + request.id);
        }
      } catch (error) {
        const e = error as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG,
          'USER_FILE_EXPORT_COMPLETION_FAILED ' + request.id + ' ' + e.code + ' ' + e.message);
      }
      this.activeUserFileExports.delete(request.id);
    }
  }

  private startPendingUserFileExports(): void {
    if (this.snowShotNative === null) {
      return;
    }
    try {
      const pending: Array<NativeUserFileExport> = this.snowShotNative.takePendingUserFileExports();
      pending.forEach((request: NativeUserFileExport) => {
        if (this.activeUserFileExports.has(request.id)) {
          return;
        }
        this.activeUserFileExports.add(request.id);
        this.publishUserFileExport(request);
      });
    } catch (error) {
      const e = error as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG, 'USER_FILE_EXPORT_POLL_FAILED ' + e.code + ' ' + e.message);
    }
  }

  private reportHotkeyRegistrationFailure(portableText: string, errorCode: number): void {
    this.failedShortcutTexts.set(portableText, errorCode);
    try {
      if (this.snowShotNative === null) {
        return;
      }
      this.snowShotNative.rejectHotkeyRegistration(portableText, errorCode);
    } catch (error) {
      const e = error as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG, 'NATIVE_HOTKEY_FAILURE_REPORT_FAILED ' + e.code + ' ' + e.message);
    }
  }

  private syncGlobalShortcuts(): void {
    if (QAbility.shortcutBridgeOwner !== this) {
      return;
    }
    let registrations: Array<NativeHotkeyRegistration>;
    try {
      if (this.snowShotNative === null) {
        return;
      }
      QAbility.foregroundPickerAbility?.startPendingUserFileSavePickers();
      this.startPendingUserFileExports();
      registrations = this.snowShotNative.getRegisteredHotkeys() as Array<NativeHotkeyRegistration>;
    } catch (error) {
      const e = error as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG, 'NATIVE_HOTKEY_QUERY_FAILED ' + e.code + ' ' + e.message);
      return;
    }

    if (registrations.length === 0 && !this.shortcutRegistrySeen) {
      return;
    }
    if (registrations.length > 0) {
      this.shortcutRegistrySeen = true;
    }

    const desired = new Set<string>(registrations.map((item: NativeHotkeyRegistration) => item.portableText));
    this.failedShortcutTexts.forEach((_errorCode: number, portableText: string) => {
      if (!desired.has(portableText)) {
        this.failedShortcutTexts.delete(portableText);
      }
    });
    this.shortcutSubscriptions.forEach((subscription: ArkHotkeySubscription, portableText: string) => {
      if (!desired.has(portableText)) {
        try {
          inputConsumer.off('hotkeyChange', subscription.options, subscription.callback);
        } catch (error) {
          const e = error as BusinessError;
          hilog.warn(LOG_DOMAIN, LOG_TAG, 'HOTKEY_UNREGISTER_FAILED ' + portableText + ' ' + e.code);
        }
        this.shortcutSubscriptions.delete(portableText);
      }
    });

    registrations.forEach((registration: NativeHotkeyRegistration) => {
      if (this.shortcutSubscriptions.has(registration.portableText) ||
        this.failedShortcutTexts.has(registration.portableText)) {
        return;
      }
      const options: inputConsumer.HotkeyOptions = {
        preKeys: registration.preKeys.map((key: number) => key),
        finalKey: registration.finalKey,
        isRepeat: false
      };
      const callback = (_event: inputConsumer.HotkeyOptions): void => {
        if (this.snowShotNative !== null) {
          this.snowShotNative.activateHotkey(registration.portableText);
        } else {
          this.pendingHotkeyActivations.add(registration.portableText);
        }
      };
      try {
        inputConsumer.on('hotkeyChange', options, callback);
        this.shortcutSubscriptions.set(registration.portableText, {options, callback});
      } catch (error) {
        const e = error as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG, 'HOTKEY_REGISTER_FAILED ' + registration.portableText + ' ' + e.code + ' ' + e.message);
        this.reportHotkeyRegistrationFailure(registration.portableText, e.code);
      }
    });
  }

  private startGlobalShortcutBridge(): void {
    if (QAbility.shortcutBridgeOwner !== this || this.shortcutSyncTimer !== undefined) {
      return;
    }
    this.syncGlobalShortcuts();
    this.shortcutSyncTimer = setInterval(() => this.syncGlobalShortcuts(), 500);
  }

  private registerEarlyDefaultShortcuts(): void {
    if (QAbility.shortcutBridgeOwner !== this || this.earlyShortcutsRegistered) {
      return;
    }
    // this.snowShotNative is assigned asynchronously (await import('libsnow_shot.so')
    // in onCreate()); a strict '=== null' check does not catch 'undefined', which is
    // what the field actually holds until that import resolves. On r226 the import
    // had not resolved by the time this ran, so the old guard let an unguarded
    // this.snowShotNative.parseShortcut(...) crash the whole process (device evidence:
    // logs/r226-crash-report.txt, TypeError: Cannot read property parseShortcut of
    // undefined). Treat "not yet available" as retryable instead of fatal: reschedule
    // a bounded number of times rather than silently abandoning early registration
    // (production's own startup still registers shortcuts later, but we should not
    // rely on that as the only path while native loading is still in flight).
    if (this.snowShotNative == null) {
      this.earlyShortcutsRetryCount += 1;
      if (this.earlyShortcutsRetryCount > QAbility.earlyShortcutsMaxRetries) {
        this.earlyShortcutsRegistered = true;
        hilog.warn(LOG_DOMAIN, LOG_TAG,
          'SNOW_TRACE_EARLY_SHORTCUTS_NATIVE_TIMEOUT ' + this.earlyShortcutsRetryCount);
        return;
      }
      setTimeout(() => this.registerEarlyDefaultShortcuts(), QAbility.earlyShortcutsRetryDelayMs);
      return;
    }
    this.earlyShortcutsRegistered = true;
    const defaultTexts: Array<string> = ['Ctrl+Alt+F1', 'Ctrl+Alt+F3', 'Ctrl+F1', 'Ctrl+F3'];
    let configuredTexts: Set<string> = new Set<string>();
    try {
      const configText = fileIo.readTextSync(this.context.filesDir + '/config.json');
      const config = JSON.parse(configText) as PersistedShortcutConfig;
      const groups = config.global_shortcuts;
      if (groups !== undefined) {
        Object.keys(groups).forEach((key: string) => {
          const bindings = groups[key];
          bindings.forEach((binding: PersistedShortcutBinding) => {
            if (binding.portable.length > 0) {
              configuredTexts.add(binding.portable);
            }
          });
        });
      }
    } catch (error) {
      const e = error as BusinessError;
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'EARLY_SHORTCUT_CONFIG_FALLBACK ' + this.context.filesDir +
        '/config.json ' + e.code + ' ' + e.message);
    }
    if (configuredTexts.size === 0) {
      configuredTexts = new Set<string>(defaultTexts);
    }
    configuredTexts.forEach((portableText: string) => {
      if (this.shortcutSubscriptions.has(portableText)) {
        return;
      }
      if (this.snowShotNative == null) {
        return;
      }
      const registration = this.snowShotNative.parseShortcut(portableText) as NativeHotkeyRegistration | null;
      if (registration === null || registration === undefined) {
        return;
      }
      const options: inputConsumer.HotkeyOptions = {
        preKeys: registration.preKeys, finalKey: registration.finalKey, isRepeat: false
      };
      const callback = (_event: inputConsumer.HotkeyOptions): void => {
        if (this.snowShotNative !== null) {
          this.snowShotNative.activateHotkey(registration.portableText);
        } else {
          this.pendingHotkeyActivations.add(registration.portableText);
        }
      };
      try {
        inputConsumer.on('hotkeyChange', options, callback);
        this.shortcutSubscriptions.set(registration.portableText, {options, callback});
      } catch (error) {
        const e = error as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG, 'SNOW_BRIDGE_EARLY_REGISTER_FAILED ' + registration.portableText + ' ' + e.code + ' ' + e.message);
        this.reportHotkeyRegistrationFailure(registration.portableText, e.code);
      }
    });
  }

  private ensureAssetDirectory(path: string): void {
    try {
      fileIo.mkdirSync(path, true);
    } catch (error) {
      const e = error as BusinessError;
      if (e.code !== 13900015) {
        throw new Error(e.message);
      }
    }
  }

  private installOcrAssets(): void {
    const appFilesDir: string = this.context.getApplicationContext().filesDir;
    const modelId: string = 'ppocrv6-small-463ea9f';
    const names: Array<string> = [
      'ocr/asset-manifest.json',
      'ocr/models/' + modelId + '/PP-OCRv6_det_small.onnx',
      'ocr/models/' + modelId + '/PP-OCRv6_rec_small.onnx',
      'ocr/models/' + modelId + '/ppocrv6_dict.txt',
      'qrcode/detect.prototxt',
      'qrcode/detect.caffemodel',
      'qrcode/sr.prototxt',
      'qrcode/sr.caffemodel'
    ];
    names.forEach((name: string) => {
      const bytes: Uint8Array = this.context.resourceManager.getRawFileContentSync(name);
      const destination: string = appFilesDir + '/assets/' + name;
      const parent: string = destination.substring(0, destination.lastIndexOf('/'));
      this.ensureAssetDirectory(parent);
      const file = fileIo.openSync(destination,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try {
        const written: number = fileIo.writeSync(file.fd, bytes.buffer);
        if (written !== bytes.byteLength) {
          throw new Error('short packaged model write: ' + name + ' (' + written + '/' + bytes.byteLength + ')');
        }
      } finally {
        fileIo.closeSync(file.fd);
      }
    });
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    QAbilityStage.initQtAppContextIfNeeded(this.context.getApplicationContext());
    const atManager = abilityAccessCtrl.createAtManager();
    this.permissionRequest = atManager.requestPermissionsFromUser(
      this.context, ['ohos.permission.CUSTOM_SCREEN_CAPTURE']
    ).then(async () => {
      qpa.handleAbilityOnCreate(this, want, launchParam);
      try {
        this.installOcrAssets();
        const nativeModule: ESObject = await import('libsnow_shot.so');
        this.snowShotNative = nativeModule.default as SnowShotNativeModule;
        this.pendingHotkeyActivations.forEach((portableText: string) => {
          this.snowShotNative?.activateHotkey(portableText);
        });
        this.pendingHotkeyActivations.clear();
        this.failedShortcutTexts.forEach((errorCode: number, portableText: string) => {
          this.reportHotkeyRegistrationFailure(portableText, errorCode);
        });
      } catch (error) {
        const e = error as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG, 'SNOW_NATIVE_LAZY_IMPORT_FAILED ' + e.code + ' ' + e.message);
      }
    });
  }

  onDestroy(): void | Promise<void> {
    QAbility.shortcutBridgeCandidates.delete(this);
    this.releaseGlobalShortcutBridge();
    return qpa.handleAbilityOnDestroy(this);
  }

  onPrepareToTerminate(): boolean {
    return qpa.handleAbilityOnPrepareToTerminate(this);
  }

  onPrepareToTerminateAsync(): Promise<boolean> {
    return qpa.handleAbilityOnPrepareToTerminateAsync(this);
  }

  onWindowStageCreate(windowStage: Window.WindowStage) {
    const continueStageCreate = (): void => {
      QAbility.shortcutBridgeCandidates.add(this);
      if (QAbility.shortcutBridgeOwner === null) {
        QAbility.shortcutBridgeOwner = this;
      }
      qpa.handleAbilityOnWindowStageCreate(this, windowStage);
      this.startGlobalShortcutBridge();
      setTimeout(() => this.registerEarlyDefaultShortcuts(), 250);
    };
    if (this.permissionRequest) {
      this.permissionRequest.then(continueStageCreate);
    } else {
      continueStageCreate();
    }
  }

  onWindowStageRestore(windowStage: Window.WindowStage): void {
    QAbility.shortcutBridgeCandidates.add(this);
    if (QAbility.shortcutBridgeOwner === null) {
      QAbility.shortcutBridgeOwner = this;
      this.registerEarlyDefaultShortcuts();
      this.startGlobalShortcutBridge();
    }
    qpa.handleAbilityOnWindowStageRestore(this, windowStage);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    qpa.handleAbilityOnNewWant(this, want, launchParam);
  }

  onForeground() {
    QAbility.foregroundPickerAbility = this;
    this.startPendingUserFileSavePickers();
    this.startPendingUserFileExports();
    qpa.handleAbilityOnForeground(this);
  }

  onBackground() {
    if (QAbility.foregroundPickerAbility === this) {
      QAbility.foregroundPickerAbility = null;
    }
    qpa.handleAbilityOnBackground(this);
  }

  onWindowStageDestroy() {
    QAbility.shortcutBridgeCandidates.delete(this);
    this.releaseGlobalShortcutBridge();
    qpa.handleAbilityOnWindowStageDestroy(this);
  }

  private releaseGlobalShortcutBridge(): void {
    if (QAbility.shortcutBridgeOwner !== this) {
      return;
    }
    if (this.shortcutSyncTimer !== undefined) {
      clearInterval(this.shortcutSyncTimer);
      this.shortcutSyncTimer = undefined;
    }
    this.shortcutSubscriptions.forEach((subscription: ArkHotkeySubscription) => {
      inputConsumer.off('hotkeyChange', subscription.options, subscription.callback);
    });
    this.shortcutSubscriptions.clear();
    QAbility.shortcutBridgeOwner = null;
    const nextOwner: QAbility | undefined = QAbility.shortcutBridgeCandidates.values().next().value;
    if (nextOwner !== undefined) {
      QAbility.shortcutBridgeOwner = nextOwner;
      nextOwner.registerEarlyDefaultShortcuts();
      nextOwner.startGlobalShortcutBridge();
    }
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult | Promise<AbilityConstant.OnContinueResult> {
    return qpa.handleAbilityOnContinue(this, wantParam);
  }
}
