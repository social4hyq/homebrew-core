// Quick-operation panel shown when the tray icon is left-clicked. The status
// bar service requires a host page even when the app draws nothing there.
@Entry
@Component
struct StatusBarPage {
  build() {
    Row() {
      Column() {}
    }
    .width('100%')
    .height('100%')
  }
}
