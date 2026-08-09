{
  lib,
  python3,
}:
python3.pkgs.buildPythonApplication {
  pname = "web-noise";
  version = "2.0.0";

  pyproject = true;

  src = ./.;

  build-system = with python3.pkgs; [
    setuptools
  ];

  dependencies = with python3.pkgs; [
    requests
  ];

  # setup.py's data_files covers $out/share; the sitePackages copy is what
  # find_profiles() looks at first.
  postInstall = ''
    install -Dm644 ${./browser_profiles.json} $out/share/web-noise/browser_profiles.json
    install -Dm644 ${./config.example.json} $out/share/web-noise/config.example.json
    cp ${./browser_profiles.json} $out/${python3.sitePackages}/browser_profiles.json
  '';

  doCheck = false;
  pythonImportsCheck = ["noise_generator"];

  meta = with lib; {
    description = "Generate realistic web traffic noise for privacy";
    longDescription = ''
      A tool that generates realistic-looking random web traffic to obfuscate
      browsing patterns. Supports multiple concurrent simulated users with
      real browser profiles and headers.
    '';
    homepage = "https://github.com/aciddemon/nixfiles";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.unix;
    mainProgram = "web-noise";
    sourceProvenance = with sourceTypes; [fromSource];
  };
}
