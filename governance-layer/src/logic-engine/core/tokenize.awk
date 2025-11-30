#!/usr/bin/awk -f
# core/tokenize.awk - Tokenizer for Logic Engine
# Figure 26 Phase 1: Enhanced Input Analysis - Tokenization
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Tokenizes input into logical components using extended Unicode dictionary.
# Output format: TYPE:VALUE per line

BEGIN {
    # Load operator mappings from Figs 1-15
    # Format: symbol -> type

    # Core operators (Fig 1)
    op["¬"] = "NOT"
    op["∧"] = "AND"
    op["∨"] = "OR"
    op["→"] = "IMPLIES"
    op["↔"] = "IFF"
    op["⊤"] = "TRUE"
    op["⊥"] = "FALSE"

    # Quantifiers (Fig 2)
    op["∀"] = "FORALL"
    op["∃"] = "EXISTS"
    op["λ"] = "LAMBDA"
    op["μ"] = "LFP"
    op["ν"] = "GFP"

    # Modal/Temporal (Fig 3)
    op["□"] = "NECESSARY"
    op["◇"] = "POSSIBLE"
    op["○"] = "NEXT"

    # Deontic markers (will be detected by pattern)
    # O( P( F( for Obligation, Permission, Forbidden

    # Epistemic markers
    # K_ B_ for Knowledge, Belief

    # Fuzzy (Fig 6)
    op["⊙"] = "TNORM"
    op["⊕"] = "TCONORM"

    # Paraconsistent (Fig 7)
    op["~"] = "WEAK_NEG"

    # Set theory (Fig 8)
    op["∈"] = "MEMBER"
    op["⊆"] = "SUBSET"
    op["∪"] = "UNION"
    op["∩"] = "INTERSECT"

    # Type theory (Fig 10)
    op["⊢"] = "TURNSTILE"
    op["Π"] = "PI_TYPE"
    op["Σ"] = "SIGMA_TYPE"

    # Separators
    op["("] = "LPAREN"
    op[")"] = "RPAREN"
    op[","] = "COMMA"
    op[":"] = "COLON"
    op["="] = "EQUALS"

    # Track paradigms detected
    has_modal = 0
    has_deontic = 0
    has_epistemic = 0
    has_temporal = 0
    has_fuzzy = 0
    has_quantifiers = 0
}

# Process each line
{
    # Split into characters (handling UTF-8)
    n = split($0, chars, "")

    i = 1
    while (i <= n) {
        c = chars[i]

        # Skip whitespace
        if (c ~ /[ \t\n\r]/) {
            i++
            continue
        }

        # Check for operators
        if (c in op) {
            print op[c] ":" c

            # Track paradigms
            if (c == "□" || c == "◇") has_modal = 1
            if (c == "○") has_temporal = 1
            if (c == "∀" || c == "∃") has_quantifiers = 1
            if (c == "⊙" || c == "⊕") has_fuzzy = 1

            i++
            continue
        }

        # Check for deontic operators: O( P( F(
        if ((c == "O" || c == "P" || c == "F") && i < n && chars[i+1] == "(") {
            if (c == "O") print "OBLIGATION:" c
            else if (c == "P") print "PERMISSION:" c
            else if (c == "F") print "FORBIDDEN:" c
            has_deontic = 1
            i++
            continue
        }

        # Check for epistemic operators: K_ B_
        if ((c == "K" || c == "B") && i < n && chars[i+1] == "_") {
            if (c == "K") print "KNOWLEDGE:" c
            else print "BELIEF:" c
            has_epistemic = 1
            i += 2  # Skip the underscore

            # Capture agent name
            agent = ""
            while (i <= n && chars[i] ~ /[a-z]/) {
                agent = agent chars[i]
                i++
            }
            print "AGENT:" agent
            continue
        }

        # Check for temporal operators: G F U R (in temporal context)
        if (c == "G" || c == "U" || c == "R") {
            if (c == "G") print "GLOBALLY:" c
            else if (c == "U") print "UNTIL:" c
            else if (c == "R") print "RELEASE:" c
            has_temporal = 1
            i++
            continue
        }

        # Variable (single uppercase letter not followed by special)
        if (c ~ /[A-Z]/) {
            # Check if it's just a propositional variable
            if (i >= n || chars[i+1] !~ /[_(a-z]/) {
                print "VAR:" c
            } else {
                print "SYMBOL:" c
            }
            i++
            continue
        }

        # Identifier (lowercase word)
        if (c ~ /[a-z]/) {
            word = ""
            while (i <= n && chars[i] ~ /[a-z0-9_]/) {
                word = word chars[i]
                i++
            }

            # Check for keywords
            if (word == "not") {
                print "NAF:not"
            } else if (word == "and") {
                print "AND:and"
            } else if (word == "or") {
                print "OR:or"
            } else if (word == "if") {
                print "IF:if"
            } else if (word == "then") {
                print "THEN:then"
            } else if (word == "true") {
                print "TRUE:true"
            } else if (word == "false") {
                print "FALSE:false"
            } else {
                print "IDENT:" word
            }
            continue
        }

        # Number (integer or decimal for fuzzy logic)
        if (c ~ /[0-9]/) {
            num = ""
            while (i <= n && chars[i] ~ /[0-9.]/) {
                num = num chars[i]
                i++
            }
            if (num ~ /\./) {
                print "FLOAT:" num
                has_fuzzy = 1
            } else {
                print "INT:" num
            }
            continue
        }

        # Unknown character
        print "UNKNOWN:" c
        i++
    }
}

END {
    # Output detected paradigms
    print "---"
    print "PARADIGMS:"
    print "  boolean:1"
    if (has_modal) print "  modal:1"
    if (has_deontic) print "  deontic:1"
    if (has_epistemic) print "  epistemic:1"
    if (has_temporal) print "  temporal:1"
    if (has_fuzzy) print "  fuzzy:1"
    if (has_quantifiers) print "  fol:1"
}
