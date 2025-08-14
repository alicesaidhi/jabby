--!nonstrict

local gt = require(script.Parent.Parent.Parent.roblox_packages.gt)
local jest_globals =
	require(script.Parent.Parent.Parent.roblox_packages.jest_globals)
local lib = require(script.Parent.Parent.lib)

local describe = jest_globals.describe
local it = jest_globals.it

local function TOKEN<T>(kind: T, text: string?): lib.Token<T>
	return gt.table {
		kind = gt.literal(kind),
		text = gt.literal(text or kind),
		span = gt.vector(),
	}
end

local function TERM_STRING(token: string): lib.Term_Named
	return gt.table {
		kind = gt.literal "named",
		token = TOKEN("string", `"{token}"`),
		span = gt.vector(),
	}
end

local function TERM_IDENTIFIER(token: string): lib.Term_Named
	return gt.table {
		kind = gt.literal "named",
		token = TOKEN("identifier", token),
		span = gt.vector(),
	}
end

local function TERM_ID(token: string | number): lib.Term_Id
	return gt.table {
		kind = gt.literal "id",
		prefix = TOKEN "$",
		token = TOKEN("number", tostring(token)),
		span = gt.vector(),
	}
end

local function TERM_WILDCARD(): lib.Term_Wildcard
	return gt.table {
		kind = gt.literal "wildcard",
		token = TOKEN "*",
		span = gt.vector(),
	}
end

local function TERM_RELATIONSHIP(
	left: lib.TermPrimitive | lib.Term_Wildcard,
	right: lib.TermPrimitive | lib.Term_Wildcard
): lib.Term_Relationship
	return gt.table {
		kind = gt.literal "relationship",
		span = gt.vector(),
		tokens = {
			left = TOKEN "(",
			right = TOKEN ")",
			value = {
				left = left,
				right = right,
				separator = TOKEN ",",
			},
		},
	}
end

local function EXCLUDE_TERM(term: lib.Term): lib.ExcludeTerm
	return gt.table {
		kind = gt.literal "exclude",
		span = gt.vector(),

		prefix = TOKEN "!",
		term = term,
	}
end

local function TAG_TERM(term: lib.Term): lib.TagTerm
	return gt.table {
		kind = gt.literal "tag",
		span = gt.vector(),

		prefix = TOKEN "#",
		term = term,
	}
end

local function VIEW_TERM(term: lib.Term): lib.ViewTerm
	return gt.table {
		kind = gt.literal "view",
		span = gt.vector(),

		term = term,
	}
end

local function TERMS(terms: { lib.QueryTerm }): lib.QueryResult
	return gt.table {
		terms = gt.table(
			{ [gt.any()] = gt.never(), unpack(terms) },
			{ raw = true }
		),
	}
end

local function parse_tests(tests: {
	{
		name: string,
		input: string,
		matches: any,
	}
})
	for _, test in tests do
		it(test.name, function()
			local ok, value: lib.ParseResult =
				pcall(lib.parse, buffer.fromstring(test.input))

			if not ok then
				for _, issue in value.issues do
					print(issue)
				end
			end

			gt.build(test.matches):assert(value.result)
		end)
	end
end

