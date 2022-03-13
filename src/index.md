# Telestion Message Type DSL Specification

This document specifies the YAML-based Domain-specific language (DSL) for the specification of JSON message types within the Telestion ecosystem.

## Prerequisites

Please refer to the Specification for more information

### JSON base types

For this documentation, we use the following base types / terminology:

:: A _string_ is a text-based value.

:: A _boolean_ is a value that can either be {true} or {false}.

:: A _number_ is a value representing a numeric value.

:: _null_ is a value representing the explicit absence of a value.

:: An _object_ is a value that maps a _string_-based key to a _value_ for any unique keys.

:: An _array_ is a value that contains a list where each item is a _value_.

:: A _value_ is either a _string_, a _boolean_, a _number_, _null_, an _object_ or an _array_.

### YAML Base Types

A definition of the YAML expressions used within the DSL's syntax.

BooleanValue: one of

- `true`
- `false`

StringValue: "any YAML syntax representing a string value"

NumberValue: "any YAML syntax representing a number value"

Value: one of

- StringValue
- NumberValue
- BooleanValue

### Transpiler

:: A _transpiler_ generates code for a _target language_ from the DSL defined in this document.

### Target language

:: A _target language_ is a programming language for which you generate code representing the types defined with the DSL defined in this document.

Every Telestion project can have one or more *target language*s.

NOTE: The most common *target language*s for Telestion projects are Java and TypeScript.

## Specification

### Types folder

:: The _Types folder_ is a folder that contains type files. Its location is determined by the tooling used in the concrete Telestion Project.

### Type File

:: A _Type File_ is any file within the _Types folder_ with the file extension `.types.yaml`. Its contents are defined by {TypeFileContent}.

TypeFileContent: "an object containing" InterfaceSpecifications MessagesSpecification PrimitiveSpecification?

{TypeFileContent} must be a valid YAML file.

Any files fulfilling the _Type File_ specification should get merged in interpretation if they are compatible. For example, any _Interface_ defined in `a.types.yaml` should also be available in `b.types.yaml` as if it had been declared in `b.types.yaml`'s {InterfaceSpecifications}. The same holds true for {MessagesSpecification} and {PrimitiveSpecification}. If types cannot be merged, the _Transpiler_ should abort with an error.

### Interfaces

:: An _Interface_ is a specification of an _object_'s structure.

Every _Interface_ has an {InterfaceName}, _Interface properties_, and optionally a set of _Interface modifiers_.

```yaml example
interfaces:
  BaseMessage:
    type: string
  MyMessage:
    type:
      value: "my"
    numbers: double[]
```

InterfaceSpecifications: `interfaces:` "an object containing" InterfaceSpecification+

- Let {InterfaceSpecifications} be the `interfaces` property (an _object_) of the _Type File_'s root _object_.
- Then {InterfaceSpecification+} contains the definitions of the interfaces defined by the current _Type File_.

InterfaceSpecification: InterfaceName `:` InterfaceDetails

- Let {InterfaceSpecification} be a property of the {InterfaceSpecifications} _object_
- Let {InterfaceName} be the key of the {InterfaceSpecifications} property
- Let {InterfaceDetails} be the properties of an _object_.

InterfaceName: /^[A-Z][a-zA-Z0-9]+$/ but not `Message`

- If any {InterfaceName} doesn't match the specified pattern
  - show a warning. The pattern is supposed to enable maximum cross-language support.

InterfaceDetails: "an object containing" InterfaceModifiers InterfaceProperties

#### Interface modifiers

:: _Interface modifiers_ are essentially statements modifying how the _Interface_'s definition should be interpreted.

_Interface modifiers_ allow modifying interfaces by

- making them _abstract_ (disallowing creation of instances of the _Interface_)
- adding a description to the _Interface_
- extending another _Interface_ and inheriting its _Interface properties_

```yaml example
interfaces:
  BaseInterface:
    __abstract: true

  MyInterface:
    __extends: BaseInterface
    __description: "A nice little interface"
```

InterfaceModifiers: "an object containing" AbstractModifier? ExtendsModifier? DescriptionModifier?

AbstractModifier: `__abstract: ` BooleanValue

- Let the {BooleanValue} represent whether the current interface is abstract (default: false)
- If the {BooleanValue} is {true}
  - forbid creating an _object_ of this _Interface_'s type, if possible within the _target language_
  - forbid using this _Interface_'s {InterfaceName} in the {MessagesSpecification}

ExtendsModifier: `__extends: ` InterfaceName

- Let {InterfaceName} be any defined _Interface_'s name.
- If the current _Interface_ declares any property whose {PropertyType} is incompatible with the {PropertyType} of any _Interface properties_ with the same name {PropertyName} in the _Interface_ {InterfaceName}
  - abort with an error message
