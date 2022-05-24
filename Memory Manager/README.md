## Virtual Memory Manager

This project consists of a program that translates logical to physical addresses for a virtual
address space of size 65,536 bytes.

The program reads logical address from the file *adresses.txt*.


*output.txt* contains the correct output values for the file *adresses.txt*.

At the end of the file the program prints two statisitcs, Page-fault rate, and TLB hit rate.

**Page-fault rate**—The percentage of address references that resulted in
page faults.

**TLB hit rate**—The percentage of address references that were resolved in
the TLB.


## Running The Program

To run the code, download all the files and compile it in c using the following:

``gcc program.c -o a.out``

Then run the following command:

``./a.out addresses.txt.``

The contents of *output*.txt will be printed to your terminal.
