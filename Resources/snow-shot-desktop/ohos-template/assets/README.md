# HAP brand assets

`app-icon.svg` is the Snow Shot upstream application icon, copied without modification from `mg-chao/snow-shot` at `snow_shot/resources/app-icon.svg`.

- Upstream source: <https://github.com/mg-chao/snow-shot/blob/main/snow_shot/resources/app-icon.svg>
- SHA-256: `e0978efa76d639524f8f48c65caf102c2a26a59cea75c34d8729525a56021de0`
- The raster files under `AppScope/` and `entry/src/main/resources/base/media/` are generated from this SVG at their target HarmonyOS resource dimensions. The adaptive icon uses a white background layer so it retains the official white rounded-square mark instead of the previous generic blue placeholder.
- `scripts/stage-ohos-app-icon-assets.py` copies and dimension-checks all four raster assets into the HAP stage before packaging.
