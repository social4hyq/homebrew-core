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

declare const snowShotNative: {
  getRegisteredHotkeys(): Array<NativeHotkeyRegistration>;
  activateHotkey(portableText: string): void;
  parseShortcut(portableText: string): NativeHotkeyRegistration | null;
  rejectHotkeyRegistration(portableText: string, errorCode: number): void;
  takePendingUserFileExports(): Array<NativeUserFileExport>;
  completeUserFileExport(id: number, succeeded: boolean, error?: string): boolean;
  takePendingUserFileSavePickers(): Array<NativeUserFileSavePickerRequest>;
  completeUserFileSavePicker(id: number, uri: string, suffixIndex: number, error?: string): boolean;
};

export default snowShotNative;
