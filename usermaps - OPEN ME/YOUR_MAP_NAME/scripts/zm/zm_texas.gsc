#using scripts\shared\util_shared;
#using scripts\shared\array_shared;
#insert scripts\shared\shared.gsh;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_score;
#using scripts\shared\ai\zombie_utility;
#using scripts\zm\_zm_powerups;
#using scripts\codescripts\struct;
#using scripts\zm\zm_texas_ai;


#precache("material", "2_of_clubs");
#precache("material", "3_of_clubs");
#precache("material", "4_of_clubs");
#precache("material", "5_of_clubs");
#precache("material", "6_of_clubs");
#precache("material", "7_of_clubs");
#precache("material", "8_of_clubs");
#precache("material", "9_of_clubs");
#precache("material", "10_of_clubs");
#precache("material", "jack_of_clubs");
#precache("material", "queen_of_clubs");
#precache("material", "king_of_clubs");
#precache("material", "ace_of_clubs");
#precache("material", "2_of_hearts");
#precache("material", "3_of_hearts");
#precache("material", "4_of_hearts");
#precache("material", "5_of_hearts");
#precache("material", "6_of_hearts");
#precache("material", "7_of_hearts");
#precache("material", "8_of_hearts");
#precache("material", "9_of_hearts");
#precache("material", "10_of_hearts");
#precache("material", "jack_of_hearts");
#precache("material", "queen_of_hearts");
#precache("material", "king_of_hearts");
#precache("material", "ace_of_hearts");
#precache("material", "2_of_spades");
#precache("material", "3_of_spades");
#precache("material", "4_of_spades");
#precache("material", "5_of_spades");
#precache("material", "6_of_spades");
#precache("material", "7_of_spades");
#precache("material", "8_of_spades");
#precache("material", "9_of_spades");
#precache("material", "10_of_spades");
#precache("material", "jack_of_spades");
#precache("material", "queen_of_spades");
#precache("material", "king_of_spades");
#precache("material", "ace_of_spades");
#precache("material", "2_of_diamonds");
#precache("material", "3_of_diamonds");
#precache("material", "4_of_diamonds");
#precache("material", "5_of_diamonds");
#precache("material", "6_of_diamonds");
#precache("material", "7_of_diamonds");
#precache("material", "8_of_diamonds");
#precache("material", "9_of_diamonds");
#precache("material", "10_of_diamonds");
#precache("material", "jack_of_diamonds");
#precache("material", "queen_of_diamonds");
#precache("material", "king_of_diamonds");
#precache("material", "ace_of_diamonds");
#precache("material", "sleeve");

#define AI_ALLOWED 1
#define MIN_PLAYERS 2
#define MAX_PLAYERS 5
#define CHIPSTOPLAY 5
function init_texas_poker()
{
    tables = GetEntArray("poker_table", "targetname");
    for(i = 0; i < tables.size; i++)
    {
        tables[i] SetHintString("^3Press &&1 to play Poker");
        tables[i].poker_in_use = false;
        tables[i] thread poker_table_think();
    }
}

function poker_table_think()
{
    trig = self;
    while(1)
    {
        trig waittill("trigger", player);
        if(trig.poker_in_use)
            continue;
        if(!isDefined(player.poker_busy))
        {
            // Only show waiting hint if more than one player
            if(GetPlayers().size > 1)
                trig SetHintString("^1Waiting for players...");
            if(isDefined(player.sessionstate) && (!isDefined(player.poker_chips) || player.poker_chips < CHIPSTOPLAY))
            {
                player IPrintLnBold("You need at least " + CHIPSTOPLAY + " chips to play poker! Visit the bank.");
                continue;
            }
            trig.poker_in_use = true;
            player.poker_busy = true;
            player thread poker_lobby(trig);
        }
    }
}

