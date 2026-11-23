#!/usr/bin/env bash
set -euo pipefail

keymap -c "draw/config.yaml" parse -z "config/lily58.keymap" --virtual-layers Combos -o "draw/base.yaml"
yq -Yi '.combos.[].l = ["Combos"]' "draw/base.yaml"
keymap -c "draw/config.yaml" draw "draw/base.yaml" -o "draw/base.svg"

jq_expr='
	def extract_label: if type == "string" then . else .t end;
	def is_transparent: type == "object" and (.type == "trans" or .type == "held");
	.layers = {
	base: [
		[.layers.base, .layers.navi, .layers.func, .layers.numb, .layers.syst] | transpose[] |
		(.[0] | if type == "string" then {t: .} else . end) as $base |
		(.[1] | if is_transparent then null else extract_label end) as $nav |
		(.[2] | if is_transparent then null else extract_label end) as $fn |
		(.[3] | if is_transparent then null else extract_label end) as $num |
		(.[4] | if is_transparent then null else extract_label end) as $sys |
		$base
		+ (if $nav == null then {} else {tr: $nav} end)
		+ (if $fn == null then {} else {tl: $fn} end)
		+ (if $num == null then {} else {bl: $num} end)
		+ (if $sys == null then {} else {br: $sys} end)
	],
	Combos: .layers.Combos
	} |
	.combos = [.combos[] | .l = ["Combos"]]
'
yq -y "$jq_expr" "draw/base.yaml" >"draw/overview.yaml"
keymap -c "draw/config.yaml" draw "draw/overview.yaml" -o "draw/overview.svg"
sed -i '/<text.*class="label"/d' "draw/overview.svg"
