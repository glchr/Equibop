{
  lib,
  stdenv,
  bun,
  git,
  nodejs,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  electron,
  libicns,
  pipewire,
  libpulseaudio,
  autoPatchelfHook,
  writableTmpDirAsHomeHook,
  src,
  withTTS ? true,
  withMiddleClickScroll ? false,
  nodeModulesHash ? "sha256-zsdMwgngsP51Y4Eg9/UgpF8o/zvFvmUxg6QG7oF63vo=",
}:
let
  packageJson = lib.importJSON ../package.json;
in
stdenv.mkDerivation (finalAttrs: {
  pname = packageJson.name;
  version = packageJson.version;
  inherit src;

  node_modules = stdenv.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs)
      src
      version
      ;

    # Allow fixed-output dependency fetching behind enterprise proxies.
    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;
    # Fixed-output derivations cannot contain store path references.
    # stdenv fixup may patch shebangs to /nix/store/.../bash, so disable it here.
    dontFixup = true;
    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

      # Keep dependency fetch reproducible. Lifecycle scripts are run later.
      bun install --no-progress --frozen-lockfile --ignore-scripts --no-cache

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R ./node_modules $out/

      runHook postInstall
    '';

    outputHash = nodeModulesHash;
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    git
    nodejs
    bun
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  postPatch = ''
    # electron-builder tries to mutate the copied Electron binary when
    # electronFuses is configured, which fails against Nix store-sourced bits.
    substituteInPlace package.json \
      --replace-fail '"electronFuses": {' '"electronFusesDisabledForNix": {'
  '';

  buildInputs = [
    libpulseaudio
    pipewire
    (lib.getLib stdenv.cc.cc)
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
    HOME = "$TMPDIR";
  };

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/node_modules .

    # Bun and node-based tooling execute from here during build.
    chmod -R u+rwX node_modules
    patchShebangs node_modules
    export PATH="$PWD/node_modules/.bin:$PATH"

    # Build arRPC binary for the current target platform.
    bun run compileArrpc

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    bun run build
    ./node_modules/.bin/electron-builder \
      --dir \
      -c.asarUnpack="**/*.node" \
      -c.electronDist=${electron.dist} \
      -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  postBuild = ''
    pushd build
    ${libicns}/bin/icns2png -x icon.icns
    popd
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/Equibop
    cp -r dist/*unpacked/resources $out/opt/Equibop/

    for file in build/icon_*x32.png; do
      file_suffix=''${file//build\/icon_}
      install -Dm0644 "$file" "$out/share/icons/hicolor/''${file_suffix//x32.png}/apps/equibop.png"
    done

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${electron}/bin/electron $out/bin/equibop \
      --add-flags $out/opt/Equibop/resources/app.asar \
      ${lib.optionalString withTTS "--add-flags \"--enable-speech-dispatcher\""} \
      ${lib.optionalString withMiddleClickScroll "--add-flags \"--enable-blink-features=MiddleClickAutoscroll\""} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  desktopItems = makeDesktopItem {
    name = "equibop";
    desktopName = "Equibop";
    exec = "equibop %U";
    icon = "equibop";
    startupWMClass = "Equibop";
    genericName = "Internet Messenger";
    keywords = [
      "discord"
      "equibop"
      "electron"
      "chat"
    ];
    categories = [
      "Network"
      "InstantMessaging"
      "Chat"
    ];
  };

  meta = {
    description = "Custom Discord App aiming to give you better performance and improve linux support";
    homepage = packageJson.homepage;
    license = lib.licenses.gpl3Only;
    mainProgram = "equibop";
    platforms = lib.platforms.linux;
  };
})
