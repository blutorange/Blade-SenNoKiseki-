require 'json'

###################################INPUT########################################
input = $stdin.gets
state = JSON.parse(input)


###################################STRATEGY#####################################
# select card to play at random
card = rand(state["player"]["hand"].length)

###################################RESPONSE#####################################
# including a newline
$stdout.puts card
