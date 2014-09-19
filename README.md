Blade-SenNoKiseki-
==================

Codegolf challenge.

# Detailed Rules

32 cards:

    CardDesignation NumberOfCards (CardsValue)
    1 2 (1)
    2 3 (2)
    3 4 (3)
    4 4 (4)
    5 4 (5)
    6 3 (6)
    7 2 (7)
    B 6 (1)
    M 4 (1)

(B=Bolt, M=Mirror)


# Hidden Cards
 - you can see:
   - the cards in your hand
   - the cards on the field (yours+opp.)
 - you cannot see:
   - the cards in your deck
   - the cards in your opponent's deck
   - the cards in the opponent's hand


# Preparation

 - Take 32 cards as described above, and split into two decks
 - 2 players, one deck of 16 cards each
 - Each player draws 10 cards from his deck
 - Goto Initialization.

# Initialization

    (deck empty, hand empty)
        - Draw
    (deck empty, hand not empty)
        - place card from hand on the field
    (deck not empty)
        - draw card, place on the field
  
 - Repeat until score is not equal.
 - Player with lower score begins.
 - Goto Turn.

# Turn

    (hand empty)
        (opponent's hand empty)
            - Calculate both player's score
                (equal)
                    - Draw
                (not equal)
                    - player with highest score Wins
                    - player with lower score Loses
        (opponent's hand not empty)
            - You Lose.
    (hand not empty)
        - place card from your hand on the field
            (card is last card, and M or B)
                - You Lose
            (otherwise)
                - Reevaluate field.
                - Calculate score.
                    (your score is lower)
                        - you lose
                    (your score is equal to the opp.)
                        - Goto Initialization.
                    (your score is higher)
                        - Goto opponent's Turn.

# Score Calculation

 - add values of all cards on your field, excluding invalidated cards

# Field Reevaluation

    (card is 2-7)
        - remove your invalidated card if applicable
    (card is M)
        - exchange field cards, including invalidated cards
    (card is B)
        - remove opponent's invalidated card if applicable
        - invalidate most recently played card on the opponent's field
        (card is 1)
            (invalidated card on your field)
                - validate this card
            (otherwise)
                - remove your invalidated card if applicable
    
# Scoring

    - both players start with a score of 0
    - N (tbd - to be decided) turns, timelimit T (tbd), for each turn:
        (Draw)
            - score +1
        (Win)
            - score +2
        (Lose)
            - score +0
   
# Input

 - your program (cli) gets called once for each decision it need to make
 - ie, choosing a card to play, or choosing an initial card when there are no cards left in your deck
 - stdin
 - one line, including a newline, with a json object representing the current state

# Output

 - stdout
 - a number, including a newline, representing the card you wish to play
 - 0 corresponds to the first card in the json["player"]["hand"] array    

# Sample JSON input

See file `sample_json`.

# Sample match

See file `sample_match`