function poker_lobby(trig)
{
    host = self;
    players = [];
    players[players.size] = host;
    lobby_huds = [];
    min_players = MIN_PLAYERS;
    max_players = MAX_PLAYERS;

    // If solo, skip lobby and fill with AI
    if(GetPlayers().size == 1)
    {
        if(AI_ALLOWED == 1)
        {
            while(players.size < max_players)
            {
                ai = zm_texas_ai::create_texas_ai();
                players[players.size] = ai;
				ai.poker_chips = 100;
                host IPrintLnBold("AI Player added: " + ai.name);
            }
            thread play_texas_hand_multiplayer(trig, players);
            return;
        }
    }

    // --- original lobby loop here ---
    while(1)
    {
        // Show lobby HUD to host
        if(!isDefined(lobby_huds["host"]))
        {
            lobby_huds["host"] = NewClientHudElem(host);
            lobby_huds["host"].alignX = "center";
            lobby_huds["host"].alignY = "middle";
            lobby_huds["host"].horzAlign = "center";
            lobby_huds["host"].vertAlign = "middle";
            lobby_huds["host"].y = -120;
        }
        lobby_huds["host"] SetText("^2Players joined: " + players.size + "  (Use = Start, Crouch = Cancel)");

        // Let other players join by proximity/trigger
        ents = GetEntArray("poker_table", "targetname");
        for(i=0;i<ents.size;i++)
        {
            ent = ents[i];
            near_players = GetPlayers();
            for(j=0;j<near_players.size;j++)
            {
                p = near_players[j];
                if(array_index_of(players, p) == -1 && !isDefined(p.poker_busy) && Distance(p.origin, ent.origin) < 100)
                {
                    players[players.size] = p;
					p.poker_busy = true;
					if(isDefined(p.sessionstate))
					{
						join_hud = NewClientHudElem(p);
						join_hud.alignX = "center";
						join_hud.alignY = "middle";
						join_hud.horzAlign = "center";
						join_hud.vertAlign = "middle";
						join_hud.y = -120;
						join_hud SetText("^2Joined Poker Table! Waiting for host...");
						lobby_huds[p GetEntityNumber()] = join_hud;
					}
                }
            }
        }

        // Host can start or cancel
        if(host UseButtonPressed() && players.size >= min_players)
        {
            // If only one human, fill with AI and start immediately
            if(AI_ALLOWED == 1 && players.size == 1)
            {
                while(players.size < max_players)
                {
                    ai = zm_texas_ai::create_texas_ai();
                    players[players.size] = ai;
                    host IPrintLnBold("AI Player added: " + ai.name);
                }
                // Clean up lobby HUDs
                for(i=0;i<players.size;i++)
                {
                    p = players[i];
                    if(isDefined(p.sessionstate) && isDefined(lobby_huds[p GetEntityNumber()]))
    					lobby_huds[p GetEntityNumber()] Destroy();
                }
                if(isDefined(lobby_huds["host"])) lobby_huds["host"] Destroy();
                thread play_texas_hand_multiplayer(trig, players);
                return;
            }
            break;
        }
        if(host GetStance() == "crouch")
        {
            // Cancel lobby
            for(i=0;i<players.size;i++)
            {
                p = players[i];
                if(isDefined(p.poker_busy)) p.poker_busy = undefined;
                if(isDefined(p.sessionstate) && isDefined(lobby_huds[p GetEntityNumber()]))
    				lobby_huds[p GetEntityNumber()] Destroy();
            }
            if(isDefined(lobby_huds["host"])) lobby_huds["host"] Destroy();
            trig.poker_in_use = false;
            trig SetHintString("^3Press &&1 to play Poker");
            return;
        }
        wait(0.1);
    }

    // Clean up lobby HUDs
    for(i=0;i<players.size;i++)
    {
        p = players[i];
        if(isDefined(p.sessionstate) && isDefined(lobby_huds[p GetEntityNumber()]))
    		lobby_huds[p GetEntityNumber()] Destroy();
    }
    if(isDefined(lobby_huds["host"])) lobby_huds["host"] Destroy();

    // After host presses Use to start
    if(AI_ALLOWED == 1 && players.size == 1)
    {
        while(players.size < max_players)
        {
            ai = zm_texas_ai::create_texas_ai();
            players[players.size] = ai;
            host IPrintLnBold("AI Player added: " + ai.name);
        }
        thread play_texas_hand_multiplayer(trig, players);
        return;
    }

    // Fill empty seats with AI if allowed and only one human player
    if(AI_ALLOWED == 1 && players.size == 1)
    {
        while(players.size < max_players)
        {
            ai = zm_texas_ai::create_texas_ai();
            players[players.size] = ai;
        }
    }

    // Start the game for all players
    thread play_texas_hand_multiplayer(trig, players);
}

function make_shuffled_deck()
{
    deck = [];
    suits = [];
    suits[0] = "hearts";
    suits[1] = "diamonds";
    suits[2] = "clubs";
    suits[3] = "spades";

    ranks = [];
    ranks[0] = 2;
    ranks[1] = 3;
    ranks[2] = 4;
    ranks[3] = 5;
    ranks[4] = 6;
    ranks[5] = 7;
    ranks[6] = 8;
    ranks[7] = 9;
    ranks[8] = 10;
    ranks[9] = 11;
    ranks[10] = 12;
    ranks[11] = 13;
    ranks[12] = 14;

    // Create all 52 cards
    for(i=0;i<suits.size;i++)
    {
        for(j=0;j<ranks.size;j++)
        {
            card = spawnstruct();
            card.suit = suits[i];
            card.rank = ranks[j];
            deck[deck.size] = card;
        }
    }

    // Fisher-Yates shuffle
    for(i=deck.size-1;i>0;i--)
    {
        j = RandomInt(i+1);
        temp = deck[i];
        deck[i] = deck[j];
        deck[j] = temp;
    }

    return deck;
}

