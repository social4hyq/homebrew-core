import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DEFAULT_TERMINAL_CONFIG, TerminalController, TerminalSurface } from 'libghostty-ohos';

const TAG = 'cmuxP2';

// P2 骨架探针：真 TerminalSurface（libghostty-ohos）+ Web 组件同窗并列。
// 这是 cmux-like UI 壳的核心：左 terminal pane / 右 browser pane。
// 终端 driver 暂用回显（输入原样 feed 回去），P2 后续接 herdr-bridge → hc。
@Entry
@Component
struct Index {
  private webController: webview.WebviewController = new webview.WebviewController();
  private termController: TerminalController = new TerminalController();
  @State private termReady: boolean = false;
  @State private webReady: boolean = false;

  aboutToAppear(): void {
    try {
      webview.WebviewController.setWebDebuggingAccess(true);
      hilog.info(0x0000, TAG, 'web debug on');
    } catch (e) {
      hilog.error(0x0000, TAG, 'web debug failed: %{public}s', JSON.stringify(e));
    }
    try {
      this.termController.setConfig({
        fontSize: 15,
        scrollbackLines: 15000,
        bgColor: DEFAULT_TERMINAL_CONFIG.bgColor,
        fgColor: DEFAULT_TERMINAL_CONFIG.fgColor,
        cursorStyle: DEFAULT_TERMINAL_CONFIG.cursorStyle,
        cursorBlink: DEFAULT_TERMINAL_CONFIG.cursorBlink
      });
      this.termController.setTheme('Aizen_Dark');
      // 回显 driver：输入直接 feed 回终端，验证 input/output 链路。
      this.termController.setInputListener((data: string) => {
        try {
          this.termController.feed(data);
        } catch (e) {
          hilog.error(0x0000, TAG, 'feed failed: %{public}s', JSON.stringify(e));
        }
      });
      this.termReady = true;
    } catch (e) {
      hilog.error(0x0000, TAG, 'terminal setup failed: %{public}s', JSON.stringify(e));
    }
  }

  build() {
    Column() {
      Text(`cmux P2: terminal | web  (term=${this.termReady} web=${this.webReady})`)
        .fontSize(14).padding(6)

      Row() {
        // ---- 左：终端 pane（libghostty-ohos）----
        Column() {
          TerminalSurface({
            controller: this.termController,
            surfaceId: 'cmux_p2_term_surface',
            surfaceColor: '#0B0D10'
          })
            .width('100%').height('100%')
        }
        .width('50%').height('100%')
        .border({ width: 1, color: Color.Green })

        // ---- 右：浏览器 pane（ArkWeb，CDP 可编程）----
        Column() {
          Web({ src: $rawfile('probe.html'), controller: this.webController })
            .javaScriptAccess(true).fileAccess(true).domStorageAccess(true)
            .width('100%').height('100%')
            .onPageEnd(() => { this.webReady = true; })
        }
        .width('50%').height('100%')
        .border({ width: 1, color: Color.Blue })
      }
      .width('100%').layoutWeight(1)
    }
    .width('100%').height('100%')
  }
}
