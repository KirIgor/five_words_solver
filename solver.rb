# frozen_string_literal: true

WORDS = File.read("dict.txt").split("\n")
FIRST_WORD = "океан" # precalculated
FULL_SEARCH_THRESHOLD = 40
PRECALCULATED_FIRST_ROUND = {
  "ччччч" => "силур",
  "жчччч" => "сироп",
  "чжччч" => "тупик",
  "ччжчч" => "литер",
  "чччжч" => "мирта",
  "ччччж" => "лунит",
  "жчччж" => "рондо",
  "жччжч" => "тропа",
  "жчжчч" => "торец",
  "жжччч" => "ролик",
  "чжччж" => "узник",
  "чжчжч" => "кабил",
  "чжжчч" => "телик",
  "ччжчж" => "центр",
  "ччжжч" => "талер",
  "чччжж" => "раина",
}

class LetterProps
  attr_reader :letter
  attr_accessor :positions, :excluded_positions, :included, :excluded
  alias included? included
  alias excluded? excluded

  def initialize(letter, positions: [], excluded_positions: [], included: false, excluded: false)
    @letter = letter
    self.positions = positions
    self.excluded_positions = excluded_positions
    self.included = included
    self.excluded = excluded
  end

  def suitable?(word)
    letters = word.split("")
    positions = letters.each_index.select{ |i| letters[i] == letter }

    return false if self.positions.any? && (self.positions - positions).any?
    return false if excluded_positions.intersect?(positions)
    return false if included? && positions.empty?
    return false if excluded? && positions.any?
    true
  end

  def add_position!(index)
    self.included = true
    positions << index
    positions.uniq!
  end

  def exclude_position!(index)
    self.included = true
    excluded_positions << index
    excluded_positions.uniq!
  end
end

class WordMask
  attr_reader :mask

  def initialize(mask = {})
    @mask = mask
  end

  def [](letter)
    mask[letter] ||= LetterProps.new(letter)
  end

  def consume_round_mask!(checked_word, round_mask)
    for i in 0...5
      letter = checked_word[i]
      signal = round_mask[i]
      letter_props = self.[](letter)

      case signal
      when "з"
        letter_props.add_position!(i)
      when "ж"
        letter_props.exclude_position!(i)
      when "ч"
        letter_props.excluded = true
      end
    end
  end

  def filter_words(words)
    words.select do |word|
      mask.values.all? { |letter_props| letter_props.suitable?(word) }
    end
  end

  def compare_words!(hidden, checked)
    for i in 0...5
      letter = checked[i]
      letter_props = self.[](letter)
  
      if hidden.include?(letter)
        letter_props.included = true
      else
        letter_props.excluded = true
      end
  
      if hidden[i] == letter
        letter_props.add_position!(i) 
      else
        letter_props.exclude_position!(i) if letter_props.included?
      end
    end
  end
end

class Game
  attr_reader :mask, :filtered_words, :checked_word, :round, :round_mask

  def initialize
    @mask = WordMask.new
    @filtered_words = WORDS
    @checked_word = FIRST_WORD
    @round = 0
  end

  def next_round
    @round_mask = prompt_round_mask
    mask.consume_round_mask!(checked_word, round_mask)
    @filtered_words = mask.filter_words(filtered_words)
    @checked_word = find_best
    @round += 1
    return checked_word
  end

  def prompt_round_mask
    printf "Enter round mask (ex. ззжчз): "
    gets.chomp
  end

  private

  def find_best
    precalculated = PRECALCULATED_FIRST_ROUND[@round_mask]
    return precalculated if @round == 0 && !precalculated.nil?

    # only filtered check works much faster but it less efficient
    # especially when there are a lot of letters with position (ex вахта, тахта, бахта, шахта and mask *ахта)
    checked_words = filtered_words.size <= FULL_SEARCH_THRESHOLD ? WORDS : filtered_words

    checked_words.min_by.with_index do |checked, i|
      # puts "#{i} / #{checked_words.size}"

      filtered_words.sum do |hidden|
        mask = WordMask.new
        mask.compare_words!(hidden, checked)
        mask.filter_words(filtered_words).size
      end
    end
  end
end

def print_greeeting
  puts "How to enter round mask:"
  puts "  з = letter at right position"
  puts "  ж = there is letter in word but not on that position"
  puts "  ч = there is no letter in word"
  puts "Best first word is #{FIRST_WORD}"
end

game = Game.new
print_greeeting

while true
  next_best = game.next_round
  if game.filtered_words.size == 1
    puts "Word of game is #{game.filtered_words.first}. Game finished."
    puts "Starting new game..."
    puts
    game = Game.new
    print_greeeting
  else
    puts "Next best word is #{next_best}"
  end
end
