## This file is for functional tests based on BATS
## They run after the node converges for real (not like unit tests which run on a fake chef node)

@test "Check something happened for real" {
  run mycommand myparam
  [ "$status" -eq 0 ]
  [ "$output" = "omg it worked" ] 
}

# @test "Check we have bacon" {
#   run grep bacon /etc/sandwich.d/breakfast.conf
#   [ "$status" -eq 0 ]
#   [ "$output" = "bacon_quantity = 32kg"]
# }

# Note that a blank line needs to exist below this one for BATS tests to pass
# DO NOT REMOVE IT !!!


