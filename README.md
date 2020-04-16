# A little, straightforward console tool for (Rake) logging purposes.

## Usage:
````
output something to the console (block is optional):

console.say("Info for terminal output") { sleep 5 }

Keep track of the time:

console.say_with_time("Info for terminal output") { sleep 5 }
=> this will output "5.0 seconds" after the log itself.

This command    => writes + counts:
console.dot     =>  .
console.skip    =>  >
console.failure =>  x
console.error   =>  x
````
It will count the dots with their types

## Example:
````
console.say_with_time("FIRST level") do
  console.say("SECOND level") do
    console.say_with_time("THIRD level") do
      420.times{ console.dot }
    end
    # console.dot
    console.puts("second")
  end
  console.dot
  console.dot
  console.puts("first")
  console.dot
  console.dot
end
````

### Will output:
````
FIRST level
  SECOND level
    THIRD level
      .................................................................................................... 100
      .................................................................................................... 200
      .................................................................................................... 300
      .................................................................................................... 400
      ....................
     -> 0.00 seconds
    second
  ..first
  ..
 -> 0.01 seconds
````
