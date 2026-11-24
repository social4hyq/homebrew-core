import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { DEFAULT_TERMINAL_CONFIG, TerminalController, TerminalSurface } from 'libghostty-ohos';
import { HcBridge } from '../bridge/HcBridge';

const TAG = 'cmuxApp';

// PTY byte <-> char mapping (Latin-1): keeps escape sequences and UTF-8 bytes
// byte-for-byte intact across the hc bridge <-> libghostty boundary.
function bytesToString(data: Uint8Array): string {
  let s = '';
  for (let i = 0; i < data.length; i++) s += String.fromCharCode(data[i]);
  return s;
}
function stringToBytes(s: string): Uint8Array {
  const out = new Uint8Array(s.length);
  for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i) & 0xff;
  return out;
}
function lastPath(p: string): string {
  const i = p.lastIndexOf('/');
  return i >= 0 ? p.substring(i + 1) : p;
}

interface TermInfo {
  address: string;
  agent: string;
  status: string;
  cwd: string;
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
        // ghostty emits terminal byte streams as strings; send bytes verbatim.
        this.bridge.sendInput(this.streamChannel, stringToBytes(data));
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

      const list = await bridge.call('terminal.list', new Object()) as Record<string, Object>;
      const arr = list['terminals'] as Array<Record<string, Object>>;
      const infos: TermInfo[] = [];
      for (const t of arr) {
        const fg = t['foreground'] as Record<string, Object> | undefined;
        let agent = 'shell';
        if (fg !== undefined && fg['name'] !== undefined) agent = String(fg['name']);
        let status = '';
        const sv = t['status'];
        if (typeof sv === 'string') status = sv;
        infos.push({
          address: String(t['address']),
          agent: agent,
          status: status,
          cwd: t['cwd'] !== undefined ? String(t['cwd']) : ''
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
      // hc PTY output is UTF-8 text; feed() takes a string. (A per-frame
      // TextDecoder is what rendered CJK correctly in the verified build.)
      try { this.termController.feed(new util.TextDecoder().decodeToString(data)); }
      catch (e) { /* feed race */ }
    });
    this.streamChannel = ch;
    hilog.info(0x0000, TAG, 'attached %{public}s ch=%{public}d', address, ch);
  }

  @Builder
  statusDot(s: string) {
    Circle({ width: 8, height: 8 })
      .fill(s === 'working' ? '#e5c07b' : (s === 'idle' ? '#61afef' : '#7ec87e'))
  }

  @Builder
  agentGlyph(agent: string) {
    Text(agent === 'opencode' ? '◉' : (agent === 'antigravity' ? '✦' : '›'))
      .fontSize(15)
      .fontColor(agent === 'opencode' ? '#7ee2c0' : '#9aa4b2')
      .width(22)
      .textAlign(TextAlign.Center)
  }

  build() {
    Row() {
      // ============ left sidebar ============
      Column() {
        // brand + connection
        Row() {
          Text('◧').fontSize(20).fontColor('#4c8bf5').margin({ right: 8 })
          Text('cmux').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#eef1f5')
        }
        .width('100%').padding({ left: 16, top: 18, bottom: 14 })

        Row() {
          Circle({ width: 7, height: 7 })
            .fill(this.status === 'connected' ? '#7ec87e' : '#e06c75')
          Text(this.status === 'connected' ? 'Connected' : this.status)
            .fontSize(11).fontColor('#8b93a1').margin({ left: 7 })
        }
        .width('100%').padding({ left: 16, bottom: 18 })

        // Spaces section label
        Row() {
          Text('SPACES').fontSize(10).fontColor('#6b7280').fontWeight(FontWeight.Medium)
          Text('+').fontSize(14).fontColor('#8b93a1')
        }
        .width('100%').justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 16, right: 16, bottom: 8 })

        // workspace card (active)
        Row() {
          Stack() {
            Circle({ width: 20, height: 20 }).fill('#3b82f6')
            Text('W').fontSize(11).fontColor(Color.White).fontWeight(FontWeight.Bold)
          }
          Text('Workspace').fontSize(13).fontColor('#eef1f5').margin({ left: 10 })
        }
        .width('calc(100% - 20px)').margin({ left: 10, right: 10, bottom: 16 })
        .padding({ left: 8, top: 8, bottom: 8 })
        .backgroundColor('#2d2f36').borderRadius(8)

        // Agents section label
        Row() {
          Text('AGENTS').fontSize(10).fontColor('#6b7280').fontWeight(FontWeight.Medium)
          Circle({ width: 14, height: 14 }).fill('#2d2f36')
        }
        .width('100%').justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 16, right: 16, bottom: 8 })

        // agent tabs
        ForEach(this.terms, (t: TermInfo) => {
          Row() {
            this.agentGlyph(t.agent)
            Column() {
              Text(t.agent).fontSize(12).fontColor('#eef1f5').maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(t.address + (t.cwd.length > 0 ? ' · ' + lastPath(t.cwd) : ''))
                .fontSize(9).fontColor('#6b7280').maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1).alignItems(HorizontalAlign.Start)
            this.statusDot(t.status)
          }
          .width('calc(100% - 20px)').margin({ left: 10, right: 10, bottom: 4 })
          .padding({ left: 8, right: 10, top: 9, bottom: 9 })
          .backgroundColor(t.address === this.currentTerm ? '#0d6efd' : 'transparent')
          .borderRadius(8)
          .onClick(() => { this.openTerm(t.address); })
        })

        Blank()

        // footer
        Row() {
          Text('⚙').fontSize(13).fontColor('#8b93a1').margin({ right: 12 })
          Text('+  New agent').fontSize(12).fontColor('#8b93a1')
        }
        .width('100%').padding({ left: 16, bottom: 18 })
      }
      .width(240).height('100%').backgroundColor('#1a1b1e')
      .border({ width: { right: 1 }, color: '#2a2c31' })

      // ============ center: terminal pane ============
      // TerminalSurface needs a full-size, stable surface to bind its native
      // renderer at onLoad; a layoutWeight'd/partial-height parent makes the
      // native bind fail and libghostty falls back to overlapping plain text.
      Stack() {
        TerminalSurface({
          controller: this.termController,
          surfaceId: 'cmux_main_term',
          surfaceColor: '#0B0D10'
        })
          .width('100%').height('100%')
      }
      .layoutWeight(1).height('100%').backgroundColor('#0B0D10')

      // ============ right: browser pane ============
      Column() {
        Row() {
          Text('◍').fontSize(12).fontColor('#4c8bf5').margin({ right: 7 })
          Text('Browser').fontSize(12).fontColor('#c9d1d9')
          Blank()
          Text('⋯').fontSize(14).fontColor('#8b93a1')
        }
        .width('100%').height(36).padding({ left: 14, right: 14 })
        .backgroundColor('#202126')

        Web({ src: $rawfile('probe.html'), controller: this.webController })
          .javaScriptAccess(true).fileAccess(true).domStorageAccess(true)
          .width('100%').layoutWeight(1)
          .onPageEnd(() => { this.webReady = true; })
      }
      .width('34%').height('100%').backgroundColor('#141519')
    }
    .width('100%').height('100%')
  }
}