function texas_betting_round(players, min_bet)
{
    IPrintLnBold("=== Starting betting round. Min bet: " + min_bet + " ===");
    pot = 0;
    highest_bet = min_bet;
    for(i=0;i<players.size;i++)
    {
        p = players[i];
        p.current_bet = 0;
        // Do NOT reset p.folded here!
    }

    done = false;
    round_num = 1;
    while(!done)
    {
        IPrintLnBold("Betting round pass #" + round_num);
        done = true;

        // --- Early exit if only one player left ---
        active_players = 0;
        last_player = undefined;
        for(i=0;i<players.size;i++)
        {
            if(!players[i].folded)
            {
                active_players++;
                last_player = players[i];
            }
        }
        if(active_players == 1)
        {
            IPrintLnBold(last_player.name + " wins the pot (everyone else folded)!");
            last_player.poker_chips += pot;
            return pot;
        }

        for(i=0;i<players.size;i++)
        {
            p = players[i];
            //IPrintLnBold("DEBUG: " + p.name + " folded=" + p.folded);
            if(p.folded)
                continue;
            if(p.current_bet < highest_bet || highest_bet == 0)
            {
                // Player's turn
                if(isDefined(p.sessionstate))
                {
                    IPrintLnBold("Your turn! Current bet: " + p.current_bet + ", Highest bet: " + highest_bet);
                    hud = NewClientHudElem(p);
                    hud.alignX = "center";
                    hud.alignY = "middle";
                    hud.horzAlign = "center";
                    hud.vertAlign = "middle";
                    hud.y = 200;
                    hud.fontScale = 1.2;
                    hud SetText("^2Use = Call/Check | Crouch = Fold | Melee = Raise");
                    choice = undefined;
                    while(!isDefined(choice))
                    {
                        if(p UseButtonPressed())
                            choice = "call";
                        else if(p GetStance() == "crouch")
                            choice = "fold";
                        else if(p MeleeButtonPressed())
                            choice = "raise";
                        wait(0.05);
                    }
                    hud Destroy();
                    if(choice == "call")
                    {
                        cost = highest_bet - p.current_bet;
                        if(p.points >= cost)
                        {
                            p.points -= cost;
                            pot += cost;
                            p.current_bet = highest_bet;
                            p IPrintLnBold("You call. Points left: " + p.points);
                        }
                        else
                        {
                            p IPrintLnBold("Not enough points to call! You fold.");
                            p.folded = true;
                        }
                    }
                    else if(choice == "raise")
                    {
                        raise_amt = highest_bet + 1;
                        cost = raise_amt - p.current_bet;
                        if(p.points >= cost)
                        {
                            highest_bet = raise_amt;
                            p.points -= cost;
                            pot += cost;
                            p.current_bet = highest_bet;
                            p IPrintLnBold("You raise. Points left: " + p.points);
                            done = false;
                        }
                        else
                        {
                            p IPrintLnBold("Not enough points to raise! You call instead.");
                            cost = highest_bet - p.current_bet;
                            if(p.points >= cost)
                            {
                                p.points -= cost;
                                pot += cost;
                                p.current_bet = highest_bet;
                            }
                            else
                            {
                                p.folded = true;
                            }
                        }
                    }
                    else if(choice == "fold")
                    {
                        p.folded = true;
                        p IPrintLnBold("You fold.");
                        if(isDefined(p.hud)) {
                            destroy_texas_hud(p.hud);
                            p.hud = undefined;
                        };
                    }
                }
                else
                {
                    // --- AI logic: simple random for now ---
                    IPrintLnBold(p.name + "'s turn. Current bet: " + p.current_bet + ", Highest bet: " + highest_bet);
                    ai_action = RandomInt(3); // 0=fold, 1=call, 2=raise
                    if(ai_action == 0)
                    {
                        p.folded = true;
                        IPrintLnBold(p.name + " folds.");
                    }
                    else if(ai_action == 1)
                    {
                        IPrintLnBold(p.name + " calls.");
                        pot += (highest_bet - p.current_bet);
                        p.current_bet = highest_bet;
                    }
                    else
                    {
                        raise_amt = highest_bet + 1;
                        highest_bet = raise_amt;
                        pot += (highest_bet - p.current_bet);
                        p.current_bet = highest_bet;
                        if(isDefined(p.sessionstate))
                            p IPrintLnBold("You raise. Points left: " + p.points);
                        else
                            IPrintLnBold(p.name + " raises.");
                        done = false;
                    }
                    wait(0.5);
                }
            }
        }
        // Print who is still in
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            IPrintLnBold(p.name + " folded: " + p.folded + ", current bet: " + p.current_bet);
        }
        // Check if all non-folded players have matched the highest bet
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(!p.folded && p.current_bet < highest_bet)
                done = false;
        }
        round_num++;
    }
    IPrintLnBold("=== Betting round complete. Pot: " + pot + " ===");
    return pot;
}


