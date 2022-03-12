# Telestion Message Type DSL Specification

This document specifies the YAML-based Domain-specific language (DSL) for the specification of JSON message types within the Telestion ecosystem.

## Prerequesites

Please refer to the Specification for more information

### JSON base types

For this documentation, we use the following base types / terminology:

:: A *string* is a text-based value.

:: A *boolean* is a value that can either be {true} or {false}.

:: A *number* is a value representing a numeric value.

:: *null* is a value representing the explicit absence of a value.

:: An *object* is a value that maps a *string*-based key to a *value* for any number of unique keys.

:: An *array* is a value that contains a list where each item is a *value*.

:: A *value* is either a *string*, a *boolean*, a *number*, *null*, an *object* or an *array*.

### YAML Base Types

A definition of the YAML expressions used within the DSL's syntax.

BooleanValue: one of
- `true`
- `false`

StringValue: "any YAML syntax representing a string value"

NumberValue: "any YAML syntax representing a number value"

### Transpiler

:: A *transpiler* generates code for a *target language* from the DSL defined in this document.

### Target language

:: A *target language* is a programming language for which you generate code representing the types defined with the DSL defined in this document.

Every Telestion project can have an arbitrary number of *target language*s.

NOTE: The most common *target language*s for Telestion projects are Java and TypeScript.

## Specification

### Types folder

:: The *Types folder* is a folder that contains type files. Its location is determined by the tooling used in the concrete Telestion Project.

### Type File

:: A *Type File* is any file within the *Types folder* with the file extension `.types.yaml`. Its contents are defined by {TypeFileContent}.

TypeFileContent: InterfaceSpecifications MessagesSpecification PrimitiveSpecification?

{TypeFileContent} must be a valid YAML file.

### Interfaces

:: An *Interface* is a specification of an *object*'s structure.

Every *Interface* has an {InterfaceName}, a number of *Interface properties*, and optionally a set of *Interface modifiers*.

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

* Let {InterfaceSpecifications} be the `interfaces` property (an *object*) of the *Type File*'s root *object*.
* Then {InterfaceSpecification+} contains the definitions of the interfaces defined by the current *Type File*.

InterfaceSpecification: InterfaceName `:` InterfaceDetails
* Let {InterfaceSpecification} be a property of the {InterfaceSpecifications} *object*
* Let {InterfaceName} be the key of the {InterfaceSpecifications} property
* Let {InterfaceDetails} be the properties of an *object*.

TODO Handling of duplicate interface names

InterfaceName: /^[A-Z][a-zA-Z0-9]+$/
* If any {InterfaceName} doesn't match the specified pattern
    * show a warning. The pattern is supposed to enable maximum cross-language support.

InterfaceDetails: InterfaceModifiers InterfaceProperties

#### Interface modifiers

:: *Interface modifiers* are essentially statements modifying how the *Interface*'s definition should be intrepreted.

*Interface modifiers* allow to modify interfaces by

- making them *abstract* (disallowing creation of instances of the *Interface*)
- adding a description to the interface
- extending another *Interface* and inheriting its *Interface properties*

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
* Let the {BooleanValue} represent whether the current interface is abstract (default: false)
* If the {BooleanValue} is {true}
    * forbid creation of an *object* of this *Interface*'s type, if possible within the *target language*
    * forbid using this *Interface*'s {InterfaceName} in the {MessagesSpecification}

ExtendsModifier: `__extends: ` InterfaceName
* Let {InterfaceName} be any defined *Interface*'s name.
* If the current *Interface* declares any property whose {PropertyType} is incompatible with the {PropertyType} of any *Interface properties* with the same name {PropertyName} in the *Interface* {InterfaceName}
    * abort with an error message
* Then, the following statements are true for the current *Interface*:
    * it contains all *Interface properties* from the *Interface* with the provided {InterfaceName}
    * it contains all *Interface properties* declared by the current *Interface*
    * for any *Interface properties* with the same {PropertyName}, the strictest type gets used.
  
DescriptionModifier: `__description: ` StringValue
* Let {StringValue} be any *string*
* Then {StringValue} represents a text description of the current *Interface*

#### Interface properties

:: *Interface properties* are the properties of an *object* of the *Interface*'s type.

InterfaceProperties: Property+
* Let {InterfaceProperties} be the collection of properties in an {InterfaceDetails} object where the keys don't correspond to any {InterfaceModifier}.
* Then {Property+} represents all properties of any *object* of the *Interface*'s type.

Property: PropertyName `:` PropertyType
* Any *object* of the *Interface*'s type must contain a property with the key {PropertyName} with a *value* of the type {PropertyType}.

TODO Handling of duplicate property names

PropertyName: /^[a-z][a-z0-9]*$/
* If any {PropertyName} doesn't match the specified pattern
    * show a warning. The pattern is supposed to enable maximum cross-language support.

PropertyType: TypeSpecifier

### Message types

MessagesSpecification: InterfaceName+
* Let {InterfaceName} be a property of the {InterfaceSpecifications} object with an *array* value.
* If {InterfaceName} isn't specified in any {InterfaceSpecifications} in the type folder
    * abort compilation with an error
* Then every message must be of one of the types specified by the {InterfaceDetails} of the corresponding {InterfaceName}.

### Primitives

:: A *Primitive* is a type that cannot be further specified within the DSL.

A *Primitive* is clearly defined by a unique {PrimitiveName}.

Any *Primitive* must get mapped to a type in every *target language*.

NOTE: A *Primitive* within the DSL needn't necessarily be a "primitive" in a _target language_. For example, you can define a `date` primitive that can get mapped to a `DateTime` instance in Java. In this case, you couldn't define how a `date` gets represented any better within the DSL (making it a *Primitive*), but it wouldn't be a "primitive" value in Java.

### Type specifiers

:: A *Type Specifier* is a representation of a *value*'s type.

TypeSpecifier: one of SimpleTypeSpecifier ComplexTypeSpecifier

#### Simple type specifier

:: A *Simple type specifier* is a representation of a *value*'s type as a *string*.

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
* Then the resulting type is equivalent to the type specified by the {SimpleTypeSpecifier}

ArrayTypeSpecifier: SimpleTypeSpecifier `[]`
* Then the resulting type is an array whose values are of the type specified by the {SimpleTypeSpecifier}

NullableTypeSpecifier: SimpleTypeSpecifier `?`
* Then the resulting type can be the type specified by the {SimpleTypeSpecifier} or *null*.

UnionTypeSpecifier: SimpleTypeSpecifier | SimpleTypeSpecifier
* Then the resulting type can be the type specified by either the first or the second {SimpleTypeSpecifier}.

InterfaceTypeSpecifier: InterfaceName
* If no *Interface* with the given {InterfaceName} is defined
    * abort with an error.
* Then the resulting type is an *object* with the structure specified by the {InterfaceDetails} of the *Interface* with the corresponding {InterfaceName}.

PrimitiveTypeSpecifier: PrimitiveName
* If no *Primitive* with the given {PrimitiveName} is defined
    * abort with an error.
* Then the resulting type is the target language's type defined by the *Primitive* with the given {PrimitiveName}.

#### Complex type specifier

:: A *Complex type specifier* is an *object* representing a type that allows for specification of more details for that type than a *Simple type specifier*.

ComplexTypeSpecifier: "an object-based specification of a value's type that allows for a few more options"
