## 2xa3 fproj

The task was to translate the python file `fproj.py` to a nasm program.

### Example execution 

first to compile the nasm executable, run:

  `make all`

Then you can run executable with any input.

For example, running `fproj ababab` will produce:

Input string: ababab
border array: 4, 3, 2, 1, 0, 0


+++ \
+++  +++ \
+++  +++  +++ \
+++  +++  +++  +++  ...  ... 

A quick explanation of this output is that the program computes the border array of the input string and displays it in a simple way (as an array of numbers), and in a fancy way (as a bar diagram)
