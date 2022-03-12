# Telestion Message Type DSL Specification

This document specifies the YAML-based Domain-specific language (DSL) for the specification of JSON message types within the Telestion ecosystem.

## Prerequesites

Please refer to the Specification for more information

### JSON base types

For this documentation, we use the following base types / terminology:

:: A _string_ is a text-based value.

:: A _boolean_ is a value that can either be {true} or {false}.

:: A _number_ is a value representing a numeric value.

:: _null_ is a value representing the explicit absence of a value.

:: An _object_ is a value that maps a _string_-based key to a _value_ for any number of unique keys.

:: An _array_ is a value that contains a list where each item is a _value_.

:: A _value_ is either a _string_, a _boolean_, a _number_, _null_, an _object_ or an _array_.

### YAML Base Types

A definition of the YAML expressions used within the DSL's syntax.

BooleanValue: one of

- `true`
- `false`

StringValue: "any YAML syntax representing a string value"

NumberValue: "any YAML syntax representing a number value"

### Transpiler

:: A _transpiler_ generates code for a _target language_ from the DSL defined in this document.

### Target language

:: A _target language_ is a programming language for which you generate code representing the types defined with the DSL defined in this document.

Every Telestion project can have an arbitrary number of *target language*s.

NOTE: The most common *target language*s for Telestion projects are Java and TypeScript.

## Specification

### Types folder

:: The _Types folder_ is a folder that contains type files. Its location is determined by the tooling used in the concrete Telestion Project.

### Type File

:: A _Type File_ is any file within the _Types folder_ with the file extension `.types.yaml`. Its contents are defined by {TypeFileContent}.

TypeFileContent: InterfaceSpecifications MessagesSpecification PrimitiveSpecification?

{TypeFileContent} must be a valid YAML file.

### Interfaces

:: An _Interface_ is a specification of an _object_'s structure.

Every _Interface_ has an {InterfaceName}, a number of _Interface properties_, and optionally a set of _Interface modifiers_.

```yaml example
interfaces:
  BaseMessage:
    type: string
  MyMessage:
    type:
      value: "my"
    numbers: double[]
```

InterfaceSpecifications: `interfaces:` InterfaceSpecification+

- Let {InterfaceSpecifications} be the `interfaces` property (an _object_) of the _Type File_'s root _object_.
- Then {InterfaceSpecification+} contains the definitions of the interfaces defined by the current _Type File_.

InterfaceSpecification: InterfaceName `:` InterfaceDetails

- Let {InterfaceSpecification} be a property of the {InterfaceSpecifications} _object_
- Let {InterfaceName} be the key of the {InterfaceSpecifications} property
- Let {InterfaceDetails} be the properties of an _object_.

TODO Handling of duplicate interface names

InterfaceName: /^[A-Z][a-za-z0-9]+$/

- If any {InterfaceName} doesn't match the specified pattern
  - show a warning. The pattern is supposed to enable maximum cross-language support.

InterfaceDetails: InterfaceModifiers InterfaceProperties

#### Interface modifiers

:: _Interface modifiers_ are essentially statements modifying how the _Interface_'s definition should be intrepreted.

_Interface modifiers_ allow to modify interfaces by

- making them _abstract_ (disallowing creation of instances of the _Interface_)
- adding a description to the interface
- extending another _Interface_ and inheriting its _Interface properties_

```yaml example
interfaces:
  BaseInterface:
    __abstract: true

  MyInterface:
    __extends: BaseInterface
    __description: "A nice little interface"
```

InterfaceModifiers: AbstractModifier? ExtendsModifier? DescriptionModifier?

AbstractModifier: `__abstract: ` BooleanValue

- Let the {BooleanValue} represent whether the current interface is abstract (default: false)
- If the {BooleanValue} is {true}
  - forbid creation of an _object_ of this _Interface_'s type, if possible within the _target language_
  - forbid using this _Interface_'s {InterfaceName} in the {MessagesSpecification}

ExtendsModifier: `__extends: ` InterfaceName

