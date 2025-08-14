--[=[
@class JabbyQueryParser

Jabby query parser converts a string into a list of predicates that need to be matched for a query.
You pass a set of feature flags which allows certain things and denies others for deviating libraries.

A term in this case can refer to either an entity or component. A query is built
up out of a set of predicates.

- query filter predicate
	Gives a list of components to query and list of components to exclude from the
	query
- value filter predicate
	Takes in a term and a function that takes a value and returns a boolean.
- read predicate
	Contains a component and optionally a predicate for that component. This
	needs to be read and sent to the user.


Syntax:

Every identifier is a Named Term.
Use "" to include symbols in your term.

To specify an Id, prefix it with $, followed by numbers

Relationships are two terms surrounded by parantheses and a comma separating
them. (A, B)

Wildcard is `*`

Exclude by prefixing a term with `!`.

Specify tag by prefixing a term with `#`.	

]=]

--[=[
@class Term
A term specifies a 
]=]

export type QueryFilterPredicate = {
	include: { Term },
	exclude: { Term },
	read: { Term },
}

export type ValueFilterPredicate = {
	conditional: (unknown) -> boolean,
}

export type ReadPredicate = {
	term: Term,
	predicate: ValueFilterPredicate?,
}

-- Parser

type Span = vector

type Separated<Node> = { Node }
type Surrounded<T, L, R> = { left: Token<L>, right: Token<R>?, value: T? }

export type TokenKindText = | "identifier" | "number" | "string" | "error"

export type TokenKindRest =
	-- OPERATORS
	| "*"
	-- Symbols
	| "("
	| ")"
	| "$"
	| "!"
	| "#"
	| ","
	-- LINE ENDINGS
	| "\n"
	| ";"
	-- WHITESPACE
	| "eof"
	| "whitespace"
	| "comment"

export type TokenKind = TokenKindText | TokenKindRest

export type Token<T = TokenKind> = {
	kind: T,
	text: string,
	span: Span,
}

export type Term_Named = {
	read kind: "named",
	read token: Token<"string" | "identifier">,
	read span: Span,
}

export type Term_Id = {
	read kind: "id",
	read prefix: Token<"$">,
	read token: Token<"number">?,
	read span: Span,
}

export type Term_Wildcard = {
	read kind: "wildcard",
	read token: Token<"*">,
	read span: Span,
}

export type Term_Relationship = {
	read kind: "relationship",
	read tokens: Surrounded<{
		read left: TermPrimitive | Term_Wildcard?,
		read separator: Token<",">?,
		read right: TermPrimitive | Term_Wildcard?,
	}, "(", ")">,
	read span: vector,
}

-- type Predicate_FunctionCall = {
-- 	read kind: "function",
-- 	read span: Span,
-- 	read token: Token<"identifier">
-- }

-- type Predicate_String = {
-- 	read kind: "string",
-- 	read span: Span,
-- 	read token: Token<"string">
-- }

-- type Predicate_Number = {
-- 	read kind: "number",
-- 	read span: Span,
-- 	read token: Token<"number">
-- }

-- type Predicate_Filter = {
-- 	read kind: "predicate",
-- 	read span: Span,

-- 	read prefix: Token<"@">,
-- 	read filter: Token<"identifier">,
-- 	read arguments: Surrounded<{
-- 		read value:
-- 		read separator: Token<",">,
-- 		read span: Span
-- 	}, "(", ")">,

-- }

export type TermPrimitive = | Term_Named | Term_Id

export type Term = | TermPrimitive | Term_Relationship

export type ExcludeTerm = {
	read kind: "exclude",
	read prefix: Token<"!">,
	read term: Term?,
	read span: Span,
}

export type ViewTerm = {
	read kind: "view",
	read term: Term,
	read span: Span,
}

export type TagTerm = {
	read kind: "tag",
	read prefix: Token<"#">,
	read term: Term?,
	read span: Span,
}

export type QueryTerm = | ExcludeTerm | ViewTerm | TagTerm

