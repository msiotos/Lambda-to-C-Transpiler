![Lambda_to_C_Transpiler](https://github.com/user-attachments/assets/ff92d0e3-04b9-47d7-abeb-034435cb71cf)

### Description
This project implements a transpiler (source-to-source compiler) for the Lambda (made-up) programming language, as defined in the Theory of Computation course (ΠΛΗ 402) at the Technical University of Crete. The transpiler takes Lambda source code as input and generates equivalent C code, facilitating the compilation and execution of Lambda programs.

### Key Features:

Lexical Analysis: Uses Flex to tokenize Lambda source code, identifying keywords, identifiers, constants, operators, and delimiters.
Syntax Analysis: Employs Bison to parse the tokenized code, ensuring it adheres to the grammatical rules of Lambda.
Code Generation: Translates valid Lambda code into C99 code, leveraging the features and libraries of C for execution.
Error Handling: Provides informative error messages in case of lexical or syntactical errors, indicating the line number and nature of the error.

### Tools Used:

Flex: A lexical analyzer generator.
Bison: A parser generator.
C: The target language for code generation.
GCC: The C compiler used for compiling the generated C code.

### Project Structure:

mylexer.l: Flex specification for Lambda lexical analysis.
myanalyzer.y: Bison specification for Lambda syntax analysis and C code generation.
lambdalib.h: Header file containing C implementations of Lambda's built-in functions.
correct1.la, correct2.la: Example Lambda programs.
correct1.c, correct2.c: Corresponding C translations of the example programs.

### Usage:

Ensure Flex, Bison, and GCC are installed on your system.
Place your Lambda source code in a file with the .la extension.
Run the transpiler using the command ./mycompiler < your_lambda_file.la.
If the Lambda code is valid, the equivalent C code will be generated in a file named your_lambda_file.c.
Compile the generated C code using GCC: gcc -std=c99 -Wall your_lambda_file.c -o your_lambda_file.
Run the executable: ./your_lambda_file.

### Grade: 9.5/10
