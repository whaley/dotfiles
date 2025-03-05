display_next="yabai -m  --swap next "
display_first="yabai -m display --swap 1"

$display_next
if [ $? != 0 ]; then
    $display_first
fi