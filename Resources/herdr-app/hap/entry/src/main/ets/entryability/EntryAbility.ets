import { AbilityConstant, Want } from "@kit.AbilityKit";
import { fileIo as fs } from "@kit.CoreFileKit";
import { LazyPlugin, NativeAbility } from "@ohos-rs/ability";
import { AppControlPlugin } from "@ohos-rs/ability-plugin-app-control";
import { ClipboardPlugin } from "@ohos-rs/ability-plugin-clipboard";
import { FilesPlugin } from "@ohos-rs/ability-plugin-files";
import { MenuPlugin } from "@ohos-rs/ability-plugin-menu";
import { NotificationPlugin } from "@ohos-rs/ability-plugin-notification";
import { PermissionPlugin } from "@ohos-rs/ability-plugin-permission";
import { SystemStatePlugin } from "@ohos-rs/ability-plugin-system-state";
import { UrlPlugin } from "@ohos-rs/ability-plugin-url";
import { WindowPlugin } from "@ohos-rs/ability-plugin-window";
import * as nativeModule from "libopenharmony_ability.so";

export default class EntryAbility extends NativeAbility {
  public moduleName: string = "openharmony_ability";
  public defaultPage: boolean = true;
  public bridgePlugins = [
    new LazyPlugin(() => new AppControlPlugin()),
    new LazyPlugin(() => new ClipboardPlugin()),
    new LazyPlugin(() => new PermissionPlugin()),
    new LazyPlugin(() => new FilesPlugin()),
    new LazyPlugin(() => new MenuPlugin()),
    new LazyPlugin(() => new NotificationPlugin({ scheme: "gpui-notification" })),
    new LazyPlugin(() => new SystemStatePlugin()),
    new LazyPlugin(() => new UrlPlugin()),
    new LazyPlugin(() => new WindowPlugin()),
  ];

  /**
   * `herdr-app install` bakes the core bridge's address and token into the HAP as rawfile/bridge.conf.
   * The native side reads it from the app's files directory, so copy it there before anything starts.
   * A HAP without the file removes an older copy: the app follows the HAP it was installed from.
   */
  private publishBridgeConfig(): void {
    const dir = `${this.context.filesDir}/herdr-app`;
    const target = `${dir}/bridge.conf`;
    try {
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
      const content = this.context.resourceManager.getRawFileContentSync("bridge.conf");
      const file = fs.openSync(target, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, content.buffer.slice(content.byteOffset, content.byteOffset + content.byteLength));
      } finally {
        fs.closeSync(file);
      }
    } catch (e) {
      try {
        if (fs.accessSync(target)) {
          fs.unlinkSync(target);
        }
      } catch (ignored) {
        // nothing to remove
      }
    }
  }

  override onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (typeof nativeModule.init !== "function") {
      throw new Error("GPUI example native module is unavailable");
    }
    this.publishBridgeConfig();
    super.onCreate(want, launchParam);
  }
}
