Builtin levels to compile into source code

# Level set file format

## Principles

* The level file is a **textual** description of a set of levels. It is _human-readable_ and _machine-parseable_.
* Thus a **MARKDOWN extended syntax** has been chosen, as it allow to give structure to a document, and usual project forges (github, gitlab, bitbucket) have builtin formatting when browsing the project repository.

## Overall organisation

* Each level start with a top level header (one line starting with '#'). The heading text is ignored.
* _Anything before the first level is considered part of the header of the description._

```
Header bla bla bla

# what ever

First level data

# nevermind

Second level data

# and so on

Third level data

```

## Blockquote as comment

Blockquoted sections are considered as comments, and thus are explicitely ignored by the parser.

```
> don't mind me
```

## Level description

Each level is composed of up to 4 lines of introductory text to be displayed before playing the level, followed by the level brick layout.

* Each line of introductory text is one paragraphe of at most 40 supported printable characters (see below). Lower case are converted into uppercase for convenience, unsupported chars are ignored.
* Supported formatting control chars, mixable :
  * '\*\*' toggle 'bold' on/off
  * '\_' toggle 'emphase' on/off
* Lines beyond 4 are ignored.


The level data is enclosed in a _fenced_ code block (triple backtick before and after).

````
# sample level

An introductory text _with **some_ formatting**.

```
bricks layout data
```
````

### Supported printable characters table

> The list of printable characters is case-insensitive.
>
> This table also specify the text base encoding.
>
> Emphasized text : add 48 to the character code.
>
> Bold text : add 96 to the character code.

|-|0|1|2|3|4|5|6|7|8|9|A|B|C|D|E|F|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|$00|0|1|2|3|4|5|6|7|8|9|A|B|C|D|E|F|
|$10|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|
|$20|W|X|Y|Z| |.|!|?|,|-|"|'|(|)|/|@|



## Level description format

* 10 lines of 40 printable characters, following the brick description format.
* case insensitive

### Empty space

 '.' : empty space

 Any invalid char will give an empty space too

### 1 tile width bricks
 '\*' : star brick.
       Their is a time limit to collect all the stars before any remaining star are disabled. The goal is
       to reach a 'full star' clearing of the level (somewhere between 45 secs and 90 secs). More than 4 stars is meaningless, though.
       The number of full stars to get is min(3,number of stars), compared against (total number of stars - broken active stars).

### 2 or more tiles width bricks
 '-' : extends the width of the current brick.
       general format is [type code] followed by required amount of '-'.

#### fixed width bricks
 Fixed width bricks MUST have 2 chars : [type code]+[whatever]. For legibility,
 use '-' as second char

 'W' : Key (memo : suggest the key's ward).
       All the keys MUST be collected to activate Exit bricks. Meaningless without at least one exit brick.

 'X' : eXit.
       Activated (breakable) if there is no more key. Breaking it clear the level.

 'O' : 'shallOw' mode (memo : suggest an empty sphere).
       The ball cannot break any brick during the effect

 'G' : 'Glue' mode.
       The ball stick to the paddle, allowing the player to steer the ball before relaunching it, and the speed of the ball is reduced.

 'J' : 'Juggernaut' mode.
       The ball break any bricks without rebound

#### variable width tiles
 '1' to '9' and 'A' to 'F'
     : normal brick, with resistance (ignored, all break with one collision with the ball)
