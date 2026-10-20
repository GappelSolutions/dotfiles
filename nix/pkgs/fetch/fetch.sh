# One greeting for every pane: the spinning 3D logo (any key stops it) when the pane is bigger
# than half the screen, the compact one otherwise or without a terminal.
# 3D needs 32 rows for the logo + 1 for the prompt, and room beside it for the info.

if [ -t 0 ] && [ -t 1 ]; then
	read -r rows cols <<-SIZE
		$(stty size)
	SIZE
	if [ "$cols" -ge 100 ] && [ "$rows" -ge 34 ]; then
		exec @fetch3d@ --height 32 --infinite
	fi
fi
exec @small@
