/// CARTO Basemaps API key (Voyager / dark_all raster tiles).
///
/// Must appear as `?key=...` on every tile URL (see CARTO email / basemaps docs).
/// Do not use a `{key}` placeholder — embed the value so flutter_map cannot
/// drop it. https://carto.com/basemaps/apikey
const String kCartoApiKey = 'cb1_435a_1_efb596f1f2fdf59017093964';

/// CARTO raster tile URLs for [flutter_map].
abstract final class CartoMapTiles {
  /// Exact CARTO shape:
  /// `https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png?key=...`
  ///
  /// Uses `@2x` tiles for sharp phones (no flutter_map `{r}` / retinaMode hacks).
  static String urlTemplate({required bool dark}) {
    final style = dark ? 'dark_all' : 'voyager';
    return 'https://basemaps.cartocdn.com/rastertiles/$style/{z}/{x}/{y}@2x.png'
        '?key=$kCartoApiKey';
  }

  /// Required attribution: https://carto.com/attributions
  static const String attribution =
      '© CARTO, © OpenStreetMap contributors';
}