function play_texas_hand_multiplayer(trig, players)
{
    while(1)
    {
        // --- Deduct 5 chip ante from each player and add to pot ---
        pot = 0;
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(!isDefined(p.poker_chips)) p.poker_chips = 100; // fallback for AI
            if(p.poker_chips < 5)
            {
                p.folded = true;
                p IPrintLnBold("Not enough chips for ante! You are out.");
            }
            else
            {
                p.poker_chips -= 5;
                pot += 5;
                p.folded = false;
                if(isDefined(p.sessionstate))
                    p IPrintLnBold("Paid 5 chip ante. Chips left: " + p.poker_chips);
                else
                    IPrintLnBold(p.name + " paid 5 chip ante. Chips left: " + p.poker_chips);
            }
        }

        // --- Give each player 100 chips for betting this hand (or less if they have less) ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(!p.folded)
            {
                p.points = 100;
                if(p.poker_chips < 100)
                    p.points = p.poker_chips;
            }
        }

        IPrintLnBold("=== New Texas Hold'em hand starting! ===");
        deck = make_shuffled_deck();
        deck_index_ref = spawnstruct();
        deck_index_ref.idx = 0;
        flop = [];
        turn = undefined;
        river = undefined;
        flop_hud_imgs = [];
        turn_hud_imgs = [];
        river_hud_imgs = [];

        // --- Create Pot and Chips HUDs for each real player ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(isDefined(p.sessionstate))
            {
                // Pot HUD (top left)
                p.pot_hud = NewClientHudElem(p);
                p.pot_hud.alignX = "left";
                p.pot_hud.alignY = "top";
                p.pot_hud.horzAlign = "left";
                p.pot_hud.vertAlign = "top";
                p.pot_hud.x = 20;
                p.pot_hud.y = 20;
                p.pot_hud.fontScale = 1.2;
                p.pot_hud SetText("Current Pot: " + pot);

                // Chips HUD (bottom left)
                p.chips_hud = NewClientHudElem(p);
                p.chips_hud.alignX = "left";
                p.chips_hud.alignY = "bottom";
                p.chips_hud.horzAlign = "left";
                p.chips_hud.vertAlign = "bottom";
                p.chips_hud.x = 20;
                p.chips_hud.y = -20;
                p.chips_hud.fontScale = 1.2;
                p.chips_hud SetText("Chips: " + p.poker_chips);
            }
        }

        // --- Deal player hands ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            p.poker_hand = [];
            if(isDefined(p.sessionstate))
            {
                p.hud = create_texas_hud(p);
                p.hud.player_card_imgs = [];
                for(j=0;j<2;j++)
                {
                    img = NewClientHudElem(p);
                    img.alignX = "center";
                    img.alignY = "middle";
                    img.horzAlign = "center";
                    img.vertAlign = "middle";
                    img.x = -40 + j*80;
                    img.y = 150;
                    img SetShader("sleeve", 64, 64);
                    p.hud.player_card_imgs[p.hud.player_card_imgs.size] = img;
                    wait(0.4);
                    card = draw_card(deck, deck_index_ref);
                    p.poker_hand[p.poker_hand.size] = card;
                    //IPrintLnBold("Dealt to player " + i + " (human): " + card.rank + " of " + card.suit + " (deck_index_ref=" + deck_index_ref.idx + ")");
                    mat = card_to_material(card, card.suit);
                    img SetShader(mat, 64, 64);
                    wait(0.2);
                }
                update_texas_hud(p, p.hud);
            }
            else if(!p.folded) // AI
            {
                for(j=0;j<2;j++)
                {
                    card = draw_card(deck, deck_index_ref);
                    p.poker_hand[p.poker_hand.size] = card;
                    //IPrintLnBold("Dealt to player " + i + " (AI): " + card.rank + " of " + card.suit + " (deck_index_ref=" + deck_index_ref.idx + ")");
                }
            }
        }

        // --- Betting round before flop ---
        pot += texas_betting_round(players, 0);

        // --- Update Pot HUD after betting round ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(isDefined(p.sessionstate) && isDefined(p.pot_hud))
                p.pot_hud SetText("Current Pot: " + pot);
        }

        // --- Community cards (flop, turn, river) ---
        // Flop
        IPrintLnBold("Dealing the flop...");
        for(i=0;i<3;i++)
        {
            for(j=0;j<players.size;j++)
            {
                p = players[j];
                if(isDefined(p.sessionstate))
                {
                    img = NewClientHudElem(p);
                    img.alignX = "center";
                    img.alignY = "middle";
                    img.horzAlign = "center";
                    img.vertAlign = "middle";
                    img.x = -80 + i*80;
                    img.y = -60;
                    img SetShader("sleeve", 64, 64);
                    if(!isDefined(flop_hud_imgs[j])) flop_hud_imgs[j] = [];
                    flop_hud_imgs[j][i] = img;
                }
            }
            wait(0.4);
            card = draw_card(deck, deck_index_ref);
            flop[flop.size] = card;
            //IPrintLnBold("Flop card " + i + ": " + card.rank + " of " + card.suit + " (deck_index_ref=" + deck_index_ref.idx + ")");
            mat = card_to_material(card, card.suit);
            for(j=0;j<players.size;j++)
            {
                p = players[j];
                if(isDefined(p.sessionstate) && isDefined(flop_hud_imgs[j][i]))
                    flop_hud_imgs[j][i] SetShader(mat, 64, 64);
            }
            wait(0.2);
        }

        // --- Betting round after flop ---
        pot += texas_betting_round(players, 0);

        // --- Update Pot HUD after betting round ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(isDefined(p.sessionstate) && isDefined(p.pot_hud))
                p.pot_hud SetText("Current Pot: " + pot);
        }

        // Turn
        IPrintLnBold("Dealing the turn...");
        for(j=0;j<players.size;j++)
        {
            p = players[j];
            if(isDefined(p.sessionstate))
            {
                turn_img = NewClientHudElem(p);
                turn_img.alignX = "center";
                turn_img.alignY = "middle";
                turn_img.horzAlign = "center";
                turn_img.vertAlign = "middle";
                turn_img.x = 80 * 2;
                turn_img.y = -60;
                turn_img SetShader("sleeve", 64, 64);
                turn_hud_imgs[j] = turn_img;
            }
        }
        wait(0.4);
        turn = draw_card(deck, deck_index_ref);
        IPrintLnBold("Turn card: " + turn.rank + " of " + turn.suit + " (deck_index_ref=" + deck_index_ref.idx + ")");
        mat = card_to_material(turn, turn.suit);
        for(j=0;j<players.size;j++)
        {
            p = players[j];
            if(isDefined(p.sessionstate) && isDefined(turn_hud_imgs[j]))
                turn_hud_imgs[j] SetShader(mat, 64, 64);
        }
        wait(0.2);

        // --- Betting round after turn ---
        pot += texas_betting_round(players, 0);

        // --- Update Pot HUD after betting round ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(isDefined(p.sessionstate) && isDefined(p.pot_hud))
                p.pot_hud SetText("Current Pot: " + pot);
        }

        // River
        IPrintLnBold("Dealing the river...");
        for(j=0;j<players.size;j++)
        {
            p = players[j];
            if(isDefined(p.sessionstate))
            {
                river_img = NewClientHudElem(p);
                river_img.alignX = "center";
                river_img.alignY = "middle";
                river_img.horzAlign = "center";
                river_img.vertAlign = "middle";
                river_img.x = 80 * 3;
                river_img.y = -60;
                river_img SetShader("sleeve", 64, 64);
                river_hud_imgs[j] = river_img;
            }
        }
        wait(0.4);
        river = draw_card(deck, deck_index_ref);
        IPrintLnBold("River card: " + river.rank + " of " + river.suit + " (deck_index_ref=" + deck_index_ref.idx + ")");
        mat = card_to_material(river, river.suit);
        for(j=0;j<players.size;j++)
        {
            p = players[j];
            if(isDefined(p.sessionstate) && isDefined(river_hud_imgs[j]))
                river_hud_imgs[j] SetShader(mat, 64, 64);
        }
        wait(0.2);

        // --- Showdown (only for players who didn't fold) ---
        IPrintLnBold("Showdown! Evaluating hands...");
        best_eval = undefined;
        winner = undefined;
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(!p.folded)
            {
                cards = combine_and_sort_hand(p.poker_hand, flop, turn, river);
                eval = evaluate_hand(cards);
                IPrintLnBold(p.name + ": " + hand_description(eval));
                if(!isDefined(best_eval) || compare_hands(eval, best_eval) > 0)
                {
                    best_eval = eval;
                    winner = p;
                }
            }
        }
        if(isDefined(winner))
        {
            IPrintLnBold("Winner: " + winner.name + " with " + hand_description(best_eval));
            winner.poker_chips += pot;
            if(isDefined(winner.sessionstate))
                winner IPrintLnBold("You won the pot of " + pot + " chips! Total chips: " + winner.poker_chips);
            else
                IPrintLnBold(winner.name + " won the pot of " + pot + " chips! Total chips: " + winner.poker_chips);
            // Update chips HUD for winner
            if(isDefined(winner.sessionstate) && isDefined(winner.chips_hud))
                winner.chips_hud SetText("Chips: " + winner.poker_chips);
        }
        else
        {
            IPrintLnBold("No winner (everyone folded?)");
        }

        // --- HUD CLEANUP: Destroy all player and community card HUDs ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(isDefined(p.hud))
            {
                destroy_texas_hud(p.hud);
                p.hud = undefined;
            }
            // Destroy community card HUDs for this player
            if(isDefined(flop_hud_imgs[i]))
            {
                for(j=0;j<flop_hud_imgs[i].size;j++)
                    if(isDefined(flop_hud_imgs[i][j])) flop_hud_imgs[i][j] Destroy();
            }
            if(isDefined(turn_hud_imgs[i])) turn_hud_imgs[i] Destroy();
            if(isDefined(river_hud_imgs[i])) river_hud_imgs[i] Destroy();

            // Destroy Pot and Chips HUDs (only for real players)
            if(isDefined(p.sessionstate) && isDefined(p.pot_hud)) p.pot_hud Destroy();
            if(isDefined(p.sessionstate) && isDefined(p.chips_hud)) p.chips_hud Destroy();
        }

        // --- Ready up system: wait for all human players to press Use ---
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(isDefined(p.sessionstate))
            {
                p.ready = false;

                p.ready_hud = NewClientHudElem(p);
                p.ready_hud.alignX = "center";
                p.ready_hud.alignY = "middle";
                p.ready_hud.horzAlign = "center";
                p.ready_hud.vertAlign = "middle";
                p.ready_hud.y = 200;
                p.ready_hud.fontScale = 1.2;
                p.ready_hud SetText("^2Press Use to play again | Melee to end");
            }
        }
        while(1)
        {
            all_ready = true;
            for(i=0;i<players.size;i++)
            {
                p = players[i];
                if(isDefined(p.sessionstate) && !p.ready)
                {
                    if(p UseButtonPressed())
                    {
                        p.ready = true;
                        if(isDefined(p.ready_hud)) p.ready_hud Destroy();
                    }
                    else if(p MeleeButtonPressed())
                    {
                        p.quit_poker = true;
                        if(isDefined(p.ready_hud)) p.ready_hud Destroy();
                    }
                    else
                    {
                        all_ready = false;
                    }
                }
            }
            // If any player chose to quit, end the poker game
            quit = false;
            for(i=0;i<players.size;i++)
            {
                if(isDefined(players[i].quit_poker) && players[i].quit_poker)
                    quit = true;
            }
            if(quit)
                break;
            if(all_ready)
                break;
            wait(0.05);
        }
        // Clean up ready HUDs
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(isDefined(p.ready_hud)) p.ready_hud Destroy();
        }

        // --- QUIT CHECK: End the poker game if any player pressed melee ---
        for(i=0;i<players.size;i++)
        {
           if(isDefined(players[i].quit_poker) && players[i].quit_poker)
            {
                // Clear poker_busy for all human players
                for(j=0;j<players.size;j++)
                {
                    if(isDefined(players[j].sessionstate) && isDefined(players[j].poker_busy))
                        players[j].poker_busy = undefined;
                }
                if(isDefined(trig)) trig.poker_in_use = false;
                //IPrintLnBold("Poker game ended by player.");
                return;
            }
        }

        // Optionally: Remove players with no chips left from the table
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(p.poker_chips < 5)
            {
                p IPrintLnBold("You are out of chips and removed from the table.");
                p.folded = true;
                if(isDefined(p.poker_busy))
                    p.poker_busy = undefined;
            }
            // Update chips HUD for all players
            if(isDefined(p.sessionstate) && isDefined(p.chips_hud))
                p.chips_hud SetText("Chips: " + p.poker_chips);
        }

        // If all players are out, break the loop
        active_players = 0;
        for(i=0;i<players.size;i++)
        {
            p = players[i];
            if(!p.folded && p.poker_chips >= 5)
                active_players++;
        }
        if(active_players == 0)
        {
            IPrintLnBold("All players are out of chips. Poker game over.");
            // Clear poker_busy for all human players
            for(i=0;i<players.size;i++)
            {
                if(isDefined(players[i].sessionstate) && isDefined(players[i].poker_busy))
                    players[i].poker_busy = undefined;
            }
            if(isDefined(trig)) trig.poker_in_use = false;
            break;
        }
    }
}
function combine_and_sort_hand(hand, flop, turn, river)
{
    cards = [];
    for(i=0;i<hand.size;i++) cards[cards.size]=hand[i];
    for(i=0;i<flop.size;i++) cards[cards.size]=flop[i];
    cards[cards.size]=turn;
    cards[cards.size]=river;
    // Sort by rank value descending
    for(i=0;i<cards.size-1;i++)
    for(j=i+1;j<cards.size;j++)
        if(card_rank_value(cards[j]) > card_rank_value(cards[i]))
        {
            temp=cards[i];cards[i]=cards[j];cards[j]=temp;
        }
    return cards;
}