describe(
	"view term",
	function()
		parse_tests {
			{
				name = "should parse identifiers",
				input = "input",
				matches = TERMS {
					VIEW_TERM(TERM_IDENTIFIER "input"),
				},
			},
			{
				name = "should parse multiple identifiers",
				input = "inputa, inputb, inputc",
				matches = TERMS {
					VIEW_TERM(TERM_IDENTIFIER "inputa"),
					VIEW_TERM(TERM_IDENTIFIER "inputb"),
					VIEW_TERM(TERM_IDENTIFIER "inputc"),
				},
			},
			{
				name = "should parse a string",
				input = `"input"`,
				matches = TERMS {
					VIEW_TERM(TERM_STRING "input"),
				},
			},
			{
				name = "should parse multiple strings",
				input = `"inputa", "inputb", "inputc"`,
				matches = TERMS {
					VIEW_TERM(TERM_STRING "inputa"),
					VIEW_TERM(TERM_STRING "inputb"),
					VIEW_TERM(TERM_STRING "inputc"),
				},
			},
			{
				name = "should parse a mix of strings and identifiers",
				input = `"inputa", inputb, "inputc"`,
				matches = TERMS {
					VIEW_TERM(TERM_STRING "inputa"),
					VIEW_TERM(TERM_IDENTIFIER "inputb"),
					VIEW_TERM(TERM_STRING "inputc"),
				},
			},
			{
				name = "should parse numbers into id identifiers",
				input = `$123`,
				matches = TERMS {
					VIEW_TERM(TERM_ID(123)),
				},
			},
			{
				name = "should parse multiple numbers into id identifiers",
				input = `$123, $456`,
				matches = TERMS {
					VIEW_TERM(TERM_ID(123)),
					VIEW_TERM(TERM_ID(456)),
				},
			},
			{
				name = "should parse a mix of values",
				input = `$123, "inputa", inputb, $456`,
				matches = TERMS {
					VIEW_TERM(TERM_ID(123)),
					VIEW_TERM(TERM_STRING "inputa"),
					VIEW_TERM(TERM_IDENTIFIER "inputb"),
					VIEW_TERM(TERM_ID(456)),
				},
			},
			{
				name = "should parse a relationship",
				input = `(a, b)`,
				matches = TERMS {
					VIEW_TERM(
						TERM_RELATIONSHIP(
							TERM_IDENTIFIER "a",
							TERM_IDENTIFIER "b"
						)
					),
				},
			},
			{
				name = "should parse a relationship with ids",
				input = `(a, $456)`,
				matches = TERMS {
					VIEW_TERM(
						TERM_RELATIONSHIP(TERM_IDENTIFIER "a", TERM_ID(456))
					),
				},
			},
			{
				name = "should parse a relationship with wildcard",
				input = `(a, *)`,
				matches = TERMS {
					VIEW_TERM(
						TERM_RELATIONSHIP(TERM_IDENTIFIER "a", TERM_WILDCARD())
					),
				},
			},
		}
	end
)

describe(
	"exclude term",
	function()
		parse_tests {
			{
				name = "should parse a identifier",
				input = "!input",
				matches = TERMS {
					EXCLUDE_TERM(TERM_IDENTIFIER "input"),
				},
			},
			{
				name = "should parse multiple identifiers",
				input = "!inputa, !inputb, !inputc",
				matches = TERMS {
					EXCLUDE_TERM(TERM_IDENTIFIER "inputa"),
					EXCLUDE_TERM(TERM_IDENTIFIER "inputb"),
					EXCLUDE_TERM(TERM_IDENTIFIER "inputc"),
				},
			},
			{
				name = "should parse a string",
				input = `!"input"`,
				matches = TERMS {
					EXCLUDE_TERM(TERM_STRING "input"),
				},
			},
			{
				name = "should parse multiple strings",
				input = `!"inputa", !"inputb", !"inputc"`,
				matches = TERMS {
					EXCLUDE_TERM(TERM_STRING "inputa"),
					EXCLUDE_TERM(TERM_STRING "inputb"),
					EXCLUDE_TERM(TERM_STRING "inputc"),
				},
			},
			{
				name = "should parse a mix of strings and identifiers",
				input = `!"inputa", !inputb, !"inputc"`,
				matches = TERMS {
					EXCLUDE_TERM(TERM_STRING "inputa"),
					EXCLUDE_TERM(TERM_IDENTIFIER "inputb"),
					EXCLUDE_TERM(TERM_STRING "inputc"),
				},
			},
			{
				name = "should parse numbers into id identifiers",
				input = `!$123`,
				matches = TERMS {
					EXCLUDE_TERM(TERM_ID(123)),
				},
			},
			{
				name = "should parse multiple numbers into id identifiers",
				input = `!$123, !$456`,
				matches = TERMS {
					EXCLUDE_TERM(TERM_ID(123)),
					EXCLUDE_TERM(TERM_ID(456)),
				},
			},
			{
				name = "should parse a mix of values",
				input = `!$123, !"inputa", !inputb, !$456`,
				matches = TERMS {
					EXCLUDE_TERM(TERM_ID(123)),
					EXCLUDE_TERM(TERM_STRING "inputa"),
					EXCLUDE_TERM(TERM_IDENTIFIER "inputb"),
					EXCLUDE_TERM(TERM_ID(456)),
				},
			},
			{
				name = "should parse a relationship",
				input = `!(a, b)`,
				matches = TERMS {
					EXCLUDE_TERM(
						TERM_RELATIONSHIP(
							TERM_IDENTIFIER "a",
							TERM_IDENTIFIER "b"
						)
					),
				},
			},
			{
				name = "should parse a relationship with ids",
				input = `!(a, $456)`,
				matches = TERMS {
					EXCLUDE_TERM(
						TERM_RELATIONSHIP(TERM_IDENTIFIER "a", TERM_ID(456))
					),
				},
			},
			{
				name = "should parse a relationship with wildcard",
				input = `!(a, *)`,
				matches = TERMS {
					EXCLUDE_TERM(
						TERM_RELATIONSHIP(TERM_IDENTIFIER "a", TERM_WILDCARD())
					),
				},
			},
		}
	end
)

