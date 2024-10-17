--- STEAMODDED HEADER
--- MOD_NAME: Mystes' Mod
--- MOD_ID: MystesMod
--- MOD_AUTHOR: [Mystes]
--- MOD_DESCRIPTION: Adds 12 jokers.
--- BADGE_COLOUR: 66AB05
--- DISPLAY_NAME: Mystes' Mod

-- Lovers can enhance 2 cards
G.P_CENTERS.c_lovers.config.max_highlighted = 2

-- Hiker rarity adjustment
G.P_CENTERS.j_hiker.rarity = 1

--------------------------------------------
-- HELPER FUNCTIONS (much credit to Mika) --

local function init_joker(joker, no_sprite)
    no_sprite = no_sprite or false

    local new_joker = SMODS.Joker:new(
        joker.ability_name,
        joker.slug,
        joker.ability,
        { x = 0, y = 0 },
        joker.loc,
        joker.rarity,
        joker.cost,
        joker.unlocked,
        joker.discovered,
        joker.blueprint_compat,
        joker.eternal_compat,
        joker.effect,
        joker.atlas,
        joker.soul_pos
    )
    new_joker:register()

    if not no_sprite then
        local sprite = SMODS.Sprite:new(
            new_joker.slug,
            SMODS.findModByID("MystesMod").path,
            new_joker.slug .. ".png",
            71,
            95,
            "asset_atli"
        )
        sprite:register()
    end
end

local function create_tarot(joker, seed)
    if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
        G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
        G.E_MANAGER:add_event(Event({
            trigger = "before",
            delay = 0.0,
            func = (function()
                local card = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, seed)
                card:add_to_deck()
                G.consumeables:emplace(card)
                G.GAME.consumeable_buffer = 0
                return true
            end)
        }))
        card_eval_status_text(joker, "extra", nil, nil, nil, {
            message = localize("k_plus_tarot"),
            colour = G.C.PURPLE
        })
    else
        card_eval_status_text(joker, "extra", nil, nil, nil, {
            message = localize("k_no_space_ex")
        })
    end
end

local function is_fibo(card)
    local id = card:get_id()
    return id == 2 or id == 3 or id == 5 or id == 8 or id == 14
end

local fibo = {5,8,13,21}
local function getfibo(i)
    if #fibo >= i then
        return fibo[i]
    else
        fibo[i] = fibo[i-1] + fibo[i-2]
        return fibo[i]
    end
end

local enhancements = {
    G.P_CENTERS.m_bonus,
    G.P_CENTERS.m_mult,
    G.P_CENTERS.m_wild,
    G.P_CENTERS.m_glass,
    G.P_CENTERS.m_steel,
    G.P_CENTERS.m_stone,
    G.P_CENTERS.m_gold,
    G.P_CENTERS.m_lucky
}

local seals = {
    'Red',
    'Blue',
    'Purple',
    'Gold',
}

------------
-- JOKERS --

