# Produces window ids that aren't focused, space delimited: e.g. "59112 22636 47407 56082" 
window_ids=$(yabai -m query --windows | jq 'map(select(."has-focus" == false)) | map(.id) | @sh'  | sed s/\"//g) 

for id in $window_ids; do
  yabai -m window --minimize $id
done
