display_next="yabai -m display --focus next"
display_first="yabai -m display --focus 1"

$display_next
if [ $? != 0 ]; then
    $display_first
fi
