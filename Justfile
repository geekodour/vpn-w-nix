default:
	@just --list

nix-spin: rebuild apply

rebuild:
	colmena build

apply:
	colmena apply