- Then, the following statements are true for the current _Interface_:
  - it contains all _Interface properties_ from the _Interface_ with the provided {InterfaceName}
  - it contains all _Interface properties_ declared by the current _Interface_
  - for any _Interface properties_ with the same {PropertyName}, the strictest type gets used.
  - the current _Interface_ _extends_ the _Interface_ with the passed {InterfaceName}.

For example, the following {SimpleTypeSpecifier}s would be compatible and thus, the `OtherType` _Interface_ _extends_ the `BaseType` _Interface_.

```yaml example
interfaces:
  BaseType:
    prop: string | number
  OtherType:
    __extends: BaseType
    prop: number
```

In the next example, however, the {SimpleTypeSpecifier} `boolean` is incompatible to the {SimpleTypeSpecifier} `string | number` in `BaseType`, so the _Transpiler_ should abort with an error:

```yaml counter-example
interfaces:
  BaseType:
    prop: string | number
  OtherType:
    __extends: BaseType
    prop: boolean # incompatible with "string | number"
```

DescriptionModifier: `__description: ` StringValue

- Let {StringValue} be any _string_
- Then {StringValue} represents a text description of the current _Interface_ authored in Markdown

#### Interface properties

:: _Interface properties_ are the properties of an _object_ of the _Interface_'s type.

InterfaceProperties: Property+

- Let {InterfaceProperties} be the collection of properties in an {InterfaceDetails} object where the keys don't correspond to any {InterfaceModifier}.
- Then {Property+} represents all properties of any _object_ of the _Interface_'s type.

Property: PropertyName `:` PropertyType

- Any _object_ of the _Interface_'s type must contain a property with the key {PropertyName} with a _value_ of the type {PropertyType}.

PropertyName: /^[a-z][a-z0-9]\*$/

- If any {PropertyName} doesn't match the specified pattern
  - show a warning. The pattern is supposed to enable maximum cross-language support.

PropertyType: TypeSpecifier

### Message types

MessagesSpecification: `messages:` "an array of" InterfaceName+

- Let {InterfaceName} be a property of the {InterfaceSpecifications} object with an _array_ value.
- If {InterfaceName} isn't specified in any {InterfaceSpecifications} in the _Types folder_
  - abort compilation with an error
- Then every message must be of one of the types specified by the {InterfaceDetails} of the corresponding {InterfaceName}.

### Primitives

:: A _Primitive_ is a type that cannot be further specified within the DSL.

A _Primitive_ is defined by a unique {PrimitiveName}.

Any _Primitive_ must get mapped to a type in every _target language_ for which a _Transpiler_ gets run.

NOTE: A _Primitive_ within the DSL needn't necessarily be a "primitive" in a _target language_.
For example, you can define a `date` primitive that can get mapped to a `DateTime` instance in Java. In this case, you couldn't define how a `date` gets represented any better within the DSL (making it a _Primitive_), but it wouldn't be a "primitive" value in Java.

PrimitiveSpecification: `primitives:` "an object containing" Primitive+

Primitive: PrimitiveName `:` "an object containing" PrimitiveLanguageMapEntry+

PrimitiveName: /^[a-z][a-z_0-9]\*$/

- Then the _Primitive_ {PrimitiveName} is defined by its {PrimitiveLanguageMapEntry+}.

PrimitiveLanguageMapEntry: TargetLanguageName `:` StringValue

- Let {TargetLanguageName} be an identifier of a _Target language_.
- Then {StringValue} contains the current {Primitive}'s type in that _Target language_. It is up to the _Transpiler_ to interpret that value and specify what it needs.

TargetLanguageName: /^[a-z][a-zA-Z0-9]\*$/

NOTE: While this specification doesn't define any required _Target language_ (this depends on the individual project and the _Transpiler_ it uses), the most commonly used {TargetLanguageName} values are `java`, `json`, and `typescript`.

```yaml example
primitives:
  double:
    java: double
    json: number
    typescript: number
  string:
    java: String
    json: string
    typescript: string
  json:
    java: com.fasterxml.jackson.databind.JsonNode
    json: '["number","string","boolean","object","array", "null"]'
    typescript: any
```

### Type specifiers

:: A _Type Specifier_ is a representation of a _value_'s type.

TypeSpecifier: one of SimpleTypeSpecifier ComplexTypeSpecifier

#### Simple type specifier

:: A _Simple type specifier_ is a representation of a _value_'s type as a _string_.

```example
string[]
(string | number)[]?
(string[] | number | MyInterface?[])[]
```

SimpleTypeSpecifier: StringValue "consisting of" SimpleTypeSpecifierNode