export type QueryResult = {
	read terms: Separated<QueryTerm>,
}

export type Issue = {
	why: string,
	span: vector,
}
export type ParseResult = { result: QueryResult?, issues: { Issue } }

local function char(c: string): number return string.byte(c) :: number end

local function parse(input: buffer): ParseResult
	local pos = 0
	local line = 0
	local len = buffer.len(input)
	local issues: { Issue } = {}

	local function peek(): number
		if pos == len then return 0 end
		return buffer.readu8(input, pos) :: any
	end

	local function bump() pos = math.min((pos + 1) :: any, len) end

	local function bump_any()
		if peek() == char "\n" then
			line += 1
		end

		bump()
		return peek()
	end

	local function eof(msg: string)
		if pos >= len then
			table.insert(issues, { why = msg, span = vector.create(pos, pos) })
			error({
				result = nil,
				issues = issues,
			}, 0)
		end
		return false
	end

	local function bump_peek()
		bump()
		return peek()
	end

	local function is_whitespace(c: number): boolean
		return c == char " " or c == char "\t" or c == char "\r"
	end

	local function is_digit(c: number): boolean
		return char "0" <= c and c <= char "9"
	end

	local function is_alpha(c: number): boolean
		return (char "a" <= c and c <= char "z")
			or (char "A" <= c and c <= char "Z")
			or c == char "_"
	end

	local function string_backslash()
		local c = peek()

		if c == char "\r" then
			c = bump_peek()

			if c == char "\n" then
				bump()
				line += 1
			end
		elseif c == char "z" then
			bump()

			while is_whitespace(peek()) do
				bump_any()
			end
		else
			bump_any()
		end
	end

	local function quoted_string(): "string" | "error"
		local delim = peek()
		local c = bump_peek()

		while
			c ~= delim and not eof("expected string to be finished at", pos)
		do
			if c == 0 or c == char "\n" or c == char "\r" then
				return "error"
			elseif c == char "\\" then
				bump()
				string_backslash()
			else
				bump()
			end

			c = peek()
		end

		bump()
		return "string"
	end

	local function number(): "number" | "error"
		local start = pos
		local base = 10

		local c: number = peek()
		local has_sign = false

		if c == char "-" then
			c = bump_peek()
			has_sign = true
		end

		-- if c == char "0" then
		-- 	c = bump_peek()

		-- 	if c == char "x" or c == char "X" then
		-- 		c = bump_peek()
		-- 		base = 16
		-- 	elseif c == char "b" or c == char "B" then
		-- 		c = bump_peek()
		-- 		base = 2
		-- 	end
		-- end

		while is_digit(c) or c == char "." or c == char "_" do
			c = bump_peek()
		end

		if c == char "e" or c == char "E" then
			c = bump_peek()

			if c == char "+" or c == char "-" then c = bump_peek() end
		end

		while is_digit(c) or is_alpha(c :: any) or c == char "_" do
			c = bump_peek()
		end

		local text: string
		if base == 10 then
			text = buffer.readstring(input, start, pos - start) :: string
		else
			text = buffer.readstring(
				input,
				start + 2 + if has_sign then 1 else 0,
				pos - start - 2 - if has_sign then 1 else 0
			) :: string
		end

		text = string.gsub(text, "_", "")

		if tonumber(text, base) then
			return "number"
		else
			return "error"
		end
	end

	local function read_kind(): TokenKindRest | TokenKindText
		local c: number = peek()

		if c == 0 then return "eof" end

		if c == char "#" then
			bump()
			return "#"
		elseif c == char "!" then
			bump()
			return "!"
		elseif is_whitespace(c) then
			bump()
			return "whitespace"
		elseif is_alpha(c) then
			repeat
				c = bump_peek()
			until not (
					is_alpha(c :: number)
					or is_digit(c :: number)
					or c == char "-"
				)

			return "identifier"
		elseif is_digit(c :: number) or c == char "-" then
			return number()
		elseif c == char '"' then
			return quoted_string()
		elseif c == char "'" then
			return quoted_string()
		elseif c == char "$" then
			bump()
			return "$"
		elseif c == char "(" then
			bump()
			return "("
		elseif c == char ")" then
			bump()
			return ")"
		elseif c == char "\n" then
			bump()
			return "\n"
		elseif c == char ";" then
			bump()
			return ";"
		elseif c == char "," then
			bump()
			return ","
		elseif c == char "*" then
			bump()
			return "*"
		elseif is_whitespace(c) then
			bump()
			return read_kind()
		end

		bump()
		return "error"
	end

	local function next_token()
		local start = pos
		local kind = read_kind()

		while kind == "whitespace" or kind == "comment" do
			start = pos
			kind = read_kind()
		end

		return {
			kind = kind,
			text = buffer.readstring(input, start, pos - start),
			span = vector.create(start, pos, 0),
		}
	end

	local current_token = next_token()
	local current_kind = current_token.kind
	local current_pos = current_token.span.x
	local lookahead_token = next_token()
	local lookahead_kind = lookahead_token.kind
	local lookahead_pos = lookahead_token.span.x

	local function consume()
		local old_token, old_kind = current_token, current_kind
		current_token, current_kind = lookahead_token, lookahead_kind
		current_pos = lookahead_pos
		lookahead_token = next_token()
		lookahead_kind = lookahead_token.kind
		lookahead_pos = lookahead_token.span.x
		return old_token, old_kind
	end

	local function current_is(kind: TokenKindText | TokenKindRest)
		while current_kind == "\n" do
			consume()
		end

		return current_kind == kind
	end

	local function lookahead_is(kind: TokenKindText | TokenKindRest)
		while lookahead_kind == "\n" do
			lookahead_token = next_token()
			lookahead_kind = lookahead_token.kind
		end

		return lookahead_kind == kind
	end

	local function display(token: Token): string
		local kind = token.kind

		if kind == "identifier" or kind == "number" or kind == "string" then
			return token.text
		elseif token.kind == "error" then
			return "error '" .. token.text .. "'"
		else
			return "'" .. kind .. "'"
		end
	end

	local function fatal(message: string, span: vector?): never
		local report = {
			why = message,
			span = span or current_token.span,
		}

		table.insert(issues, report)
		return error {
			result = nil,
			issues = issues,
		}
	end

	local function nonfatal(message: string, span: vector?): false
		local report = {
			why = message,
			span = span or current_token.span,
		}

		table.insert(issues, report)
		return false
	end

	local function expect_fatal(kind: TokenKindText | TokenKindRest): never
		return fatal(
			`expected {display({ kind = kind } :: any)}, but got {display(
				current_token
			)} of {current_kind} instead`
		)
	end

	local function expect_nonfatal(kind: TokenKindText | TokenKindRest): false
		nonfatal(
			`expected {display({ kind = kind } :: any)}, but got {display(
				current_token
			)} of {current_kind} instead`
		)
		consume()
		return false
	end

	local function expect<T>(
		kind: T & (TokenKindText | TokenKindRest)
	): Token<T> | false
		if current_is(kind) then
			return consume() :: any
		else
			return expect_nonfatal(kind)
		end
	end

	local parse_relationship: () -> Term_Relationship?
	local parse_term_prim: () -> TermPrimitive?
	local parse_term_prim_or_wildcard: () -> (TermPrimitive | Term_Wildcard)?
	local parse_term: () -> Term?
	local parse_tag_term: () -> TagTerm
	local parse_view_term: () -> ViewTerm
	local parse_exclude_term: () -> ExcludeTerm
	local parse_terms: () -> QueryResult

	function parse_relationship(): Term_Relationship?
		local left = expect("(" :: "(")
		if not left then return nil end

		local term_a = parse_term_prim_or_wildcard()
		local separator = expect("," :: ",")
		local term_b = parse_term_prim_or_wildcard()

		local right = expect(")" :: ")")

		local last_term = right or term_b or separator or term_a or left

		if
			term_a
			and term_a.kind == "wildcard"
			and term_b
			and term_b.kind == "wildcard"
		then
			nonfatal(
				"both relationship terms are wildcards",
				vector.create(left.span.x, last_term.span.y)
			)
		end

		return {
			kind = "relationship",
			span = vector.create(left.span.x, last_term.span.y),

			tokens = {
				left = left,
				right = right or nil,
				value = {
					left = term_a,
					separator = separator or nil,
					right = term_b,
				},
			},
		}
	end

	function parse_term_prim(): TermPrimitive?
		if current_is "string" or current_is "identifier" then
			local token = if current_is "string"
				then expect("string" :: "string")
				else expect("identifier" :: "identifier")
			if not token then
				return expect_fatal("string or identifier" :: any)
			end

			return {
				kind = "named",
				token = token :: Token<"string" | "identifier">,
				span = token.span,
			}
		elseif current_is "$" then
			local prefix = expect("$" :: "$")
			if not prefix then return expect_fatal "$" end

			local id = expect("number" :: "number")
			local last = id or prefix

			return {
				kind = "id",
				prefix = prefix,
				token = id or nil,
				span = vector.create(prefix.span.x, last.span.y),
			}
		else
			expect_nonfatal("term" :: any)
			return nil
		end
	end

	function parse_term_prim_or_wildcard(): (TermPrimitive | Term_Wildcard)?
		if current_is "*" then
			local token = expect("*" :: "*")
			if not token then return expect_fatal "*" end

			local wildcard: Term_Wildcard = {
				kind = "wildcard",
				token = token,
				span = token.span,
			}

			return wildcard
		else
			return parse_term_prim()
		end
	end

	function parse_term(): Term?
		if current_is "(" then
			return parse_relationship()
		else
			return parse_term_prim()
		end
	end

	function parse_view_term(): ViewTerm
		local term = parse_term()
		if not term then return expect_fatal("term" :: any) end

		return {
			kind = "view",
			term = term,
			span = term.span,
		}
	end

	function parse_exclude_term(): ExcludeTerm
		local prefix = expect("!" :: "!")
		if not prefix then return expect_fatal "!" end
		local term = parse_term()

		local last = term or prefix
		return {
			kind = "exclude",
			prefix = prefix,
			term = term,
			span = vector.create(prefix.span.x, last.span.y),
		}
	end

	function parse_tag_term(): TagTerm
		local prefix = expect("#" :: "#")
		if not prefix then return expect_fatal "#" end
		local term = parse_term()

		local last = term or prefix
		return {
			kind = "tag",
			prefix = prefix,
			term = term,
			span = vector.create(prefix.span.x, last.span.y),
		}
	end

	function parse_terms(): QueryResult
		local terms = {}

		while current_is "eof" == false do
			if current_is "#" then
				table.insert(terms, parse_tag_term())
			elseif current_is "!" then
				table.insert(terms, parse_exclude_term())
			else
				table.insert(terms, parse_view_term())
			end

			if not current_is "," then
				break
			else
				consume()
			end
		end

		if not current_is "eof" then expect_nonfatal "eof" end

		return {
			terms = terms,
		}
	end

	local result = parse_terms()

	if #issues > 0 then
		error {
			result = result,
			issues = issues,
		}
	else
		return {
			result = result,
			issues = issues,
		}
	end
