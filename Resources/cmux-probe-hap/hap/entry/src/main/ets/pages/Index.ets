import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'cmuxProbe';

// P0 问题①最小验证：ArkTS Web 组件与 XComponent（native surface）同窗并列。
// 左侧 Web 开 CDP（setWebDebuggingAccess），右侧 XComponent 占位代表 GPUI 终端 surface。
@Entry
@Component
struct Index {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State private ready: boolean = false;
  private xcomponentId: string = 'cmux_probe_surface';

  aboutToAppear(): void {
    try {
      // 开 WebView 调试，内核暴露 devtools abstract socket 供社区包 connectOverCDP 直连。
      webview.WebviewController.setWebDebuggingAccess(true);
      hilog.info(0x0000, TAG, 'setWebDebuggingAccess(true) ok');
    } catch (e) {
      hilog.error(0x0000, TAG, 'setWebDebuggingAccess failed: %{public}s', JSON.stringify(e));
    }
  }

  build() {
    Column() {
      Text('cmux probe: Web | XComponent')
        .fontSize(16)
        .padding(8)

      Row() {
        // ---- 左：ArkWeb Web 组件（可编程浏览器 pane 的原型）----
        Column() {
          Web({ src: $rawfile('probe.html'), controller: this.webController })
            .javaScriptAccess(true)
            .fileAccess(true)
            .domStorageAccess(true)
            .width('100%')
            .height('100%')
            .onPageEnd(() => {
              this.ready = true;
              hilog.info(0x0000, TAG, 'web page end');
            })
        }
        .width('50%')
        .height('100%')
        .border({ width: 1, color: Color.Blue })

        // ---- 右：XComponent（native surface，代表 GPUI 终端 pane）----
        Column() {
          // 不指定 libraryname：探针只验证两种组件能否同窗共存渲染，
          // surface 本身空白即可，不加载 native .so。
          XComponent({
            id: this.xcomponentId,
            type: XComponentType.SURFACE,
          })
            .onLoad(() => {
              hilog.info(0x0000, TAG, 'xcomponent onLoad');
            })
            .width('100%')
            .height('100%')
        }
        .width('50%')
        .height('100%')
        .border({ width: 1, color: Color.Green })
      }
      .width('100%')
      .layoutWeight(1)

      Text(`web ready: ${this.ready}`)
        .fontSize(12)
        .padding(4)
    }
    .width('100%')
    .height('100%')
  }
}
