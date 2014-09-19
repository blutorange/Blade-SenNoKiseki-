require 'timeout'
require 'json'

################################################################################
class Draw < StandardError ; end
class Winner < StandardError ; end
class InvalidResponse < StandardError ; end
class RuntimeError < StandardError ; end
class TimelimitError < StandardError ; end

class NilClass
    def inspect
        nil
    end
end

class Card
    attr_reader :type
    attr_reader :valid
    def initialize(type)
        @valid = true
        if type == :bolt
            @type = 0
            @value = 1
        elsif type == :mirror
            @type = 8
            @value = 1
        else
            @type = type.to_i
            @value = @type
        end
        @type.freeze
    end
    def invalid?
        not @valid
    end
    def is_1?
        @type == 1
    end
    def is_2?
        @type == 2
    end
    def is_3?
        @type == 3
    end
    def is_4?
        @type == 4
    end
    def is_5?
        @type == 5
    end
    def is_6?
        @type == 6
    end
    def is_7?
        @type == 7
    end
    def is_bolt?
        @type == 0
    end
    def is_mirror?
        @type == 8
    end
    def is_valid?
        @valid
    end
    def validate!
        @valid = true
    end
    def invalidate!
        @valid = false
    end
    def value
        @valid ? @value : 0
    end
    def sort_order
        case @type
        when 0
            8
        when 8
            9
        else
            @value
        end
    end
    def <=>(card)
        self.sort_order <=> card.sort_order
    end
    def to_s
        if (1..7).include?(@type)
            @type.to_s + (@valid ? '' : 'X')
        elsif @type == 0
            'B'
        elsif @type == 8
            'M'
        end
    end
    def inspect
        {"type" => @type, "value" => @value, "valid" => @valid}
    end
end

class Hand < Array
    attr_reader :cards
    def initialize(*args)
        super(*args)
    end
    def to_s
        sort.map(&:to_s).join(' ')
    end
end

class Deck < Array
    attr_reader :cards
    def initialize(*args)
        super
    end
    def to_s
        map(&:to_s).join(' ')
    end
end

class Field < Array
    attr_reader :cards
    def initialize(*args)
        super
    end
    def to_s
        map(&:to_s).join(' ')
    end
    def score
        map(&:value).inject(0,&:+)
    end
    def pop_invalid
        pop if last && last.invalid?
    end
end

################################################################################
def debug(str)
    $stderr.puts str if Debug
end

################################################################################
def current_state(player, turn)  
    opponent = (player + 1) % 2
    state = {
        "file" => Prog[player][3],
        "turn" => turn,
        "player" => {
            "hand" => Hands[player].map(&:inspect),
            "field" => Fields[player].map(&:inspect),
            "deck" => Decks[player].length,
            "score" => Fields[player].score,
            "lastmove" => LastMove[player].inspect
        },
        "opponent" => {
            "hand" => Hands[opponent].length,
            "field" => Fields[opponent].map(&:inspect),
            "deck" => Decks[opponent].length,
            "score" => Fields[opponent].score,
            "lastmove" => LastMove[opponent].inspect
        }
    }
    JSON.generate(state)
end

def request_card(player, turn)
    resp = -1
    begin
        state = current_state(player, turn)
        Timeout::timeout(Timelimit) do
            IO.popen(Prog[player][0],"w+") do |io|
                start = Time.now
                io.puts state
                resp = io.gets
                Prog[player][2] += Time.now - start
            end
        end
    rescue Timeout::Error
        raise TimelimitError, player
    rescue StandardError
        raise RuntimeError, player
    end
    card = resp.to_i
    if (0..Hands[player].length-1).include?(card)
        Hands[player][card]
    else
        raise InvalidResponse, player
    end
end


################################################################################
def init(player, turn)
    debug "Player #{player} draws initial card."
    opponent = (player + 1) % 2
    if Decks[player].empty?
        debug "But player #{player}'s deck is empty."
        debug "Player #{player}'s hand (#{Hands[player].length}): #{Hands[player]}"
        if Hands[player].empty?
            if Decks[opponent].empty? && Hands[opponent].empty?
                debug "Opponent's deck is empty as well."
                raise Draw
            else
                debug "Only the player's deck is empty."
                raise Winner, opponent
            end
        else
            card = request_card(player, turn)
            debug "Player #{player} selects #{card}, and puts it on the field."
            Hands[player].delete(card)
            Fields[player].push(card)
        end
    else
        card = Decks[player].pop
        Fields[player].push(card)
        debug "Player draws #{card}, and puts it on the field."
    end
