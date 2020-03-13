# The Lego Asynchronous State Machine Language Compiler
Execute Asynchronous State Machine (ASM) charts as RCX programs

## Key Concepts
* Asynchronous State Machine (ASM) charts illustrate state machines in the form of a flow chart.
* The ASM Language provides a way to express an ASM Chart as a program.
* The Perl-based compiler compiles the ASM Language code in Lego Assembly code for the Lego Mindstorm.


## Background
The ASM Language and Compiler were developed at [Wright State University](https://wright.edu/) during the Fall and Winter quarters of 2000 and 2001.
It was developed to meet the design clinic requirements of the Computer Engineering department and the Departmental Honors program.
The project was developed by Jason Gilder, Mike Peterson, and Jason Wright with Dr. Travis Doom as the project advisor.
* Original website – http://birg.cs.wright.edu/legoASM.html
* Version 1.0
* Last Updated March 14, 2001
* Written by Jason Gilder, Mike Peterson, and Jason Wright
* Copyright © 2001 Wright State University
* Archived website snapshot
  - https://web.archive.org/web/20080420130053/http://birg.cs.wright.edu/legoasm.html


## Requirements
* Perl
* Lego MindStorms SDK
  - v2.0 contains the ATLClient program to send Lego Assembly programs to the RCX
  - v2.5 contains the ScriptEd program to send Lego Assembly programs to the RCX


## Steps
1. Design an ASM chart and label your states
2. Write program in the ASM Language using any text editor
3. Compile the program
4. Use the Lego ATLClient program or ScriptEd program to send the Lego Assembly program to the Mindstorm
