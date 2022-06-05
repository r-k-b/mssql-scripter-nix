{
  description =
    "A command-line client for SQL Server with auto-completion and syntax highlighting";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.source = {
    url = "github:dbcli/mssql-cli";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, source }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib callPackage stdenv;

        #        mssql-scripter = stdenv.mkDerivation {
        #          name = "mssql-scripter";
        #          src = pkgs.fetchFromGitHub {
        #            owner = "microsoft";
        #            repo = "mssql-scripter";
        #            rev = "v1.0.0a23";
        #            sha256 = "sha256-pjIxsywAKrznomvOOSz9ucNHFrwmQVhedqvpHzH0ZHU=";
        #          };
        #        };
        version = "1.0.0a23";
        mssql-scripter = pkgs.python3Packages.buildPythonApplication {
          name = "mssql-scripter";
          inherit version;
          src = pkgs.fetchFromGitHub {
            owner = "microsoft";
            repo = "mssql-scripter";
            rev = "v${version}";
            sha256 = "sha256-pjIxsywAKrznomvOOSz9ucNHFrwmQVhedqvpHzH0ZHU=";
          };

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
