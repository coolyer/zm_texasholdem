#using scripts\shared\util_shared;
#using scripts\shared\array_shared;
#insert scripts\shared\shared.gsh;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_score;
#using scripts\shared\ai\zombie_utility;
#using scripts\zm\_zm_powerups;
#using scripts\codescripts\struct;
#using scripts\zm\zm_texas;

#define AI_DIFFICULTY_EASY 0
#define AI_DIFFICULTY_MEDIUM 1
#define AI_DIFFICULTY_HARD 2

function create_texas_ai()
{
    ai = spawnstruct();
    ai.difficulty = random_ai_difficulty();
    ai.personality = random_ai_personality();
    ai.name = get_random_ai_name();
    return ai;
}

function random_ai_difficulty()
{
    r = RandomInt(3);
    if(r == 0) return "EASY";
    if(r == 1) return "MEDIUM";
    return "HARD";
}

function random_ai_personality()
{
    if(RandomInt(2) == 0)
        return "show_hand";
    return "hide_hand";
}

function get_random_ai_name()
{
    names = [];
    names[0] = "Coolyer";
    names[1] = "Oblight";
    names[2] = "Droby";
    names[3] = "Porcupine";
    names[4] = "Rag";
    names[5] = "Sparky";
    names[6] = "ORCGAMING";
    // Build a list of unused names
    unused = [];
    if(!isDefined(level.used_ai_names))
        level.used_ai_names = [];
    for(i=0;i<names.size;i++)
    {
        if(zm_texas::array_index_of(level.used_ai_names, names[i]) == -1)
            unused[unused.size] = names[i];
    }

    if(unused.size > 0)
    {
        idx = RandomInt(unused.size);
        name = unused[idx];
        level.used_ai_names[level.used_ai_names.size] = name;
        return name;
    }
    else
    {
        // All names used, just pick a random base name (duplicates possible)
        name = names[RandomInt(names.size)];
        level.used_ai_names[level.used_ai_names.size] = name;
        return name;
    }
}

// AI fold action
function ai_fold(ai, hand)
{
    if(ai.personality == "show_hand")
    {
        foreach(player in GetPlayers())
            player IPrintLnBold(ai.name + " folds and shows: " + hand_to_string(hand));
    }
    else
    {
        foreach(player in GetPlayers())
            player IPrintLnBold(ai.name + " folds.");
    }
}

// Helper to convert hand to string
function hand_to_string(hand)
{
    s = "";
    for(i=0;i<hand.size;i++)
    {
        card = hand[i];
        if(i > 0) s += ", ";
        s += card.rank + " of " + card.suit;
    }
    return s;
}

// Returns "fold", "call", "raise", or "check"
function ai_get_action(ai, hand, community_cards, current_bet, can_check)
{
    // Show AI thinking
    foreach(player in GetPlayers())
        player IPrintLnBold(ai.name + " is thinking...");

    hand_strength = evaluate_simple_hand_strength(hand, community_cards);

    // Easy: mostly calls/checks, rarely raises, sometimes folds weak hands
    if(ai.difficulty == "EASY")
    {
        if(hand_strength == "strong" && RandomInt(4) == 0)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " raises.");
            return "raise";
        }
        if(hand_strength == "weak" && RandomInt(3) == 0)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " folds.");
            return "fold";
        }
        if(can_check)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " checks.");
            return "check";
        }
        else
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " calls.");
            return "call";
        }
    }

    // Medium: raises more with strong hands, folds more with weak
    if(ai.difficulty == "MEDIUM")
    {
        if(hand_strength == "strong" && RandomInt(2) == 0)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " raises.");
            return "raise";
        }
        if(hand_strength == "weak" && RandomInt(2) == 0)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " folds.");
            return "fold";
        }
        if(can_check)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " checks.");
            return "check";
        }
        else
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " calls.");
            return "call";
        }
    }

    // Hard: raises with strong, folds with weak, sometimes bluffs
    if(ai.difficulty == "HARD")
    {
        if(hand_strength == "strong" || RandomInt(5) == 0) // bluff chance
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " raises.");
            return "raise";
        }
        if(hand_strength == "weak" && RandomInt(2) == 0)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " folds.");
            return "fold";
        }
        if(can_check)
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " checks.");
            return "check";
        }
        else
        {
            foreach(player in GetPlayers())
                player IPrintLnBold(ai.name + " calls.");
            return "call";
        }
    }

    // Default fallback
    if(can_check)
    {
        foreach(player in GetPlayers())
            player IPrintLnBold(ai.name + " checks.");
        return "check";
    }
    else
    {
        foreach(player in GetPlayers())
            player IPrintLnBold(ai.name + " calls.");
        return "call";
    }
}

// Simple hand strength evaluator: returns "strong", "medium", or "weak"
function evaluate_simple_hand_strength(hand, community_cards)
{
    // Combine hand and community
    cards = [];
    for(i=0;i<hand.size;i++) cards[cards.size]=hand[i];
    for(i=0;i<community_cards.size;i++) cards[cards.size]=community_cards[i];

    // Count pairs
    rank_counts = [];
    for(i=0;i<cards.size;i++)
    {
        v = card_rank_value(cards[i]);
        if(!isDefined(rank_counts[v])) rank_counts[v]=0;
        rank_counts[v]++;
    }
    pairs = 0;
    trips = 0;
    for(v=2;v<=14;v++)
    {
        if(isDefined(rank_counts[v]))
        {
            if(rank_counts[v]==2) pairs++;
            if(rank_counts[v]==3) trips++;
            if(rank_counts[v]>=4) return "strong"; // Four of a kind
        }
    }
    if(trips > 0) return "strong";
    if(pairs > 0) return "medium";
    return "weak";
}
function card_rank_value(card)
{
    return card.rank;
}