function SMODS.INIT.MystesMod()
    init_localization()

    -- Cabinet Joker
    local cabinet = {
        loc = {
            name = "Cabinet",
            text = {
                "{C:attention}+1{} discard for each",
                "hand played this round",
            }
        },
        ability_name = "Cabinet",
        slug = "cabinet",
        ability = {
        },
        rarity = 1,
        cost = 5,
        unlocked = true,
        discovered = true,
        blueprint_compat = false,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(cabinet)
    function SMODS.Jokers.j_cabinet.loc_def(card)
        return {}
    end
    SMODS.Jokers.j_cabinet.calculate = function(card, context)
        if context.after and not context.blueprint and context.cardarea == G.jokers then
            ease_discard(1)
        end
    end

    -- Juggling Manual Joker
    local juggling_manual = {
        loc = {
            name = "Juggling Manual",
            text = {
                "{C:attention}+1{} hand size for each",
                "hand played this round",
            }
        },
        ability_name = "Juggling Manual",
        slug = "juggling_manual",
        ability = {
            h_size = 0,
        },
        rarity = 1,
        cost = 5,
        unlocked = true,
        discovered = true,
        blueprint_compat = false,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(juggling_manual)
    function SMODS.Jokers.j_juggling_manual.loc_def(card)
        return {card.ability.h_size}
    end
    SMODS.Jokers.j_juggling_manual.calculate = function(card, context)
        if context.after and not context.blueprint and context.cardarea == G.jokers then
            G.hand:change_size(1)
            card.ability.h_size = card.ability.h_size + 1
        elseif context.end_of_round and not context.blueprint then
            G.hand:change_size(- card.ability.h_size)
            card.ability.h_size = 0
        end
    end

    -- Long Game Joker
    local long_game = {
        loc = {
            name = "Long Game",
            text = {
                "Earn {C:money}$#1#{} on",
                "hand played",
            }
        },
        ability_name = "Long Game",
        slug = "long_game",
        ability = {
            extra = {
                dollars = 2,
            }
        },
        rarity = 1,
        cost = 4,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = -0.3}
    }
    init_joker(long_game)
    function SMODS.Jokers.j_long_game.loc_def(card)
        return {card.ability.extra.dollars}
    end
    SMODS.Jokers.j_long_game.calculate = function(card, context)
        if context.after and context.cardarea == G.jokers then
            G.E_MANAGER:add_event(Event({
                func = function()
                    ease_dollars(card.ability.extra.dollars)
                    card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('$')..card.ability.extra.dollars,colour = G.C.MONEY, delay = 0.45})
                    return true end}))
        end
    end

    -- Tortoise Joker
    local tortoise = {
        loc = {
            name = "Tortoise Joker",
            text = {
                "{X:mult,C:white} X#1# {} Mult for each",
                "{C:attention}Hand{} played this round",
                "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
            }
        },
        ability_name = "Tortoise",
        slug = "tortoise",
        ability = {
            extra = {
                x_mult = 0.5,
                increase = 1,
                base = 0.5,
            }
        },
        rarity = 2,
        cost = 7,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(tortoise)
    function SMODS.Jokers.j_tortoise.loc_def(card)
        return {card.ability.extra.increase, card.ability.extra.x_mult}
    end
    SMODS.Jokers.j_tortoise.calculate = function(card, context)
        if context.joker_main then   
            return {
                message = localize{type='variable',key='a_xmult',vars={card.ability.extra.x_mult}},
                Xmult_mod = card.ability.extra.x_mult,
            }
        elseif context.after and not context.blueprint and context.cardarea == G.jokers then
            card.ability.extra.x_mult = card.ability.extra.x_mult + card.ability.extra.increase
        elseif context.end_of_round then
            card.ability.extra.x_mult = card.ability.extra.base
        end
    end

    -- Charred Joker
    local charred = {
        loc = {
            name = "Charred Joker",
            text = {
                "{C:attention}Enhance{} a random card",
                "out of the first {C:attention}discarded",
                "each round",
            }
        },
        ability_name = "Charred",
        slug = "charred",
        ability = {

        },
        rarity = 1,
        cost = 5,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(charred)
    function SMODS.Jokers.j_charred.loc_def(card)
        return {}
    end
    SMODS.Jokers.j_charred.calculate = function(card, context)
        if context.pre_discard and G.GAME.current_round.discards_used <= 0 and not context.hook then
            local temp_hand = {}
            for k, v in ipairs(G.hand.highlighted) do 
                if(v.ability.effect == "Base") then
                    temp_hand[#temp_hand+1] = v
                end
            end
            local theCards = nil
            if #temp_hand > 0 then 
                theCards = temp_hand 
            else
                theCards = G.hand.highlighted
            end
            local theCard = pseudorandom_element(theCards, pseudoseed("charred"))
            theCard:set_ability(pseudorandom_element(enhancements, pseudoseed("charred")), nil, true)
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = localize("k_upgrade_ex"),
                delay = 0.45,
                card = card
            })
        end
    end

    -- Love Triangle Joker
    local love_triangle = {
        loc = {
            name = "Love Triangle",
            text = {
                "When a {C:attention}discard{} contains",
                "a {C:attention}#1#{}, add a",
                "random {C:attention}seal{} on one of the cards",
            }
        },
        ability_name = "Love Triangle",
        slug = "love_triangle",
        ability = {
            extra = "Three of a Kind",
        },
        rarity = 2,
        cost = 6,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(love_triangle)
    function SMODS.Jokers.j_love_triangle.loc_def(card)
        return {card.ability.extra}
    end
    SMODS.Jokers.j_love_triangle.calculate = function(card, context)
        if context.pre_discard and not context.hook then
            local text,disp_text,poker_hands = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
            if next(poker_hands[card.ability.extra]) then
                local temp_hand = {}
                for k, v in ipairs(G.hand.highlighted) do 
                    if(v.seal == nil) then
                        temp_hand[#temp_hand+1] = v
                    end
                end
                local theCards = nil
                if #temp_hand > 0 then 
                    theCards = temp_hand
                else
                    theCards = G.hand.highlighted
                end
                local theCard = pseudorandom_element(theCards, pseudoseed("love_triangle"))
                theCard:set_seal(pseudorandom_element(seals, pseudoseed("love_triangle")))
                card_eval_status_text(card, "extra", nil, nil, nil, {
                    message = localize("k_upgrade_ex"),
                    delay = 0.45,
                    card = card
                })
            end
        end
    end

    -- Connoisseur Joker
    local theHands = {
        "Three of a Kind",
        "Flush", 
        "Straight"
    }
    local connoisseur = {
        loc = {
            name = "Connoisseur",
            text = {
                "Gains {X:mult,C:white} X#1# {} Mult when",
                "{C:attention}discarding{} a {C:attention}#2#",
                "{C:inactive}(hand changes on trigger",
                "{C:inactive}and on round end)",
                "{C:inactive}(Currently {X:mult,C:white} X#3# {C:inactive} Mult)",
            }
        },
        ability_name = "Connoisseur",
        slug = "connoisseur",
        ability = {
            x_mult = 1,
            extra = {
                gain = 0.5,
                hands = theHands,
                current_hand = pseudorandom_element(theHands, math.random()),
            }
        },
        rarity = 3,
        cost = 7,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(connoisseur)
    function SMODS.Jokers.j_connoisseur.loc_def(card)
        return {card.ability.extra.gain, card.ability.extra.current_hand, card.ability.x_mult}
    end
    SMODS.Jokers.j_connoisseur.calculate = function(card, context)
        local isTrigger = false
        if context.pre_discard and not context.hook then
            local text,disp_text,poker_hands = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
            if next(poker_hands[card.ability.extra.current_hand]) then
                isTrigger = true
                card.ability.x_mult = card.ability.x_mult + card.ability.extra.gain 
                card_eval_status_text(card, "extra", nil, nil, nil, {
                    message = localize("k_upgrade_ex"),
                    delay = 0.45,
                    card = card
                })
            end
        end
        if isTrigger or context.end_of_round then
            card.ability.extra.current_hand = pseudorandom_element(card.ability.extra.hands, pseudoseed("connoisseur"))
        end
    end

    -- Abstinent Joker
    local abstinence = {
        loc = {
            name = "Abstinent Joker",
            text = {
                "{C:attention}+#1#{} hand size",
                "{C:red}-1{} hand size on discard",
                "{C:inactive}(resets every round){}",
            }
        },
        ability_name = "Abstinence",
        slug = "abstinence",
        ability = {
            h_size = 2,
            extra = {
                h_size_original = 2,
            }
        },
        rarity = 2,
        cost = 5,
        unlocked = true,
        discovered = true,
        blueprint_compat = false,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(abstinence)
    function SMODS.Jokers.j_abstinence.loc_def(card)
        return {card.ability.h_size}
    end
    SMODS.Jokers.j_abstinence.calculate = function(card, context)
        if context.pre_discard and not context.blueprint then
            G.hand:change_size(-1)
            card.ability.h_size = card.ability.h_size - 1
        elseif context.end_of_round and not context.blueprint then
            G.hand:change_size(card.ability.extra.h_size_original - card.ability.h_size)
            card.ability.h_size = card.ability.extra.h_size_original
        end
    end

    -- Santa Joker
    local santa = {
        loc = {
            name = "Santa Joker",
            text = {
                "{C:green}#1# in #2#{} chance of adding {C:dark_edition}Foil{},",
                "{C:dark_edition}Holographic{} or {C:dark_edition}Polychrome{} effect to",
                "one random normal card on {C:attention}first draw{}",
            }
        },
        ability_name = "Santa",
        slug = "santa",
        ability = {
            extra = 3,
        },
        rarity = 2,
        cost = 5,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(santa)
    function SMODS.Jokers.j_santa.loc_def(card)
        return {G.GAME.probabilities.normal, card.ability.extra}
    end
    SMODS.Jokers.j_santa.calculate = function(card, context)
        if context.first_hand_drawn and (pseudorandom('santa') < G.GAME.probabilities.normal/card.ability.extra) then
            G.E_MANAGER:add_event(Event({
                func = function() 
                    local temp_hand = {}
                    for k, v in ipairs(G.hand.cards) do 
                        if(v.seal == nil) then
                            temp_hand[#temp_hand+1] = v
                        end
                    end
                    if #temp_hand > 0 then 
                        local theCard = pseudorandom_element(temp_hand, pseudoseed("santa"))
                        local edition = poll_edition('santa', nil, true, true)
                        theCard:set_edition(edition, true)
                        card_eval_status_text(card, "extra", nil, nil, nil, {
                            message = localize("k_upgrade_ex"),
                            delay = 0.45,
                            card = card
                        })
                        card:juice_up()
                        return true
                    end
                end}))
        end
    end

    -- Syndacate Joker
    local syndacate = {
        loc = {
            name = "The Syndacate",
            text = {
                "{X:mult,C:white} X#1# {} Mult if played",
                "hand contains",
                "a {C:attention}#2#",
            }
        },
        ability_name = "Syndacate",
        slug = "syndacate",
        ability = {
            Xmult = 5,
            type = "Straight Flush",
            extra = 5,
        },
        rarity = 3,
        cost = 8,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(syndacate)
    function SMODS.Jokers.j_syndacate.loc_def(card)
        return {card.ability.extra, card.ability.type}
    end
    SMODS.Jokers.j_syndacate.calculate = function(card, context)
        -- Implement the Joker's effect here if necessary
    end

    --- FORMERLY FUSION JOKERS ---

    -- Court Magician (rarity adjusted to 4)
    local court_magician = {
        loc = {
            name = "Court Magician",
            text = {
                "Playing a {C:attention}#1#{} cuts the current",
                "Blind by {C:attention}#2#%{} and earns {C:money}$#3#{} and",
                "creates a {C:spectral}Spectral{} and a {C:tarot}Tarot{} card",
            }
        },
        ability_name = "Court Magician",
        slug = "court_magician",
        ability = {
            extra = {
                hand = "Royal Flush",
                cut = 0.3,
                dollars = 10,
            }
        },
        rarity = 4,
        cost = 20,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(court_magician)
    function SMODS.Jokers.j_court_magician.loc_def(card)
        return {card.ability.extra.hand, 100*(1 - card.ability.extra.cut), card.ability.extra.dollars}
    end
    SMODS.Jokers.j_court_magician.calculate = function(card, context)
        if context.joker_main and G.GAME.current_round.current_hand.handname == card.ability.extra.hand then

            if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local card = create_card('Spectral',G.consumeables, nil, nil, nil, nil, nil, 'cmg')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer - 1
                        return true end)}))
            end

            if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    func = (function()
                        G.E_MANAGER:add_event(Event({
                            func = function() 
                                local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, 'cmg')
                                card:add_to_deck()
                                G.consumeables:emplace(card)
                                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer - 1
                                return true end}))   
                            card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})                       
                        return true end)}))
            end

            G.E_MANAGER:add_event(Event({
                func = function()
                    ease_dollars(card.ability.extra.dollars)
                    card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('$')..card.ability.extra.dollars,colour = G.C.MONEY, delay = 0.45})
                    return true end}))

            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
                G.GAME.blind.chips = math.floor(G.GAME.blind.chips * card.ability.extra.cut)
                G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
                
                local chips_UI = G.hand_text_area.blind_chips
                G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
                G.HUD_blind:recalculate() 
                chips_UI:juice_up()
        
                if not silent then play_sound('chips2') end
                return true end}))
        end
    end

    -- Math Wiz (rarity adjusted to 3)
    local mathwiz = {
        loc = {
            name = "Math Wiz",
            text = {
                "Each played {C:attention}Ace{}, {C:attention}2{}, {C:attention}3{}, {C:attention}5{}, or {C:attention}8{}",
                "gives Fibonacci Chips and Mult",
                "when scored (starting at",
                "{C:chips}+13{} Chips and {C:mult}+5{} Mult)",
            }
        },
        ability_name = "MathWiz",
        slug = "mathwiz",
        ability = {
            extra = {
                base_chips_fibo = 3,
                base_mult_fibo = 1,
                current_chips_fibo = 3,
                current_mult_fibo = 1,
            }
        },
        rarity = 3,
        cost = 13,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(mathwiz)
    SMODS.Jokers.j_mathwiz.calculate = function(card, context)
        if context.individual and context.cardarea == G.play and is_fibo(context.other_card) then
            local theChips = getfibo(card.ability.extra.current_chips_fibo)
            local theMult = getfibo(card.ability.extra.current_mult_fibo)
            if not context.blueprint then
                card.ability.extra.current_chips_fibo = card.ability.extra.current_chips_fibo + 1
                card.ability.extra.current_mult_fibo = card.ability.extra.current_mult_fibo + 1
            end
            return {
                chips = theChips,
                mult = theMult,
                card = card
            }
        elseif context.after and context.cardarea == G.jokers then
            card.ability.extra.current_chips_fibo = card.ability.extra.base_chips_fibo
            card.ability.extra.current_mult_fibo = card.ability.extra.base_mult_fibo
        end
    end

    -- Apophenia (rarity adjusted to 3)
    local apophenia = {
        loc = {
            name = "Apophenia",
            text = {
                "{C:attention}+#1#{} consumable slot",
                "Create a {C:tarot}Tarot{} card when",
                "{C:attention}Blind{} is selected or when",
                "any {C:attention}Booster Pack{} is opened",
            }
        },
        ability_name = "Apophenia",
        slug = "apophenia",
        ability = {
            extra = {
                slots = 1,
            }
        },
        rarity = 3,
        cost = 12,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(apophenia)
    function SMODS.Jokers.j_apophenia.loc_def(card)
        return {card.ability.extra.slots}
    end
    SMODS.Jokers.j_apophenia.calculate = function(card, context)
        if context.setting_blind and not card.getting_sliced and not (context.blueprint_card or card).getting_sliced then
            create_tarot(card, 'apo')
        elseif context.open_booster then
            create_tarot(card, 'apo')
        end
    end

    -- Four-Finger Discount (rarity adjusted to 3)
    local four_finger_discount = {
        loc = {
            name = "Four-Finger Discount",
            text = {
                "All {C:attention}Flushes{} and {C:attention}Straights{}",
                "can be made with {C:attention}4{} cards.",
                "Allows {C:attention}Straights{} to be",
                "made with gaps of {C:attention}1 rank.",
                "Earn {C:money}$#1#{} when scoring",
                "a {C:attention}#2#{}.",
            }
        },
        ability_name = "Four Finger Discount",
        slug = "four_finger_discount",
        ability = {
            extra = {
                dollars = 5,
                type = "Straight Flush",
            }
        },
        rarity = 3,
        cost = 12,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(four_finger_discount)
    function SMODS.Jokers.j_four_finger_discount.loc_def(card)
        return {card.ability.extra.dollars, card.ability.extra.type}
    end
    SMODS.Jokers.j_four_finger_discount.calculate = function(card, context)
        if context.before and next(context.poker_hands[card.ability.extra.type]) then
            G.E_MANAGER:add_event(Event({
                func = function()
                    ease_dollars(card.ability.extra.dollars)
                    card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('$')..card.ability.extra.dollars,colour = G.C.MONEY, delay = 0.45})
                    return true
                end}))
            return
        end
    end

    -- Conquistador (rarity adjusted to 4)
    local conquistador = {
        loc = {
            name = "Conquistador",
            text = {
                "Earn {C:money}$#1#{} on hand", 
                "triggering {C:attention}Boss Blind{}",
                "ability and then disables blind",
            }
        },
        ability_name = "Conquistador",
        slug = "conquistador",
        ability = {
            extra = 20,
        },
        rarity = 4,
        cost = 13,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        soul_pos = {x = 1, y = 0}
    }
    init_joker(conquistador)
    function SMODS.Jokers.j_conquistador.loc_def(card)
        return {card.ability.extra}
    end
    SMODS.Jokers.j_conquistador.calculate = function(card, context)
        if context.debuffed_hand and G.GAME.blind.triggered then 
            ease_dollars(card.ability.extra)
            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra
            G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
            card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('ph_boss_disabled')})
            G.GAME.blind:disable()
            return {
                message = localize('$')..card.ability.extra,
                dollars = card.ability.extra,
                colour = G.C.MONEY
            }
        end
    end

