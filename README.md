# formatstr

String interpolation library, complement of [std/strformat](https://nim-lang.org/docs/strformat.html) for runtime pattern.

The main differences are that the arguments are to be called by `format`, similarly to Python's `str.format()`, and that the pattern string can be set at runtime.

For example:
```nim
import formatstr

var str = "{} lives {:.1f} km from {:>10}."
echo str.format("Peio", 8 / 3, "Garazi.")
```
gives
```
Peio lives 2.7 km from     Garazi.
```

You can use numbers to indicate the argument to use:
```nim
let str = if character == "Yoda": "In {2}, {1} is" else: "{1} is in {2}"
echo str.format("Yoda", "Ryan", "the kitchen")
```

**Warning** : You cannot use unnumbered formats after the first numbered format

The specification of standard format specifiers (after the `:`) is exactly the same as in [strformat](https://nim-lang.org/docs/strformat.html#standard-format-specifiers-for-strings-integers-and-floats),
as it use the same procedure `formatValue`.

Similarly to `strformat`, one can provide `formatValue` for a custom type:
```nim
import formatstr
type Person = object
  name: string
  age: int

proc formatValue(result: var string, arg: Person, spec: string) =
  result.add(arg.name)
  if 'a' in spec:
    result.add "(" & $arg.age & " years old)"

let person = Person(name: "Alice", age: 42)
check "{}".format(person) == "Alice"
check "{:a}".format(person) == "Alice(42 years old)"
```
should give
```
Alice
Alice(42 years old)
```

# Installation

```
nimble install formatstr
```

## Requirements

- [Nim](https://nim-lang.org/)

## License

MIT