end

def first_turn
    score0 = Fields[0].score
    score1 = Fields[1].score
    if score0 > score1
        1
    elsif score0 < score1
        0
    else
        debug "Both player's initial scores are equal."
        -1
    end
end

def play_card(player, turn, card)
    debug "Player #{player} plays #{card}."
    opponent = (player + 1) % 2
    Hands[player].delete(card)
    if card.is_1?
        if Fields[player].last.invalid?
            Fields[player].last.validate!
        else
            Fields[player].push(card)
        end
    elsif card.is_bolt?
        Fields[opponent].pop_invalid
        Fields[opponent].last.invalidate!
    elsif card.is_mirror?
        Fields[0], Fields[1] = Fields[1], Fields[0]
    else
        Fields[player].pop_invalid
        Fields[player].push(card)
    end
end

def turn(player, turn)
    opponent = (player + 1) % 2
    debug "\n\nTurn #{turn} starts."
    debug "Player #{player}'s turn."
    debug "Player 0's field: #{Fields[0]} (#{Fields[0].score})"
    debug "Player 1's field: #{Fields[1]} (#{Fields[1].score})"
    debug "Player 0's hand (#{Hands[0].length}): #{Hands[0]}"
    debug "Player 1's hand (#{Hands[1].length}): #{Hands[1]}"
    debug "Cards remaining in player 0's deck: #{Decks[0].length}."
    debug "Cards remaining in player 1's deck: #{Decks[1].length}."
    if Hands[player].empty?
        if Hands[opponent].empty?
            score_player = Fields[player].score
            score_opponent = Fields[opponent].score
            if score_player == score_opponent
                debug "Both players got the same score."
                raise Draw
            elsif score_player > score_opponent
                debug "Player #{player}'s score is higher."
                raise Winner, player
            else
                debug "Player #{opponent}'s score is higher."
                raise Winner, opponent
            end
        else
            debug "Only player #{player} is left with no cards in his hand."
            raise Winner, opponent
        end
    else
        card = request_card(player, turn)      
        if Hands[player].length == 1 && (card.is_mirror? || card.is_bolt?)
            debug "Player #{player} played bolt or lightning as his last card."
            raise Winner, opponent
        else
            play_card(player, turn, card)
            score_player = Fields[player].score
            score_opponent = Fields[opponent].score
            if score_player == score_opponent
                debug "Both player's scores are equal."
                return false
            elsif score_player < score_opponent
                debug "Player #{player} could not match the opponent's score."
                raise Winner, opponent
            end
        end
        LastMove[player] = card
    end
    debug "Player #{player} ends his turn."
    debug "Player 0's field: #{Fields[0]} (#{Fields[0].score})"
    debug "Player 1's field: #{Fields[1]} (#{Fields[1].score})"
    return true
end


################################################################################

def initialize_round(player0, player1)
    # setup command lines
    Prog[0] = Players[player0]
    Prog[1] = Players[player1]

    # prepare deck of 32 cards
    cards = [
        Card.new(1),
        Card.new(1),
        Card.new(2),
        Card.new(2),
        Card.new(2),
        Card.new(2),
        Card.new(3),
        Card.new(3),
        Card.new(3),
        Card.new(3),
        Card.new(4),
        Card.new(4),
        Card.new(4),
        Card.new(4),
        Card.new(5),
        Card.new(5),
        Card.new(5),
        Card.new(5),
        Card.new(6),
        Card.new(6),
        Card.new(6),
        Card.new(7),
        Card.new(7),
        Card.new(:bolt),
        Card.new(:bolt),
        Card.new(:bolt),
        Card.new(:bolt),
        Card.new(:bolt),
        Card.new(:bolt),
        Card.new(:mirror),
        Card.new(:mirror),
        Card.new(:mirror),
    ]

    # each player gets a deck of 16 cards at random
    Decks[0].clear
    Decks[1].clear
    16.times do
        Decks[0].push(cards.shuffle!.pop)
        Decks[1].push(cards.shuffle!.pop)
    end

    debug "Each player gets a deck of 16 cards."
    debug "Player 0: #{Decks[0]}"
    debug "Player 1: #{Decks[1]}"

    # each player draws 10 cards
    Hands[0].clear
    Hands[1].clear
    10.times do
        Hands[0].push(Decks[0].pop)
        Hands[1].push(Decks[1].pop)
    end

    debug "Each player draws 10 cards."
    debug "Player 0: #{Hands[0]}"
    debug "Player 1: #{Hands[1]}"
    debug "Cards remaining in each deck:"
    debug "Player 0: #{Decks[0]}"
    debug "Player 1: #{Decks[1]}"

    # each player starts with an empty field
    Fields[0].clear
    Fields[1].clear

    # no move has been made yet
    LastMove.clear
