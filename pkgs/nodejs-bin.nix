{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  python3,
}:
let
  version = "24.22.1";
  # Official https://nodejs.org/dist/v24.22.1/SHASUMS256.txt values.
  sources = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha256-icaCWT12zUQjP6U7FWMmTn3py7GJytFpE1xbT637wKc=";
    };
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-62co53xXajUWLBIsRcyt8iTYn/AKvI2uRswol8YALXw=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "nodejs-bin";
  inherit version;

  src = fetchurl {
    url = "https://nodejs.org/dist/v${version}/node-v${version}-${source.platform}.tar.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;
  dontConfigure = true;
  dontBuild = true;
  # Keep the upstream macOS code signature intact.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R bin include lib share "$out/"
    runHook postInstall
  '';

  preFixup = ''
    PATH="$out/bin:$PATH" patchShebangs "$out/lib/node_modules/npm"
  '';

  passthru = {
    python = python3;
    interpreterName = "nodejs";
  };

  meta = {
    description = "Node.js 24 official security release";
    homepage = "https://nodejs.org/";
    changelog = "https://nodejs.org/en/blog/release/v${version}";
    license = lib.licenses.mit;
    platforms = builtins.attrNames sources;
    mainProgram = "node";
  };
}