- Let {InterfaceName} be any defined _Interface_'s name.
- If the current _Interface_ declares any property whose {PropertyType} is incompatible with the {PropertyType} of any _Interface properties_ with the same name {PropertyName} in the _Interface_ {InterfaceName}
  - abort with an error message
- Then, the following statements are true for the current _Interface_:
  - it contains all _Interface properties_ from the _Interface_ with the provided {InterfaceName}
  - it contains all _Interface properties_ declared by the current _Interface_
  - for any _Interface properties_ with the same {PropertyName}, the strictest type gets used.

DescriptionModifier: `__description: ` StringValue

- Let {StringValue} be any _string_
- Then {StringValue} represents a text description of the current _Interface_

#### Interface properties

:: _Interface properties_ are the properties of an _object_ of the _Interface_'s type.

InterfaceProperties: Property+

- Let {InterfaceProperties} be the collection of properties in an {InterfaceDetails} object where the keys don't correspond to any {InterfaceModifier}.
- Then {Property+} represents all properties of any _object_ of the _Interface_'s type.

Property: PropertyName `:` PropertyType

- Any _object_ of the _Interface_'s type must contain a property with the key {PropertyName} with a _value_ of the type {PropertyType}.

TODO Handling of duplicate property names

PropertyName: /^[a-z][a-z0-9]\*$/

- If any {PropertyName} doesn't match the specified pattern
  - show a warning. The pattern is supposed to enable maximum cross-language support.

PropertyType: TypeSpecifier

### Message types

MessagesSpecification: InterfaceName+

- Let {InterfaceName} be a property of the {InterfaceSpecifications} object with an _array_ value.
- If {InterfaceName} isn't specified in any {InterfaceSpecifications} in the type folder
  - abort compilation with an error
- Then every message must be of one of the types specified by the {InterfaceDetails} of the corresponding {InterfaceName}.

### Primitives

:: A _Primitive_ is a type that cannot be further specified within the DSL.

A _Primitive_ is clearly defined by a unique {PrimitiveName}.

Any _Primitive_ must get mapped to a type in every _target language_.

NOTE: A _Primitive_ within the DSL needn't necessarily be a "primitive" in a _target language_. For example, you can define a `date` primitive that can get mapped to a `DateTime` instance in Java. In this case, you couldn't define how a `date` gets represented any better within the DSL (making it a _Primitive_), but it wouldn't be a "primitive" value in Java.

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

SimpleTypeSpecifier: one of

- ParenthesizedTypeSpecifier
- ArrayTypeSpecifier
- NullableTypeSpecifier
- UnionTypeSpecifier
- InterfaceTypeSpecifier
- PrimitiveTypeSpecifier

ParenthesizedTypeSpecifier: ( SimpleTypeSpecifier )

- Then the resulting type is equivalent to the type specified by the {SimpleTypeSpecifier}

ArrayTypeSpecifier: SimpleTypeSpecifier `[]`

- Then the resulting type is an array whose values are of the type specified by the {SimpleTypeSpecifier}

NullableTypeSpecifier: SimpleTypeSpecifier `?`

- Then the resulting type can be the type specified by the {SimpleTypeSpecifier} or _null_.

UnionTypeSpecifier: SimpleTypeSpecifier | SimpleTypeSpecifier

- Then the resulting type can be the type specified by either the first or the second {SimpleTypeSpecifier}.

InterfaceTypeSpecifier: InterfaceName

- If no _Interface_ with the given {InterfaceName} is defined
  - abort with an error.
- Then the resulting type is an _object_ with the structure specified by the {InterfaceDetails} of the _Interface_ with the corresponding {InterfaceName}.

PrimitiveTypeSpecifier: PrimitiveName

- If no _Primitive_ with the given {PrimitiveName} is defined
  - abort with an error.
- Then the resulting type is the target language's type defined by the _Primitive_ with the given {PrimitiveName}.

#### Complex type specifier

:: A _Complex type specifier_ is an _object_ representing a type that allows for specification of more details for that type than a _Simple type specifier_.

ComplexTypeSpecifier: "an object-based specification of a value's type that allows for a few more options"