end

--[=[
@within JabbyQueryParser
@interface FeatureFlags

]=]
export type FeatureOptions = {
	enable_relationships: boolean?,
	enable_excludes: boolean?,
	enable_wildcard: boolean?,
	-- enables only having excludes in your component
	enable_only_excludes: boolean?,
	disable_merge_include_view: boolean?,
}

type Result = {
	result: QueryResult?,
	values: { include: { Term }, exclude: { Term }, view: { Term } }?,
	issues: { Issue },
}

local function process(
	input: string,
	options: {
		is_component: ((string) -> boolean)?,
		is_id: ((number) -> boolean)?,

		features: FeatureOptions,
	}
): Result
	local b = buffer.fromstring(input)
	local result = parse(b)
	assert(result.result)

	local function throw(msg: string, where: vector)
		table.insert(result.issues, { why = msg, span = where })
	end

	local function check_name_term(term: Term_Named)
		if not options.is_component then return end

		local token = term.token
		if token.kind == "identifier" then
			if options.is_component(token.text) then return end
			throw(`"{token.text}" is not a valid component`, token.span)
		elseif token.kind == "string" then
			local text = string.sub(token.text, 2, -2)
			if options.is_component(text) then return end
			throw(`"{text}" is not a valid component`, token.span)
		end
	end

	local function check_id_term(term: Term_Id)
		if not options.is_id then return end

		local token = term.token
		if not token then return end

		local n = tonumber(token.text)
		if not n then
			return throw(`{token.text} is not a valid number`, token.span)
		end
		if options.is_id(n) then return end
		throw(`{token.text} is not a valid id`, token.span)
	end

	local function check_primitive(term: TermPrimitive)
		if term.kind == "named" then
			check_name_term(term)
		else
			check_id_term(term)
		end
	end

	local function check_primitive_or_wildcard(
		term: TermPrimitive | Term_Wildcard
	)
		if term.kind == "wildcard" then
			if not options.features.enable_wildcard then
				throw("wildcards are not enabled", term.span)
			end
			return
		else
			check_primitive(term)
		end
	end

	local function check_relationship(term: Term_Relationship)
		if not options.features.enable_relationships then
			return throw(`relationships are not enabled`, term.span)
		end

		local value = term.tokens.value
		if not value then return end
		if value.left then check_primitive_or_wildcard(value.left) end
		if value.right then check_primitive_or_wildcard(value.right) end
	end

	local function check_term(term: Term)
		if term.kind == "relationship" then
			return check_relationship(term)
		else
			return check_primitive(term)
		end
	end

	local include = {}
	local exclude = {}
	local view = {}

	for _, term in result.result.terms do
		if term.kind == "exclude" then
			if not options.features.enable_excludes then
				throw("excludes are not enabled", term.span)
				continue
			end

			if not term.term then continue end
			check_term(term.term)

			table.insert(exclude, term.term)
		elseif term.kind == "tag" then
			if not term.term then continue end
			check_term(term.term)
			table.insert(include, term.term)
		elseif term.kind == "view" then
			check_term(term.term)

			table.insert(view, term.term)
			if not options.features.disable_merge_include_view then
				table.insert(include, term.term)
			end
		end
	end

	if options.features.enable_only_excludes ~= true then
		if #include == 0 and #exclude ~= 0 then
			throw(
				"cannot exclude without including compoennts",
				vector.create(1, #input)
			)
		end
	end

	local output = {
		result = result.result,
		issues = result.issues,
		values = {
			include = include,
			exclude = exclude,
			view = view,
		},
	}

	if #result.issues > 0 then
		error(output)
	else
		return output
	end
end

local function into_string<T>(
	options: {
		get_relationship: ((T) -> (T?, T?))?,
		is_exclude: ((T) -> boolean)?,
		get_name: ((T) -> string?)?,
	},
	...: T
)
	local get_relationship = options.get_relationship
	local is_exclude = options.is_exclude
	local get_name = options.get_name
	local entities = {}

	local function to_named(input: T): string
		local left, right

		if get_relationship then
			left, right = get_relationship(input)
		end

		if left and right then
			local pair = `({to_named(left)}, {to_named(right)})`
			return if is_exclude and is_exclude(input) then `!{pair}` else pair
		end

		local name = get_name and get_name(input) or `${input}`
		return if is_exclude and is_exclude(input) then `!{name}` else name
	end

	for i = 1, select("#", ...) do
		local value = select(i, ...)
		entities[i] = to_named(value)
	end

	return table.concat(entities, ", ")
end

return {
	parse = parse,
	values = process,
	into_string = into_string,
}
