
import std/unittest
import formatstr

type Obj = object

proc `$`(o: Obj): string = "foobar"

type Case = object

proc formatValue(result: var string, arg: Case, options: string) =
  case options
  of "c":
    result.add "fooBar"
  of "s":
    result.add "foo_bar"
  else:
    result.add "foobar"

type Person = object
  name: string
  age: int

proc formatValue(result: var string, arg: Person, spec: string) =
  result.add(arg.name)
  if 'a' in spec:
    result.add "(" & $arg.age & " years old)"

suite "format":

  test "numbers":
    doAssert format("{1:<10d}", 55) == "55        "
    doAssert format("{1:<8.3f},{2:>8.3f}", 3.1415, 1.2345) == "3.142   ,   1.234"
    doAssert format("\\{{} {1:5d}\\} ", 1, 3.1415, 1.777777e7) == "{1     1} "
    doAssert format("\\{{2:.3g} {2:.3f} {2:.3e} {2:.3f}\\}", 1, 3.1415, 1.777777e7) == "{3.14 3.142 3.142e+00 3.142}"
    doAssert format("\\{{3:.3g}€ {3:.3f}€ {3:.3e}€ €\\} \\{{2:e}\\}", 1, 3.1415,
            1.777777e7) == "{1.78e+07€ 17777770.000€ 1.778e+07€ €} {3.141500e+00}"
    doAssert format("\\{{},{1:6d},{1:<6d}\\} ", 1000, 3.1415, 1.777777e7) == "{1000,  1000,1000  } "
    doAssert format("\\{{2:>8.3g},{2:<8.3f},{2:>8.3e},{2:8.3f}\\}", 1000, 3.1415, 1.777777e7) == "{    3.14,3.142   ,3.142e+00,   3.142}"
    doAssert format("\\{{3:10.3g}€,{3:>10.3f}€,{3:<10.3e}€,{3:10.3f}€\\}", 1000, 3.1415,
        1.777777e7) == "{  1.78e+07€,17777770.000€,1.778e+07 €,17777770.000€}"
    doAssert format("\\{{1:<2d}\\}", 1000, 3.1415, 1.777777e7) == "{1000}"
    doAssert("{1:>20}".format(@['1', '2', ]) == "         @['1', '2']")

  test "$ defined":
    var obj: Obj
    check format("{1}", obj) == "foobar"
    check format("{1:10}", obj) == "foobar    "
    check format("{1:>10}", obj) == "    foobar"

  test "formatValue defined":
    var cas: Case
    check format("{1:c}", cas) == "fooBar"
    check format("{1:s}", cas) == "foo_bar"
    check format("{1}", cas) == "foobar"

    let person = Person(name: "Alice", age: 42)
    check "{}".format(person) == "Alice"
    check "{:a}".format(person) == "Alice(42 years old)"

  test "example":
    var str = "{} lives {:.1f} km from {:>10}."
    check str.format("Peio", 8 / 3, "Garazi") == "Peio lives 2.7 km from     Garazi."

  test "numbered":
    proc whereis(character, who, where: string): string =
      let str = if character == "Yoda": "In {2}, {1} is" else: "{1} is in {2}"
      str.format(who, where)
    check whereis("Yoda", "Ryan", "the kitchen") == "In the kitchen, Ryan is"
    check whereis("OB1", "Ryan", "the kitchen") == "Ryan is in the kitchen"

  test "invalid":
    expect(SyntaxError):
      let s = "{1} {}".format(1, 2)
    expect(SyntaxError):
      let s = "{2} {3}".format(1, 2)
    expect(SyntaxError):
      let s = "{} }".format(1)

  test "backslash":
    check format("\\\\{\\}\\}\\{") == "\\{}}{"
    check format("\\\\\\{{}\\\\", 3) == "\\\\{3\\\\"
    check format("\\", 3) == "\\"

suite "format by string":

  test "basic":
    check "hello {name}".format({"name": "Bob"}) == "hello Bob"

  test "invalid":
    expect(ValueError):
      let s = "{one} {two} {three}".format({"one": 1, "two": 2})
    expect(ValueError):
      let s = "{one} {} {two}".format({"one": 1, "two": 2})
    expect(ValueError):
      let s = "{1} {2}".format({"one": 1, "two": 2})


  test "numbers":
    doAssert format("{age:<10d}", {"age": 55}) == "55        "
    doAssert format("{one}\\{{pi:.3g} {pi:.3f} {pi:.3e} {pi:.3f}\\}", {"one": 1, "pi": 3.1415,
        "w": 1.777777e7}) == "1{3.14 3.142 3.142e+00 3.142}"

  test "example":
    check "Hello {his name}, I am number {my number}".format({"my number": 33,
        "his name": "Bob"}) == "Hello Bob, I am number 33"

  test "peio":
    var str = "{name} lives {distance:.1f} km from {where:>10}."
    check str.format({"name": "Peio", "where": "Garazi", "distance": 8 / 3}) == "Peio lives 2.7 km from     Garazi."