describe(
	"tag term",
	function()
		parse_tests {
			{
				name = "should parse a identifier",
				input = "#input",
				matches = TERMS {
					TAG_TERM(TERM_IDENTIFIER "input"),
				},
			},
			{
				name = "should parse multiple identifiers",
				input = "#inputa, #inputb, #inputc",
				matches = TERMS {
					TAG_TERM(TERM_IDENTIFIER "inputa"),
					TAG_TERM(TERM_IDENTIFIER "inputb"),
					TAG_TERM(TERM_IDENTIFIER "inputc"),
				},
			},
			{
				name = "should parse a string",
				input = `#"input"`,
				matches = TERMS {
					TAG_TERM(TERM_STRING "input"),
				},
			},
			{
				name = "should parse multiple strings",
				input = `#"inputa", #"inputb", #"inputc"`,
				matches = TERMS {
					TAG_TERM(TERM_STRING "inputa"),
					TAG_TERM(TERM_STRING "inputb"),
					TAG_TERM(TERM_STRING "inputc"),
				},
			},
			{
				name = "should parse a mix of strings and identifiers",
				input = `#"inputa", #inputb, #"inputc"`,
				matches = TERMS {
					TAG_TERM(TERM_STRING "inputa"),
					TAG_TERM(TERM_IDENTIFIER "inputb"),
					TAG_TERM(TERM_STRING "inputc"),
				},
			},
			{
				name = "should parse numbers into id identifiers",
				input = `#$123`,
				matches = TERMS {
					TAG_TERM(TERM_ID(123)),
				},
			},
			{
				name = "should parse multiple numbers into id identifiers",
				input = `#$123, #$456`,
				matches = TERMS {
					TAG_TERM(TERM_ID(123)),
					TAG_TERM(TERM_ID(456)),
				},
			},
			{
				name = "should parse a mix of values",
				input = `#$123, #"inputa", #inputb, #$456`,
				matches = TERMS {
					TAG_TERM(TERM_ID(123)),
					TAG_TERM(TERM_STRING "inputa"),
					TAG_TERM(TERM_IDENTIFIER "inputb"),
					TAG_TERM(TERM_ID(456)),
				},
			},
			{
				name = "should parse a relationship",
				input = `#(a, b)`,
				matches = TERMS {
					TAG_TERM(
						TERM_RELATIONSHIP(
							TERM_IDENTIFIER "a",
							TERM_IDENTIFIER "b"
						)
					),
				},
			},
			{
				name = "should parse a relationship with ids",
				input = `#(a, $456)`,
				matches = TERMS {
					TAG_TERM(
						TERM_RELATIONSHIP(TERM_IDENTIFIER "a", TERM_ID(456))
					),
				},
			},
			{
				name = "should parse a relationship with wildcard",
				input = `#(a, *)`,
				matches = TERMS {
					TAG_TERM(
						TERM_RELATIONSHIP(TERM_IDENTIFIER "a", TERM_WILDCARD())
					),
				},
			},
		}
	end
)
