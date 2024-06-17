stack_next="yabai -m window --focus stack.next "
stack_first="yabai -m window --focus stack.first "

$stack_next
if [ $? != 0 ]; then
    $stack_first
fi
