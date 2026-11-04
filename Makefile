.DEFAULT_GOAL := help

.PHONY: help init rebuild update-nixpkgs update-all

help:
	@printf '%s\n' \
	  'make / make help     操作一覧を表示' \
	  'make init            local.nixを生成し、成功後に初回適用' \
	  'make rebuild         設定変更を反映' \
	  'make update-nixpkgs  Nixpkgsのみ更新（flake.lock）' \
	  'make update-all      全inputsを更新（flake.lock）'

init:
	./scripts/init-local.sh && ./scripts/bootstrap.sh

rebuild:
	./scripts/rebuild.sh

update-nixpkgs:
	nix --extra-experimental-features nix-command \
	  --extra-experimental-features flakes flake update nixpkgs

update-all:
	nix --extra-experimental-features nix-command \
	  --extra-experimental-features flakes flake update
