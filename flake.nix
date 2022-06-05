{
  description =
    "A command-line client for SQL Server with auto-completion and syntax highlighting";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.source = {
    url =
      "github:microsoft/mssql-scripter?rev=a2e3efddfcf744a4f7d11f2b3b538f8f7102728c";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, source }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib callPackage stdenv;

        version = "1.0.0a23";
        mssql-scripter = pkgs.python3Packages.buildPythonApplication {
          name = "mssql-scripter";
          inherit version;
          src = source;

          buildInputs = with pkgs; [ python3 ];

          # "mssql-scripter: error: unrecognized arguments: test"
          doCheck = false;

          propagatedBuildInputs = with pkgs.python3.pkgs; [ future ];

          preBuild = ''
            mkdir -p "$TMPDIR"/homeless_shelter
            export HOME="$TMPDIR"/homeless_shelter
            patchShebangs ./
          '';
        };

        createDotEnv = pkgs.writeScriptBin "createDotEnv" ''
          #!${pkgs.bash}/bin/bash
          ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel)
          cat <<EOF > "$ROOT"/.env
            DB_SA_PASSWORD=
            MSSQL_SCRIPTER_CONNECTION_STRING="Server=localhost,1433;Database=scratch;User Id=sa;Password=YOUR_DB_SA_PASSWORD_HERE;"
          EOF
          echo Secrets file "$ROOT/.env" created from template.
          echo Fill it in with some secrets.
        '';

        program = "${pkgs.writeScript "mssql-scripter-program" ''
          #!${pkgs.bash}/bin/bash
          ${mssql-scripter}/bin/mssql-scripter "$@"
        ''}";

      in {
        defaultPackage = mssql-scripter;
        apps.default = {
          type = "app";
          inherit program;
        };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            createDotEnv
            docker-compose
            python3
            mssql-scripter
            nodePackages.prettier
          ];
          shellHook = ''
            #!${pkgs.bash}/bin/bash
            ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel)
            echo ===
            echo This is the dev shell for "$ROOT".
            if [[ ! -f "$ROOT/.env" ]]; then
                echo "Run 'createDotEnv', fill in the resulting .env file with some secrets."
            fi
            echo You can start a scratch / testing DB with \'docker-compose up\'.
            echo ===    
          '';
        };
      });

  nixConfig.bash-prompt = "[mssql-scripter]$ ";
}
