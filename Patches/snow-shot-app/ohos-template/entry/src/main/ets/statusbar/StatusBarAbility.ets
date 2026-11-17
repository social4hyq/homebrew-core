// Status bar extension for the Qt tray icon. The Qt OHOS platform plugin
// registers the icon through @kit.StatusBarExtensionKit, which requires the app
// to declare a statusBarView extension ability; the generated Qt HAP template
// has none, so the tray never appears without this file.
import { StatusBarViewExtensionAbility } from '@kit.StatusBarExtensionKit';
import { UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SnowShotStatusBar';

export default class StatusBarAbility extends StatusBarViewExtensionAbility {
  onCreate(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'onCreate');
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    hilog.info(0x0000, TAG, '%{public}s', 'onSessionCreate');
    session.loadContent('statusbar/StatusBarPage');
  }

  onForeground(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'onBackground');
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    hilog.info(0x0000, TAG, '%{public}s', 'onSessionDestroy');
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'onDestroy');
  }
}