end

-----------
-- DECKS --

-- The deck test code has been removed because the config options have been removed.

---------------
-- OVERRIDES --

function get_flush(hand)
    local ret = {}
    local four_fingers = next(find_joker('Four Fingers')) or next(find_joker('Four Finger Discount'))
    local suits = SMODS.Card.SUIT_LIST
    if #hand < (5 - (four_fingers and 1 or 0)) then
        return ret
    else
        for j = 1, #suits do
            local t = {}
            local suit = suits[j]
            local flush_count = 0
            for i = 1, #hand do
                if hand[i]:is_suit(suit, nil, true) then
                    flush_count = flush_count + 1
                    t[#t + 1] = hand[i]
                end
            end
            if flush_count >= (5 - (four_fingers and 1 or 0)) then
                table.insert(ret, t)
                return ret
            end
        end
        return {}
    end
end

function get_straight(hand)
    local ret = {}
    local four_fingers = next(find_joker('Four Fingers')) or next(find_joker('Four Finger Discount'))
    local can_skip = next(find_joker('Shortcut')) or next(find_joker('Four Finger Discount'))
    if #hand < (5 - (four_fingers and 1 or 0)) then return ret end
    local t = {}
    local RANKS = {}
    for i = 1, #hand do
        local rank = hand[i].base.value
        if RANKS[rank] then
            RANKS[rank][#RANKS[rank] + 1] = hand[i]
        else
            RANKS[rank] = { hand[i] }
        end
    end
    local straight_length = 0
    local straight = false
    local skipped_rank = false
    local vals = {}
    for k, v in pairs(SMODS.Card.RANKS) do
        if v.straight_edge then
            table.insert(vals, k)
        end
    end
    local init_vals = {}
    for _, v in ipairs(vals) do
        init_vals[v] = true
    end
    if not next(vals) then table.insert(vals, 'Ace') end
    local initial = true
    local br = false
    local end_iter = false
    local i = 0
    while 1 do
        end_iter = false
        if straight_length >= (5 - (four_fingers and 1 or 0)) then
            straight = true
        end
        i = i + 1
        if br or (i > #SMODS.Card.RANK_LIST + 1) then break end
        if not next(vals) then break end
        for _, val in ipairs(vals) do
            if init_vals[val] and not initial then br = true end
            if RANKS[val] then
                straight_length = straight_length + 1
                skipped_rank = false
                for _, vv in ipairs(RANKS[val]) do
                    t[#t + 1] = vv
                end
                vals = SMODS.Card.RANKS[val].next
                initial = false
                end_iter = true
                break
            end
        end
        if not end_iter then
            local new_vals = {}
            for _, val in ipairs(vals) do
                for _, r in ipairs(SMODS.Card.RANKS[val].next) do
                    table.insert(new_vals, r)
                end
            end
            vals = new_vals
            if can_skip and not skipped_rank then
                skipped_rank = true
            else
                straight_length = 0
                skipped_rank = false
                if not straight then t = {} end
                if straight then break end
            end
        end
    end
    if not straight then return ret end
    table.insert(ret, t)
    return ret
end

local add_to_deckref = Card.add_to_deck
function Card:add_to_deck(from_debuff)
    if not self.added_to_deck then
        if self.ability.name == 'Apophenia' then
            G.consumeables:change_size(self.ability.extra.slots)
        end
    end
    add_to_deckref(self, from_debuff)
end

local remove_from_deckref = Card.remove_from_deck
function Card:remove_from_deck(from_debuff)
    if self.added_to_deck then
        if self.ability.name == 'Apophenia' then
            G.consumeables:change_size(-self.ability.extra.slots)
        end
    end
    remove_from_deckref(self, from_debuff)
end
