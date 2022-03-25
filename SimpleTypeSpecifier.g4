// SimpleTypeSpecifierNode parser as per
// https://wuespace.github.io/telestion-message-type-dsl-specs/#sec-Simple-type-specifier

grammar SimpleTypeSpecifier;

// SimpleTypeSpecifier

simpleTypeSpecifierNode
    : OpenParenthesized simpleTypeSpecifierNode CloseParenthesized # parenthesizedTypeSpecifier
    | simpleTypeSpecifierNode Array # arrayTypeSpecifier
    | simpleTypeSpecifierNode Nullable # nullableTypeSpecifier
    | simpleTypeSpecifierNode Union simpleTypeSpecifierNode # unionTypeSpecifier
    | Interface # interfaceTypeSpecifier
    | Primitive # primitiveTypeSpecifier
    ;

// Lexer rules

Interface: [A-Z][a-zA-Z_]*;
Primitive: [a-z][a-zA-Z_]*;

Union: '|';
Array: '[]';
Nullable: '?';
OpenParenthesized: '(';
CloseParenthesized: ')';

WS
    : [ \t\r\n]+ -> skip;
