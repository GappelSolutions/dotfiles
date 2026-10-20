# Compact greeting for small panes, cut down from nerdfetch 8.4.2 (MIT, ThatOneCalculator)
# to the hosts here: NixOS (incl. WSL) and macOS with nix-darwin, Nerd Font icons.
# RAM and uptime refresh every second until a key is pressed, like the 3D greeting.

case $(uname) in
Linux)
	host=$(cat /proc/sys/kernel/hostname)
	. /etc/os-release
	os=$PRETTY_NAME
	osi="󱄅"
	cpu=$(lscpu | awk -F: '/^Model name:/ { sub(/^[ \t]+/, "", $2); print $2; exit }')
	uptime_s() { IFS=. read -r s _ </proc/uptime; }
	# KiB, used = total - available like fastfetch
	memory() {
		while IFS=':k ' read -r key val _; do
			case $key in
			MemTotal) mem_full=$val ;;
			MemAvailable) mem_avail=$val ;;
			esac
		done </proc/meminfo
		mem_used=$((mem_full - mem_avail))
	}
	;;
Darwin)
	host=$(scutil --get LocalHostName)
	os="$(sw_vers -productName) $(sw_vers -productVersion)"
	osi=""
	cpu=$(sysctl -n machdep.cpu.brand_string)
	boot=$(sysctl -n kern.boottime)
	boot=${boot#*sec = }
	boot=${boot%%,*}
	uptime_s() { s=$(($(date +%s) - boot)); }
	mem_full=$(($(sysctl -n hw.memsize) / 1024))
	page_kib=$(($(sysctl -n vm.pagesize) / 1024))
	# KiB, used = app + wired + compressed pages
	memory() {
		mem_used=0
		while IFS=:. read -r key val _; do
			case $key in
			'Anonymous '* | *' wired'* | *' occupied'*) mem_used=$((mem_used + ${val:-0})) ;;
			*' purgeable'*) mem_used=$((mem_used - ${val:-0})) ;;
			esac
		done < <(vm_stat)
		mem_used=$((mem_used * page_kib))
	}
	;;
esac
cpu=$(printf '%s' "$cpu" | sed 's/(R)//g; s/(TM)//g; s/  */ /g; s/ CPU @ / @ /; s/ with .*//; s/ w\/ .*//')

count() { nix-store -q --requisites "$1" 2>/dev/null | wc -l | tr -d ' '; }
packages="$(count /run/current-system/sw) system, $(count /etc/profiles/per-user/"$USER") home"

# Same colors as the 3D greeting: NixOS logo blue/cyan, user@host blue, labels magenta,
# plain values, percentage green/yellow/red.
e=$'\033'
r="$e[0m" lc="$r$e[1;35m" c0="$r$e[1;34m" c1="$r$e[1;36m"

# Values of the two live rows, memory in GiB like fastfetch
gib() { local c=$((($1 * 100 + 524288) / 1048576)); printf '%d.%02d' $((c / 100)) $((c % 100)); }
mem_line() {
	memory
	local pct=$(((mem_used * 100 + mem_full / 2) / mem_full)) pc=32
	((pct >= 50)) && pc=33
	((pct >= 80)) && pc=31
	mem_line="$(gib "$mem_used") / $(gib "$mem_full") GiB ($e[${pc}m$pct%$r)"
}
up_line() {
	uptime_s
	local d=$((s / 86400)) h=$((s / 3600 % 24)) m=$((s / 60 % 60))
	up_line=
	((d > 0)) && up_line="${d}d "
	((h > 0)) && up_line="$up_line${h}h "
	up_line="$up_line${m}m"
}
mem_row() { printf '%s' "$c1  ## $c0**     **        $lc󰍛  $r$mem_line"; }
up_row() { printf '%s' "$c1 ##  $c0***$c1#########     $lc󰅶  $r$up_line"; }
mem_line
up_line

cat <<OUT

$c0    **   $c1##   ##
$c0     **   $c1## ##       $c0$USER$r@$c0$host$r
$c0  *********$c1###  $c0**    $r--------
$c1     ##     ## $c0**     $lc$osi  $r$os
$c1######       #$c0**      $lc󰏔  $r$packages
$c1   ##$c0*       ******   $lc󰻠  $r$cpu
$(mem_row)
$(up_row)
$c0    ** **   $c1##        $lc󰏘  $e[31m███$e[32m███$e[33m███$e[34m███$e[35m███$e[36m███$r
$c0   **   **   $c1##$r
OUT

[[ -t 0 && -t 1 ]] || exit 0
# RAM is 4 rows above the cursor, uptime 3
printf '%s[?25l' "$e"
trap 'printf "%s[?25h" "$e"' EXIT
trap 'exit 130' INT TERM
until read -rsn1 -t 1; do
	mem_line
	up_line
	printf '\r%s[4A%s%s[K\n%s%s[K\r%s[3B' "$e" "$(mem_row)" "$e" "$(up_row)" "$e" "$e"
done