end


################################################################################

def duel(player0, player1)
    debug "\n\n\nMatch between both players starts."
    debug "<#{player0}> vs. <#{player1}>"

    
    round = 0
    score = [0,0]

    while round < Rounds
        debug "\n\nInitializing round #{round}."
        initialize_round(player0, player1)
        debug "\n\nRound #{round} starts."
        begin
            loop do
                player = -1
                turn = 0
                while player == -1
                    debug "\n\nField initialization starts."
                    Fields[0].clear
                    Fields[1].clear
                    init(0, turn)
                    init(1, turn)
                    player = first_turn
                end
                debug "Player #{player} gets first turn."
                while turn(player % 2, turn)
                    player += 1
                    turn += 1
                end
            end
        rescue Draw
            score[0] += 2
            score[1] += 2
        rescue Winner => player
            debug "Player #{player} wins this turn."
            score[player.message.to_i] += 2
        rescue TimelimitError => player
            debug "Player #{player} was thinking too long and loses this turn."
            score[(player.message.to_i+1)%2] += 2
        rescue RuntimeError => player
            debug "Player #{player}'s mind broke and he loses this turn."
            score[(player.message.to_i+1)%2] += 2
        rescue InvalidResponse => player
            debug "Player #{player} made an invalid move and loses this turn."
            score[(player.message.to_i+1)%2] += 2
        end
        round += 1
    end

    debug "\n\nMatch between both players ends."
    debug "Player 0's score: #{score[0]}"
    debug "Player 1's score: #{score[1]}"

    Prog[0][1] += score[0]
    Prog[1][1] += score[1]
end

################################################################################

if ARGV.length != 4
    puts "usage: ruby #{$0} <players> <timelimit> <turns> <quiet (y/n)>"
    exit
end

Playerfile = ARGV[0]
Timelimit = ARGV[1].to_f
Rounds = ARGV[2].to_i
Debug = ARGV[3].downcase == 'y' ? false : true

Players = {}
File.read(Playerfile).each_line do |line|
        next if line.empty? || line[0] == '#'
        player = line.chomp.split('~')
        file = File.expand_path(File.join('files',player[0].strip))
        File.open(file,'w'){}
        Players[player[0].strip] = [player[1].strip,0,0.0,file]
end

Decks = [Deck.new, Deck.new]
Hands = [Hand.new, Hand.new]
Fields = [Field.new, Field.new]
LastMove = Array.new
Prog = Array.new

# initialize random generator
File.open("/dev/random") do |dev_random|
    seed = dev_random.read(4).unpack('l').first
    debug "Random seed: #{seed}"
    srand(seed)
end

duel "basic", "basic"
exit

Players.each_key do |p0|
    Players.each_key do |p1|
        if p0 != p1
            puts "#{p0.ljust(16)} vs. #{p1.rjust(16)}"
            duel p0,p1
        end
    end
end

matches = 2 * (Players.length * (Players.length-1) * Rounds).to_f
puts "\n\nMatches: #{matches}"
puts "\nResults:\n"
Players.each_pair do |name,val|
    puts "#{name.ljust(16)}: #{(100*val[1]/matches).round(2)}% (#{val[2]}s)"
end