function evaluate_hand(cards)
{
    // cards: 7 cards, sorted by rank descending
    // Returns: [rank, high_card_value, tiebreakers...]
    // rank: 8=straight flush, 7=four, 6=full house, 5=flush, 4=straight, 3=three, 2=two pair, 1=pair, 0=high card

    // Count suits and ranks
    rank_counts = [];
    suit_counts = [];
    for(i=0;i<cards.size;i++)
    {
        v = card_rank_value(cards[i]);
        s = cards[i].suit;
        if(!isDefined(rank_counts[v])) rank_counts[v]=0;
        rank_counts[v]++;
        if(!isDefined(suit_counts[s])) suit_counts[s]=[];
        suit_counts[s][suit_counts[s].size]=v;
    }

    // Check for flush
    flush_suit = undefined;
    suit_keys = get_array_keys(suit_counts);
    for(i = 0; i < suit_keys.size; i++)
    {
        s = suit_keys[i];
        if(suit_counts[s].size >= 5) flush_suit = s;
    }

    // Check for straight (and straight flush)
    straight = undefined;
    straight_flush = undefined;
    vals = [];
    for(i=0;i<cards.size;i++)
    {
        if(array_index_of(vals, card_rank_value(cards[i]))==-1)
            vals[vals.size]=card_rank_value(cards[i]);
    }
    if(vals[0]==14) vals[vals.size]=1; // Ace-low straight
    for(i=0;i<=vals.size-5;i++)
    {
        ok = true;
        for(j=1;j<5;j++)
            if(vals[i+j]!=vals[i]-j) ok=false;
        if(ok)
        {
            straight=vals[i];
            // Check for straight flush
            if(isDefined(flush_suit))
            {
                flush_vals = [];
                for(k=0;k<cards.size;k++)
                {
                    if(cards[k].suit==flush_suit && array_index_of(flush_vals, card_rank_value(cards[k]))==-1)
                        flush_vals[flush_vals.size]=card_rank_value(cards[k]);
                }
                if(flush_vals[0]==14) flush_vals[flush_vals.size]=1;
                for(m=0;m<=flush_vals.size-5;m++)
                {
                    ok2=true;
                    for(n=1;n<5;n++)
                        if(flush_vals[m+n]!=flush_vals[m]-n) ok2=false;
                    if(ok2) straight_flush=flush_vals[m];
                }
            }
        }
    }

    // Four, full house, three, two pair, pair
    pairs = [];
    trips = [];
    quads = [];
    for(v=14;v>=2;v--)
    {
        if(isDefined(rank_counts[v]))
        {
            if(rank_counts[v]==4) quads[quads.size]=v;
            else if(rank_counts[v]==3) trips[trips.size]=v;
            else if(rank_counts[v]==2) pairs[pairs.size]=v;
        }
    }

    // Now, build return arrays without array literals
    if(isDefined(straight_flush)) {
        arr = [];
        arr[0] = 8;
        arr[1] = straight_flush;
        return arr;
    }
    if(quads.size > 0) {
        arr = [];
        arr[0] = 7;
        arr[1] = quads[0];
        arr2 = [];
        arr2[0] = quads[0];
        arr[2] = get_kicker(vals, arr2);
        return arr;
    }
    if(trips.size > 0 && pairs.size > 0) {
        arr = [];
        arr[0] = 6;
        arr[1] = trips[0];
        arr[2] = pairs[0];
        return arr;
    }
    if(trips.size > 1) {
        arr = [];
        arr[0] = 6;
        arr[1] = trips[0];
        arr[2] = trips[1];
        return arr;
    }
    if(isDefined(flush_suit)) {
        arr = [];
        arr[0] = 5;
        arr[1] = suit_counts[flush_suit][0];
        arr[2] = suit_counts[flush_suit][1];
        arr[3] = suit_counts[flush_suit][2];
        arr[4] = suit_counts[flush_suit][3];
        arr[5] = suit_counts[flush_suit][4];
        return arr;
    }
    if(isDefined(straight)) {
        arr = [];
        arr[0] = 4;
        arr[1] = straight;
        return arr;
    }
    if(trips.size > 0) {
        arr = [];
        arr[0] = 3;
        arr[1] = trips[0];
        arr2 = [];
        arr2[0] = trips[0];
        // Find two kickers
        kicker_count = 0;
        for(i=0;i<vals.size;i++) {
            if(array_index_of(arr2, vals[i]) == -1) {
                arr[2 + kicker_count] = vals[i];
                kicker_count++;
                if(kicker_count == 2) break;
            }
        }
        return arr;
    }
    if(pairs.size > 1) {
        arr = [];
        arr[0] = 2;
        arr[1] = pairs[0];
        arr[2] = pairs[1];
        arr2 = [];
        arr2[0] = pairs[0];
        arr2[1] = pairs[1];
        arr[3] = get_kicker(vals, arr2);
        return arr;
    }
    if(pairs.size > 0) {
        arr = [];
        arr[0] = 1;
        arr[1] = pairs[0];
        arr2 = [];
        arr2[0] = pairs[0];
        arr[2] = get_kicker(vals, arr2);
        return arr;
    }
    // High card
    arr = [];
    arr[0] = 0;
    arr[1] = vals[0];
    arr[2] = vals[1];
    arr[3] = vals[2];
    arr[4] = vals[3];
    arr[5] = vals[4];
    return arr;
}

