# How to contribute
This is mostly for the author, but if you're looking to contribute, then please follow this.

## Coding convention
- Try not to pipe
- Use `[[]]` for tests
- Use snake_case for variable and function names
- Indent with 4 spaces

## Shellcheck
All future changes must pass ShellCheck

## Follow the knbnBrd hierarchy
Arguments must be in this order: Functions > Columns > Tasks > Note offset > Description

This is a requirement to keep everything consistent

### For example:
- Add a task to "todo": `knbn add todo "Description"`
- Remove 2nd task in "todo": `knbn rm todo 2`
- Move 5th task from "todo" to "in progress": `knbn mv todo "in progress" 5`