- Let {raw} be equal to the {StringValue}'s _string_ value.
- Let {specifier} be {raw} with all whitespaces removed.
- Then {specifier} is a {SimpleTypeSpecifierNode}.

SimpleTypeSpecifierNode: one of

- ParenthesizedTypeSpecifier
- UnionTypeSpecifier
- ArrayTypeSpecifier
- NullableTypeSpecifier
- InterfaceTypeSpecifier
- PrimitiveTypeSpecifier

NOTE: When parsing a {SimpleTypeSpecifierNode}, the types of {SimpleTypeSpecifierNode} take precedence in the order declared above.
I.e., {ParenthesizedTypeSpecifier} takes precedence over {UnionTypeSpecifier} which takes precedence over {ArrayTypeSpecifier},
and so on.
Use the first one that matches.

ParenthesizedTypeSpecifier: ( SimpleTypeSpecifierNode )

- Then the resulting type is equivalent to the type specified by the {SimpleTypeSpecifierNode}

UnionTypeSpecifier: SimpleTypeSpecifierNode | SimpleTypeSpecifierNode

- Then the resulting type can be the type specified by either the first or the second {SimpleTypeSpecifierNode}.

ArrayTypeSpecifier: SimpleTypeSpecifierNode `[]`

- Then the resulting type is an array whose values are of the type specified by the {SimpleTypeSpecifierNode}

NOTE: As the {UnionTypeSpecifier} takes precedence, the {SimpleTypeSpecifierNode} in an {ArrayTypeSpecifier} can't be a
{UnionTypeSpecifier}.

NullableTypeSpecifier: SimpleTypeSpecifierNode `?`

- Then the resulting type can be the type specified by the {SimpleTypeSpecifierNode} or _null_.

NOTE: As the {UnionTypeSpecifier} takes precedence, the {SimpleTypeSpecifierNode} in a {NullableTypeSpecifier} can't be a 
{UnionTypeSpecifier}.

InterfaceTypeSpecifier: InterfaceName

- If no _Interface_ with the given {InterfaceName} is defined
  - abort with an error.
- Then the resulting type is an _object_ with the structure specified by the {InterfaceDetails} of the _Interface_ with the corresponding {InterfaceName}.

PrimitiveTypeSpecifier: PrimitiveName

- If no _Primitive_ with the given {PrimitiveName} is defined
  - abort with an error.
- Then the resulting type is the target language's type defined by the _Primitive_ with the given {PrimitiveName}.

NOTE: We evaluated using the GraphQL syntax for compatibility, but found it to be incompatible with YAML as a _value_ starting with {`[`} for an _array_ would have resulted in interpretation as an _array_ instead of the required {StringValue}.

#### Complex type specifier

:: A _Complex type specifier_ is an _object_ representing a type that allows for specifications for more details for that type than a _Simple type specifier_.

ComplexTypeSpecifier: "an object containing" ComplexTypeSpecifierType? ComplexTypeSpecifierValue? ComplexTypeSpecifierMinimumValue? ComplexTypeSpecifierMaximumValue?

- If no {ComplexTypeSpecifierType?} (or {SimpleTypeSpecifier}) exists for the current property in the current _Interface_ or any _Interface_ that the current _Interface_ extends (directly or indirectly)
  - abort with an error

ComplexTypeSpecifierType: `type:` SimpleTypeSpecifier

ComplexTypeSpecifierValue: `value:` "an array of" Value+

- Then any _value_ of the type represented by the {ComplexTypeSpecifier} must be equal to at least one {Value} from the {Value+} _array_

ComplexTypeSpecifierDescription: `description:` StringValue

- Then the {StringValue} is a text description of the type represented by the {ComplexTypeSpecifier} authored in Markdown.

ComplexTypeSpecifierMinimumValue: `min:` NumberValue

- Then the {NumberValue} represents the minimum valid _value_ of the type specified by the {ComplexTypeSpecifier}.

ComplexTypeSpecifierMaximumValue: `max:` NumberValue

- Then the {NumberValue} represents the maximum valid _value_ of the type specified by the {ComplexTypeSpecifier}.

```yaml example
interfaces:
  MyInterface:
    someProperty:
      type: double
      min: 3
      description: |
        This is a multiline description.

        I can use `Markdown` here.
```

## A. About this specification

### Authors

Thanks to everyone who contributed to this specification:

<a href="https://github.com/wuespace/telestion-message-type-dsl-specs/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=wuespace/telestion-message-type-dsl-specs" />
</a>

### Generated with / special thanks to

This specification website was generated using _Spec Markdown_.

[Learn more about Spec Markdown](https://spec-md.com/)