function get_kicker(vals, exclude)
{
    for(i=0;i<vals.size;i++)
        if(array_index_of(exclude, vals[i]) == -1)
            return vals[i];
    return 0;
}

function compare_hands(hand1, hand2)
{
    for(i=0;i<hand1.size;i++)
    {
        if(hand1[i]>hand2[i]) return 1;
        if(hand1[i]<hand2[i]) return -1;
    }
    return 0; // Tie
}

function hand_name(rank)
{
    if(rank==8) return "Straight Flush";
    if(rank==7) return "Four of a Kind";
    if(rank==6) return "Full House";
    if(rank==5) return "Flush";
    if(rank==4) return "Straight";
    if(rank==3) return "Three of a Kind";
    if(rank==2) return "Two Pair";
    if(rank==1) return "Pair";
    return "High Card";
}

// ----------- Helper Functions -----------

function get_array_keys(arr)
{
    keys = [];
    for(i = 0; i < arr.size; i++)
        if(isDefined(arr[i])) keys[keys.size] = i;
    return keys;
}

function array_index_of(arr, val)
{
    for(i = 0; i < arr.size; i++)
        if(arr[i] == val)
            return i;
    return -1;
}

function hand_description(eval)
{
    rank = eval[0];
    if(rank == 8) return "Straight Flush to " + card_rank_name(eval[1]);
    if(rank == 7) return "Four of " + card_rank_name(eval[1]) + "s";
    if(rank == 6) return "Full House: " + card_rank_name(eval[1]) + "s over " + card_rank_name(eval[2]) + "s";
    if(rank == 5) return "Flush, high card " + card_rank_name(eval[1]);
    if(rank == 4) return "Straight to " + card_rank_name(eval[1]);
    if(rank == 3) return "Three of " + card_rank_name(eval[1]) + "s";
    if(rank == 2) return "Two Pair: " + card_rank_name(eval[1]) + "s and " + card_rank_name(eval[2]) + "s";
    if(rank == 1) return "Pair of " + card_rank_name(eval[1]) + "s";
    return "High Card " + card_rank_name(eval[1]);
}

