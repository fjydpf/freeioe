--[[
Taken from sputnik
License: MIT/X, see http://sputnik.freewisdom.org/en/License
]]-- 

-------------------------------------------------------------------------------
-- Provides method for replacing translatable strings with the right 
-- translations, using a fallback mechanism.
-------------------------------------------------------------------------------

local _M = {}

-------------------------------------------------------------------------------
-- Generates a list of fallback language codes for a given language.  E.g., for
-- pt_PT we might get back {"pt_PT", "pt_BR", "en_US"}, meaning: use pt_PT 
-- translation if defined, if not try pt_BR, if that isn't defined either use
-- en_US.  The list of fallbacks depends on the fallback_table, though, which
-- defines a set of fallbacks for any specific language prefix.  
-- For instance, if we have
--
--     fallback_table = {
--        en = "en_US",
--        pt = "pt_BR",
--        _all = "en_US",
--     }
-- 
-- This means that any "pt" language has "pt_BR" as fallback, and _any_ language 
-- falls back on en_US.
-------------------------------------------------------------------------------
local function make_language_fallback_chain(fallback_table, lang) 
	local fallback_chain = {}
	if lang then 
		fallback_chain[1] = lang 
		local prefix = lang
		while prefix do
			if prefix and fallback_table[prefix] then
				table.insert(fallback_chain, fallback_table[prefix])
			end
			prefix, _ = prefix:match("(.+)_([^_]*)")
		end
	end   
	table.insert(fallback_chain, fallback_table._all or "en_US")
	return fallback_chain
end

-------------------------------------------------------------------------------
-- Generates a closure with two functions: translate_key() which looks up the
-- translation for a specific key, and translate() which replaces all keys in 
-- the text with their translations.
-------------------------------------------------------------------------------
function _M.make_translator(translations, language, fallback_table)
	--print('Make translator ', #translations, language)
	if not fallback_table then
		fallback_table = translations.FALLBACKS or {}
	end
	local fallback_chain = make_language_fallback_chain(fallback_table, language)

	--[[
	local function translate_key(key)
	if not translations[key] then  -- simply no entry for this key
	return "_("..key..")" 
	else
	for i, lang in ipairs(fallback_chain) do  -- down the fallback chain
	if translations[key][lang] then
	return translations[key][lang] -- return a match
	end
	end
	return "%("..key..")"       -- didn't find anything - shouldn't happen
	end
	end

	local function translate(text)
	return string.gsub(text, "_%(([%w_%d]+)([^%)]*)%)", translate_key)
	end

	return {
	translate = translate,
	translate_key = translate_key
	}
	--]]
	local function translate(key)
		if not translations[key] then
			return key, nil
		end
		for i, lang in ipairs(fallback_chain) do  -- down the fallback chain
			if translations[key][lang] then
				return translations[key][lang], lang -- return a match
			end
		end
		return key, nil   -- didn't find anything - shouldn't happen
	end
	local function translatef(key, ...)
		return tostring(translate(key)):format(...)
	end
	local function t_string(key)
		return tostring(translate(key))
	end
	local function t_stringf(key, ...)
		return tostring(translate(key)):format(...)
	end

	return {
		translate = translate,
		translatef = translatef,
		string = t_string,
		stringf = t_stringf,
	}
end

function _M.make_fallback(translator, fallback_translator)
	local function translate(key)
		local trans, lang = translator.translate(key)
		--print(trans, lang)
		if lang then
			return trans, lang
		end

		--print('getting from fallback')
		--print(fallback_translator.translate(key))
		return fallback_translator.translate(key)
	end
	local function translatef(key, ...)
		return tostring(translate(key)):format(...)
	end
	local function t_string(key)
		return tostring(translate(key))
	end
	local function t_stringf(key, ...)
		return tostring(translate(key)):format(...)
	end

	return {
		translate = translate,
		translatef = translatef,
		string = t_string,
		stringf = t_stringf,
	}
end

return _M
