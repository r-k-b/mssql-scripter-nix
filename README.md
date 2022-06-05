# usage

requires:

- nix >= 2.4 with Flakes enabled

`$ nix run github:r-k-b/mssql-scripter-nix -- --version`

`$ nix run github:r-k-b/mssql-scripter-nix -- --help`

Etc etc.

# dev setup

requires:

- nix >= 2.4 with Flakes enabled
- direnv
- a host with a running Docker daemon

steps:

- `direnv allow`
- `createDotEnv`
- fill in `./.env`
- `docker-compose up -d`
- `mssql-scripter --version`
- hack away

# see also

- <https://github.com/microsoft/mssql-scripter>
- <https://github.com/dbcli/mssql-cli>
- <https://github.com/r-k-b/mssql-cli-nix>