function card_rank_name(val)
{
    if(val == 14) return "Ace";
    if(val == 13) return "King";
    if(val == 12) return "Queen";
    if(val == 11) return "Jack";
    return "" + val;
}

function player_fold_choice(player, hand)
{
    if(isDefined(player.sessionstate))
    {
        hud = NewClientHudElem(player);
        hud.alignX = "center";
        hud.alignY = "middle";
        hud.horzAlign = "center";
        hud.vertAlign = "middle";
        hud.y = 200;
        hud.fontScale = 1.2;
        hud SetText("^2Use = Show cards | Crouch = Hide cards");

        choice = undefined;
        while(!isDefined(choice))
        {
            if(player UseButtonPressed())
                choice = "show";
            else if(player GetStance() == "crouch")
                choice = "hide";
            wait(0.05);
        }
        hud Destroy();
    }
    else
    {
        // AI/struct logic if needed
        choice = "hide"; // or whatever default you want for AI
    }

    if(choice == "show")
    {
        foreach(p in GetPlayers())
            p IPrintLnBold(player.name + " folds and shows: " + hand_to_string(hand));
    }
    else
    {
        foreach(p in GetPlayers())
            p IPrintLnBold(player.name + " folds.");
    }
}

// ----------- Minimal HUD Functions -----------

