import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { DEFAULT_TERMINAL_CONFIG, TerminalController, TerminalSurface } from 'libghostty-ohos';
import { HcBridge } from '../bridge/HcBridge';

const TAG = 'cmuxApp';

interface TermInfo {
  address: string;
  agent: string;
  status: string;
}

// cmux-like main UI:
//  left   = vertical tab sidebar (terminals + agent status, from hc)
//  center = terminal pane (libghostty surface fed by hc PTY stream via herdr-bridge)
//  right  = browser pane (ArkWeb, CDP-programmable)
@Entry
@Component
struct Index {
  private webController: webview.WebviewController = new webview.WebviewController();
  private termController: TerminalController = new TerminalController();
  private bridge: HcBridge | null = null;
  private streamChannel: number = -1;
  private currentTerm: string = '';
  @State private terms: TermInfo[] = [];
  @State private status: string = 'init';
  @State private webReady: boolean = false;
  @State private termReady: boolean = false;

  aboutToAppear(): void {
    // Terminal controller: input goes back to hc via bridge stream channel.
    this.termController.setConfig({
      fontSize: 15,
      scrollbackLines: 15000,
      bgColor: DEFAULT_TERMINAL_CONFIG.bgColor,
      fgColor: DEFAULT_TERMINAL_CONFIG.fgColor,
      cursorStyle: DEFAULT_TERMINAL_CONFIG.cursorStyle,
      cursorBlink: DEFAULT_TERMINAL_CONFIG.cursorBlink
    });
    this.termController.setTheme('Aizen_Dark');
    this.termController.setInputListener((data: string) => {
      if (this.bridge !== null && this.streamChannel >= 0) {
        // keystrokes are UTF-8 text from libghostty; send raw bytes on the PTY stream.
        this.bridge.sendInput(this.streamChannel, new util.TextEncoder().encodeInto(data));
      }
    });
    this.termReady = true;

    try {
      webview.WebviewController.setWebDebuggingAccess(true);
    } catch (e) {
      hilog.error(0x0000, TAG, 'web debug: %{public}s', JSON.stringify(e));
    }

    this.connectCore();
  }

  // Read bridge.conf (addr + token) injected as a rawfile, then connect.
  private async connectCore(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const raw = ctx.resourceManager.getRawFileContentSync('bridge.conf');
      const conf = new util.TextDecoder().decodeToString(raw);
      let addr = '127.0.0.1:8765';
      let token = '';
      for (const line of conf.split('\n')) {
        const i = line.indexOf('=');
        if (i <= 0) continue;
        const key = line.substring(0, i);
        const val = line.substring(i + 1).trim();
        if (key === 'addr') addr = val;
        if (key === 'token') token = val;
      }
      const parts = addr.split(':');
      const host = parts[0];
      const port = Number(parts[1]);
      hilog.info(0x0000, TAG, 'bridge %{public}s:%{public}d', host, port);

      const bridge = new HcBridge(token);
      await bridge.connect(host, port);
      this.bridge = bridge;

      const list = await bridge.call('terminal.list', {}) as Record<string, Object>;
      const arr = list['terminals'] as Array<Record<string, Object>>;
      const infos: TermInfo[] = [];
      for (const t of arr) {
        const fg = t['foreground'] as Record<string, Object> | undefined;
        infos.push({
          address: String(t['address']),
          agent: fg !== undefined && fg['name'] !== undefined ? String(fg['name']) : 'shell',
          status: String(t['status'] !== undefined ? t['status'] : '')
        });
      }
      this.terms = infos;
      if (infos.length > 0) await this.openTerm(infos[0].address);
      this.status = 'connected';
    } catch (e) {
      this.status = 'error';
      hilog.error(0x0000, TAG, 'connectCore: %{public}s', JSON.stringify(e));
    }
  }

  private async openTerm(address: string): Promise<void> {
    if (this.bridge === null) return;
    this.currentTerm = address;
    const bridge = this.bridge;
    const ch = await bridge.attach(address, 24, 80, (data: Uint8Array) => {
      // hc PTY bytes -> ghostty terminal renderer
      try { this.termController.feed(data); } catch (e) { /* ignore feed races */ }
    });
    this.streamChannel = ch;
    hilog.info(0x0000, TAG, 'attached %{public}s ch=%{public}d', address, ch);
  }

  build() {
    Row() {
      // ---- left: vertical tab sidebar ----
      Column() {
        Text('cmux').fontSize(18).fontWeight(FontWeight.Bold).padding(8)
        Text(this.status).fontSize(11).fontColor(Color.Gray).padding({ left: 8, bottom: 8 })
        ForEach(this.terms, (t: TermInfo) => {
          Row() {
            Text(t.agent).fontSize(13)
            Text(t.status).fontSize(10).fontColor(t.status === 'working' ? '#e5c07b' : '#61afef')
          }
          .padding(8)
          .backgroundColor(t.address === this.currentTerm ? '#3a3f4b' : 'transparent')
          .onClick(() => { this.openTerm(t.address); })
        })
      }
      .width('20%').height('100%').backgroundColor('#21252b')

      // ---- center: terminal pane ----
      Column() {
        TerminalSurface({
          controller: this.termController,
          surfaceId: 'cmux_main_term',
          surfaceColor: '#0B0D10'
        }).width('100%').height('100%')
      }
      .width('45%').height('100%')

      // ---- right: browser pane ----
      Column() {
        Web({ src: $rawfile('probe.html'), controller: this.webController })
          .javaScriptAccess(true).fileAccess(true).domStorageAccess(true)
          .width('100%').height('100%')
          .onPageEnd(() => { this.webReady = true; })
      }
      .width('35%').height('100%')
    }
    .width('100%').height('100%')
  }
}
