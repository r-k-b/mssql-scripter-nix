# usage

requires:

- nix >= 2.4 with Flakes enabled

`$ nix run github:r-k-b/mssql-cli-nix -- --version`

`$ nix run github:r-k-b/mssql-cli-nix -- --help`

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