function create_texas_hud(player)
{
    hud = spawnstruct();
    hud.player_card_imgs = [];
    // Add more HUD elements as needed
    return hud;
}

function update_texas_hud(player, hud)
{
    // Implement HUD updates as needed
}

function destroy_texas_hud(hud)
{
    if(isDefined(hud.player_card_imgs))
    {
        for(i=0;i<hud.player_card_imgs.size;i++)
            if(isDefined(hud.player_card_imgs[i])) hud.player_card_imgs[i] Destroy();
    }
}

function destroy_flop_hud(hud_imgs)
{
    for(i=0;i<hud_imgs.size;i++)
        if(isDefined(hud_imgs[i])) hud_imgs[i] Destroy();
}
function draw_card(deck, deck_index_ref)
{
    if(deck_index_ref.idx >= deck.size)
        return undefined;
    card = deck[deck_index_ref.idx];
    deck_index_ref.idx = deck_index_ref.idx + 1;
    return card;
}
function card_to_material(card, suit)
{
    rank = card.rank;
    if(rank == 11)
        rank_str = "jack";
    else if(rank == 12)
        rank_str = "queen";
    else if(rank == 13)
        rank_str = "king";
    else if(rank == 14)
        rank_str = "ace";
    else
        rank_str = rank + "";

    return rank_str + "_of_" + suit;
}
function card_rank_value(card)
{
    return card.rank;
}
function hand_to_string(hand)
{
    str = "";
    for(i = 0; i < hand.size; i++)
    {
        card = hand[i];
        // Get rank name
        if(card.rank == 14)
            rank_str = "Ace";
        else if(card.rank == 13)
            rank_str = "King";
        else if(card.rank == 12)
            rank_str = "Queen";
        else if(card.rank == 11)
            rank_str = "Jack";
        else
            rank_str = card.rank + "";
        // Just use the suit as-is given the limited number of options and to avoid long names
        suit_str = card.suit;
        card_str = rank_str + " of " + suit_str;
        if(i > 0)
            str += ", ";
        str += card_str;
    }
    return str;
}