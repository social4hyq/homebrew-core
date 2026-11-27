/* herdr-app OHOS napi module */
export interface HerdrModule {
  init(ability: object): void
  render(...args: unknown[]): unknown
  dispose(...args: unknown[]): void
}
export const init: (ability: object) => void
export function render(...args: unknown[]): unknown
export function dispose(...args: unknown[]): void
