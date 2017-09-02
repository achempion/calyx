# Calyx Syntax Specification

> An ad-hoc, informally specified, bug-ridden, etc... etc...

## Background

Since `v0.11`, Calyx has supported loading grammars from external JSON files—a very similar format to Tracery<sup>[1][1]</sup>—but the precise syntax and structure used by these files was never properly documented or defined in a schema<sup>[2][2]</sup>.

This is worth documenting for several reasons:

1) It’s rather obvious that having good documentation will make it easier for new users to get started and for advanced users to learn about the limits of what they can do with the tool.
2) A well-defined schema reduces ambiguity and helps focus on authoring concerns, rather than drifting towards implementation concerns. This is currently a particular risk in Calyx because of the impedance mismatch between the Ruby DSL and JSON data.
3) A well-defined schema opens up potential for collaboration with authors of other similar tools and could help provide a future foundation for a standard data format that enables sharing grammars across languages and tools. This would be of particular benefit to authors, making it easier to build up reusable content libraries. It could also provide a foundation for new innovations in authoring UIs that aren’t tied to a specific language or tool.

## Format

### Files

External grammars are defined in JSON files. They must be encoded as `utf-8`, have a `.json` extension and conform to standard JSON syntax rules.

### Structure

#### Top Level

The top-level structure of the grammar must be a map/object-literal with each key representing a single left-hand rule symbol and the value representing the grammar productions for that rule:

```json
{
  "start": "Colorless green ideas sleep furiously."
}
```

Empty grammars should be represented by an empty object:

```json
{}
```

#### Production Rules

Left hand side rules must be string symbols conforming to the following pattern:

```ruby
/^[A-Za-z0-9_\-]+$/
```

Grammars are not context-sensitive<sup>[3][3]</sup>. The left-hand side rules must be a direct symbol reference, not a production that can be expanded.

Right-hand side productions can be either single strings, arrays of strings or weighted probability objects.

Strings represent the template for a single choice that the production will always resolve to:

```json
{
  "start": "Colorless green ideas sleep furiously."
}
```

Arrays of strings represent multiple choices that can produce any one of the possible output strings. Each string should have a (roughly) equal chance of being selected to expand to a result.

```json
{
  "start": ["red", "green", "blue"]
}
```

Weighted probability objects represent a mapping of possible output strings to their probability of expanding to a result. The keys represent the possible output strings, and the values represent their probability of the string being selected.

Supported intervals are:

- 0..1 (`Number`)

The following example shows `red` with a 50% chance of being selected; `green` and `blue` with 25% chances:

```json
{
  "start": {
    "red": 0.5,
    "green": 0.25,
    "blue": 0.25
  }
}
```

#### Template Expansions

Productions can be recursively expanded by embedding rules using the template expression syntax, with the expressions delimited by `{` and `}` characters. Everything outside of the delimiters is treated as literal text.

Basic syntax:

```json
"{weather}"
```

Expanding a simple rule:

```json
{
  "start": "The sky was {weather}.",
  "weather": ["cloudy", "dark", "clear", "bright"]
}
```

A chain of nested expansions:

```json
{
  "start": "{best} {worst}",
  "best": "{twas} the {best_adj} of times.",
  "worst": "{twas} the {worst_adj} of times.",
  "twas": ["It was", "'Twas"],
  "best_adj": ["best", "greatest"],
  "worst_adj": ["worst", "most insufferable"]
}
```

#### Expression Modifiers

There are two different forms of expression modifiers—**Selection Modifiers** and **Output Modifiers**.

Selection modifiers apply to the grammar production itself, influencing how the rule is expanded. They are defined by prefixing a rule expression with a sigil that defines the behaviour of the selection.

```json
"{$unique_rule}"
"{@memoized_rule}"
```

Output modifiers format the string that is generated by the grammar production. They are defined by a chain of `.` separated references following the rule.

```json
"{formatted_rule.upcase}"
"{formatted_rule.downcase.capitalize}"
```

#### Unique Choices

Unique choices are prefixed with the `$` sigil in an expression.

This ensures that multiple references to the same production will always result in a unique value being chosen (until the choices in the production are exhausted).

```json
{
  "start": "{$medal}. {$medal}. {$medal}.",
  "medal": ["Gold", "Silver", "Bronze"]
}
```

```json
{
  "start": "It was the {$adj} of times; it was the {$adj} of times.",
  "adj": ["best", "worst"]
}
```

#### Memoized Choices

Memoized choices are prefixed with the `@` sigil in an expression.

This ensures that multiple references to the same production will always result in the first selected value being repeated.

```json
{
  "start": "The {@pet} ran to join the other {@pet}s.",
  "pet": ["cat", "dog"]
}
```

#### Output Modifiers

Due to their dependency on Ruby string methods and Calyx internals, output modifiers are currently a bit of a nightmare for interoperability.

All basic Ruby string formatting methods with arity 0 are supported by default<sup>[4][4]</sup>.

```json
"{my_rule.downcase}"
"{my_rule.upcase}"
"{my_rule.capitalize}"
"{my_rule.reverse}"
"{my_rule.swapcase}"
"{my_rule.strip}"
"{my_rule.lstrip}"
"{my_rule.rstrip}"
"{my_rule.succ}"
"{my_rule.chop}"
"{my_rule.chomp}"
```

The Ruby DSL provides a variety of methods for extending the supported range of modifiers. This behaviour currently won’t work at all when grammars are defined in JSON.

## References

[1]: http://tracery.io/
[2]: http://json-schema.org/
[3]: https://en.wikipedia.org/wiki/Context-sensitive_grammar
[4]: https://ruby-doc.org/core-2.4.0/String.html

1) http://tracery.io/
2) http://json-schema.org/
3) https://en.wikipedia.org/wiki/Context-sensitive_grammar
4) https://ruby-doc.org/core-2.4.0/String.html